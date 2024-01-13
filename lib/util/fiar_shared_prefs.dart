import 'package:flutter/foundation.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides type-safe access to shared preferences with conversion to/from complex datatypes.
class FiarSharedPrefs with ChangeNotifier {
  FiarSharedPrefs._();
  static final FiarSharedPrefs i = FiarSharedPrefs._();

  late SharedPreferences _prefs;
  static SharedPreferences get prefs => i._prefs;

  void onSharedPrefsChanged() => notifyListeners();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static _SharedPrefPair sessionToken = _SharedPrefPair(
    "sessionToken",
    defaultValue: () {
      if (prefs.containsKey("username") && prefs.containsKey("password")) {
        String username = prefs.getString("username")!;
        String password = prefs.getString("password")!;
        prefs.remove("username");
        prefs.remove("password");
        return "migration:::$username:::$password";
      } else {
        return null;
      }
    },
  );

  static _SharedPrefPair<DateTime, int> shownRatingDialog = _SharedPrefPair(
    "ShownRatingDialog",
    defaultValue: () => DateTime.fromMicrosecondsSinceEpoch(0),
    serialize: (date) => date.millisecondsSinceEpoch,
    deserialize: (millis) => DateTime.fromMillisecondsSinceEpoch(millis),
  );

  static _SharedPrefPair<int, int> shownOnlineDialogCount =
      _SharedPrefPair("ShownOnlineDialogCount", defaultValue: () => 0);

  static _SharedPrefPair<String, String> selectedThemeId =
      _SharedPrefPair("selectedThemeId", defaultValue: () => FiarThemeDefault().id);

  static _SharedPrefPair<SocialFeatures, String> socialFeatures = _SharedPrefPair(
    "socialFeatures",
    defaultValue: () => SocialFeatures.NotAsked,
    serialize: (s) => s.name,
    deserialize: (s) => SocialFeatures.values.firstWhere((v) => v.name == s),
  );

  static _SharedPrefPair<bool, bool> settingsAllowVibrate =
      _SharedPrefPair("settingsAllowVibrate", defaultValue: () => true);

  static _SharedPrefPair<bool, bool> settingsAllowNotifications =
      _SharedPrefPair("settingsAllowNotifications", defaultValue: () => true);

  static _SharedPrefPair<List<String>, String> settingsQuickchatEmojis = _SharedPrefPair(
    "settingsQuickchatEmojis",
    defaultValue: () => ["😐", "🤔", "👏", "😄"],
    serialize: (l) => l.join("#"),
    deserialize: (s) => s.split("#").toList(),
  );
}

class _SharedPrefPair<UsedAs, SavedAs> {
  final String key;
  final UsedAs Function() defaultValue;
  final SavedAs Function(UsedAs) serialize;
  final UsedAs Function(SavedAs) deserialize;

  _SharedPrefPair(
    this.key, {
    required this.defaultValue,
    SavedAs Function(UsedAs)? serialize,
    UsedAs Function(SavedAs)? deserialize,
  })  : this.serialize = serialize ?? ((UsedAs d) => d as SavedAs),
        this.deserialize = deserialize ?? ((SavedAs s) => s as UsedAs);

  void set(UsedAs value) async {
    SharedPreferences sp = FiarSharedPrefs.prefs;
    SavedAs serialized = serialize(value);
    switch (serialized.runtimeType) {
      case bool:
        await sp.setBool(this.key, serialized as bool);
        break;
      case int:
        await sp.setInt(this.key, serialized as int);
        break;
      case String:
        await sp.setString(this.key, serialized as String);
        break;
      case double:
        await sp.setDouble(this.key, serialized as double);
        break;
      default:
        throw new UnsupportedError("Unknown setup key type: ${serialized.runtimeType}");
    }
    FiarSharedPrefs.i.onSharedPrefsChanged();
  }

  UsedAs get() {
    SharedPreferences sp = FiarSharedPrefs.prefs;
    final value = sp.get(key);
    return value == null ? defaultValue() : deserialize(value as SavedAs);
  }
}

enum SocialFeatures {
  NotAsked,
  DontAllow,
  Allow,
}
