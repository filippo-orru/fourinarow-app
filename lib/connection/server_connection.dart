import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'messages.dart';

class ServerConnection with ChangeNotifier {
  StreamController<ServerMessage> _incoming =
      StreamController<ServerMessage>.broadcast();
  Stream<ServerMessage> get incoming => _incoming.stream;

  StreamController<PlayerMessage> _outgoing =
      StreamController<PlayerMessage>.broadcast();
  Stream<PlayerMessage> get outgoing => _outgoing.stream;

  Timer? _timeoutTimer;

  WebSocketChannel? _connection;
  StreamSubscription? _wsMsgSub;
  StreamSubscription? _playerMsgSub;

  List<PlayerMessage> _playerMsgQueue = List.empty(growable: true);

  bool get connected => _connection != null && _connection!.closeCode == null;

  ServerConnection() {
    _connect();
  }

  void send(PlayerMessage msg) {
    this._outgoing.add(msg);
  }

  bool refresh() {
    // TODO
    return connected;
  }

  void close() {
    _outgoing.close();
    _incoming.close();
  }

  void _connect() {
    _wsMsgSub?.cancel();
    _playerMsgSub?.cancel();

    this._connection = WebSocketChannel.connect(
      Uri.parse(WS_URL),
    );
    _wsMsgSub = _handleServerMessages(_connection!.stream);
    _playerMsgSub = _handlePlayerMessages(_connection!.sink);
    _heartbeats();
    _sendMessagesInQueue();
    notifyListeners();
  }

  void _heartbeats() {
    // TODO heartbeats. maybe built-in?
  }

  void _sendMessagesInQueue() {
    while (_playerMsgQueue.isNotEmpty) {
      this._outgoing.add(_playerMsgQueue.removeLast());
    }
  }

  StreamSubscription _handleServerMessages(Stream<dynamic> wsStream) {
    return wsStream.listen((msg) {
      if (msg is String) {
        print(">> $msg");
        var onlineMsg = ServerMessage.parse(msg);
        if (onlineMsg == null) return;

        _incoming.sink.add(onlineMsg);
      } else {
        print(">> #OTR# \"$msg\"");
      }
    }, onError: (dynamic err) {
      print(">> #ERR# \"${err.toString()}\"");
      //this.timeoutTimer?.cancel();
      // TODO reconnect
    }, onDone: () {
      // TODO reconnect?
    });
  }

  StreamSubscription _handlePlayerMessages(WebSocketSink wsSink) {
    return this._outgoing.stream.listen((pmsg) {
      String msg = pmsg.serialize();
      print("<< $msg");
      if (wsSink != null) {
        wsSink.add(msg);
      } else {
        _playerMsgQueue.add(pmsg);
      }
    });
  }
}
