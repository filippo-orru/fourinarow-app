import 'dart:async';

import 'package:vibration/vibration.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';

class Vibrations {
  static bool? _canVibrate;

  static FutureOr<bool> get canVibrate async {
    if (_canVibrate == null) {
      if (await Vibration.hasVibrator() == true) {
        _canVibrate = true;
      } else {
        _canVibrate = false;
      }
    }
    return _canVibrate!;
  }

  static FutureOr<bool> get shouldVibrate async {
    bool _canVibrate = await canVibrate;
    return _canVibrate && FiarSharedPrefs.settingsAllowVibrate;
  }

  static final _light = 20;
  static final _medium = 120;

  static void win() async {
    if (!await shouldVibrate) return;

    Vibration.vibrate(
      pattern: [0, _medium, 80, 80, 50, 160],
      intensities: [0, 220, 0, 150, 0, 220],
    );
  }

  static void loose() async {
    if (!await shouldVibrate) return;

    Vibration.vibrate(
      pattern: [0, _medium, 40, 80],
      intensities: [0, 255, 0, 120],
    );
  }

  static void turnChange() async => tiny();

  static void tiny() async {
    if (!await shouldVibrate) return;

    Vibration.vibrate(duration: _light);
  }

  static void battleRequest() async {
    if (!await shouldVibrate) return;

    Vibration.vibrate(duration: _medium);
  }

  static void gameFound() async {
    if (!await shouldVibrate) return;

    Vibration.vibrate(pattern: [90, _light, 60, _light, 60, _light]);
  }
}
