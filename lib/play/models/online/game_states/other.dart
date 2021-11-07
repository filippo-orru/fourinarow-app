import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';

import 'game_state.dart';

class WaitingForLobbyInfoState extends GameState {
  WaitingForLobbyInfoState(GameStateManager gsm) : super(gsm);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      return InLobbyState(super.gsm, msg.code);
      /* TODO this looks like it's outdate but it's 2:57 right now and I don't care.
    } else if (msg is MsgOkay && code != null) {
      return InLobbyReadyState(super.gsm);*/
    }
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => WaitingForLobbyInfoViewer(s);
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
