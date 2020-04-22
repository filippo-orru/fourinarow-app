import 'package:flutter/material.dart';

import '../messages.dart';
import 'all.dart';

class WaitingForLobbyInfo extends GameState {
  // final _WaitingForLobbyInfoState state;
  final String lobbyCode;

  WaitingForLobbyInfo(Sink<PlayerMessage> sink, {this.lobbyCode}) : super(sink);

  @override
  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      return InLobby(msg.code, this.sink);
    } else if (msg is MsgOkay && this.lobbyCode != null) {
      return InLobbyReady(this.sink);
    }
    return super.handleMessage(msg);
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return null;
  }

  createState() => _WaitingForLobbyInfoState();
}

class _WaitingForLobbyInfoState extends State<WaitingForLobbyInfo> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
          widget.lobbyCode == null ? "waiting for server" : "joining lobby"),
    );
  }
}

class WaitingForWWOkay extends GameState {
  WaitingForWWOkay(Sink<PlayerMessage> sink) : super(sink);

  @override
  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgOkay) {
      return WaitingForWWOpponent(this.sink);
    }
    return super.handleMessage(msg);
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return null;
  }

  createState() => _WaitingForWWOkayState();
}

class _WaitingForWWOkayState extends State<WaitingForWWOkay> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("waiting..."),
    );
  }
}

class WaitingForWWOpponent extends GameState {
  WaitingForWWOpponent(Sink<PlayerMessage> sink) : super(sink);

  @override
  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgOppJoined) {
      return InLobbyReady(this.sink);
    }
    return super.handleMessage(msg);
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return null;
  }

  createState() => _WaitingForWWOpponentState();
}

class _WaitingForWWOpponentState extends State<WaitingForWWOpponent> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("waiting for opponent..."),
    );
  }
}
