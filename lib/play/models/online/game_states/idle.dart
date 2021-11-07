import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';

import 'game_state.dart';

class IdleState extends GameState {
  IdleState(GameStateManager gsm) : super(gsm);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgLobbyJoin) {
      return InLobbyState(super.gsm, msg.code);
    } else if (msg is PlayerMsgLobbyRequest) {
      return WaitingForLobbyInfoState(super.gsm);
    } else if (msg is PlayerMsgWorldwideRequest) {
      return WaitingForWWOpponentState(super.gsm);
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
}
