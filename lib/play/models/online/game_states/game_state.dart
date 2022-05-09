import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/idle.dart';
import 'package:four_in_a_row/play/models/online/game_states/playing.dart';

export 'idle.dart';
export 'in_lobby.dart';
export 'other.dart';
export 'playing.dart';

abstract class GameState with ChangeNotifier {
  GameState(this.gsm);

  final GameStateManager gsm;

  @mustCallSuper
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgReset) {
      return IdleState(gsm);
    } else if (msg is MsgLobbyClosing && this is! PlayingState) {
      gsm.hideViewer = true;

      return IdleState(gsm);
    }
    return null;
  }

  @mustCallSuper
  GameState? handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgLeave) {
      return IdleState(gsm);
    }
    return null;
  }
}

// typedef AbstractGameStateViewer = Widget Function(GameState);
abstract class AbstractGameStateViewer extends StatelessWidget {
  const AbstractGameStateViewer({Key? key}) : super(key: key);
}
