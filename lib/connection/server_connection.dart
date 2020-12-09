import 'dart:async';
import 'dart:math';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'messages.dart';

// TODO: react to sessionstate: new connection if idle, reconnect if disconnected
// set sessionstate on disconnect and wait+Msg:Found/Msg:NotFound

class ServerConnection with ChangeNotifier {
  WebSocketChannel? _connection;

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

  int _connectionTries = 0;

  ServerConnection() {
    _connect();
  }

  void send(PlayerMessage msg) {
    this._playerMsgStreamCtrl.add(msg);
  }

  bool refresh() {
    // TODO
    return connected;
  }

  void close() {
    _serverMsgStreamCtrl.close();
    _playerMsgStreamCtrl.close();

    _wsInStreamCtrl.close();
    _reliablePktOutStreamCtrl.close();
  }

  void _connect() {
    this._connectionTries += 1;
    // this._serverMsgSub?.cancel();
    this._playerMsgSub?.cancel();

    this._wsInSub?.cancel();
    this._reliablePktOutSub?.cancel();

    if (!kIsWeb) {
      this._connection = IOWebSocketChannel.connect(Uri.parse(WS_URL),
          pingInterval: Duration(seconds: 1));
    } else {
      throw UnimplementedError();
    }
    // .connect(
    //   ,
    // );
    _wsInSub = _handleWsIn(_connection!.stream);
    _reliablePktOutSub = _handleReliablePktOut(_connection!.sink);

    // _serverMsgSub = _handleServerMsg();
    _playerMsgSub = _handlePlayerMsg();

    var _sessionState = this._sessionState;
    if (_sessionState is SessionStateIdle) {
      _reliablePktOutStreamCtrl.add(ReliablePktReqNew());
    } else if (_sessionState is SessionStateDisconnected) {
      _reliablePktOutStreamCtrl
          .add(ReliablePktReconnect(_sessionState.identifier));
    }

    notifyListeners();
  }

  StreamSubscription _handleWsIn(Stream<dynamic> wsStream) {
    return wsStream.listen(this._receivedWsMsg,
        onError: this._websocketErr, onDone: this._websocketDone);
  }

  StreamSubscription _handleReliablePktOut(WebSocketSink wsSink) {
    return this._reliablePktOutStreamCtrl.stream.listen((rPkt) {
      if (rPkt is ReliablePktMsgOut) {
        this._playerMsgQ.add(QueuedMessage(rPkt.id, rPkt.msg));
      }

      String msgStr = rPkt.serialize();
      print("<< $msgStr");
      wsSink.add(msgStr);
    });
  }

  StreamSubscription _handlePlayerMsg() {
    return this.playerMsgStream.listen((msg) {
      this._playerMsgIndex += 1;
      this
          ._reliablePktOutStreamCtrl
          .add(ReliablePktMsgOut(this._playerMsgIndex, msg));
    });
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
    print(">> #ERR# \"${err.toString()}\"");
  }

  void _websocketDone() {
    print(">> #DONE#");
    var _sessionState = this._sessionState;
    if (_sessionState is SessionStateConnected) {
      this._sessionState = SessionStateDisconnected(_sessionState.identifier);
    }
    notifyListeners();
    Future.delayed(Duration(seconds: max(8, _connectionTries)), _connect);
  }

  void _receivedReliablePacket(ReliablePacketIn rPkt) {
    if (rPkt is ReliablePktAckIn) {
      this._playerMsgQ.removeWhere((msg) => msg.id == rPkt.id);
    } else if (rPkt is ReliablePktMsgIn) {
      final int expectedId = this._serverMsgIndex + 1;
      if (rPkt.id == expectedId) {
        this._serverMsgIndex = rPkt.id;
        this._serverMsgStreamCtrl.sink.add(rPkt.msg);
        this._ackMessage(rPkt.id);
        this._processQueue();
      } else if (rPkt.id > expectedId) {
        this._queueMessgage(rPkt.id, rPkt.msg);
        this._ackMessage(this._serverMsgIndex);
      } else {
        // Client re-sent already known message -> maybe ack got lost -> ack but don't process
        this._ackMessage(rPkt.id);
      }
    } else if (this._sessionState is SessionStateDisconnected &&
        rPkt is ReliablePktNotFound) {
      this._reliablePktOutStreamCtrl.add(ReliablePktReqNew());
    } else if (rPkt is ReliablePktFound) {
      this._sessionState = SessionStateConnected(rPkt.id);
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
      this._serverMsgQ.asMap().forEach((index, queuedMessage) {
        int expectedId = this._serverMsgIndex + 1;
        if (queuedMessage.id == expectedId) {
          this._serverMsgIndex += 1;
          this._serverMsgStreamCtrl.sink.add(queuedMessage.msg);
          this._ackMessage(this._serverMsgIndex);
          this._serverMsgQ.removeAt(index);
          added = true;
        }
      });
    } while (added);
  }
}

abstract class SessionState {}

class SessionStateIdle extends SessionState {}

class SessionStateWaiting extends SessionState {}

class SessionStateConnected extends SessionState {
  final String identifier;

  SessionStateConnected(this.identifier);
}

class SessionStateDisconnected extends SessionState {
  final String identifier;

  SessionStateDisconnected(this.identifier);
}
