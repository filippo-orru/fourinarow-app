// @dart=2.9

import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/inherit/route.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'inherit/chat.dart';
import 'inherit/user.dart';
import 'inherit/lifecycle.dart';
import 'inherit/notifications.dart';

import 'menu/main_menu.dart';

void main() => runApp(ChangeNotifierProvider<ServerConnection>(
      create: (_) => ServerConnection(),
      child: ChangeNotifierProvider<UserInfo>(
        create: (_) => UserInfo(),
        child: Consumer<ServerConnection>(
          builder: (_, serverConnection, child) => MultiProvider(
            providers: [
              ChangeNotifierProvider<GameStateManager>(
                create: (_) => GameStateManager(serverConnection),
                lazy: false,
              ),
              ChangeNotifierProvider<ChatState>(
                create: (_) => ChatState(serverConnection),
                lazy: false,
              )
            ],
            child: child,
          ),
          child: MyApp(),
        ),
        lazy: false,
      ),
    ));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  bool exitConfirm = false;

  NavigatorState _navigator;

  void _initialization(BuildContext ctx) {
    var gsm = context.read<GameStateManager>();
    gsm.lifecycle ??= LifecycleProvider.of(ctx);
    gsm.notifications ??= NotificationsProvider.of(ctx);
    gsm.userInfo ??= context.read<UserInfo>();
  }

  @override
  Widget build(BuildContext context) {
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
                  width: max(MediaQuery.of(ctx).size.width * 0.8, 256),
                  child: Column(
                    children: <Widget>[
                      Center(child: Text("Are you sure you want to exit?")),
                      RaisedButton(
                        onPressed: () {
                          exitConfirm = true;
                          Navigator.of(ctx).pop();
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
        child: LifecycleProvider(
          child: NotificationsProvider(
            child: WidgetsApp(
              localizationsDelegates: [DefaultMaterialLocalizations.delegate],
              title: 'Four in a Row',
              color: Colors.blueAccent,
              initialRoute: "/",
              pageRouteBuilder: <T>(RouteSettings settings,
                  Widget Function(BuildContext) builder) {
                return MaterialPageRoute<T>(
                    builder: builder, settings: settings);
              },
              builder: (ctx, child) {
                _initialization(ctx);
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: Stack(children: [
                        child,
                        Positioned(
                          top: MediaQuery.of(ctx).padding.top,
                          right: 24,
                          child: Opacity(
                            opacity: 0.3,
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
                                'BETA2',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(ctx).padding.top,
                          left: 0,
                          right: 0,
                          child: Selector<GameStateManager, List<dynamic>>(
                              shouldRebuild: (list1, list2) {
                                return !listEquals(list1, list2);
                              },
                              selector: (_, gsm) => [
                                    gsm.showViewer,
                                    gsm.hideViewer,
                                    gsm.connected,
                                    gsm.currentGameState
                                        is WaitingForWWOpponentState
                                  ],
                              builder: (_, tuple, __) {
                                // print("building popup");
                                var gsm = ctx.read<GameStateManager>();
                                if (gsm.showViewer) {
                                  Future.delayed(Duration.zero, () {
                                    _navigator
                                        .push(slideUpRoute(GameStateViewer()));
                                  });
                                  // gsm.showViewer = false;
                                }

                                if (gsm.hideViewer) {
                                  // gsm.closingViewer();
                                  Future.delayed(Duration.zero, () {
                                    _navigator.pop();
                                  });
                                }
                                return TweenAnimationBuilder(
                                    curve: Curves.easeOutQuad,
                                    tween: Tween<double>(
                                        begin: 1,
                                        end: gsm.currentGameState
                                                is WaitingForWWOpponentState
                                            ? 0
                                            : 1),
                                    duration: Duration(milliseconds: 250),
                                    builder: (_, val, child) =>
                                        Transform.translate(
                                            offset: Offset(0, -144 * val),
                                            child: child),
                                    child: SearchingGameNotification(
                                        gsm.connected));
                              }),
                        ),
                      ]),
                    ),
                    !kIsWeb && Platform.isIOS
                        ? GestureDetector(
                            onTap: () => _navigator?.maybePop(),
                            child: Container(
                              color: Colors.black,
                              height: 32,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // BackButton(color: Colors.white),
                                  Icon(Icons.arrow_back, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Go back'),
                                ],
                              ),
                            ),
                          )
                        : SizedBox(),
                  ],
                );
              },
              home: Builder(
                builder: (context) {
                  _navigator = Navigator.of(context);
                  return MainMenu();
                },
              ),
              debugShowCheckedModeBanner: false,
              navigatorObservers: [routeObserver],
            ),
          ),
        ),
      ),
    );
  }
}
