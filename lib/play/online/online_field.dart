import '../game_logic/field.dart';
import '../game_logic/player.dart';

class OnlineField extends Field {
  final Player me = Player.One;
  bool waitingToPlayAgain = false;

  OnlineField();
}
