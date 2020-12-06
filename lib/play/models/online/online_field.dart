import 'package:four_in_a_row/util/vibration.dart';

import '../common/field.dart';
import '../common/player.dart';

class OnlineField extends Field {
  final Player me = Player.One;
  bool waitingToPlayAgain = false;

  OnlineField();

  @override
  void dropChipNamed(int column, Player p) {
    super.dropChipNamed(column, p);
    this.checkWin();
  }

  @override
  WinDetails? checkWin() {
    WinDetails? winDetails = super.checkWin();
    if (winDetails?.winner == this.me) {
      Vibrations.win();
    } else if (winDetails?.winner == this.me.other) {
      Vibrations.loose();
    }
    return winDetails;
  }
}
