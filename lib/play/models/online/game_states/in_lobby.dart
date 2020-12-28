import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/inherit/lifecycle.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/widgets/online/in_lobby.dart';

class InLobbyState extends GameState {
  final String? code;

  InLobbyState(GameStateManager gsm, this.code) : super(gsm);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgOppJoined) {
      return InLobbyReadyState(super.gsm);
    }
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => InLobbyViewer(s);
}

class InLobbyReadyState extends GameState {
  InLobbyReadyState(GameStateManager gsm) : super(gsm);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgGameStart) {
      return PlayingState(
        super.gsm,
        myTurnToStart: msg.myTurn,
        opponentId: msg.opponentId,
      );
    }
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => InLobbyReadyViewer(s);
}
