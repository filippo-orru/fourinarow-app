import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';

import 'game_state.dart';

class WaitingForLobbyInfoState extends GameState {
  final String? code;

  WaitingForLobbyInfoState(
    GameStateManager gsm, {
    this.code,
  }) : super(gsm);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      return InLobbyState(super.gsm, msg.code);
    } else if (msg is MsgOkay && code != null) {
      return InLobbyReadyState(super.gsm);
    }
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => WaitingForLobbyInfoViewer(s);
}

class WaitingForWWOkayState extends GameState {
  WaitingForWWOkayState(GameStateManager gsm) : super(gsm);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgOkay) {
      return WaitingForWWOpponentState(super.gsm);
    }
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => WaitingForWWOkayViewer(s);
}

class WaitingForWWOpponentState extends GameState {
  WaitingForWWOpponentState(GameStateManager gsm) : super(gsm);

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
  // AbstractGameStateViewer get viewer => (s) => WaitingForWWOpponentViewer(s);
}
