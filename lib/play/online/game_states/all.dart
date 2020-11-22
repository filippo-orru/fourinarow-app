import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:four_in_a_row/inherit/connection/messages.dart';

export 'error.dart';
export 'idle.dart';
export 'in_lobby.dart';
export 'other.dart';
export 'playing.dart';

import 'error.dart';

typedef CGS = void Function(GameState);

// class GameStateWrapper extends StatefulWidget {
abstract class GameState<T extends StatefulWidget> {
  final StreamController<PlayerMessage> pMsgCtrl;
  final StreamController<ServerMessage> sMsgCtrl;
  final CGS changeState;

  GameState(this.pMsgCtrl, this.sMsgCtrl, this.changeState);

  void handleServerMessageSuper(ServerMessage msg) {
    // print("Called handleServerMessageSuper ($msg)");
    if (msg is MsgError) {
      // String txt = "An error occurred" + (msg.maybeErr?.toString() ?? "");
      switch (msg.maybeErr) {
        case MsgErrorType.LobbyNotFound:
          changeState(Error(
              LobbyNotFound(), this.pMsgCtrl, this.sMsgCtrl, this.changeState));
          break;
        case MsgErrorType.AlreadyPlaying:
          changeState(Error(AlreadyPlaying(), this.pMsgCtrl, this.sMsgCtrl,
              this.changeState));
          break;
        default:
      }
      changeState(Error(
          Internal(false), this.pMsgCtrl, this.sMsgCtrl, this.changeState));
    } else if (msg is MsgLobbyClosing) {
      // Future.delayed(Duration(), () {
      // if (mounted) {
      changeState(
          Error(LobbyClosed(), this.pMsgCtrl, this.sMsgCtrl, this.changeState));
      //   }
      // });
    }
  }

  void dispose();

  T get build;
}
