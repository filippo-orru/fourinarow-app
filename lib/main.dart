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
import 'package:four_in_a_row/util/constants.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

import 'inherit/chat.dart';
import 'inherit/user.dart';
import 'inherit/lifecycle.dart';
import 'inherit/notifications.dart';

import 'menu/main_menu.dart';

void main() {
  runApp(
    SplashApp(
      key: UniqueKey(),
      mainApp: mainApp,
    ),
  );
}

class SplashApp extends StatefulWidget {
  final Widget Function() mainApp;

  const SplashApp({
    Key key,
    @required this.mainApp,
  }) : super(key: key);

  @override
  _SplashAppState createState() => _SplashAppState();
}

enum AppLoadState { Loading, Preloading, Loaded, Error }

class _SplashAppState extends State<SplashApp>
    with SingleTickerProviderStateMixin {
  AnimationController _lottieAnimCtrl;
  AppLoadState state = AppLoadState.Loading;

  @override
  void initState() {
    super.initState();

    _lottieAnimCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1100))
          ..forward()
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _lottieAnimCtrl.value = 0; //.95 / 3.0;
              _lottieAnimCtrl.forward();
            }
          });
    _initializeAsyncDependencies();
  }

  Future<void> _initializeAsyncDependencies() async {
    setState(() => state = AppLoadState.Loading);
    await Future.delayed(Duration(milliseconds: STARTUP_DELAY_MS));
    FiarSharedPrefs.setup().then(
      (_) {
        setState(() => state = AppLoadState.Preloading);
        Future.delayed(Duration(milliseconds: 380), () {
          setState(() => state = AppLoadState.Loaded);
        });
      },
      onError: ((error, stackTrace) {
        setState(() => state = AppLoadState.Error);
      }),
    );
  }

  Widget buildLoadingScreen() {
    switch (state) {
      case AppLoadState.Error:
        return Container(
          key: ValueKey("err"),
          color: Colors.white,
          constraints: BoxConstraints.expand(),
          child: Column(
            children: [
              Text('Could not load the app due to an error. Please try again.'),
              ElevatedButton(
                child: Text('Retry'),
                onPressed: () => _initializeAsyncDependencies(),
              ),
            ],
          ),
        );
      case AppLoadState.Loading:
      case AppLoadState.Preloading:
        return WidgetsApp(
          debugShowCheckedModeBanner: false,
          color: Colors.blue,
          builder: (_, __) => Container(
            key: ValueKey("loading"),
            color: Colors.white,
            constraints: BoxConstraints.expand(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _lottieAnimCtrl,
                  builder: (_, child) => Transform.rotate(
                      angle: pi * _lottieAnimCtrl.value, child: child),
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey[100],
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 0),
                              blurRadius: 12),
                        ]),
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          buildDot(red: true),
                          SizedBox(width: 8),
                          buildDot(red: false),
                        ]),
                        SizedBox(height: 8),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          buildDot(red: false),
                          SizedBox(width: 8),
                          buildDot(red: true),
                        ])
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return SizedBox();
    }
  }

  Widget buildDot({bool red}) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: red ? Colors.redAccent : Colors.blueAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        state == AppLoadState.Preloading || state == AppLoadState.Loaded
            ? mainApp()
            : SizedBox(),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 150),
          child: buildLoadingScreen(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _lottieAnimCtrl.dispose();
    super.dispose();
  }
}

Widget mainApp() {
  return ChangeNotifierProvider<ServerConnection>(
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
        child: FiarApp(),
      ),
      lazy: false,
    ),
  );
}

class FiarApp extends StatefulWidget {
  @override
  _FiarAppState createState() => _FiarAppState();
}

class _FiarAppState extends State<FiarApp> {
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
                      ElevatedButton(
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
