import 'package:flutter/material.dart';

import '../messages.dart';
import 'all.dart';

class Idle extends GameState {
  final IdleState state;

  Idle(Sink<PlayerMessage> sink, {bool ready})
      : state = IdleState(ready: ready),
        super(sink);

  createState() => state;

  @override
  GameState handleMessage(ServerMessage msg) {
    return state.handleMessage(msg) ?? super.handleMessage(msg);
  }
}

class IdleState extends State<Idle> {
  bool ready; // true if opponent is in lobby

  IdleState({this.ready = false});

  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      return InLobby(msg.code, widget.sink);
    } else if (msg is MsgOppJoined) {
      ready = true;
    } else if (msg is MsgGameStart) {
      return Playing(msg.myTurn, widget.sink);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Idle. Ready: $ready"),
    );
  }
}
