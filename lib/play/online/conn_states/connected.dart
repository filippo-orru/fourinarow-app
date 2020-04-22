import 'dart:async';

import '../../play_online.dart';
import 'all.dart';
import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/play/online/game_states/all.dart' as game_state;
import 'package:four_in_a_row/play/online/messages.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConnStateConnected extends ConnState {
  // final ConnStateConnectedState state;
  final Function(ConnState) changeStateCallback;
  final OnlineRequest req;

  ConnStateConnected(this.req, {@required this.changeStateCallback, Key key})
      : super(key: key);

  createState() => ConnStateConnectedState(req);

  // static IOWebSocketChannel createConnection() {
  //   return
  // }
}

class ConnStateConnectedState extends State<ConnStateConnected> {
  bool _awaitingConfirmation = false;

  IOWebSocketChannel _connection;
  StreamController<PlayerMessage> _outgoingCtrl;
  Sink<PlayerMessage> _outgoing;

  game_state.GameState gameState;

  ConnStateConnectedState(OnlineRequest req) {
    this._connection = IOWebSocketChannel.connect("wss://fourinarow.ml/game/",
        pingInterval: Duration(seconds: 1));

    this._outgoing = _mapSink(_connection.sink);
    // this._incoming =
    _mapStream(_connection.stream);
    this.gameState = game_state.Idle(_outgoing);
    if (req is ORqLobby) {
      this.sink.add(req.lobbyCode == null
          ? PlayerMsgLobbyRequest()
          : PlayerMsgLobbyJoin(req.lobbyCode));
    } else if (req is ORqWorldwide) {
      this.sink.add(PlayerMsgWorldwideRequest());
    }
  }

  // Stream<ServerMessage> get stream => _incoming;

  StreamSink<PlayerMessage> get sink => _outgoing;

  @override
  Widget build(BuildContext context) {
    return this.gameState;
  }

  // Stream<ServerMessage>
  void _mapStream(Stream<dynamic> wsStream) {
    // return
    wsStream.listen((msg) {
      if (msg is String) {
        print(">> \"$msg\"");
        var onlineMsg = OnlineMessageExt.parse(msg);
        if (onlineMsg is MsgOkay ||
            onlineMsg is MsgLobbyResponse ||
            onlineMsg is MsgError) {
          this._awaitingConfirmation = false;
        }
        if (super.mounted) {
          setState(() {
            gameState = gameState.handleMessage(onlineMsg) ?? gameState;
          });
        }
        return onlineMsg;
      } else {
        print("Received other message: " + msg);
      }
      return null;
    }, onError: (err) {
      print(">> #ERR# \"${err.toString()}\"");
    });
    // .asBroadcastStream();
  }

  Sink<PlayerMessage> _mapSink(WebSocketSink wsSink) {
    this._outgoingCtrl = StreamController<PlayerMessage>.broadcast();
    this._outgoingCtrl.stream.listen((pmsg) {
      _awaitingConfirmation = true;
      Future.delayed(Duration(seconds: 3), () {
        if (this._awaitingConfirmation) {
          this.dispose();
          widget.changeStateCallback(ConnStateError(ConnErrorTimeout()));
          print("Confirmation timeout!");
        }
      });

      setState(() {
        gameState = gameState.handlePlayerMessage(pmsg) ?? gameState;
      });
      String msg = pmsg.serialize();
      print("<< \"$msg\"");
      wsSink.add(msg);
    });
    return this._outgoingCtrl.sink;
  }

  @override
  void dispose() {
    _connection.sink.close();
    _outgoing.close();
    _outgoingCtrl.close();
    super.dispose();
  }
}
