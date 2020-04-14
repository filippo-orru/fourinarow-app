import 'package:flutter/material.dart';

import '../messages.dart';
import 'all.dart';

class Error extends GameState {
  final GameStateError message;

  Error(this.message, Sink<PlayerMessage> sink) : super(sink);

  createState() => ErrorState();

  @override
  GameState handleMessage(ServerMessage msg) {
    return super.handleMessage(msg);
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return null;
  }
}

class ErrorState extends State<Error> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          Text("Error" + (widget.message != null ? ": ${widget.message}" : "")),
    );
  }
}

abstract class GameStateError {}

class Internal extends GameStateError {
  final String message;
  Internal(this.message);
}

class LobbyClosed extends GameStateError {}
