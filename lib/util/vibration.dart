import 'package:flutter_vibrate/flutter_vibrate.dart';

class Vibrations {
  static void win() async {
    if (!await Vibrate.canVibrate) return;

    Vibrate.feedback(FeedbackType.medium);
    await Future.delayed(Duration(milliseconds: 160));
    Vibrate.feedback(FeedbackType.medium);
    await Future.delayed(Duration(milliseconds: 210));
    Vibrate.vibrate();
  }

  static void loose() async {
    if (!await Vibrate.canVibrate) return;

    Vibrate.feedback(FeedbackType.medium);
    await Future.delayed(Duration(milliseconds: 160));
    Vibrate.feedback(FeedbackType.medium);
  }

  static void turnChange() async {
    if (!await Vibrate.canVibrate) return;

    Vibrate.feedback(FeedbackType.light);
  }

  static void tiny() async {
    if (!await Vibrate.canVibrate) return;

    Vibrate.feedback(FeedbackType.light);
  }

  static void battleRequest() async {
    if (!await Vibrate.canVibrate) return;

    Vibrate.feedback(FeedbackType.medium);
  }

  static void gameFound() async {
    if (!await Vibrate.canVibrate) return;

    await Future.delayed(Duration(milliseconds: 90));
    Vibrate.feedback(FeedbackType.light);
    await Future.delayed(Duration(milliseconds: 60));
    Vibrate.feedback(FeedbackType.light);
    await Future.delayed(Duration(milliseconds: 60));
    Vibrate.feedback(FeedbackType.light);
  }
}
