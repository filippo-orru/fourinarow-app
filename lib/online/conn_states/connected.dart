import 'dart:async';

import 'all.dart';
import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/online/game_states/all.dart' as game_state;
import 'package:four_in_a_row/online/messages.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConnStateConnected extends ConnState {
  // final IOWebSocketChannel connection;
  final ConnStateConnectedState state;
  ConnStateConnected(IOWebSocketChannel connection, {Key key})
      : state = ConnStateConnectedState(connection),
        super(key: key);

  createState() => state;
}

class ConnStateConnectedState extends State<ConnStateConnected> {
  // final IOWebSocketChannel _connection;
  Stream<ServerMessage> _incoming;
  StreamController<PlayerMessage> _outgoingCtrl;
  Sink<PlayerMessage> _outgoing;

  game_state.GameState gameState;

  ConnStateConnectedState(IOWebSocketChannel connection) {
    this._outgoing = _mapSink(connection.sink);
    this._incoming = _mapStream(connection.stream);
    this.gameState = game_state.Idle(_outgoing);
  }

  Stream<ServerMessage> get stream => _incoming;

  StreamSink<PlayerMessage> get sink => _outgoing;

  @override
  Widget build(BuildContext context) {
    return this.gameState;
  }

  Stream<ServerMessage> _mapStream(Stream<dynamic> stream) {
    return stream.map(
      (msgStr) {
        if (msgStr is String) {
          print(">> \"$msgStr\"");
          var onlineMsg = OnlineMessageExt.parse(msgStr);
          gameState = gameState.handleMessage(onlineMsg) ?? gameState;
          setState(() {});
          return onlineMsg;
        }
        return null;
      },
    ).asBroadcastStream();
  }

  Sink<PlayerMessage> _mapSink(WebSocketSink wsSink) {
    this._outgoingCtrl = StreamController<PlayerMessage>.broadcast();
    this._outgoingCtrl.stream.listen((pmsg) {
      String msg = pmsg.serialize();
      print("<< \"$msg\"");
      wsSink.add(msg);
    });
    return this._outgoingCtrl.sink;
  }

  @override
  void dispose() {
    _outgoing.close();
    _outgoingCtrl.close();
    super.dispose();
  }
}
