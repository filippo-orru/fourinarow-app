import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/play/widgets/online/playing.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:http/http.dart' as http;

import 'package:four_in_a_row/util/constants.dart' as constants;
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/util/toast.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/online/online_field.dart';
import 'game_state.dart';

class PlayingState extends GameState {
  PlayingState(
    void Function(PlayerMessage msg) sendPlayerMessage, {
    bool myTurnToStart,
    String opponentId,
  }) : super(sendPlayerMessage) {
    field = OnlineField();
    field.turn = myTurnToStart ? field.me : field.me.other;
    _loadOpponentInfo(opponentId: opponentId);
  }

  OnlineField field;
  bool awaitingConfirmation;
  bool leaving = false;
  ToastState toastState;
  Timer toastTimer;
  OpponentInfo opponentInfo = OpponentInfo();

  @override
  GameState handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgPlayAgain) {
      field.waitingToPlayAgain = true;
    } else if (msg is PlayerMsgPlaceChip) {
      awaitingConfirmation = true;
    } else if (msg is PlayerMsgLeave) {
      leaving = true;
    }
    return null;
  }

  @override
  GameState handleServerMessage(ServerMessage msg) {
    if (msg is MsgPlaceChip) {
      field.dropChipNamed(msg.row, field.me.other);
      notifyListeners();
    } else if (msg is MsgGameStart) {
      this._reset(msg.myTurn);
    } else if (msg.isConfirmation) {
      awaitingConfirmation = false;
      notifyListeners();
    } else if (msg is MsgOppLeft) {
      opponentInfo.hasLeft = true;
      notifyListeners();
      if (field.checkWin() == null) {
        this.leaving = true;
        showPopup("Opponent left", angery: true);
        //Future.delayed(this.toastState.duration * 0.6, () => this.pop());
        // TODO ^ pop viewer / show [ dialog: okay ]
      } else {
        showPopup("Opponent left");
      }
      // return Idle(widget.sink);
    } else if (msg is MsgLobbyClosing &&
        !this.leaving &&
        !this.opponentInfo.hasLeft) {
      // TODO: do I need this?

      // return ErrorState(
      //     LobbyClosed(), widget.pMsgCtrl, widget.sMsgCtrl, widget.changeState));
    } else if (msg is MsgError && msg.maybeErr == MsgErrorType.NotInLobby) {
      // TODO: do I need this? maybe just pop / dialog

      // widget.changeState(Error(
      //     LobbyClosed(), widget.pMsgCtrl, widget.sMsgCtrl, widget.changeState));
    }
    return null;
  }

  @override
  StatelessWidget Function(GameState) get viewer => (s) => PlayingViewer(s);

  void _loadOpponentInfo({String opponentId}) async {
    if (opponentId == null) {
      if (this.opponentInfo == null) {
        return;
      } else {
        opponentId = this.opponentInfo.user.id;
      }
    }

    http.Response response =
        await http.get("${constants.URL}/api/users/$opponentId");
    if (response.statusCode == 200) {
      this.opponentInfo =
          OpponentInfo(user: PublicUser.fromMap(jsonDecode(response.body)));
      // TODO vvv
      /*if (UserinfoProvider.of(context)
            .user
            .friends
            .any((friend) => friend.id == opponentInfo.id)) {
          opponentInfo.isFriend = true;
        }*/
    }
  }

  void _reset(bool myTurn) {
    field = OnlineField();
    field.turn = myTurn ? field.me : field.me.other;
  }

  void dropChip(int column) {
    if (field.turn == field.me) {
      field.dropChipNamed(column, field.me);

      super.sendPlayerMessage(PlayerMsgPlaceChip(column));
    }
  }

  void playAgain() {
    super.sendPlayerMessage(PlayerMsgPlayAgain());
  }

  void showPopup(String s, {bool angery}) {}
}

class OpponentInfo {
  final PublicUser user;
  bool hasLeft = false;

  OpponentInfo({this.user});
}
