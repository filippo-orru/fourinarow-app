import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'inherit/user.dart';
import 'inherit/lifecycle.dart';
import 'inherit/connection/server_conn.dart';
import 'inherit/notifications.dart';

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
          child: LifecycleProvider(
            child: NotificationsProvider(
              child: UserinfoProvider(
                child: Builder(
                  builder: (ctx) => WidgetsApp(
                    localizationsDelegates: [
                      DefaultMaterialLocalizations.delegate
                    ],
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
                      child: Stack(children: [
                        child,
                        Positioned(
                          top: MediaQuery.of(ctx).padding.top,
                          right: 0,
                          child: Opacity(
                            opacity: 1,
                            // opacity: 0.4,
                            child: Container(
                              margin: EdgeInsets.all(16), //top: 32, right:
                              decoration: BoxDecoration(
                                color: Colors.white54,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                                boxShadow: [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Colors.black12,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Text(
                                'BETA',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
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
