import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/widgets/online/idle.dart';

import 'game_state.dart';

class IdleState extends GameState {
  IdleState(void Function(PlayerMessage) sendPlayerMessage)
      : super(sendPlayerMessage);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgLobbyJoin) {
      return WaitingForLobbyInfoState(super.sendPlayerMessage, code: msg.code);
    } else if (msg is PlayerMsgLobbyRequest) {
      return WaitingForLobbyInfoState(super.sendPlayerMessage);
    } else if (msg is PlayerMsgWorldwideRequest) {
      return WaitingForWWOkayState(super.sendPlayerMessage);
    } else if (msg is PlayerMsgBattleRequest) {
      return InLobbyState(super.sendPlayerMessage, null);
    }

    return null;
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      return InLobbyState(super.sendPlayerMessage, msg.code);
    }
    return null;
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => IdleViewer(s);
}
