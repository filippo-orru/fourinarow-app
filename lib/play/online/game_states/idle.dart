import 'dart:async';

import 'package:flutter/material.dart';

import 'package:four_in_a_row/inherit/connection/messages.dart';
import 'all.dart';

class Idle extends GameState {
  StreamSubscription sMsgListen;
  StreamSubscription pMsgListen;

  Idle(StreamController<PlayerMessage> p, StreamController<ServerMessage> s,
      CGS change,
      {bool ready})
      : super(p, s, change) {
    // print("idle init");
    sMsgListen = sMsgCtrl.stream.listen(handleServerMessage);
    pMsgListen = pMsgCtrl.stream.listen(handlePlayerMessage);
  }

  dispose() {
    sMsgListen.cancel();
    pMsgListen.cancel();
  }

  void handleServerMessage(ServerMessage msg) {
    if (msg is MsgLobbyResponse) {
      changeState(InLobby(msg.code, pMsgCtrl, sMsgCtrl, changeState));
    }
  }

  void handlePlayerMessage(PlayerMessage msg) {
    // print("idle passed pleyrmsg $msg");

    if (msg is PlayerMsgLobbyJoin) {
      changeState(WaitingForLobbyInfo(pMsgCtrl, sMsgCtrl, changeState,
          lobbyCode: msg.code));
    } else if (msg is PlayerMsgLobbyRequest) {
      changeState(WaitingForLobbyInfo(pMsgCtrl, sMsgCtrl, changeState));
    } else if (msg is PlayerMsgWorldwideRequest) {
      changeState(WaitingForWWOkay(pMsgCtrl, sMsgCtrl, changeState));
    } else if (msg is PlayerMsgBattleRequest) {
      changeState(InLobby(null, pMsgCtrl, sMsgCtrl, changeState));
    }
  }

  get build => IdleWidget();
}

class IdleWidget extends StatefulWidget {
  createState() => IdleState();
}

class IdleState extends State<IdleWidget> {
  IdleState({this.ready = false});

  bool ready; // true if opponent is in lobby

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('idle'));
  }
}
