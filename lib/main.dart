import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/inherit/user.dart';

import 'inherit/connection/server_conn.dart';
import 'menu/main_menu.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  bool exitConfirm = false;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarColor: Colors.black26,
    ));

    return WillPopScope(
      onWillPop: () {
        if (exitConfirm) {
          return Future.value(true);
        } else {
          showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return Container(
                  height: 96,
                  width: max(MediaQuery.of(context).size.width * 0.8, 256),
                  child: Column(
                    children: <Widget>[
                      Center(child: Text("Are you sure you want to exit?")),
                      RaisedButton(
                        onPressed: () {
                          exitConfirm = true;
                          Navigator.of(context).pop();
                        },
                        child: Text("Yes"),
                      ),
                    ],
                  ),
                );
              });
          return Future.value(false);
        }
      },
      child: RouteObserverProvider(
        observer: routeObserver,
        child: GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);

            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: UserinfoProvider(
            child: Builder(
              builder: (ctx) => WidgetsApp(
                localizationsDelegates: [DefaultMaterialLocalizations.delegate],
                title: 'Four in a Row',
                color: Colors.green,
                initialRoute: "/",
                pageRouteBuilder: <T>(RouteSettings settings,
                    Widget Function(BuildContext) builder) {
                  return MaterialPageRoute<T>(
                      builder: builder, settings: settings);
                },
                builder: (ctx, child) => ServerConnProvider(
                  userInfo: UserinfoProvider.of(ctx),
                  child: child,
                ),
                // routes: {
                //   "/": (context) => MainMenu(),
                // "/playOverview": (_) => PlayOverviewMenu(),
                // "/local/play": (context) => PlayingLocal(),
                // "/online/selectRange": (context) => OnlineMenuRange(),
                // "/online/selectHost": (context) => OnlineMenuHost(),
                // "/online/play": (context) => PlayingOnline(),
                // },
                home: MainMenu(),
                debugShowCheckedModeBanner: false,
                navigatorObservers: [routeObserver],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RouteObserverProvider extends InheritedWidget {
  RouteObserverProvider(
      {Key key, @required this.child, @required this.observer})
      : super(key: key, child: child);

  final Widget child;
  final RouteObserver observer;

  static RouteObserverProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RouteObserverProvider>();
  }

  @override
  bool updateShouldNotify(RouteObserverProvider oldWidget) {
    return false;
  }
}
