import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';

import 'game_state.dart';

class IdleState extends GameState {
  IdleState(GameStateManager gsm) : super(gsm);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgLobbyJoin) {
      return WaitingForLobbyInfoState(super.gsm, code: msg.code);
    } else if (msg is PlayerMsgLobbyRequest) {
      return WaitingForLobbyInfoState(super.gsm);
    } else if (msg is PlayerMsgWorldwideRequest) {
      return WaitingForWWOkayState(super.gsm);
    } else if (msg is PlayerMsgBattleRequest) {
      return InLobbyState(super.gsm, null);
    }

    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      return InLobbyState(super.gsm, msg.code);
    }
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => IdleViewer(s);
}
