// @dart=2.9

import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/inherit/route.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'inherit/chat.dart';
import 'inherit/user.dart';
import 'inherit/lifecycle.dart';
import 'inherit/notifications.dart';

import 'menu/main_menu.dart';

Key splashAppKey = UniqueKey();

void main() {
  runApp(
    WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: Colors.blue,
      builder: (_, __) => SplashAppInternal(key: splashAppKey),
    ),
  );
}

class SplashAppInternal extends StatefulWidget {
  const SplashAppInternal({
    Key key,
  }) : super(key: key);

  @override
  _SplashAppInternalState createState() => _SplashAppInternalState();
}

enum AppLoadState { Loading, Preloading, Loaded, Error }

class _SplashAppInternalState extends State<SplashAppInternal>
    with TickerProviderStateMixin {
  AppLoadState state = AppLoadState.Loading;

  AnimationController _lottieAnimCtrl;
  AnimationController _moveUpAnimCtrl;
  Animation _moveUpAnim;
  AnimationController _crossfadeAnimCtrl;

  @override
  void initState() {
    super.initState();

    _lottieAnimCtrl = AnimationController(vsync: this);

    _crossfadeAnimCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 240),
    );

    Future.delayed(Duration(milliseconds: 500), () {
      // Usually, the lottie animation calls initialize() when loaded.
      // If it hasn't yet been called, call it here (screen is probably off).

      _initializeAsyncDependencies(skipAnimations: true);
    });

    SystemUiStyle.mainMenu();
  }

  @override
  void dispose() {
    _lottieAnimCtrl.dispose();
    _moveUpAnimCtrl.dispose();
    _crossfadeAnimCtrl.dispose();
    super.dispose();
  }

  bool _fastForward = false;
  bool _startedInitializing = false;

  Future<void> _initializeAsyncDependencies({
    bool skipAnimations = false,
  }) async {
    if (state == AppLoadState.Loaded) return; // already initialized

    if (_startedInitializing && state != AppLoadState.Error)
      return; // Was already called
    _startedInitializing = true;

    setState(() => state = AppLoadState.Loading);

    FiarSharedPrefs.setup().then(
      (_) async {
        if (skipAnimations) {
          setState(() => state = AppLoadState.Loaded);
          return;
        }

        await Future.delayed(Duration(milliseconds: STARTUP_DELAY_MS));
        if (_fastForward) {
          _preload();
        } else {
          _lottieAnimCtrl.forward();
          Future.delayed(_lottieAnimCtrl.duration, () {
            _preload();
          });
        }
      },
      onError: ((error, stackTrace) {
        setState(() => state = AppLoadState.Error);
      }),
    );
  }

  void _preload() {
    if (_fastForward) return;
    setState(() => state = AppLoadState.Preloading);

    Future.delayed(Duration(milliseconds: 300), () {
      // Short delay between animations because preloading causes jank
      // Then: move up & fade to app
      _moveUpAnimCtrl.forward().then((_) {
        if (_fastForward) return;
        Future.delayed(Duration(milliseconds: 100), () {
          if (_fastForward) return;
          _crossfadeAnimCtrl.forward().then((_) {
            if (_fastForward) return;
            setState(() => state = AppLoadState.Loaded);
          });
        });
      });
    });
  }

  void _skipAnims() {
    _fastForward = true;

    _lottieAnimCtrl.stop();
    _moveUpAnimCtrl.stop();
    _crossfadeAnimCtrl.stop();
    setState(() => state = AppLoadState.Loaded);
  }

  Widget buildSplashScreen() {
    if (state != AppLoadState.Loaded) {
      return GestureDetector(
        onDoubleTap: () => _skipAnims(),
        child: AnimatedBuilder(
          animation: _crossfadeAnimCtrl,
          builder: (_, child) => Opacity(
            opacity: 1 - _crossfadeAnimCtrl.value,
            child: child,
          ),
          child: Container(
            constraints: BoxConstraints.expand(),
            alignment: Alignment.center,
            color: Colors.white,
            child: buildSplashScreenInternal(),
          ),
        ),
      );
    } else {
      return SizedBox();
    }
  }

  Widget buildSplashScreenInternal() {
    if (_moveUpAnimCtrl == null) {
      double viewHeight = MediaQuery.of(context).size.height;
      _moveUpAnimCtrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 350),
      );

      double begin = max(0, viewHeight * 0.5 - 110 / 2);
      double end = max(0, viewHeight * 0.22);

      _moveUpAnim = _moveUpAnimCtrl.drive(
        Tween<double>(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
      );
    }

    switch (state) {
      case AppLoadState.Error:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load the app due to an error. Please try again.',
                style: TextStyle(
                  color: Colors.black87,
                )),
            ElevatedButton(
              child: Text('Retry'),
              onPressed: () => _initializeAsyncDependencies(),
            ),
          ],
        );
      case AppLoadState.Loading:
      case AppLoadState.Preloading:
        return Align(
          alignment: Alignment.topCenter,
          child: AnimatedBuilder(
            animation: _moveUpAnimCtrl,
            builder: (_, child) => Container(
              padding:
                  EdgeInsets.only(left: 32, right: 32, top: _moveUpAnim.value),
              child: child,
            ),
            child: Lottie.asset(
              "assets/lottie/main_menu/wide logo banner anim.json",
              fit: BoxFit.contain,
              controller: _lottieAnimCtrl,
              onLoaded: (c) {
                _lottieAnimCtrl.duration = c.duration * 0.85;
                _initializeAsyncDependencies();
              },
            ),
          ),
        );
      default:
        return SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        state == AppLoadState.Preloading || state == AppLoadState.Loaded
            ? FiarProviderApp()
            : SizedBox(),
        buildSplashScreen(),
      ],
    );
  }
}

class FiarProviderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
    if (gsm.userInfoNotSet) gsm.userInfo = context.read<UserInfo>();
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
                                  child:
                                      SearchingGameNotification(gsm.connected),
                                );
                              }),
                        ),
                        Selector<ServerConnection, bool>(
                          selector: (_, connection) =>
                              connection.catastrophicFailure,
                          shouldRebuild: (_, fail) => fail,
                          builder: (_, catastrophicFailure, child) =>
                              catastrophicFailure
                                  ? AbsorbPointer(
                                      child: Container(
                                        color: Colors.black54,
                                        constraints: BoxConstraints.expand(),
                                        child: FiarSimpleDialog(
                                          title: "Error!",
                                          content:
                                              "Oh no! A fatal error has occurred :( \n\nThe app will close now.",
                                          showOkay: false,
                                        ),
                                      ),
                                    )
                                  : SizedBox(),
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
