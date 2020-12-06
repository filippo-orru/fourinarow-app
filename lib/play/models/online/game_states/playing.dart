import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/widgets/online/playing.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:http/http.dart' as http;

import 'package:four_in_a_row/util/constants.dart' as constants;
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/util/toast.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'game_state.dart';

class PlayingState extends GameState {
  PlayingState(
    void Function(PlayerMessage msg) sendPlayerMessage, {
    required bool myTurnToStart,
    String? opponentId,
  }) : super(sendPlayerMessage) {
    FieldPlaying _field = FieldPlaying();
    _field.turn = myTurnToStart ? me : me.other;
    this.field = _field;
    _loadOpponentInfo(opponentId: opponentId);
  }

  final Player me = Player.One;
  late Field field;

  bool leaving = false;

  bool awaitingConfirmation = false;

  ToastState? toastState;
  Timer? toastTimer;
  OpponentInfo opponentInfo = OpponentInfo();

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgPlayAgain) {
      if (field is FieldFinished) {
        (field as FieldFinished).waitingToPlayAgain = true;
      }
    } else if (msg is PlayerMsgPlaceChip) {
      awaitingConfirmation = true;
    } else if (msg is PlayerMsgLeave) {
      leaving = true;
    }
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    if (msg is MsgPlaceChip) {
      var _field = field;
      if (_field is FieldPlaying) {
        dropChipNamed(msg.row, me.other);
        notifyListeners();
      }
    } else if (msg is MsgGameStart) {
      this._reset(msg.myTurn);
    } else if (msg.isConfirmation) {
      awaitingConfirmation = false;
      notifyListeners();
    } else if (msg is MsgOppLeft) {
      opponentInfo.hasLeft = true;
      notifyListeners();
      if (field is FieldPlaying) {
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

  // @override
  // StatelessWidget Function(GameState) get viewer => (s) => PlayingViewer(s);

  void _loadOpponentInfo({String? opponentId}) async {
    if (opponentId == null) {
      if (this.opponentInfo.user != null) {
        opponentId = this.opponentInfo.user!.id;
      } else {
        return;
      }
    }

    http.Response response =
        await http.get("${constants.URL}/api/users/$opponentId");
    if (response.statusCode == 200) {
      this.opponentInfo.user = PublicUser.fromMap(jsonDecode(response.body));
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
    FieldPlaying _field = FieldPlaying();
    _field.turn = myTurn ? me : me.other;
  }

  void dropChip(int column) {
    var _field = field;
    if (_field is FieldPlaying && _field.turn == me) {
      dropChipNamed(column, me);

      super.sendPlayerMessage(PlayerMsgPlaceChip(column));
    }
  }

  void dropChipNamed(int column, Player p) {
    Field _field = field;
    if (_field is FieldPlaying) {
      _field.dropChipNamed(column, p);
      WinDetails? winDetails = _field.checkWin();
      if (winDetails != null) {
        field = FieldFinished(winDetails);
        notifyListeners();
        if (winDetails.winner == this.me) {
          Vibrations.win();
        } else if (winDetails.winner == this.me.other) {
          Vibrations.loose();
        }
      }
    }
  }

  void playAgain() {
    super.sendPlayerMessage(PlayerMsgPlayAgain());
  }

  void showPopup(String s, {bool angery = false}) {
    toastState = ToastState("Opponent left", angery: angery, onComplete: () {
      // TODO: how do i change state here?
      // possible solution: pass class with sendPlayerMsg() and changeState() to
      // GameState and call thaht here
    });
    notifyListeners();
  }
}

class OpponentInfo {
  PublicUser? user;
  bool hasLeft = false;

  OpponentInfo({this.user});
}
