import 'package:flutter/material.dart';
import 'package:four_in_a_row/field_logic/online_field.dart';
import 'package:four_in_a_row/field_logic/common/player.dart';

import '../messages.dart';
import 'all.dart';

class InLobby extends GameState {
  final String code;

  InLobby(this.code, Sink<PlayerMessage> sink) : super(sink);

  createState() => InLobbyState();

  @override
  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgGameStart) {
      return Playing(msg.myTurn, this.sink);
    }
    return super.handleMessage(msg);
  }
}

class InLobbyState extends State<InLobby> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            "Share this code with your friend:",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 18),
          Text(
            widget.code,
            style: TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
