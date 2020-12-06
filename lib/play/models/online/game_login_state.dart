import 'package:four_in_a_row/connection/messages.dart';

abstract class GameLoginState {
  final void Function(PlayerMessage) sendPlayerMessage;

  GameLoginState(this.sendPlayerMessage);

  GameLoginState handleServerMessage(ServerMessage msg);
}

class GameLoginLoggedOut extends GameLoginState {
  GameLoginLoggedOut(void Function(PlayerMessage) sendPlayerMessage)
      : super(sendPlayerMessage);

  @override
  GameLoginState handleServerMessage(ServerMessage msg) {
    return null;
  }
}

class GameLoginLoggedIn extends GameLoginState {
  GameLoginLoggedIn(void Function(PlayerMessage) sendPlayerMessage)
      : super(sendPlayerMessage);

  @override
  GameLoginState handleServerMessage(ServerMessage msg) {
    return null;
  }
}
