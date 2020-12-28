import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';

abstract class GameLoginState {
  final GameStateManager gsm;

  GameLoginState(this.gsm);

  GameLoginState? handleServerMessage(ServerMessage msg);
}

class GameLoginLoggedOut extends GameLoginState {
  GameLoginLoggedOut(GameStateManager gsm) : super(gsm);

  @override
  GameLoginState? handleServerMessage(ServerMessage msg) {
    return null;
  }
}

class GameLoginLoggedIn extends GameLoginState {
  GameLoginLoggedIn(GameStateManager gsm) : super(gsm);

  @override
  GameLoginState? handleServerMessage(ServerMessage msg) {
    return null;
  }
}
