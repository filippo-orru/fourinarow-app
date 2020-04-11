import 'package:flutter_vibrate/flutter_vibrate.dart';

class Vibrations {
  static win() async {
    Vibrate.feedback(FeedbackType.medium);
    await Future.delayed(Duration(milliseconds: 160));
    Vibrate.feedback(FeedbackType.medium);
    await Future.delayed(Duration(milliseconds: 210));
    Vibrate.vibrate();
  }
}
