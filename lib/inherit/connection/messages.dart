abstract class ServerMessage {
  // OnlineMessage parse()
}

class MsgPlaceChip extends ServerMessage {
  final int row;
  MsgPlaceChip(this.row);
}

class MsgOppLeft extends ServerMessage {}

class MsgOppJoined extends ServerMessage {}

class MsgPong extends ServerMessage {}

class MsgBattleReq extends ServerMessage {
  final String userId;
  final String lobbyCode;
  MsgBattleReq(this.userId, this.lobbyCode);
}

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
  InvalidColumn,
  IncorrectCredentials,
  AlreadyLoggedIn
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
    else if (str == "IncorrectCredentials")
      return MsgErrorType.IncorrectCredentials;
    else if (str == "AlreadyLoggedIn")
      return MsgErrorType.AlreadyLoggedIn;
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
  final String opponentId;

  MsgGameStart(this.myTurn, [this.opponentId]);
}

class MsgLobbyClosing extends ServerMessage {}

extension OnlineMessageExt on ServerMessage {
  static ServerMessage parse(String str) {
    // str = str.toUpperCase();
    if (str == "OKAY") {
      return MsgOkay();
    } else if (str.startsWith("LOBBY_ID")) {
      var parts = str.split(':');
      if (parts.length == 2) {
        return MsgLobbyResponse(parts[1]);
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
    } else if (str.startsWith("GAME_START")) {
      List<String> parts = str.split(":");
      if (parts.length == 2) {
        bool myTurn = parts[1] == "YOU";
        return MsgGameStart(myTurn);
      } else if (parts.length == 3) {
        bool myTurn = parts[1] == "YOU";
        String opponentId = parts[2];
        return MsgGameStart(myTurn, opponentId);
      }
    } else if (str == "LOBBY_CLOSING") {
      return MsgLobbyClosing();
    } else if (str == "PONG") {
      return MsgPong();
    } else if (str.startsWith("BATTLE_REQ")) {
      List<String> parts = str.split(":");
      if (parts.length == 3) {
        return MsgBattleReq(parts[1], parts[2]);
      }
    }

    return null;
  }

  bool get isConfirmation {
    return this is MsgOkay || this is MsgLobbyResponse || this is MsgError;
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

class PlayerMsgPing extends PlayerMessage {
  String serialize() {
    return "PING";
  }
}

class PlayerMsgBattleRequest extends PlayerMessage {
  final String id;
  PlayerMsgBattleRequest(this.id);

  String serialize() {
    return "BATTLE_REQ:" + id;
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

class PlayerMsgLogin extends PlayerMessage {
  PlayerMsgLogin(this.username, this.password);

  final String username;
  final String password;

  String serialize() {
    return "LOGIN:$username:$password";
  }
}
