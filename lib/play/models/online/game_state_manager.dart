import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/inherit/lifecycle.dart';
import 'package:four_in_a_row/inherit/notifications.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/util/battle_req_popup.dart';

import 'game_login_state.dart';
import 'game_states/game_state.dart';

class GameStateManager with ChangeNotifier {
  final ServerConnection _serverConnection;
  LifecycleProviderState? _lifecycle;
  LifecycleProviderState? get lifecycle => _lifecycle;
  set lifecycle(l) {
    lifecycle?.removeListener(_lifecycleListener);
    _lifecycle = l;
    lifecycle?.addListener(_lifecycleListener);
  }

  void _lifecycleListener() {
    if (lifecycle!.state == AppLifecycleState.detached) {
      leave();
    }
    if (!connected && lifecycle!.state == AppLifecycleState.resumed) {
      print("   #FORCE CNNCT# (app resumed)");
      _serverConnection.retryConnection();
    }
  }

  NotificationsProviderState? notifications;

  UserInfo? _userInfo;
  UserInfo get userInfo => _userInfo!;
  bool get userInfoNotSet => _userInfo == null;
  set userInfo(UserInfo u) {
    _userInfo?.removeListener(_userInfoListener);
    _userInfo = u;

    userInfo.addListener(_userInfoListener);
  }

  void _userInfoListener() {
    // print(
    //     "userinfolistener! (loggedin = ${userInfo.loggedIn}, cls = $currentLoginState)");
    if (userInfo.loggedIn == true &&
        this.currentLoginState is GameLoginLoggedOut) {
      // When logging in
      _sendLoginMsg();
    } else if (userInfo.loggedIn == false &&
        this.currentLoginState is! GameLoginLoggedOut) {
      // Need to log out
      _sendLogoutMsg();
    }
  }

  GameState? _cgs; // currentGameState
  GameState get currentGameState => _cgs!;
  set currentGameState(GameState newCgs) {
    _cgs?.removeListener(notifyListeners);
    newCgs.addListener(notifyListeners);

    if (_cgs != null) _didGameStateChange(_cgs!, newCgs);

    _cgs = newCgs;
  }

  GameLoginState? _gls;
  GameLoginState get currentLoginState => _gls!;
  set currentLoginState(GameLoginState newGls) {
    _gls?.removeListener(notifyListeners);
    newGls.addListener(notifyListeners);
    _gls = newGls;
  }

  CurrentServerInfo? _serverInfo;
  CurrentServerInfo? get serverInfo => _serverInfo;
  set serverInfo(CurrentServerInfo? s) {
    _serverInfo = s;
    _serverInfo!.currentlyConnectedPlayers--;
    if (s?.playerWaitingInLobby == true &&
        currentGameState is WaitingForWWOpponentState) {
      _serverInfo!.playerWaitingInLobby = false;
    }
  }

  BattleRequestState? incomingBattleRequest;
  Timer? incomingBattleRequestTimer;

  GameStateManager(this._serverConnection) {
    _serverConnection.addListener(() {
      notifyListeners();
    });
    currentGameState = IdleState(this);
    _gls = GameLoginLoggedOut(this);
    _listenToStreams();
  }

  bool get connected => _serverConnection.connected;

  bool get outdated => _serverConnection.outdated;

  bool _showViewer = false;
  bool get showViewer => _showViewer;
  set showViewer(s) {
    _showViewer = s;
    if (s) notifyListeners();
  }

  bool _hideViewer = false;
  bool get hideViewer => _hideViewer;
  set hideViewer(s) {
    if (s) {
      if (isViewing) {
        _hideViewer = s;
      }
    } else {
      _hideViewer = s;
    }
    notifyListeners();
  }

  bool isViewing = false;
  void showingViewer() {
    isViewing = true;
    _showViewer = false;
    _hideViewer = false;
  }

  void closingViewer() {
    isViewing = false;
    _showViewer = false;
    _hideViewer = false;
    Future.delayed(Duration(milliseconds: 350), () => leave());
  }

  void cancelIncomingBattleReq() {
    incomingBattleRequestTimer?.cancel();
    incomingBattleRequest = null;
    notifyListeners();
  }

  Future<void> startGame(OnlineRequest req) async {
    if (currentGameState is! IdleState) {
      // throw UnimplementedError("Maybe this should never occur");
      _serverConnection.send(PlayerMsgLeave());
    }

    notifyListeners();
    if (userInfo.sessionToken != null && this._gls is GameLoginLoggedOut) {
      // When starting game
      _sendLoginMsg();
    }

    this._serverConnection.send(req.playerMsg);
    if (req is! ORqWorldwide && req is! ORqBattle) {
      showViewer = true;
    }
  }

  void leave() {
    this._serverConnection.send(PlayerMsgLeave());
  }

  void Function(PlayerMessage) get sendPlayerMessage =>
      this._serverConnection.send;

  void _didGameStateChange(GameState oldState, GameState newState) {
    if (oldState is! WaitingForWWOpponentState &&
        newState is WaitingForWWOpponentState) {
      notifications?.searchingGame();
    } else if (oldState is WaitingForWWOpponentState &&
        newState is! WaitingForWWOpponentState) {
      notifications?.cancelSearchingGame();
    }
  }

  void _listenToStreams() {
    this._serverConnection.serverMsgStream.listen((msg) {
      this._handleServerMessage(msg);
      GameState? newGameState = currentGameState.handleServerMessage(msg);
      this.currentGameState = newGameState ?? currentGameState;

      GameLoginState? newLoginState =
          currentLoginState.handleServerMessage(msg);
      this.currentLoginState = newLoginState ?? currentLoginState;
      notifyListeners();
    });
    this._serverConnection.playerMsgStream.listen((msg) {
      this._handlePlayerMessage(msg);

      GameState? newGameState = currentGameState.handlePlayerMessage(msg);
      this.currentGameState = newGameState ?? currentGameState;

      GameLoginState? newLoginState =
          currentLoginState.handlePlayerMessage(msg);
      this.currentLoginState = newLoginState ?? currentLoginState;
      notifyListeners();
    });
  }

  void _handleServerMessage(ServerMessage msg) {
    if (msg is MsgCurrentServerInfo) {
      this.serverInfo = msg.currentServerInfo;
    } else if (msg is MsgOppJoined) {
      if (currentGameState is WaitingForWWOpponentState) {
        showViewer = true;
      }
      notifyListeners();
      if (lifecycle!.state != AppLifecycleState.resumed) {
        notifications!.comeToPlay();
      }
    } else if (msg is MsgReset) {
      hideViewer = true;
    } else if (msg is MsgGameOver) {
      userInfo.refresh();
    } else if (msg is MsgBattleReq) {
      userInfo.getUserInfo(userId: msg.userId).then((loadedUserInfo) {
        if (loadedUserInfo == null) return;
        incomingBattleRequestTimer?.cancel();
        incomingBattleRequest =
            BattleRequestState(loadedUserInfo, msg.lobbyCode);
        incomingBattleRequestTimer =
            Timer(BattleRequestPopup.DURATION, cancelIncomingBattleReq);
        notifyListeners();

        if (lifecycle!.state != AppLifecycleState.resumed) {
          notifications!.battleRequest(loadedUserInfo.username);
        }
      });
    } else if (msg is MsgHello) {
      if (userInfo.loggedIn == true) {
        // On startup / first connection
        _sendLoginMsg();
      }
    }
    // TODO: cancel outgoing battlerequest if err
    //else if (msg is MsgError && msg.maybeErr == MsgErrorType.UserNotPlaying)
  }

  void _handlePlayerMessage(PlayerMessage msg) {}

  void _sendLoginMsg() {
    this.sendPlayerMessage(PlayerMsgLogin(userInfo.sessionToken!));
  }

  void _sendLogoutMsg() {
    this.sendPlayerMessage(PlayerMsgLogout());
  }

  @override
  String toString() {
    return "GameStateManger(cgs=$currentGameState, gls=$currentLoginState, connected=$connected)";
  }
}

class BattleRequestState {
  final PublicUser user;
  final String lobbyId;

  BattleRequestState(this.user, this.lobbyId);
}

abstract class OnlineRequest {
  PlayerMessage get playerMsg;
}

class ORqLobbyRequest extends OnlineRequest {
  PlayerMessage get playerMsg => PlayerMsgLobbyRequest();
}

class ORqLobbyJoin extends OnlineRequest {
  final String lobbyCode;
  ORqLobbyJoin(this.lobbyCode);

  PlayerMessage get playerMsg => PlayerMsgLobbyJoin(lobbyCode);
}

class ORqWorldwide extends OnlineRequest {
  PlayerMessage get playerMsg => PlayerMsgWorldwideRequest();
}

class ORqBattle extends OnlineRequest {
  final String id;
  ORqBattle(this.id);

  PlayerMessage get playerMsg => PlayerMsgBattleRequest(id);
}

class CurrentServerInfo {
  int currentlyConnectedPlayers;
  bool playerWaitingInLobby;

  CurrentServerInfo(this.currentlyConnectedPlayers, this.playerWaitingInLobby);
}
