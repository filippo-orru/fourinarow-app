import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';

class ThemesProvider with ChangeNotifier {
  final FiarTheme? _overrideTheme;
  List<FiarTheme> allThemes = [
    FiarThemeDefault(),
    FiarThemeDefault(),
    FiarThemeDefault(),
    FiarThemeDefault(),
    FiarThemeWeird(),
    FiarThemeWeird(),
    FiarThemeWeird(),
    FiarThemeWeird(),
  ];

  ThemesProvider({FiarTheme? overrideTheme}) : this._overrideTheme = overrideTheme;

  FiarTheme get selectedTheme {
    String selectedThemeIdId = FiarSharedPrefs.selectedThemeId.get();
    return _overrideTheme ?? allThemes.firstWhere((theme) => theme.id == selectedThemeIdId);
  }

  void setSelectedTheme(String id) {
    FiarSharedPrefs.selectedThemeId.set(id);
    notifyListeners();
  }
}

class FiarTheme {
  final String id;

  /// User facing
  final String name;

  final FiarThemeCategory category;

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
    required this.category,
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

enum FiarThemeCategory { FREE, PREMIUM }

extension FiarThemeCategoryExtension on FiarThemeCategory {
  String get name {
    switch (this) {
      case FiarThemeCategory.FREE:
        return "Free";
      case FiarThemeCategory.PREMIUM:
        return "Premium";
    }
  }
}

class FiarThemeDefault extends FiarTheme {
  FiarThemeDefault()
      : super(
          "default",
          name: "Default (light)",
          category: FiarThemeCategory.FREE,
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
          category: FiarThemeCategory.PREMIUM,
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
