import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/connection/messages.dart';

export 'idle.dart';
export 'in_lobby.dart';
export 'other.dart';
export 'playing.dart';

abstract class GameState with ChangeNotifier {
  final void Function(PlayerMessage) sendPlayerMessage;
  GameState(this.sendPlayerMessage);

  GameState? handleServerMessage(ServerMessage msg);

  GameState? handlePlayerMessage(PlayerMessage msg);
}

// typedef AbstractGameStateViewer = Widget Function(GameState);
abstract class AbstractGameStateViewer extends StatelessWidget {
  const AbstractGameStateViewer({Key? key}) : super(key: key);
}
