import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/play/play_local.dart';
import 'package:four_in_a_row/play/play_online.dart';

import 'menu/main_menu.dart';
import 'menu/online_menu.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.black26,
    ));

    return MaterialApp(
      title: 'Four in a Row',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        "/": (context) => MainMenu(),
        "/local/play": (context) => PlayingLocal(),
        "/online/selectRange": (context) => OnlineMenuRange(),
        "/online/selectHost": (context) => OnlineMenuHost(),
        // "/online/play": (context) => PlayingOnline(),
      },
      debugShowCheckedModeBanner: false,
      // home: MyHomePage(),
    );
  }
}
