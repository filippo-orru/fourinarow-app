import 'package:shared_preferences/shared_preferences.dart';

class FiarSharedPrefs {
  FiarSharedPrefs._();

  static late SharedPreferences _sharedPrefsInternal;
  static SharedPreferences get _sharedPrefs {
    return _sharedPrefsInternal;
  }

  static Future<void> setup() async {
    _sharedPrefsInternal = await SharedPreferences.getInstance();

    for (var pair in _pairs) {
      if (_sharedPrefs.containsKey(pair.key)) continue;

      Function setFun;
      switch (pair.type) {
        case bool:
          setFun = _sharedPrefs.setBool;
          break;
        case int:
          setFun = _sharedPrefs.setInt;
          break;
        case String:
          setFun = _sharedPrefs.setString;
          break;
        case double:
          setFun = _sharedPrefs.setDouble;
          break;
        default:
          throw new UnsupportedError("Unknown setup key type: ${pair.type}");
      }
      setFun.call(pair.key, pair.defaultValue());
    }
  }

  // static void Function(String key) remove = _sharedPrefs.remove;

  static List<_SharedPrefPair> _pairs = [
    _shownRatingDialog,
    _shownOnlineDialogCount,
    _sessionToken,
    _shownSwipeDialog,
    _hasAcceptedChat
  ];

  static _SharedPrefPair _sessionToken =
      _SharedPrefPair("sessionToken", String, defaultValue: () {
    if (_sharedPrefs.containsKey("username") &&
        _sharedPrefs.containsKey("password")) {
      String username = _sharedPrefs.getString("username");
      String password = _sharedPrefs.getString("password");
      _sharedPrefs.remove("username");
      _sharedPrefs.remove("password");
      return "migration:$username:$password";
    } else {
      return null;
    }
  });

  static String? get sessionToken {
    if (_sharedPrefs.containsKey(_sessionToken.key)) {
      return _sharedPrefs.getString(_sessionToken.key);
    } else {
      return null;
    }
  }

  static set sessionToken(String? i) =>
      _sharedPrefs.setString(_sessionToken.key, i);

  static _SharedPrefPair _shownRatingDialog =
      _SharedPrefPair("ShownRatingDialog", int, defaultValue: () => 0);
  static DateTime get shownRatingDialog => DateTime.fromMillisecondsSinceEpoch(
      _sharedPrefs.getInt(_shownRatingDialog.key));
  static set shownRatingDialog(DateTime val) =>
      _sharedPrefs.setInt(_shownRatingDialog.key, val.millisecondsSinceEpoch);
  static bool get shouldShowRatingDialog =>
      shownRatingDialog.difference(DateTime.now()).inHours >
      24 * 30 * 4; // >4 months ago

  static _SharedPrefPair _shownOnlineDialogCount =
      _SharedPrefPair("ShownOnlineDialogCount", int, defaultValue: () => 0);
  static int get shownOnlineDialogCount =>
      _sharedPrefs.getInt(_shownOnlineDialogCount.key);
  static set shownOnlineDialogCount(int i) =>
      _sharedPrefs.setInt(_shownOnlineDialogCount.key, i);

  static _SharedPrefPair _shownSwipeDialog =
      _SharedPrefPair("shownSwipeDialog", bool, defaultValue: () {
    if (_sharedPrefs.containsKey("shown_swype_dialog")) {
      var s = _sharedPrefs.getBool("shown_swype_dialog");
      _sharedPrefs.remove("shown_swype_dialog");
      return s;
    } else {
      return false;
    }
  });
  static bool get shownSwipeDialog =>
      _sharedPrefs.getBool(_shownSwipeDialog.key);
  static set shownSwipeDialog(bool i) =>
      _sharedPrefs.setBool(_shownSwipeDialog.key, i);

  static _SharedPrefPair _hasAcceptedChat =
      _SharedPrefPair("hasAcceptedChat", bool, defaultValue: () => false);
  static bool get hasAcceptedChat => _sharedPrefs.getBool(_hasAcceptedChat.key);
  static set hasAcceptedChat(bool i) =>
      _sharedPrefs.setBool(_hasAcceptedChat.key, i);
}

class _SharedPrefPair<T> {
  final String key;
  final Type type;
  final T Function() defaultValue;

  _SharedPrefPair(this.key, this.type, {required this.defaultValue});
}
