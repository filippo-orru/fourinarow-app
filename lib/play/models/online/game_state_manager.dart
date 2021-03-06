import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/inherit/lifecycle.dart';
import 'package:four_in_a_row/inherit/notifications.dart';
import 'package:four_in_a_row/inherit/user.dart';

import 'game_login_state.dart';
import 'game_states/game_state.dart';

class GameStateManager with ChangeNotifier {
  final ServerConnection _serverConnection;
  LifecycleProviderState? _lifecycle;
  LifecycleProviderState? get lifecycle => _lifecycle;
  set lifecycle(l) {
    _lifecycle = l;
    lifecycle!.addListener(() {
      if (lifecycle!.state == AppLifecycleState.detached) {
        leave();
      }
      if (!connected && lifecycle!.state == AppLifecycleState.resumed) {
        print("   #FORCE CNNCT# (app resumed)");
        _serverConnection.retryConnection();
      }
    });
  }

  NotificationsProviderState? notifications;

  UserInfo? userInfo;

  GameState? _cgs; // currentGameState
  GameState get currentGameState => _cgs!;
  set cgs(newCgs) {
    _cgs?.removeListener(_listenToGamestate);
    newCgs.addListener(_listenToGamestate);
    _cgs = newCgs;
  }

  void _listenToGamestate() {
    notifyListeners();
  }

  late GameLoginState _gls;
  GameLoginState get gameLoginState => _gls;

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

  GameStateManager(this._serverConnection) {
    _serverConnection.addListener(() {
      notifyListeners();
    });
    cgs = IdleState(this);
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

  Future<bool> startGame(OnlineRequest req) async {
    if (currentGameState is! IdleState) {
      // throw UnimplementedError("Maybe this should never occur");
      _serverConnection.send(PlayerMsgLeave());
      _serverConnection.waitForOkay(duration: Duration(milliseconds: 400));
    }

    var userInfo = this.userInfo;
    notifyListeners();
    if (userInfo != null &&
        userInfo.username != null &&
        userInfo.password != null) {
      if (this._gls is! GameLoginLoggedIn) {
        this.sendPlayerMessage(
            PlayerMsgLogin(userInfo.username!, userInfo.password!));
      }
    }

    this._serverConnection.send(req.playerMsg);
    if (req is! ORqWorldwide) {
      showViewer = true;
    }
    return this
        ._serverConnection
        .waitForOkay(duration: Duration(milliseconds: 400));
  }

  void leave() {
    this._serverConnection.send(PlayerMsgLeave());
  }

  void Function(PlayerMessage) get sendPlayerMessage =>
      this._serverConnection.send;

  void _listenToStreams() {
    this._serverConnection.serverMsgStream.listen((msg) {
      this._handleServerMessage(msg);
      GameState? newGameState = currentGameState.handleServerMessage(msg);
      this.cgs = newGameState ?? currentGameState;

      GameLoginState? newLoginState = _gls.handleServerMessage(msg);
      this._gls = newLoginState ?? _gls;
      notifyListeners();
    });
    this._serverConnection.playerMsgStream.listen((msg) {
      this._handlePlayerMessage(msg);

      GameState? newGameState = currentGameState.handlePlayerMessage(msg);
      this.cgs = newGameState ?? currentGameState;
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
    }
  }

  void _handlePlayerMessage(PlayerMessage msg) {
    // if (msg is PlayerMsgLeave) {
    //   _cgs = IdleState(_sendPlayerMessage);
    // }
  }

  @override
  String toString() {
    return "GameStateManger(cgs=$currentGameState, gls=$gameLoginState, connected=$connected)";
  }
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
