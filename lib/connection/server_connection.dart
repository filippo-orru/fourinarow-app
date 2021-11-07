import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/util/logger.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'messages.dart';
import 'package:four_in_a_row/util/extensions.dart';

const int CONNECTION_WAS_LOST_TIMEOUT_S = 30;

class ServerConnection with ChangeNotifier {
  WebSocketChannel? _connection;

  Timer? _reconnectionTimer;

  Timer? _connectionWasLostTimer; // fires after 30s (server closed connection)

  StreamController<ServerMessage> _serverMsgStreamCtrl =
      StreamController<ServerMessage>.broadcast();
  Stream<ServerMessage> get serverMsgStream => _serverMsgStreamCtrl.stream;
  // StreamSubscription? _serverMsgSub;

  // Stays open for the app's lifetime.
  // ignore: close_sinks
  StreamController<PlayerMessage> _playerMsgStreamCtrl =
      StreamController<PlayerMessage>.broadcast();
  Stream<PlayerMessage> get playerMsgStream => _playerMsgStreamCtrl.stream;
  StreamSubscription? _playerMsgSub;

  // Stays open for the app's lifetime.
  // ignore: close_sinks
  StreamController<ReliablePacketIn> _reliablePktInStreamCtrl =
      StreamController<ReliablePacketIn>.broadcast();

  StreamController<ReliablePacketOut> _reliablePktOutStreamCtrl =
      StreamController<ReliablePacketOut>.broadcast();
  StreamSubscription? _reliablePktOutSub;

  StreamController<ReliablePacketIn> _wsInStreamCtrl =
      StreamController<ReliablePacketIn>.broadcast();
  StreamSubscription? _wsInSub;

  int _serverMsgIndex = 0;
  final List<QueuedMessage<ServerMessage>> _serverMsgQ = [];
  int _playerMsgIndex = 0;
  final List<QueuedMessage<PlayerMessage>> _playerMsgQ = [];

  SessionState _sessionState = SessionStateIdle();

  bool get connected => _sessionState is SessionStateConnected;

  bool get outdated => _sessionState is SessionStateOutDated;

  bool get serverIsDownSync => _sessionState is SessionStateServerIsDown;

  bool tryingToConnect = false;

  Future<bool> get serverIsDown async =>
      _sessionState is SessionStateServerIsDown &&
      await _serverIsDownState.isDown;

  ServerIsDownState _serverIsDownState = ServerIsDownState();

  bool catastrophicFailure = false;

  int _connectionTries = 0;
  Timer? _missingMsgSince;
  bool waitingForPong = false;

  ServerConnection() {
    _connect();
    _resendQueuedInterval();
    _sendPingsInterval();
    _startListening();
  }

  /// Returns future that completes when the message was acknowledged by the server.
  /// In case connection was lost, the future will complete with false.
  Future<bool> send(PlayerMessage msg) async {
    this._playerMsgIndex += 1;
    int messageId = _playerMsgIndex;
    Future<bool> connectionWasReset;
    Future<bool> packetWasAcknowledged =
        this._reliablePktInStreamCtrl.stream.any((rPkt) {
      return rPkt is ReliablePktAckIn && rPkt.id == messageId;
    }).then((_) => true);
    connectionWasReset = this
        ._serverMsgStreamCtrl
        .stream
        .any((msg) => msg is MsgReset)
        .then((_) => false);

    this._reliablePktOutStreamCtrl.add(ReliablePktMsgOut(messageId, msg));
    this._playerMsgStreamCtrl.add(msg);

    return waitAny([packetWasAcknowledged, connectionWasReset]);
  }

  void retryConnection({bool force = false, bool reset = false}) {
    _connect(force: force, reset: reset);
  }

  void close() {
    _reconnectionTimer?.cancel();

    _serverMsgStreamCtrl.close();

    _wsInStreamCtrl.close();

    // Not closing this because it would case errors and messages will
    //  just not be received anyway.
    //_playerMsgStreamCtrl.close();
    //_reliablePktOutStreamCtrl.close();

    _connection?.sink.close();
  }

  void _connect({bool force = false, bool reset = false}) async {
    if ((_sessionState is SessionStateOutDated ||
            _sessionState is SessionStateConnected) &&
        !force) {
      return;
    }

    this._connectionTries += 1;
    Logger.v("Opening connection (${this._connectionTries}. try)");

    tryingToConnect = true;
    notifyListeners();
    Future.delayed(Duration(milliseconds: 1000), () {
      tryingToConnect = false;
      notifyListeners();
    });

    if (await serverIsDown) {
      Logger.w("Server is down");
      _websocketDone();
      return;
    }

    _reconnectionTimer?.cancel();
    _connection?.sink.close();

    if (kIsWeb) {
      this._connection = _connectWeb();
    } else {
      this._connection = await _connectDevice();
      if (_connection == null) {
        _websocketDone();
        return;
      }
    }

    await Future.delayed(Duration(milliseconds: 100));

    _connectionWasLostTimer?.cancel();
    this._wsInSub?.cancel();
    _wsInSub = _handleWsIn(_connection!.stream);
    this._reliablePktOutSub?.cancel();
    _reliablePktOutSub = _handleReliablePktOut(_connection!.sink);

    if (reset) {
      _reliablePktOutStreamCtrl.add(ReliablePktHelloOut());
      this._sessionState = SessionStateWaiting();
    } else {
      var sessionState = this._sessionState;
      if (sessionState is SessionStateDisconnected) {
        _reliablePktOutStreamCtrl
            .add(ReliablePktHelloOut(sessionState.identifier));
        this._sessionState =
            SessionStateWaiting(identifier: sessionState.identifier);
      } else if (sessionState is SessionStateWaiting &&
          sessionState.identifier != null) {
        _reliablePktOutStreamCtrl
            .add(ReliablePktHelloOut(sessionState.identifier!));
        this._sessionState =
            SessionStateWaiting(identifier: sessionState.identifier!);
      } else if (sessionState is! SessionStateConnected) {
        _reliablePktOutStreamCtrl.add(ReliablePktHelloOut());
        this._sessionState = SessionStateWaiting();
      }
    }

    Future.delayed(Duration(milliseconds: 4000), () {
      if (this._sessionState is SessionStateWaiting) {
        Logger.w("Connection not established after 4 seconds");
        _resetReliabilityLayer(reconnect: true);
      }
    });

    notifyListeners();
  }

  WebSocketChannel _connectWeb() {
    return WebSocketChannel.connect(Uri.parse(WS_PREFIX + "://$WS_PATH"));
  }

  Future<WebSocketChannel?> _connectDevice() async {
    try {
      HttpClient client = HttpClient();
      HttpClientRequest? request = await client
          .getUrl(Uri.parse(HTTP_PREFIX + "://$WS_PATH"))
          .timeout(Duration(seconds: 4))
          .then<HttpClientRequest?>((r) => r)
          .catchError((e, stack) {
        Logger.w("Error while making request to websocket server");
        client.close(force: true);
        return null;
      });
      if (request == null) {
        return null;
      }
      Random random = new Random();
      // Generate 16 random bytes.
      Uint8List nonceData = new Uint8List(16);
      for (int i = 0; i < 16; i++) {
        nonceData[i] = random.nextInt(256);
      }
      request.headers
        ..set(HttpHeaders.connectionHeader, "Upgrade")
        ..set(HttpHeaders.upgradeHeader, "websocket")
        ..set("Sec-WebSocket-Key", nonceData.join())
        ..set("Cache-Control", "no-cache")
        ..set("Sec-WebSocket-Version", "13");

      return await request
          .close()
          .timeout(Duration(seconds: 3))
          .then<WebSocketChannel?>((response) async {
        // ignore: close_sinks
        var socket = await response.detachSocket();
        return WebSocketChannel(
          StreamChannel(socket, socket),
          serverSide: false,
          pingInterval: Duration(seconds: 1),
        );
      }).catchError((e, stack) {
        Logger.e("Error while converting socket to WebSocketChannel", e, stack);
        request.abort();
        return null;
      });
    } on SocketException catch (e) {
      var errCode = 0;
      if (e.osError?.errorCode != null) errCode = e.osError!.errorCode;
      if (![7, 101, 103].contains(errCode)) {
        Logger.e("Unknown connection err: $e");
      } else {
        // Network is unreachable / network err
      }
      return null;
    } on Exception {
      return null;
    }
  }

  StreamSubscription? _handleWsIn(Stream<dynamic> wsStream) {
    // debugPrintStack();

    try {
      return wsStream.listen(
        this._receivedWsMsg,
        onError: this._websocketErr,
        onDone: this._websocketDone,
        cancelOnError: true,
      );
    } on Exception catch (e) {
      Logger.e("Exception!", e, StackTrace.current);
      _websocketDone();
    }
  }

  StreamSubscription _handleReliablePktOut(StreamSink<dynamic> wsSink) {
    return this._reliablePktOutStreamCtrl.stream.listen(
      (rPkt) {
        if (rPkt is ReliablePktMsgOut) {
          this._playerMsgQ.add(QueuedMessage(rPkt.id, rPkt.msg));
          if (!connected) {
            return;
          }
        }

        String msgStr = rPkt.serialize();
        Logger.v("<< $msgStr");
        try {
          wsSink.add(msgStr);
        } on Exception catch (e) {
          Logger.e("Exception!", e, StackTrace.current);
          _websocketDone();
          return;
        }
      },
      onError: this._websocketErr,
      onDone: this._websocketDone,
      cancelOnError: true,
    );
  }

  void _receivedWsMsg(dynamic msg) {
    if (msg is String) {
      if (msg.contains("error")) {
        Logger.w(">> $msg");
      } else {
        Logger.v(">> $msg");
      }
      var rPkt = ReliablePacketIn.parse(msg);
      if (rPkt == null) return;
      this._receivedReliablePacket(rPkt);
    } else {
      Logger.v(">> \"$msg\"");
      Logger.w("Received message of unknown type! (${msg.runtimeType})");
    }
  }

  void _websocketErr(dynamic? err) {
    if (err is WebSocketChannelException &&
        err.inner is WebSocketChannelException) {
      var inner = err.inner as WebSocketChannelException;
      if (inner.inner is SocketException) {
        var innerInner = inner.inner as SocketException;
        if (innerInner.osError?.errorCode == 7 ||
            innerInner.osError?.errorCode == 111) {
          // Network error (no connection)
          return;
        }
      }
    }
    Logger.e("Unexpected websocket error", err);
  }

  void _websocketDone() async {
    if (catastrophicFailure) return;

    // debugPrintStack();

    int waitTimeMs =
        (min(24.0, 1 + pow(_connectionTries.toDouble(), 1.5)) * 1000).toInt();
    String waitTimeFormatted =
        (waitTimeMs.toDouble() / 1000.0).toStringAsFixed(2);
    Logger.i("Connection closed (retry in $waitTimeFormatted)");
    var sessionState = this._sessionState;
    if (sessionState is SessionStateConnected) {
      this._sessionState = SessionStateDisconnected(sessionState.identifier);
    } else if (sessionState is SessionStateWaiting &&
        sessionState.identifier != null) {
      this._sessionState = SessionStateDisconnected(sessionState.identifier!);
    } else {
      this._sessionState = SessionStateFullyDisconnected();
    }

    notifyListeners();
    var timeout = Duration(
      milliseconds: waitTimeMs,
    );
    if (_connectionWasLostTimer?.isActive != true) {
      // only check connectivity if no timer is set. To prevent double firing _connect();
      Connectivity().checkConnectivity().then((r) async {
        if (r == ConnectivityResult.none) {
          ConnectivityResult? result = await Connectivity()
              .onConnectivityChanged
              .toNullable()
              .firstWhere((result) =>
                  result == ConnectivityResult.wifi ||
                  result == ConnectivityResult.mobile)
              .timeout(timeout, onTimeout: () => null);
          if (result != null) {
            Logger.i("Force connect (${result.toString().split(".")[1]})");
            _connect();
          }
        }
      });
      _connectionWasLostTimer =
          Timer(Duration(seconds: CONNECTION_WAS_LOST_TIMEOUT_S), () {
        if (_sessionState is SessionStateServerIsDown ||
            _sessionState is SessionStateFullyDisconnected) return;

        _serverMsgStreamCtrl.add(MsgReset());
        this._sessionState = SessionStateFullyDisconnected();
      });
    }
    _reconnectionTimer = Timer(timeout, () {
      if (!connected) _connect();
    });

    if (_sessionState is SessionStateFullyDisconnected &&
        await _serverIsDownState.isDown) {
      _sessionState = SessionStateServerIsDown();
      _serverMsgStreamCtrl.add(MsgReset());
    }
  }

  void _resetReliabilityLayer({required bool reconnect}) {
    this._playerMsgIndex = 0;
    this._serverMsgIndex = 0;

    this._serverMsgStreamCtrl.add(MsgReset());

    if (reconnect) {
      Logger.w("Resetting reliability layer", null, StackTrace.current);

      this._playerMsgQ.clear();
      this._serverMsgQ.clear();

      this._sessionState = SessionStateFullyDisconnected();
      //this.retryConnection(force: true, reset: true);
      this._connection!.sink.close();
    }
  }

  void _receivedReliablePacket(ReliablePacketIn rPkt) {
    // Logger.d("Received reliable packet: $rPkt");
    if (rPkt is ReliablePktMsgIn) {
      final int expectedId = this._serverMsgIndex + 1;
      if (rPkt.id == expectedId) {
        this._serverMsgIndex = rPkt.id;
        if (rPkt.msg is MsgPong) {
          waitingForPong = false;
        }

        this._serverMsgStreamCtrl.sink.add(rPkt.msg);
        _missingMsgSince?.cancel();
        this._ackMessage(rPkt.id);
      } else if (rPkt.id > expectedId) {
        if (_missingMsgSince == null) {
          _missingMsgSince = Timer(Duration(milliseconds: 6500), () {
            Logger.w("Message(id=$expectedId) missing");
            this._resetReliabilityLayer(reconnect: true);
          });
        }
        this._queueMessgage(rPkt.id, rPkt.msg);
        this._ackMessage(this._serverMsgIndex);
      } else {
        // Client re-sent already known message -> maybe ack got lost -> ack but don't process
        this._ackMessage(rPkt.id);
      }
      this._processQueue();
    } else if (rPkt is ReliablePktAckIn) {
      if (this._playerMsgQ.any((msg) => msg.id == rPkt.id)) {
        this._playerMsgQ.removeWhere((msg) => msg.id == rPkt.id);
      } else {
        Logger.w("Got Ack for unknown message");
        this._resetReliabilityLayer(reconnect: true);
      }
      // } else
    } else if (rPkt is ReliablePktHelloIn) {
      if (this._sessionState is! SessionStateWaiting) {
        Logger.w("Got unexpected ReliablePktHelloIn");
        this._playerMsgQ.clear();
        this._serverMsgQ.clear();
        this._resetReliabilityLayer(reconnect: false);
      }
      if (rPkt.foundState == FoundState.New) {
        this._resetReliabilityLayer(reconnect: false);
      }
      _connectionTries = 0;
      this._sessionState = SessionStateConnected(rPkt.sessionIdentifier);
      this._serverMsgStreamCtrl.add(MsgHello());
      notifyListeners();
    } else if (rPkt is ReliablePktHelloInOutDated) {
      this._sessionState = SessionStateOutDated();
    } else if (rPkt is ReliablePktErrIn) {
      Logger.w("Got ReliablePktErrIn");

      if (rPkt.error == ReliablePktErr.KillClient) {
        // Failsafe sent by server in case the client is fucking up bad.
        // Crash the app after showing dialog.
        catastrophicFailure = true;
        close();
        notifyListeners();
        Future.delayed(Duration(seconds: 3), () {
          SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
          if (Platform.isIOS) {
            exit(0);
          }
        });
        return;
      }

      this._resetReliabilityLayer(reconnect: true);
      // this.retryConnection(force: true);
    } else if (rPkt is ReliablePktNotConnectedIn) {
      Logger.w("Got ReliablePktNotConnectedIn");
      this._resetReliabilityLayer(reconnect: true);
      // this.retryConnection(force: true);
    } else {
      throw UnimplementedError("Unexpected Reliable Pkt $rPkt");
    }
  }

  void _ackMessage(int id) {
    this._reliablePktOutStreamCtrl.add(ReliablePktAckOut(id));
  }

  void _queueMessgage(int id, ServerMessage msg) {
    this._serverMsgQ.add(QueuedMessage(id, msg));
  }

  void _processQueue() {
    bool added = false;
    do {
      added = false;
      [...this._serverMsgQ].asMap().forEach((index, queuedMessage) {
        int expectedId = this._serverMsgIndex + 1;
        if (queuedMessage.id == expectedId) {
          this._serverMsgQ.removeAt(index);
          this._serverMsgIndex = expectedId;
          this._serverMsgStreamCtrl.sink.add(queuedMessage.msg);
          this._ackMessage(expectedId);
          added = true;
        }
      });
    } while (added);
  }

  void _resendQueuedInterval() {
    Timer.periodic(Duration(milliseconds: QUEUE_CHECK_INTERVAL_MS), (_) {
      if (_sessionState is SessionStateConnected) {
        _resendQueued();
      }
    });
  }

  void _sendPingsInterval() {
    // TODO vv reenable?

    // Timer.periodic(Duration(milliseconds: 6 * QUEUE_CHECK_INTERVAL_MS), (_) {
    //   if (!waitingForPong) {
    //     _playerMsgStreamCtrl.add(PlayerMsgPing());
    //     waitingForPong = true;
    //   }
    // });
  }

  void _startListening() {
    serverMsgStream.listen((msg) {
      if (msg is MsgReadyForGamePing) {
        send(PlayerMsgReadyForGamePong());
      }
    });
  }

  void _resendQueued() {
    DateTime threshold = DateTime.now()
        .subtract(Duration(milliseconds: QUEUE_RESEND_TIMEOUT_MS));
    int offset = 0;
    [...this._playerMsgQ].asMap().entries.forEach((MapEntry entry) {
      int index = entry.key;
      QueuedMessage<PlayerMessage> queuedMessage = entry.value;

      if (queuedMessage.sent.isBefore(threshold)) {
        this
            ._reliablePktOutStreamCtrl
            .add(ReliablePktMsgOut(queuedMessage.id, queuedMessage.msg));
        this._playerMsgQ.removeAt(index - offset);
        offset += 1;
      }
    });
  }
}

abstract class SessionState {}

class SessionStateIdle extends SessionState {}

class SessionStateFullyDisconnected extends SessionState {}

class SessionStateWaiting extends SessionState {
  final String? identifier;

  bool get isNew => identifier == null;

  SessionStateWaiting({this.identifier});
}

class SessionStateConnected extends SessionState {
  final String identifier;

  SessionStateConnected(this.identifier);
}

class SessionStateDisconnected extends SessionState {
  final String identifier;

  SessionStateDisconnected(this.identifier);
}

class SessionStateOutDated extends SessionState {}

class SessionStateServerIsDown extends SessionState {}

class ServerIsDownState {
  bool _serverIsDown = false;
  DateTime _serverIsDownCheckDate = DateTime.fromMillisecondsSinceEpoch(0);

  // Ping server and 1.1.1.1 for comparison
  Future<bool> get isDown async {
    // Check device connection
    if (await Connectivity().checkConnectivity() == ConnectivityResult.none) {
      _serverIsDown = false;
    } else if (DateTime.now().difference(_serverIsDownCheckDate) >
        Duration(seconds: 40)) {
      // Check if server is down

      bool firstOkay = false;
      try {
        Socket socket =
            await Socket.connect("1.1.1.1", 53, timeout: Duration(seconds: 2));
        socket.destroy();
        firstOkay = true;

        socket =
            await Socket.connect(HOST, PORT, timeout: Duration(seconds: 2));
        socket.destroy();
        _serverIsDown = false;
      } on SocketException {
        if (firstOkay) {
          // Timeout to server -> is down
          _serverIsDown = true;
        } else {
          // Timeout to 1.1.1.1 -> No internet
          _serverIsDown = false;
        }
      }

      _serverIsDownCheckDate = DateTime.now();
    }
    return _serverIsDown;
  }
}
