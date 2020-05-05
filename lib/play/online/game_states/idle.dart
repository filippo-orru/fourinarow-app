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
    return super.handleMessage(msg);
    // state.handleMessage(msg) ??
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgLobbyJoin) {
      return WaitingForLobbyInfo(this.sink, lobbyCode: msg.code);
    } else if (msg is PlayerMsgLobbyRequest) {
      return WaitingForLobbyInfo(this.sink);
    } else if (msg is PlayerMsgWorldwideRequest) {
      return WaitingForWWOkay(this.sink);
    }

    return null;
  }
}

class IdleState extends State<Idle> {
  bool ready; // true if opponent is in lobby

  IdleState({this.ready = false});

  // GameState handleMessage(ServerMessage msg) {
  //   if (msg is MsgLobbyResponse) {
  //     return InLobby(msg.code, widget.sink);
  //   }
  //   return null;
  // }

  @override
  Widget build(BuildContext context) {
    return SizedBox();
  }
}
