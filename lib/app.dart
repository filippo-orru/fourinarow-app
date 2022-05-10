import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/other.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:four_in_a_row/providers/chat.dart';
import 'package:four_in_a_row/providers/notifications.dart';
import 'package:four_in_a_row/providers/route.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:four_in_a_row/util/battle_req_popup.dart';
import 'package:four_in_a_row/util/global_common_widgets.dart';
import 'package:provider/provider.dart';

import 'connection/server_connection.dart';
import 'menu/main_menu.dart';

final Key fiarProviderAppKey = UniqueKey();

class FiarProviderApp extends StatelessWidget {
  FiarProviderApp() : super(key: fiarProviderAppKey);

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

  NavigatorState? _navigator;

  void _initialization(BuildContext ctx) {
    var gsm = context.read<GameStateManager>();
    gsm.notificationsProvider ??= ctx.read<NotificationsProvider>();
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
        child: Provider<NotificationsProvider>.value(
          value: NotificationsProvider(),
          child: WidgetsApp(
            localizationsDelegates: [DefaultMaterialLocalizations.delegate],
            title: 'Four in a Row',
            color: Colors.blueAccent,
            initialRoute: "/",
            pageRouteBuilder: <T>(RouteSettings settings, Widget Function(BuildContext) builder) {
              return MaterialPageRoute<T>(builder: builder, settings: settings);
            },
            builder: (ctx, child) {
              _initialization(ctx);
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                    child: Stack(children: [
                      child ?? SizedBox(),
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
                                  gsm.currentGameState is WaitingForWWOpponentState
                                ],
                            builder: (_, tuple, __) {
                              // print("building popup");
                              var gsm = ctx.read<GameStateManager>();
                              if (gsm.showViewer) {
                                Future.delayed(Duration.zero, () {
                                  _navigator!.push(slideUpRoute(GameStateViewer()));
                                });
                                // gsm.showViewer = false;
                              }

                              if (gsm.hideViewer) {
                                // gsm.closingViewer();
                                Future.delayed(Duration.zero, () {
                                  _navigator!.pop();
                                });
                              }
                              return TweenAnimationBuilder<double>(
                                curve: Curves.easeOutQuad,
                                tween: Tween<double>(
                                  begin: 1,
                                  end: gsm.currentGameState is WaitingForWWOpponentState ? 0 : 1,
                                ),
                                duration: Duration(milliseconds: 250),
                                builder: (ctx, val, child) => Transform.translate(
                                  offset: Offset(0, -144.0 * val),
                                  child: child,
                                ),
                                child: SearchingGameNotification(gsm.connected),
                              );
                            }),
                      ),
                      Positioned(
                        top: MediaQuery.of(ctx).padding.top,
                        left: 0,
                        right: 0,
                        child: Selector<GameStateManager, BattleRequestState?>(
                          selector: (_, gsm) => gsm.incomingBattleRequest,
                          builder: (_, battleRequestState, __) => battleRequestState != null
                              ? BattleRequestPopup(
                                  username: battleRequestState.user.username,
                                  joinCallback: () => context.read<GameStateManager>()
                                    ..startGame(
                                      ORqLobbyJoin(battleRequestState.lobbyId),
                                    )
                                    ..cancelIncomingBattleReq(),
                                  leaveCallback: () =>
                                      context.read<GameStateManager>().cancelIncomingBattleReq(),
                                )
                              : SizedBox(),
                        ),
                      ),
                      Selector<ServerConnection, bool>(
                        selector: (_, connection) => connection.catastrophicFailure,
                        shouldRebuild: (_, fail) => fail,
                        builder: (_, catastrophicFailure, child) => catastrophicFailure
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
                      Selector<ServerConnection, bool>(
                        selector: (_, connection) => connection.closedDueToOtherClient,
                        shouldRebuild: (oldState, newState) => oldState != newState,
                        builder: (ctx, closedDueToOtherClient, child) => AnimatedSwitcher(
                          duration: Duration(milliseconds: 120),
                          child: closedDueToOtherClient
                              ? Container(
                                  color: Colors.black54,
                                  constraints: BoxConstraints.expand(),
                                  child: FiarSimpleDialog(
                                    title: "Connection paused",
                                    content:
                                        "You seem to be logged in on another device.\nIf you want to " +
                                            "play on this device instead, tap okay.",
                                    showOkay: true,
                                    onOkay: () async {
                                      ServerConnection connection = ctx.read<ServerConnection>();
                                      connection.closedDueToOtherClient = false;
                                      await connection.retryConnection();
                                    },
                                  ),
                                )
                              : SizedBox(),
                        ),
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
    );
  }
}
