import 'package:shared_preferences/shared_preferences.dart';

class FiarSharedPrefs {
  FiarSharedPrefs._();

  static late SharedPreferences _sharedPrefsInternal;
  static SharedPreferences get sharedPrefs {
    return _sharedPrefsInternal;
  }

  static Future<void> setup() async {
    _sharedPrefsInternal = await SharedPreferences.getInstance();

    for (var pair in _pairs) {
      if (sharedPrefs.containsKey(pair.key)) continue;

      Function setFun;
      switch (pair.type) {
        case bool:
          setFun = sharedPrefs.setBool;
          break;
        case int:
          setFun = sharedPrefs.setInt;
          break;
        case String:
          setFun = sharedPrefs.setString;
          break;
        case double:
          setFun = sharedPrefs.setDouble;
          break;
        default:
          throw new UnsupportedError("Unknown setup key type: ${pair.type}");
      }
      var value = pair.defaultValue();
      if (value == null) {
        _sharedPrefsInternal.remove(pair.key);
      } else {
        setFun.call(pair.key, value);
      }
    }
  }

  // static void Function(String key) remove = _sharedPrefs.remove;

  static List<_SharedPrefPair> _pairs = [
    _shownRatingDialog,
    _shownOnlineDialogCount,
    _sessionToken,
    _shownSwipeDialog,
    _hasAcceptedChat,
    _settingsAllowVibrate
  ];

  static _SharedPrefPair _sessionToken = _SharedPrefPair("sessionToken", String, defaultValue: () {
    if (sharedPrefs.containsKey("username") && sharedPrefs.containsKey("password")) {
      String username = sharedPrefs.getString("username")!;
      String password = sharedPrefs.getString("password")!;
      sharedPrefs.remove("username");
      sharedPrefs.remove("password");
      return "migration:::$username:::$password";
    } else {
      return null;
    }
  });

  static String? get sessionToken {
    if (sharedPrefs.containsKey(_sessionToken.key)) {
      return sharedPrefs.getString(_sessionToken.key);
    } else {
      return null;
    }
  }

  static set sessionToken(String? s) {
    if (s == null)
      sharedPrefs.remove(_sessionToken.key);
    else
      sharedPrefs.setString(_sessionToken.key, s);
  }

  static _SharedPrefPair _shownRatingDialog =
      _SharedPrefPair("ShownRatingDialog", int, defaultValue: () => 0);
  static DateTime get shownRatingDialog => DateTime.fromMillisecondsSinceEpoch(
      sharedPrefs.getInt(_shownRatingDialog.key) ?? _shownRatingDialog.defaultValue());
  static set shownRatingDialog(DateTime val) =>
      sharedPrefs.setInt(_shownRatingDialog.key, val.millisecondsSinceEpoch);
  static bool get shouldShowRatingDialog =>
      shownRatingDialog.difference(DateTime.now()).inHours > 24 * 30 * 4; // >4 months ago

  static _SharedPrefPair _shownOnlineDialogCount =
      _SharedPrefPair("ShownOnlineDialogCount", int, defaultValue: () => 0);
  static int get shownOnlineDialogCount =>
      sharedPrefs.getInt(_shownOnlineDialogCount.key) ?? _shownOnlineDialogCount.defaultValue();
  static set shownOnlineDialogCount(int i) => sharedPrefs.setInt(_shownOnlineDialogCount.key, i);

  static _SharedPrefPair _shownSwipeDialog =
      _SharedPrefPair("shownSwipeDialog", bool, defaultValue: () {
    if (sharedPrefs.containsKey("shown_swype_dialog")) {
      var s = sharedPrefs.getBool("shown_swype_dialog");
      sharedPrefs.remove("shown_swype_dialog");
      return s;
    } else {
      return false;
    }
  });
  static bool get shownSwipeDialog =>
      sharedPrefs.getBool(_shownSwipeDialog.key) ?? _shownSwipeDialog.defaultValue();
  static set shownSwipeDialog(bool i) => sharedPrefs.setBool(_shownSwipeDialog.key, i);

  static _SharedPrefPair _selectedThemeId =
      _SharedPrefPair("selectedThemeId", String, defaultValue: () {
    return "weird";
  });
  static String get selectedThemeId =>
      sharedPrefs.getString(_selectedThemeId.key) ?? _selectedThemeId.defaultValue();
  static set selectedThemeId(String t) => sharedPrefs.setString(_selectedThemeId.key, t);

  static _SharedPrefPair _hasAcceptedChat =
      _SharedPrefPair("hasAcceptedChat", bool, defaultValue: () => false);
  static bool get hasAcceptedChat =>
      sharedPrefs.getBool(_hasAcceptedChat.key) ?? _hasAcceptedChat.defaultValue();
  static set hasAcceptedChat(bool i) => sharedPrefs.setBool(_hasAcceptedChat.key, i);

  static _SharedPrefPair _settingsAllowVibrate =
      _SharedPrefPair("settingsAllowVibrate", bool, defaultValue: () => true);
  static bool get settingsAllowVibrate =>
      sharedPrefs.getBool(_settingsAllowVibrate.key) ?? _settingsAllowVibrate.defaultValue();
  static set settingsAllowVibrate(bool i) => sharedPrefs.setBool(_settingsAllowVibrate.key, i);

  static _SharedPrefPair _settingsAllowNotifications =
      _SharedPrefPair("settingsAllowNotifications", bool, defaultValue: () => true);
  static bool get settingsAllowNotifications =>
      sharedPrefs.getBool(_settingsAllowNotifications.key) ??
      _settingsAllowNotifications.defaultValue();
  static set settingsAllowNotifications(bool i) =>
      sharedPrefs.setBool(_settingsAllowNotifications.key, i);

  static _SharedPrefPair _settingsQuickchatEmojis =
      _SharedPrefPair("settingsQuickchatEmojis", String, defaultValue: () => "😐#🤔#👏#😄");
  static List<String> get settingsQuickchatEmojis =>
      (sharedPrefs.getString(_settingsQuickchatEmojis.key) ??
              _settingsQuickchatEmojis.defaultValue() as String)
          .split("#")
          .toList();
  static set settingsQuickchatEmojis(List<String> i) =>
      sharedPrefs.setString(_settingsQuickchatEmojis.key, i.join("#"));
}

// TODO actually use this
class _SharedPrefPair<T> {
  final String key;
  final Type type;
  final T? Function() defaultValue;
  final T Function()? userGet;
  final void Function(T)? userSet;

  _SharedPrefPair(this.key, this.type, {required this.defaultValue, this.userGet, this.userSet});

  void set(T value) async {
    if (userSet != null) {
      userSet!(value);
    } else {
      SharedPreferences sp = FiarSharedPrefs.sharedPrefs;
      Function setFun;
      switch (value.runtimeType) {
        case bool:
          setFun = sp.setBool;
          break;
        case int:
          setFun = sp.setInt;
          break;
        case String:
          setFun = sp.setString;
          break;
        case double:
          setFun = sp.setDouble;
          break;
        default:
          throw new UnsupportedError("Unknown setup key type: ${value.runtimeType}");
      }
      await (setFun as Future Function(String, dynamic)).call(this.key, value);
    }
  }
}
