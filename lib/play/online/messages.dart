abstract class ServerMessage {
  // OnlineMessage parse()
}

class MsgPlaceChip extends ServerMessage {
  final int row;
  MsgPlaceChip(this.row);
}

class MsgOppLeft extends ServerMessage {}

class MsgOppJoined extends ServerMessage {}

class MsgError extends ServerMessage {
  final MsgErrorType maybeErr;
  MsgError(this.maybeErr);
}

enum MsgErrorType {
  GameNotStarted,
  NotYourTurn,
  GameAlreadyOver,
  AlreadyPlaying,
  LobbyNotFound,
  InvalidColumn
}

extension MsgErrorTypeExt on MsgErrorType {
  static parse(String str) {
    if (str == "GameNotStarted")
      return MsgErrorType.GameNotStarted;
    else if (str == "NotYourTurn")
      return MsgErrorType.NotYourTurn;
    else if (str == "GameAlreadyOver")
      return MsgErrorType.GameAlreadyOver;
    else if (str == "AlreadyPlaying")
      return MsgErrorType.AlreadyPlaying;
    else if (str == "LobbyNotFound")
      return MsgErrorType.LobbyNotFound;
    else if (str == "InvalidColumn")
      return MsgErrorType.InvalidColumn;
    else
      return null;
  }
}

class MsgOkay extends ServerMessage {}

class MsgLobbyResponse extends ServerMessage {
  final String code;
  MsgLobbyResponse(this.code);
}

class MsgGameStart extends ServerMessage {
  final bool myTurn;
  MsgGameStart(this.myTurn);
}

class MsgLobbyClosing extends ServerMessage {}

extension OnlineMessageExt on ServerMessage {
  static ServerMessage parse(String str) {
    if (str == "OKAY") {
      return MsgOkay();
    } else if (str.startsWith("LOBBY_ID:")) {
      if (str.length == 9 + 4) {
        return MsgLobbyResponse(str.substring(9, 9 + 4));
      }
    } else if (str.startsWith("OPP_JOINED")) {
      return MsgOppJoined();
    } else if (str.startsWith("OPP_LEAVING")) {
      return MsgOppLeft();
    } else if (str.startsWith("ERROR:")) {
      String errStr = str.substring(6);
      MsgErrorType errType = MsgErrorTypeExt.parse(errStr);

      return MsgError(errType);
    } else if (str.startsWith("PC:")) {
      int row = int.tryParse(str.substring(3, 4));
      if (row != null) {
        // if (state == GameState.Playing) {
        // field
        return MsgPlaceChip(row);
        // }
      }
    } else if (str.startsWith("GAME_START:")) {
      if (str.length == 11 + 3) {
        bool myTurn = str.substring(11, 11 + 3) == "YOU";
        return MsgGameStart(myTurn);
      }
    } else if (str == "LOBBY_CLOSING") {
      return MsgLobbyClosing();
    }

    return null;
  }
}

abstract class PlayerMessage {
  String serialize();
}

class PlayerMsgPlaceChip extends PlayerMessage {
  final int row;
  PlayerMsgPlaceChip(this.row);

  String serialize() {
    return "PC:$row";
  }
}

class PlayerMsgLeave extends PlayerMessage {
  String serialize() {
    return "LEAVE";
  }
}

class PlayerMsgLobbyRequest extends PlayerMessage {
  String serialize() {
    return "REQ_LOBBY";
  }
}

class PlayerMsgWorldwideRequest extends PlayerMessage {
  String serialize() {
    return "REQ_WW";
  }
}

class PlayerMsgLobbyJoin extends PlayerMessage {
  final String code;
  PlayerMsgLobbyJoin(this.code);

  String serialize() {
    return "JOIN_LOBBY:$code";
  }
}

class PlayerMsgPlayAgain extends PlayerMessage {
  String serialize() {
    return "PLAY_AGAIN";
  }
}
