import 'package:flutter/widgets.dart';

import '../messages.dart';

export 'error.dart';
export 'idle.dart';
export 'in_lobby.dart';
export 'other.dart';
export 'playing.dart';

import 'error.dart';

abstract class GameState extends StatefulWidget {
  final Sink<PlayerMessage> sink;
  GameState(this.sink);

  @mustCallSuper
  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgError) {
      String txt = "An error occurred" +
          (msg.maybeErr == null ? "" : msg.maybeErr.toString());
      switch (msg.maybeErr) {
        case MsgErrorType.LobbyNotFound:
          txt = "Could not find this lobby!";
          break;
        default:
      }
      return Error(Internal(txt), this.sink);
    }
    return null;
  }
}
