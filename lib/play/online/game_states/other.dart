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
    String title =
        widget.lobbyCode == null ? "Contacting Server..." : "Joining Lobby...";
    String label = "This may take some time";
    return LoadingScreen(title: title, label: label);
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
    String title = "Contacting Server...";
    return LoadingScreen(title: title);
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
    String title = "Searching for opponent...";
    String label = "This may take some time";
    return LoadingScreen(title: title, label: label);
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    Key key,
    @required this.title,
    this.label,
  }) : super(key: key);

  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                )
              : SizedBox(),
          SizedBox(height: 18),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}
