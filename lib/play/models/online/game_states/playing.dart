import 'dart:async';
import 'dart:convert';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:http/http.dart' as http;

import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/util/constants.dart' as constants;
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/util/toast.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';

class PlayingState extends GameState {
  PlayingState(
    GameStateManager gsm, {
    required bool myTurnToStart,
    String? opponentId,
  }) : super(gsm) {
    FieldPlaying _field = FieldPlaying();
    _field.turn = myTurnToStart ? me : me.other;
    this.field = _field;
    _loadOpponentInfo(opponentId: opponentId);
  }

  final Player me = Player.One;
  late Field field;

  bool leaving = false;

  bool connectionLost = false;

  ToastState? toastState;
  Timer? toastTimer;
  OpponentInfo opponentInfo = OpponentInfo();

  bool showRatingDialog = false;

  @override
  GameState? handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgPlayAgain) {
      if (field is FieldFinished) {
        (field as FieldFinished).waitingToPlayAgain = true;
      }
    } else if (msg is PlayerMsgLeave) {
      leaving = true;
    }
    return super.handlePlayerMessage(msg);
  }

  @override
  GameState? handleServerMessage(ServerMessage msg) {
    bool callSuper = true;
    if (msg is MsgPlaceChip) {
      var _field = field;
      if (_field is FieldPlaying) {
        dropChipNamed(msg.row, me.other);
        notifyListeners();
      }
    } else if (msg is MsgGameStart) {
      this._reset(msg.myTurn);
    } else if (msg is MsgGameOver && msg.iWon) {
      _maybeShowRatingDialog();
    } else if (msg.isConfirmation) {
      //awaitingConfirmation = false;
      //notifyListeners();
    } else if (msg is MsgOppLeft) {
      opponentInfo.hasLeft = true;
      notifyListeners();
      if (field is FieldPlaying) {
        this.leaving = true;
        callSuper = false;

        showPopup("Opponent left", angery: true);
      } else {
        showPopup("Opponent left");
      }
      // return Idle(widget.sink);
    } else if (msg is MsgLobbyClosing &&
        !this.leaving &&
        !this.opponentInfo.hasLeft) {
      return IdleState(gsm);
      // TODO: do I need this?

      // return ErrorState(
      //     LobbyClosed(), widget.pMsgCtrl, widget.sMsgCtrl, widget.changeState));
    } else if (msg is MsgError && msg.maybeErr == MsgErrorType.NotInLobby) {
      var field = this.field;
      if (field is FieldFinished && field.waitingToPlayAgain) {
        // TODO close
      }
      // TODO: do I need this? maybe just pop / dialog

      // widget.changeState(Error(
      //     LobbyClosed(), widget.pMsgCtrl, widget.sMsgCtrl, widget.changeState));
    }
    if (callSuper) return super.handleServerMessage(msg);
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

    late final response;
    try {
      response = await http
          .get("${constants.HTTP_URL}/api/users/$opponentId")
          .timeout(Duration(seconds: 4));
    } on Exception {
      return;
    }
    if (response.statusCode == 200) {
      this.opponentInfo.user = PublicUser.fromMap(jsonDecode(response.body));

      if (gsm.userInfo.user?.friends
              .any((friend) => friend.id == opponentInfo.user?.id) ==
          true) {
        opponentInfo.isFriend = true;
      }
      notifyListeners();
    }
  }

  void _maybeShowRatingDialog() async {
    if (FiarSharedPrefs.shouldShowRatingDialog) {
      showRatingDialog = true;
    }
  }

  void _reset(bool myTurn) {
    FieldPlaying _field = FieldPlaying();
    _field.turn = myTurn ? me : me.other;
    field = _field;
    notifyListeners();
  }

  void dropChip(int column) {
    var _field = field;
    if (_field is FieldPlaying && _field.turn == me) {
      dropChipNamed(column, me);

      super.gsm.sendPlayerMessage(PlayerMsgPlaceChip(column));
    }
  }

  void dropChipNamed(int column, Player p) {
    Field _field = field;
    if (_field is FieldPlaying) {
      _field.dropChipNamed(column, p);
      WinDetails? winDetails = _field.checkWin();
      if (winDetails != null) {
        field = FieldFinished(winDetails, field.array);
        notifyListeners();
        if (winDetails is WinDetailsWinner) {
          if (winDetails.winner == this.me) {
            Vibrations.win();
          } else if (winDetails.winner == this.me.other) {
            Vibrations.loose();
          }
        } else {
          Vibrations.loose();
        }
      }
    }
  }

  void playAgain() {
    super.gsm.sendPlayerMessage(PlayerMsgPlayAgain());
  }

  void showPopup(String s, {bool angery = false}) {
    toastState = ToastState("Opponent left", angery: angery, onComplete: () {
      super.gsm.hideViewer = true;
    });
    notifyListeners();
  }
}

class OpponentInfo {
  PublicUser? user;
  bool hasLeft = false;
  bool? isFriend;

  OpponentInfo({this.user, this.isFriend});
}
