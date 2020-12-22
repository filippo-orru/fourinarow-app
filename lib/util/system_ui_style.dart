import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUiStyle {
  static void mainMenu() {
    SystemUiOverlayStyle(
      statusBarColor: Colors.black12,
      statusBarIconBrightness: Brightness.dark,
    ).apply();
  }
}

extension MySystemUiOverlayStyleExtension on SystemUiOverlayStyle {
  void apply() {
    SystemChrome.setSystemUIOverlayStyle(this);
  }
}
