import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUiStyle {
  static void mainMenu() {
    SystemUiOverlayStyle(
      statusBarColor: Colors.black12,
      statusBarIconBrightness: Brightness.dark,
    ).apply();
  }

  static void playSelection() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.black26,
      statusBarIconBrightness: Brightness.light,
    ));
  }
}

extension MySystemUiOverlayStyleExtension on SystemUiOverlayStyle {
  void apply() {
    SystemChrome.setSystemUIOverlayStyle(this);
  }
}
