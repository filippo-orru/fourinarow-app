import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/widgets/online/other.dart';

import 'game_state.dart';

class WaitingForLobbyInfoState extends GameState {
  final String? code;

  WaitingForLobbyInfoState(
    void Function(PlayerMessage) sendPlayerMessage, {
    this.code,
  }) : super(sendPlayerMessage);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      return InLobbyState(super.sendPlayerMessage, msg.code);
    } else if (msg is MsgOkay && code != null) {
      return InLobbyReadyState(super.sendPlayerMessage);
    }
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => WaitingForLobbyInfoViewer(s);
}

class WaitingForWWOkayState extends GameState {
  WaitingForWWOkayState(void Function(PlayerMessage) sendPlayerMessage)
      : super(sendPlayerMessage);

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgOkay) {
      return WaitingForWWOpponentState(super.sendPlayerMessage);
    }
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => WaitingForWWOkayViewer(s);
}

class WaitingForWWOpponentState extends GameState {
  WaitingForWWOpponentState(void Function(PlayerMessage) sendPlayerMessage)
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
    return super.handleServerMessage(msg);
  }

  // @override
  // AbstractGameStateViewer get viewer => (s) => WaitingForWWOpponentViewer(s);
}
