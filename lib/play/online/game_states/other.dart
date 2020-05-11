import 'dart:async';

import 'package:flutter/material.dart';

import 'package:four_in_a_row/inherit/connection/messages.dart';
import 'all.dart';

class WaitingForLobbyInfo extends GameState {
  StreamSubscription sMsgListen;
  // final _WaitingForLobbyInfoState state;
  final String lobbyCode;

  WaitingForLobbyInfo(StreamController<PlayerMessage> p,
      StreamController<ServerMessage> s, CGS change,
      {this.lobbyCode})
      : super(p, s, change) {
    sMsgListen = sMsgCtrl.stream.listen(handleMessage);
  }

  void handleMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      changeState(InLobby(msg.code, pMsgCtrl, sMsgCtrl, changeState));
    } else if (msg is MsgOkay && lobbyCode != null) {
      changeState(InLobbyReady(pMsgCtrl, sMsgCtrl, changeState));
    } else {
      handleServerMessageSuper(msg);
    }
  }

  get build => WaitingForLobbyInfoWidget(this.lobbyCode);

  dispose() {
    sMsgListen.cancel();
  }
}

class WaitingForLobbyInfoWidget extends StatefulWidget {
  final String lobbyCode;

  WaitingForLobbyInfoWidget(this.lobbyCode);

  createState() => _WaitingForLobbyInfoState();
}

class _WaitingForLobbyInfoState extends State<WaitingForLobbyInfoWidget> {
  @override
  Widget build(BuildContext context) {
    String title =
        widget.lobbyCode == null ? "Contacting Server..." : "Joining Lobby...";
    String label = "This may take some time";
    return LoadingScreen(title: title, label: label);
  }
}

class WaitingForWWOkay extends GameState {
  StreamSubscription sMsgListen;

  WaitingForWWOkay(StreamController<PlayerMessage> p,
      StreamController<ServerMessage> s, CGS change)
      : super(p, s, change) {
    sMsgListen = sMsgCtrl.stream.listen(handleMessage);
  }

  void handleMessage(ServerMessage msg) {
    if (msg is MsgOkay) {
      changeState(
          WaitingForWWOpponent(super.pMsgCtrl, super.sMsgCtrl, changeState));
    } else {
      super.handleServerMessageSuper(msg);
    }
  }

  get build => WaitingForWWOkayWidget();

  dispose() {
    sMsgListen.cancel();
  }
}

class WaitingForWWOkayWidget extends StatefulWidget {
  createState() => _WaitingForWWOkayState();
}

class _WaitingForWWOkayState extends State<WaitingForWWOkayWidget> {
  @override
  Widget build(BuildContext context) {
    String title = "Contacting Server...";
    return LoadingScreen(title: title);
  }
}

class WaitingForWWOpponent extends GameState {
  StreamSubscription sMsgListen;

  WaitingForWWOpponent(StreamController<PlayerMessage> p,
      StreamController<ServerMessage> s, CGS change)
      : super(p, s, change) {
    sMsgListen = sMsgCtrl.stream.listen(handleMessage);
  }

  void handleMessage(ServerMessage msg) {
    if (msg is MsgOppJoined) {
      changeState(
          InLobbyReady(super.pMsgCtrl, super.sMsgCtrl, super.changeState));
    } else {
      super.handleServerMessageSuper(msg);
    }
  }

  get build => WaitingForWWOpponentWidget();

  dispose() {
    sMsgListen.cancel();
  }
}

class WaitingForWWOpponentWidget extends StatefulWidget {
  createState() => _WaitingForWWOpponentState();
}

class _WaitingForWWOpponentState extends State<WaitingForWWOpponentWidget> {
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
