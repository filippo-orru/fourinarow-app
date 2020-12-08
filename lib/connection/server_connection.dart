import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'messages.dart';

class ServerConnection with ChangeNotifier {
  WebSocketChannel? _connection;

  StreamController<ServerMessage> _serverMsgStreamCtrl =
      StreamController<ServerMessage>.broadcast();
  Stream<ServerMessage> get serverMsgStream => _serverMsgStreamCtrl.stream;
  StreamSubscription? _serverMsgSub;

  StreamController<PlayerMessage> _playerMsgStreamCtrl =
      StreamController<PlayerMessage>.broadcast();
  Stream<PlayerMessage> get playerMsgStream => _playerMsgStreamCtrl.stream;
  StreamSubscription? _playerMsgSub;

  StreamController<ReliablePacketOut> _reliablePktOutStreamCtrl =
      StreamController<ReliablePacketOut>.broadcast();
  StreamSubscription? _reliablePktOutSub;

  StreamController<ReliablePacketIn> _reliablePktInStreamCtrl =
      StreamController<ReliablePacketIn>.broadcast();
  StreamSubscription? _reliablePktInSub;

  Timer? _timeoutTimer;

  int _serverMsgIndex = 0;
  final List<QueuedMessage<ServerMessage>> _serverMsgQ = List.empty();
  int _playerMsgIndex = 0;
  final List<QueuedMessage<PlayerMessage>> _playerMsgQ = List.empty();

  List<PlayerMessage> _playerMsgQueue = List.empty(growable: true);

  bool get connected => _connection != null && _connection!.closeCode == null;

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
    _playerMsgStreamCtrl.close();
    _serverMsgStreamCtrl.close();

    _reliablePktOutStreamCtrl.close();
    _reliablePktInStreamCtrl.close();
  }

  void _connect() {
    this._serverMsgSub?.cancel();
    this._playerMsgSub?.cancel();

    this._reliablePktOutSub?.cancel();
    this._reliablePktInSub?.cancel();

    this._connection = WebSocketChannel.connect(
      Uri.parse(WS_URL),
    );
    _reliablePktInSub = _handleReliablePktIn(_connection!.stream);
    _reliablePktOutSub = _handleReliablePktOut(_connection!.sink);

    _serverMsgSub = _handleServerMsg(_serverMsgStreamCtrl.stream);
    _playerMsgSub = _handlePlayerMsg(_playerMsgStreamCtrl);

    _heartbeats(_serv);
    _sendMessagesInQueue();
    notifyListeners();
  }

  void _heartbeats() {
    // TODO heartbeats. maybe built-in?
  }

  void _sendMessagesInQueue() {
    // TODO rework vv
    while (_playerMsgQueue.isNotEmpty) {
      this._playerMsgStreamCtrl.add(_playerMsgQueue.removeLast());
    }
  }

  StreamSubscription _handleReliablePktIn() {
    return this._reliablePktInStreamCtrl.stream.listen((rPkt) {
      
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
        }
      
    });
  }
  StreamSubscription _handleWsIn() {
    return this._connection!.stream.listen((msg) {
    if (msg is String) {
        print(">> $msg");
        var rPkt = ReliablePacketIn.parse(msg);
        if (rPkt == null) return;
      } else {
        print(">> #OTR# \"$msg\"");
      }
    }
  , onError: (dynamic err) {
      print(">> #ERR# \"${err.toString()}\"");
      //this.timeoutTimer?.cancel();
      // TODO reconnect
    }, onDone: () {
      // TODO reconnect?
    });
  }

  StreamSubscription _handleReliablePktOut(WebSocketSink wsSink) {
    return this._reliablePktOutStreamCtrl.stream.listen((pmsg) {
      String msg = pmsg.serialize();
      print("<< $msg");
      wsSink.add(msg);
      // _playerMsgQueue.add(pmsg);
    });
  }

  StreamSubscription _handleServerMsg(Stream<ServerMessage> serverMsgStream) {
    return serverMsgStream.listen((serverMsg) {
      this._
    });
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
