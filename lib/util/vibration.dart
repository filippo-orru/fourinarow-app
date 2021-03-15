import 'dart:async';

import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';

class Vibrations {
  static bool? _canVibrate;

  static FutureOr<bool> get shouldVibrate async {
    if (_canVibrate == null) {
      try {
        if (await Vibrate.canVibrate) {
          _canVibrate = true;

          return FiarSharedPrefs.settingsAllowVibrate;
        }
      } catch (MissingPluginException) {}
      _canVibrate = false;
      return false;
    } else {
      return _canVibrate!;
    }
  }

  static void win() async {
    if (!await shouldVibrate) return;

    Vibrate.feedback(FeedbackType.medium);
    await Future.delayed(Duration(milliseconds: 160));
    Vibrate.feedback(FeedbackType.medium);
    await Future.delayed(Duration(milliseconds: 210));
    Vibrate.vibrate();
  }

  static void loose() async {
    if (!await shouldVibrate) return;

    Vibrate.feedback(FeedbackType.medium);
    await Future.delayed(Duration(milliseconds: 160));
    Vibrate.feedback(FeedbackType.medium);
  }

  static void turnChange() async {
    if (!await shouldVibrate) return;

    Vibrate.feedback(FeedbackType.light);
  }

  static void tiny() async {
    if (!await shouldVibrate) return;

    Vibrate.feedback(FeedbackType.light);
  }

  static void battleRequest() async {
    if (!await shouldVibrate) return;

    Vibrate.feedback(FeedbackType.medium);
  }

  static void gameFound() async {
    if (!await shouldVibrate) return;

    await Future.delayed(Duration(milliseconds: 90));
    Vibrate.feedback(FeedbackType.light);
    await Future.delayed(Duration(milliseconds: 60));
    Vibrate.feedback(FeedbackType.light);
    await Future.delayed(Duration(milliseconds: 60));
    Vibrate.feedback(FeedbackType.light);
  }
}
