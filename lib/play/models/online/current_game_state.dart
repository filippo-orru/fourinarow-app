import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/inherit/lifecycle.dart';
import 'package:four_in_a_row/inherit/notifications.dart';

import 'game_login_state.dart';
import 'game_states/game_state.dart';

class GameStateManager with ChangeNotifier {
  final ServerConnection _serverConnection;

  late GameState _cgs; // currentGameState
  GameState get currentGameState => _cgs;

  late GameLoginState _gls;
  GameLoginState get gameLoginState => _gls;

  CurrentServerInfo? serverInfo;

  GameStateManager(this._serverConnection) {
    _cgs = IdleState(_sendPlayerMessage);
    _gls = GameLoginLoggedOut(_sendPlayerMessage);
    _listenToStreams();
  }

  Future<bool> startGame(OnlineRequest req) async {
    if (_cgs is InLobbyState) {
      throw UnimplementedError("Maybe this should never occur");
      _serverConnection.send(PlayerMsgLeave());
      await _serverConnection.playerMsgStream
          .firstWhere((msg) => msg is MsgOkay);
    }

    // TODO fix login
    /*if (this._gls is! GameLoginLoggedIn) {
      this.outgoing.add(
          PlayerMsgLogin(widget._userInfo.username, widget._userInfo.password));
    }*/

    this._serverConnection.send(req.playerMsg);

    return Future.value(true); // TODO return when game found / cancel
    // like this:
    // var msg = await serverConn.incoming.stream
    //     .skip(1) // skip confirmation msg
    //     .first
    //     .timeout(BattleRequestDialog.TIMEOUT, onTimeout: () => null);
  }

  void closingViewer() {
    Future.delayed(Duration(milliseconds: 350), () => leave());
  }

  void leave() {
    this._serverConnection.send(PlayerMsgLeave());
  }

  void Function(PlayerMessage) get _sendPlayerMessage =>
      this._serverConnection.send;

  void _comeToPlayNotification(
      NotificationsProviderState notifProv, LifecycleProviderState lifecycle) {
    // TODO
  }

  void _listenToStreams() {
    this._serverConnection.serverMsgStream.listen((msg) {
      this._handleServerMessage(msg);
      GameState? newGameState = _cgs.handleServerMessage(msg);
      this._cgs = newGameState ?? _cgs;

      GameLoginState? newLoginState = _gls.handleServerMessage(msg);
      this._gls = newLoginState ?? _gls;
      notifyListeners();
    });
    this._serverConnection.playerMsgStream.listen((msg) {
      this._handlePlayerMessage(msg);

      GameState? newGameState = _cgs.handlePlayerMessage(msg);
      this._cgs = newGameState ?? _cgs;
      notifyListeners();
    });
  }

  void _handleServerMessage(ServerMessage msg) {
    if (msg is MsgCurrentServerInfo) {
      this.serverInfo = msg.currentServerInfo;
    }
  }

  void _handlePlayerMessage(PlayerMessage msg) {
    // if (msg is PlayerMsgLeave) {
    //   _cgs = IdleState(_sendPlayerMessage);
    // }
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
