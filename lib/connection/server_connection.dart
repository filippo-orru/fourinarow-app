import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
// ignore: import_of_legacy_library_into_null_safe
import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_channel/stream_channel.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'messages.dart';

const int CONNECTION_WAS_LOST_TIMEOUT_S = 30;

class ServerConnection with ChangeNotifier {
  WebSocketChannel? _connection;

  Timer? _reconnectionTimer;

  Timer? _connectionWasLostTimer; // fires after 30s (server closed connection)

  StreamController<ServerMessage> _serverMsgStreamCtrl =
      StreamController<ServerMessage>.broadcast();
  Stream<ServerMessage> get serverMsgStream => _serverMsgStreamCtrl.stream;
  // StreamSubscription? _serverMsgSub;

  StreamController<PlayerMessage> _playerMsgStreamCtrl =
      StreamController<PlayerMessage>.broadcast();
  Stream<PlayerMessage> get playerMsgStream => _playerMsgStreamCtrl.stream;
  StreamSubscription? _playerMsgSub;

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

  ServerIsDownState _serverIsDownState = ServerIsDownState();
  Future<bool> get serverIsDown => _serverIsDownState.isDown;

  int _connectionTries = 0;
  Timer? _missingMsgSince;
  bool waitingForPong = false;

  ServerConnection() {
    _connect();
    _resendQueuedInterval();
    _sendPingsInterval();
  }

  void send(PlayerMessage msg) {
    this._playerMsgStreamCtrl.add(msg);
  }

  void retryConnection({bool force = false, bool reset = false}) {
    _connect(force: force, reset: reset);
  }

  Future<bool> waitForOkay(
      {Duration duration = const Duration(milliseconds: 500)}) {
    var map = serverMsgStream
        .map<ServerMessage?>((e) => e)
        .firstWhere((serverMsg) => serverMsg is MsgOkay)
        .timeout(duration, onTimeout: () => null);
    return map.then((maybeOkay) => maybeOkay is MsgOkay);
  }

  void close() {
    _serverMsgStreamCtrl.close();
    _playerMsgStreamCtrl.close();

    _wsInStreamCtrl.close();
    _reliablePktOutStreamCtrl.close();

    _connection?.sink.close();
  }

  void _connect({bool force = false, bool reset = false}) async {
    if ((_sessionState is SessionStateOutDated ||
            _sessionState is SessionStateConnected) &&
        !force) {
      return;
    }

    if ((_sessionState is SessionStateDisconnected ||
            _sessionState is SessionStateServerIsDown) &&
        await serverIsDown) {
      _sessionState = SessionStateServerIsDown();
      return;
    }

    this._connectionTries += 1;
    print("   #CONNECT# (${this._connectionTries}. try)");

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
    this._playerMsgSub?.cancel();
    _playerMsgSub = _handlePlayerMsg();

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
        print("   (reconnecting)");
        _connect(force: true);
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
          .timeout(Duration(seconds: 7))
          .then<HttpClientRequest?>((r) => r)
          .catchError((_, __) {
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
      }).catchError((_, __) {
        request.abort();
        return null;
      });
      // TODO vvv
      // if (_connection == null) {
      //   _websocketDone();
      //   return null;
      // }
    } on SocketException catch (e) {
      var errCode = 0;
      if (e.osError?.errorCode != null) errCode = e.osError!.errorCode;
      if (![7, 101, 103].contains(errCode)) {
        print("Unknown connection err: $e");
      } else {
        // Network is unreachable / network err
      }
      return null;
    } on Exception {
      return null;
    }
  }

  StreamSubscription? _handleWsIn(Stream<dynamic> wsStream) {
    try {
      return wsStream.listen(
        this._receivedWsMsg,
        onError: this._websocketErr,
        onDone: this._websocketDone,
        cancelOnError: true,
      );
    } on Exception catch (e) {
      print("exception handleWsIn: $e");
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
        print("<< $msgStr");
        try {
          wsSink.add(msgStr);
        } on Exception catch (e) {
          print("exception handleRPktOut: $e");
          _websocketDone();
          return;
        }
      },
      onError: this._websocketErr,
      onDone: this._websocketDone,
      cancelOnError: true,
    );
  }

  StreamSubscription _handlePlayerMsg() {
    return this._playerMsgStreamCtrl.stream.listen(
      (msg) {
        this._playerMsgIndex += 1;
        this
            ._reliablePktOutStreamCtrl
            .add(ReliablePktMsgOut(this._playerMsgIndex, msg));
      },
      onError: this._websocketErr,
      cancelOnError: true,
      onDone: this._connect,
    );
  }

  void _receivedWsMsg(dynamic msg) {
    if (msg is String) {
      print(">> $msg");
      var rPkt = ReliablePacketIn.parse(msg);
      if (rPkt == null) return;
      this._receivedReliablePacket(rPkt);
    } else {
      print(">> #OTR# \"$msg\"");
    }
  }

  void _websocketErr(dynamic? err) {
    if (err is WebSocketChannelException &&
        err.inner is WebSocketChannelException &&
        err.inner.inner is SocketException) {
      if (err.inner.inner.osError.errorCode == 7 ||
          err.inner.inner.osError.errorCode == 111) {
        // Network error (no connection)
      }
    } else {
      print("   #ERR# \"${err.toString()}\"");
    }
  }

  void _websocketDone() {
    int timeoutMs = (min(
              24.0,
              0.5 + pow(_connectionTries.toDouble(), 1.5),
            ) *
            1000)
        .toInt();
    print(
        "   #DONE# (retry in ${(timeoutMs.toDouble() / 1000.0).toStringAsFixed(2)})");
    var sessionState = this._sessionState;
    if (sessionState is SessionStateConnected) {
      this._sessionState = SessionStateDisconnected(sessionState.identifier);
    } else if (sessionState is SessionStateWaiting &&
        sessionState.identifier != null) {
      this._sessionState = SessionStateDisconnected(sessionState.identifier!);
    }
    notifyListeners();
    var timeout = Duration(
      milliseconds: timeoutMs,
    );
    Connectivity().checkConnectivity().then((r) async {
      if (r == ConnectivityResult.none) {
        ConnectivityResult? result = await Connectivity()
            .onConnectivityChanged
            .map<ConnectivityResult?>((e) => e)
            .firstWhere((result) =>
                result == ConnectivityResult.wifi ||
                result == ConnectivityResult.mobile)
            .timeout(timeout, onTimeout: () => null);
        if (result != null) {
          print("   #FORCE CNNCT# (${result.toString().split(".")[1]})");
          _connect();
        }
      }
    });
    if (_connectionWasLostTimer?.isActive != true) {
      _connectionWasLostTimer =
          Timer(Duration(seconds: CONNECTION_WAS_LOST_TIMEOUT_S), () {
        _serverMsgStreamCtrl.add(MsgReset());
      });
    }
    _reconnectionTimer = Timer(timeout, () {
      if (!connected) _connect();
    });
  }

  void _resetReliabilityLayer({required bool reconnect}) {
    this._playerMsgIndex = 0;
    this._serverMsgIndex = 0;
    this._serverMsgStreamCtrl.add(MsgReset());
    if (reconnect) this.retryConnection(force: true, reset: true);
  }

  void _receivedReliablePacket(ReliablePacketIn rPkt) {
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
            print("   #WARN# Message(id=$expectedId) missing");
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
        print("   #WARN# Got Ack for unknown message");
        this._resetReliabilityLayer(reconnect: true);
      }
      // } else
    } else if (rPkt is ReliablePktHelloIn) {
      if (this._sessionState is! SessionStateWaiting) {
        print("   #WARN# Got unexpected ReliablePktHelloIn");
        this._resetReliabilityLayer(reconnect: false);
      }
      if (rPkt.foundState == FoundState.New) {
        this._playerMsgQ.clear();
        this._serverMsgQ.clear();
        this._resetReliabilityLayer(reconnect: false);
      }
      _connectionTries = 0;
      this._sessionState = SessionStateConnected(rPkt.sessionIdentifier);
      notifyListeners();
    } else if (rPkt is ReliablePktHelloInOutDated) {
      this._sessionState = SessionStateOutDated();
    } else if (rPkt is ReliablePktErrIn) {
      print("   #WARN# Got ReliablePktErrIn");
      this._playerMsgQ.clear();
      this._serverMsgQ.clear();
      this._resetReliabilityLayer(reconnect: true);
      // this.retryConnection(force: true);
    } else if (rPkt is ReliablePktNotConnectedIn) {
      print("   #WARN# Got ReliablePktNotConnectedIn");
      this._playerMsgQ.clear();
      this._serverMsgQ.clear();
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

  Future<bool> get isDown async {
    if (_serverIsDownCheckDate.difference(DateTime.now()) >
        Duration(minutes: 1)) {
      // Check if server is down
      _serverIsDown = (await http.get(HTTP_URL + '/status')).body == "NOT_OK";
    }
    return _serverIsDown;
  }
}
