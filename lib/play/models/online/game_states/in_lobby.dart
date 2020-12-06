import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/widgets/online/in_lobby.dart';

class InLobbyState extends GameState {
  final String? code;

  InLobbyState(void Function(PlayerMessage) sendPlayerMessage, this.code)
      : super(sendPlayerMessage);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgOppJoined) {
      return InLobbyReadyState(super.sendPlayerMessage);
    }
    return null;
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => InLobbyViewer(s);
}

class InLobbyReadyState extends GameState {
  InLobbyReadyState(void Function(PlayerMessage) sendPlayerMessage)
      : super(sendPlayerMessage);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgGameStart) {
      return PlayingState(
        super.sendPlayerMessage,
        myTurnToStart: msg.myTurn,
        opponentId: msg.opponentId,
      );
    }
    return null;
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => InLobbyReadyViewer(s);
}
