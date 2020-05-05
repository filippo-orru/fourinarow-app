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
      // String txt = "An error occurred" + (msg.maybeErr?.toString() ?? "");
      switch (msg.maybeErr) {
        case MsgErrorType.LobbyNotFound:
          return Error(LobbyNotFound(), this.sink);
        case MsgErrorType.AlreadyPlaying:
          return Error(AlreadyPlaying(), this.sink);
        default:
      }
      return Error(Internal(false), this.sink);
    } else if (msg is MsgLobbyClosing) {
      return Error(LobbyClosed(), this.sink);
    }
    return null;
  }

  GameState handlePlayerMessage(PlayerMessage msg);
}
