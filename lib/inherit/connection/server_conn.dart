import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/play/online/play_online.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'package:four_in_a_row/util/toast.dart';
import 'package:four_in_a_row/util/battle_req_popup.dart';

import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/play/online/game_states/all.dart' as game_state;
import 'package:four_in_a_row/util/vibration.dart';
import '../lifecycle.dart';
import '../notifications.dart';
import 'messages.dart';
// import 'package:flutter_local_notifications/src/';

import 'package:web_socket_channel/web_socket_channel.dart';

class _InheritedServerConnProvider extends InheritedWidget {
  _InheritedServerConnProvider({Key key, this.child, this.data})
      : super(key: key, child: child);

  final Widget child;
  final ServerConnState data;

  @override
  bool updateShouldNotify(_InheritedServerConnProvider oldWidget) {
    // return oldWidget.data.gameState.runtimeType == this.data.gameState.runtimeType;
    // print("Update notify");
    return true;
  }
}

class ServerConnProvider extends StatefulWidget {
  ServerConnProvider({
    Key key,
    @required UserinfoProviderState userInfo,
    @required this.child,
  })  : _userInfo = userInfo,
        super(key: key);

  final Widget child;
  final UserinfoProviderState _userInfo;

  @override
  createState() => ServerConnState();

  static ServerConnState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedServerConnProvider>()
        ?.data;
  }
}

class ServerConnState extends State<ServerConnProvider> {
  ServerConnState() {
    _initializeConnection();
  }

  CurrentServerInfo currentServerInfo;

  bool _awaitingConfirmation = false;

  BuildContext menuContext;

  WebSocketChannel _connection;
  StreamSubscription _wsMsgSub;
  StreamSubscription _playerMsgSub;

  StreamController<PlayerMessage> outgoing;
  StreamController<ServerMessage> incoming;
  // Stream<ServerMessage> _incoming;
  // Sink<PlayerMessage> _outgoing;

  Timer timeoutTimer;
  bool loggedIn = false;
  VoidCallback awaitingLogin;
  bool inLobby = false;
  bool leaving = false;
  Toast popup;
  BattleRequestPopup battleRequest = BattleRequestPopup(null, null);

  // StreamController<ServerMessage> get incoming => incoming;
  // StreamController<PlayerMessage> get outgoing => outgoing;

  game_state.GameState _gameState;
  game_state.GameState get gameState => _gameState;

  bool get connected => _connection != null;
  // ConnStateConnectedState(UserinfoProviderState userInfo)

  void startGame(OnlineRequest req) async {
    if (inLobby) {
      print("leave in startgame");
      outgoing.add(PlayerMsgLeave());
    }

    if ((widget._userInfo?.loggedIn == true) && !this.loggedIn) {
      this.outgoing.add(
          PlayerMsgLogin(widget._userInfo.username, widget._userInfo.password));
      this.awaitingLogin = () {};
      // this.awaitingLogin = () => _requestGame(req);
    }

    if (!(_gameState is game_state.Idle)) {
      changeGameState(
          game_state.Idle(this.outgoing, this.incoming, changeGameState));
    }

    if (menuContext != null && !(req is ORqBattle)) {
      Navigator.of(menuContext)?.push(fadeRoute(child: PlayingOnline()));
    }
    await Future.delayed(Duration(milliseconds: 15));

    if (req is ORqLobby) {
      this.outgoing?.add(req.lobbyCode == null
          ? PlayerMsgLobbyRequest()
          : PlayerMsgLobbyJoin(req.lobbyCode));
    } else if (req is ORqWorldwide) {
      this.outgoing?.add(PlayerMsgWorldwideRequest());
    } else if (req is ORqBattle) {
      this.outgoing?.add(PlayerMsgBattleRequest(req.id));
    }
    inLobby = true;
  }

  Future<bool> refresh() async {
    _initializeConnection();
    await Future.delayed(Duration(milliseconds: 300));
    if (this.connected) {
      outgoing.add(PlayerMsgPing());
      var msg = await incoming.stream.first
          .timeout(Duration(seconds: 2), onTimeout: () => null);
      return msg is MsgPong;
    } else {
      return false;
    }
  }

  void _initializeConnection() {
    _wsMsgSub?.cancel();
    _playerMsgSub?.cancel();

    this._connection = WebSocketChannel.connect(
      Uri.parse(WS_URL),
    );
    _wsMsgSub = _handleSMessages(_connection.stream);
    _playerMsgSub = _handlePMessages(_connection.sink);

    var idle = game_state.Idle(this.outgoing, this.incoming, changeGameState);
    changeGameState(idle);
  }

  void leaveGame() {
    // print("called leave game\n" + StackTrace.current.toString());

    if (inLobby) {
      this.outgoing?.add(PlayerMsgLeave());
      inLobby = false;

      Future.delayed(
        Duration(milliseconds: 500),
        () => changeGameState(
            game_state.Idle(this.outgoing, this.incoming, changeGameState)),
      );
    }
  }

  void showBattleRequest(String userId, String lobbyCode) async {
    try {
      var user = await UserinfoProvider.of(context).getUserInfo(userId: userId);

      if (LifecycleProvider.of(context).state == AppLifecycleState.resumed) {
        Vibrations.battleRequest();
        this.battleRequest = BattleRequestPopup(user.name, () {
          startGame(ORqLobby(lobbyCode));
        });
      } else {
        var notifProv = NotificationsProvider.of(context);
        notifProv.flutterNotifications?.cancel(MyNotifications.battleRequest);
        notifProv.flutterNotifications?.show(
          MyNotifications.battleRequest,
          'Battle Request!',
          "${user.name} has requested a match. Tap to join!",
          MyNotifications.battleRequestSpecifics,
          payload: lobbyCode,
        );
        notifProv.selectedStream.first
            .timeout(BattleRequestPopup.DURATION, onTimeout: () => null)
            .then((val) {
          if (val == null) {
            // not tapped
            notifProv.flutterNotifications
                ?.cancel(MyNotifications.battleRequest);
          } else {
            startGame(ORqLobby(val));
          }
        });
      }

      setState(() {});
    } on HttpException {}
  }

  void showPopup(String text) {
    this.popup = Toast(text);
    Future.delayed(this.popup.duration, () => this.popup = null);
  }

  // void _requestGame(OnlineRequest req) {
  // }

  void changeGameState(game_state.GameState gameState) {
    print("Change state: ${this.gameState} to $gameState");
    if (_gameState != gameState) {
      this._gameState?.dispose();
      this._gameState = gameState ?? this._gameState;
      if (mounted) setState(() {});
    }
    // messageDelay = true;
    // Future.delayed(Duration(milliseconds: 10), () => this.messageDelay = false);
  }

  // Stream<ServerMessage>
  StreamSubscription _handleSMessages(Stream<dynamic> wsStream) {
    this.incoming = StreamController<ServerMessage>.broadcast();
    // return
    return wsStream.listen((msg) {
      if (msg is String) {
        print(">> \"$msg\"");
        var onlineMsg = OnlineMessageExt.parse(msg);
        if (onlineMsg == null) return;

        if (awaitingLogin != null) {
          if (onlineMsg is MsgOkay) {
            awaitingLogin();
            loggedIn = true;
            showPopup("Logged in as ${widget._userInfo.username}.");
          } else if (onlineMsg is MsgError) {
            if (onlineMsg.maybeErr == MsgErrorType.IncorrectCredentials) {
              widget._userInfo.logOut();
              showPopup("You have been logged out.");
            } else if (onlineMsg.maybeErr == MsgErrorType.AlreadyLoggedIn) {
              awaitingLogin();
              showPopup("Logged in as ${widget._userInfo.username}.");
              loggedIn = true;
            } else if (onlineMsg.maybeErr == MsgErrorType.AlreadyPlaying) {
              _initializeConnection();
              // if (widget._userInfo?.loggedIn) {

              // }
            }
          }
          awaitingLogin = null;
        }

        if (onlineMsg is MsgBattleReq) {
          showBattleRequest(onlineMsg.userId, onlineMsg.lobbyCode);
        } else if (onlineMsg is MsgLobbyClosing) {
          inLobby = false;
        } else if (onlineMsg is MsgCurrentServerInfo) {
          setState(() => currentServerInfo = onlineMsg.currentServerInfo);
        } else if (onlineMsg is MsgGameStart) {
          var lifecycle = LifecycleProvider.of(context);
          if (lifecycle.state != AppLifecycleState.resumed) {
            var notifProv = NotificationsProvider.of(context);
            notifProv.flutterNotifications?.cancel(MyNotifications.gameFound);
            notifProv.flutterNotifications?.show(
              MyNotifications.gameFound,
              'Game Starting!',
              'Come back quickly to play!',
              MyNotifications.gameFoundSpecifics,
            );
            Future.delayed(
              Duration(seconds: 45),
              () => notifProv.flutterNotifications
                  ?.cancel(MyNotifications.gameFound),
            );
            lifecycle.onReady = () {
              notifProv.flutterNotifications?.cancel(MyNotifications.gameFound);
            };
          }
        }
        //  else if (onlineMsg is MsgOkay ||
        //     onlineMsg is MsgLobbyResponse ||
        //     onlineMsg is MsgError) {}
        // this._awaitingConfirmation = false;
        this.timeoutTimer?.cancel();
        // setState(() {});

        // if (messageDelay) {
        //   Future.delayed(Duration(milliseconds: 10), () {
        //     incoming.sink.add(onlineMsg);
        //   });
        // } else {
        if (leaving && onlineMsg is MsgLobbyClosing) {
          leaving = false;
          return;
        } else {
          incoming.sink.add(onlineMsg);
        }
        // }
      } else {
        print(">> #OTR# \"$msg\"");
      }
      return;
    }, onError: (dynamic err) {
      print(">> #ERR# \"${err.toString()}\"");
      var inner = err.inner.inner;
      this.timeoutTimer?.cancel();

      if (inner is SocketException && inner.osError?.errorCode == 7) {
        changeGameState(game_state.Error(
            game_state.NoConnection(), outgoing, incoming, changeGameState));
      } else {
        changeGameState(game_state.Error(
            game_state.Internal(false), outgoing, incoming, changeGameState));
      }
      setState(() => this._connection = null);
    });
    // .asBroadcastStream();
  }

  StreamSubscription _handlePMessages(WebSocketSink wsSink) {
    this.outgoing = StreamController<PlayerMessage>.broadcast();
    return this.outgoing.stream.listen((pmsg) {
      if (!connected) {
        this._initializeConnection();
      }

      _awaitingConfirmation = true;
      this.timeoutTimer = Timer(Duration(seconds: 2), () {
        if (this._awaitingConfirmation) {
          //this.mounted &&
          if (!(this.gameState is game_state.Error)) {
            changeGameState(game_state.Error(game_state.Timeout(),
                this.outgoing, this.incoming, changeGameState));

            // setState(() {});
            // if (mounted) setState(() {});
            print("Confirmation timeout!");
          }
          setState(() => _connection = null);
        }
      });

      if (pmsg is PlayerMsgLeave) {
        // Hack to skip waiting for next CurrentServerInfo message which will hide "Player in queue"
        //  because that was this client and it just left the queue.
        setState(() => this.currentServerInfo?.playerWaitingInLobby = false);
        this.leaving = true;
        Future.delayed(Duration(seconds: 1), () {
          if (leaving) {
            leaving = false;
            // setState(() => _connection = null);
          }
        });
      }
      //  else if (pmsg is PlayerMsgBattleRequest) {
      //   inLobby = true;
      // }

      String msg = pmsg.serialize();
      print("<< \"$msg\"");
      wsSink.add(msg);
    });
    // return this.outgoing.sink;
  }

  // @override
  // void initState() {
  //   super.initState();
  // }

  // Widget buildGame(BuildContext context) {
  //   return Stack(
  //     children: <Widget>[
  //       AnimatedSwitcher(
  //           duration: Duration(milliseconds: 200), child: this.gameState),
  //       this.popup ?? SizedBox(),
  //     ],
  //   );
  // }

  void close() {
    print("disposed connection");
    _connection.sink.close();
    outgoing.close();
    incoming.close();
  }

  @override
  initState() {
    super.initState();
    if (widget._userInfo?.loggedIn == true && !this.loggedIn) {
      this.outgoing.add(
          PlayerMsgLogin(widget._userInfo.username, widget._userInfo.password));
      this.awaitingLogin = () {};
    }
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._userInfo?.loggedIn == true && !this.loggedIn) {
      print(
          "in update widget: ${widget._userInfo?.loggedIn == true} && ${!this.loggedIn}");
      this.outgoing.add(
          PlayerMsgLogin(widget._userInfo.username, widget._userInfo.password));
      this.awaitingLogin = () {};
      // this.awaitingLogin = () => _requestGame(req);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _InheritedServerConnProvider(
          data: this,
          child: widget.child,
        ),
        this.battleRequest ?? SizedBox(),
      ],
    );
  }

  @override
  void dispose() {
    // var state = this.state;
    // if (state is ConnStateConnected) {
    // state.
    close();
    // }
    super.dispose();
  }
}

class CurrentServerInfo {
  int currentlyConnectedPlayers;
  bool playerWaitingInLobby;

  CurrentServerInfo(this.currentlyConnectedPlayers, this.playerWaitingInLobby);
}

abstract class OnlineRequest {}

class ORqLobby extends OnlineRequest {
  final String lobbyCode;
  ORqLobby(this.lobbyCode);
}

class ORqWorldwide extends OnlineRequest {}

class ORqBattle extends OnlineRequest {
  final String id;
  ORqBattle(this.id);
}

class OnlineViewer extends StatelessWidget {
  OnlineViewer(this.serverConn);

  final ServerConnState serverConn;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        serverConn.leaveGame();
        UserinfoProvider.of(context).refresh();
        return Future.value(true);
      },
      child: Stack(
        children: <Widget>[
          AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: this.serverConn.gameState.build),
          this.serverConn.popup ?? SizedBox(),
        ],
      ),
    );
  }
}
