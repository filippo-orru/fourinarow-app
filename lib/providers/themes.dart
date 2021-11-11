import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';

class ThemesProvider with ChangeNotifier {
  final FiarTheme? _overrideTheme;
  List<FiarTheme> allThemes = [
    FiarThemeDefault(),
    FiarThemeWeird(),
  ];

  ThemesProvider({FiarTheme? overrideTheme}) : this._overrideTheme = overrideTheme;

  FiarTheme get selectedTheme {
    String selectedThemeIdId = FiarSharedPrefs.selectedThemeId;
    return _overrideTheme ?? allThemes.firstWhere((theme) => theme.id == selectedThemeIdId);
  }

  void setSelectedTheme(String id) {
    FiarSharedPrefs.selectedThemeId = id;
    notifyListeners();
  }
}

class FiarTheme {
  final String id;

  /// User facing
  final String name;

  /// For buttons etc
  final MaterialColor accentColor;
  //final Color buttonOutlineColor;
  final Color menuBackgroundColor;

  /// Used for chips
  final Color playerOneColor;

  /// Used for chips
  final Color playerTwoColor;

  final Color chatThemeColor;
  final MaterialColor friendsThemeColor;
  final Color accountLoginAccentColor;
  final Color accountRegisterAccentColor;
  final Color playOnlineThemeColor;
  final Color playLocalThemeColor;
  final Color playCpuThemeColor;

  FiarTheme(
    this.id, {
    required this.name,
    required this.menuBackgroundColor,
    required this.accentColor,
    //required this.buttonOutlineColor,
    required this.playerOneColor,
    required this.playerTwoColor,
    required this.chatThemeColor,
    required this.friendsThemeColor,
    required this.accountLoginAccentColor,
    // required this.accountLoginComplementaryColor,
    required this.accountRegisterAccentColor,
    required this.playOnlineThemeColor,
    required this.playLocalThemeColor,
    required this.playCpuThemeColor,
    // required this.accountRegisterComplementaryColor,
  });
}

class FiarThemeDefault extends FiarTheme {
  FiarThemeDefault()
      : super(
          "default",
          name: "Default (light)",
          menuBackgroundColor: Color(0xFFFDFDFD),
          playerOneColor: Colors.blue,
          playerTwoColor: Colors.red,
          accentColor: Colors.blue,
          //buttonOutlineColor: ,
          chatThemeColor: Colors.blueAccent,
          friendsThemeColor: Colors.purple,
          accountLoginAccentColor: Colors.blueAccent,
          accountRegisterAccentColor: Colors.redAccent,
          playOnlineThemeColor: Colors.redAccent,
          playLocalThemeColor: Colors.blueAccent,
          playCpuThemeColor: Colors.deepPurple,
        );
}

class FiarThemeWeird extends FiarTheme {
  FiarThemeWeird()
      : super(
          "weird",
          name: "Weird",
          menuBackgroundColor: Colors.amber,
          playerOneColor: Colors.purple,
          playerTwoColor: Colors.green,
          accentColor: Colors.pink,
          //buttonOutlineColor: ,
          chatThemeColor: Colors.lime,
          friendsThemeColor: Colors.green,
          accountLoginAccentColor: Colors.teal,
          // accountLoginComplementaryColor: ,
          accountRegisterAccentColor: Colors.blue,
          playOnlineThemeColor: Colors.green[100]!,
          playLocalThemeColor: Colors.green[800]!,
          playCpuThemeColor: Colors.pink[800]!,
          // accountRegisterComplementaryColor: ,
        );
}
