import 'dart:convert';

import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/util/constants.dart';

abstract class ReliablePacketIn {
  static ReliablePacketIn? parse(String str) {
    var parts = str.split("::");
    if (parts.length > 1) {
      if (parts[0] == "ACK" && parts.length == 2) {
        var id = int.tryParse(parts[1]);
        if (id == null) return null;
        return ReliablePktAckIn(id);
      } else if (parts[0] == "MSG" && parts.length == 3) {
        var id = int.tryParse(parts[1]);
        var msg = ServerMessage.parse(parts[2]);
        if (id == null || msg == null) return null;
        return ReliablePktMsgIn(id, msg);
      } else if (parts[0] == "HELLO") {
        if (parts.length == 2 && parts[1] == "OUTDATED") {
          return ReliablePktHelloInOutDated();
        } else if (parts.length == 3) {
          var id = parts[2];
          if (parts[1] == "NEW") {
            return ReliablePktHelloIn(FoundState.New, id);
          } else if (parts[1] == "FOUND") {
            return ReliablePktHelloIn(FoundState.Found, id);
          }
        }
      } else if (parts[0] == "ERR") {
        return ReliablePktErrIn();
      } else if (parts[0] == "NOT_CONNECTED") {
        return ReliablePktNotConnectedIn();
      }
    }

    return null;
  }
}

class ReliablePktAckIn extends ReliablePacketIn {
  final int id;
  ReliablePktAckIn(this.id);
}

class ReliablePktMsgIn extends ReliablePacketIn {
  final int id;
  final ServerMessage msg;

  ReliablePktMsgIn(this.id, this.msg);
}

class ReliablePktNotConnectedIn extends ReliablePacketIn {}

class ReliablePktHelloIn extends ReliablePacketIn {
  final FoundState foundState;
  final String sessionIdentifier;

  ReliablePktHelloIn(this.foundState, this.sessionIdentifier);
}

enum FoundState { New, Found }

class ReliablePktHelloInOutDated extends ReliablePacketIn {}

class ReliablePktErrIn extends ReliablePacketIn {}

abstract class ReliablePacketOut implements Serializable {}

abstract class Serializable {
  String serialize();
}

class ReliablePktAckOut extends ReliablePacketOut {
  final int id;
  ReliablePktAckOut(this.id);

  @override
  String serialize() {
    return "ACK::$id";
  }
}

class ReliablePktMsgOut extends ReliablePacketOut {
  final int id;
  final PlayerMessage msg;
  ReliablePktMsgOut(this.id, this.msg);

  @override
  String serialize() {
    return "MSG::$id::${msg.serialize()}";
  }
}

class ReliablePktHelloOut extends ReliablePacketOut {
  final int protocolVersion = PROTOCOL_VERSION;
  final String? sessionIdentifier;

  ReliablePktHelloOut([this.sessionIdentifier]);

  @override
  String serialize() {
    String postFix = "";
    if (sessionIdentifier != null) {
      postFix = "REQ:$sessionIdentifier";
    } else {
      postFix = "NEW";
    }
    return "HELLO::$protocolVersion::$postFix";
  }
}

class QueuedMessage<T> {
  final DateTime sent;
  final int id;
  final T msg;

  QueuedMessage(this.id, this.msg) : this.sent = DateTime.now();
}

abstract class ServerMessage {
  static ServerMessage? parse(String str) {
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
      int? row = int.tryParse(str.substring(3, 4));
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
    } else if (str.startsWith("GAME_OVER")) {
      List<String> parts = str.split(":");
      if (parts.length == 2) {
        bool iWon = parts[1] == "YOU";
        return MsgGameOver(iWon);
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
    } else if (str.startsWith("CURRENT_SERVER_STATE")) {
      List<String> parts = str.split(":");
      if (parts.length == 3) {
        int? currentPlayers = int.tryParse(parts[1]);
        if (currentPlayers == null) return null;
        return MsgCurrentServerInfo(
          CurrentServerInfo(currentPlayers, parts[2] == "true"),
        );
      }
    } else if (str.startsWith("CHAT_MSG")) {
      List<String> parts = str.split(":");
      if (parts.length == 4) {
        bool isGlobal = parts[1] == "true";
        String msg = utf8.decode(base64.decode(parts[2]));
        String? sender = parts[3].isEmpty ? null : parts[3];
        return MsgChatMessage(isGlobal, msg, sender);
      }
    } else if (str.startsWith("CHAT_READ")) {
      List<String> parts = str.split(":");
      if (parts.length == 2) {
        bool isGlobal = parts[1] == "true";
        return MsgChatRead(isGlobal);
      }
    }

    return null;
  }

  bool get isConfirmation {
    return this is MsgOkay || this is MsgLobbyResponse || this is MsgError;
  }
}

// Synthetic message generated by serverconnection
//  when the connection is reconnected but the state could not be found
class MsgReset extends ServerMessage {}

// Sent when the app or protocol version is out of date
class MsgOutOfDate extends ServerMessage {}

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
  NotInLobby,
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
    else if (str == "NotInLobby")
      return MsgErrorType.NotInLobby;
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
  final String? opponentId;

  MsgGameStart(this.myTurn, [this.opponentId]);
}

class MsgGameOver extends ServerMessage {
  final bool iWon;

  MsgGameOver(this.iWon);
}

class MsgLobbyClosing extends ServerMessage {}

class MsgCurrentServerInfo extends ServerMessage {
  final CurrentServerInfo currentServerInfo;

  MsgCurrentServerInfo(this.currentServerInfo);
}

class MsgChatMessage extends ServerMessage {
  final bool isGlobal;
  final String content;
  final String? senderName;

  MsgChatMessage(this.isGlobal, this.content, [this.senderName]);
}

class MsgChatRead extends ServerMessage {
  final bool isGlobal;

  MsgChatRead(this.isGlobal);
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

class PlayerMsgChatMessage extends PlayerMessage {
  final String message;

  PlayerMsgChatMessage(this.message);

  @override
  String serialize() {
    return "CHAT_MSG:" + base64.encode(utf8.encode(message));
  }
}

class PlayerMsgChatRead extends PlayerMessage {
  @override
  String serialize() {
    return "CHAT_READ";
  }
}
