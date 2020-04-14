import 'package:flutter/material.dart';

import '../messages.dart';
import 'all.dart';

// class OpponentLeft extends GameState {
//   // TODO maybe remove in favor of Error(OppLeft)
//   OpponentLeft(Sink<PlayerMessage> sink) : super(sink);

//   @override
//   GameState handleMessage(ServerMessage msg) {
//     return super.handleMessage(msg);
//   }

//   GameState handlePlayerMessage(PlayerMessage msg) {
//     return null;
//   }

//   createState() => OpponentLeftState();
// }

// class OpponentLeftState extends State<OpponentLeft> {
//   @override
//   Widget build(BuildContext context) {
//     return Text("Opponent has left!");
//   }
// }

class WaitingForLobbyInfo extends GameState {
  // final WaitingForLobbyInfoState state;
  final String lobbyCode;

  WaitingForLobbyInfo(Sink<PlayerMessage> sink, {this.lobbyCode}) : super(sink);

  @override
  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      return InLobby(msg.code, this.sink);
    } else if (msg is MsgOkay && this.lobbyCode != null) {
      return InLobbyReady(this.sink);
    }
    return super.handleMessage(msg);
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return null;
  }

  createState() => WaitingForLobbyInfoState();
}

class WaitingForLobbyInfoState extends State<WaitingForLobbyInfo> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
          widget.lobbyCode == null ? "waiting for server" : "joining lobby"),
    );
  }
}
