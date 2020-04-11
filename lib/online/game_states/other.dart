import 'package:flutter/material.dart';

import '../messages.dart';
import 'all.dart';

class OpponentLeft extends GameState {
  OpponentLeft(Sink<PlayerMessage> sink) : super(sink);

  @override
  GameState handleMessage(ServerMessage msg) {
    return super.handleMessage(msg);
  }

  createState() => OpponentLeftState();
}

class OpponentLeftState extends State<OpponentLeft> {
  @override
  Widget build(BuildContext context) {
    return Text("Opponent has left!");
  }
}

class WaitingForJoinConfirmation extends GameState {
  WaitingForJoinConfirmation(Sink<PlayerMessage> sink) : super(sink);

  @override
  GameState handleMessage(ServerMessage msg) {
    return super.handleMessage(msg);
  }

  createState() => WaitingForJoinConfirmationState();
}

class WaitingForJoinConfirmationState
    extends State<WaitingForJoinConfirmation> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("waiting..."),
    );
  }
}
