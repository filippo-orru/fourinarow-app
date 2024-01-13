import 'dart:async';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';

import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:four_in_a_row/util/toast.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
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
  void setOpponentUser(PublicUser? opponent) {
    if (this.opponentInfo.user != opponent) {
      opponentInfo.user = opponent;
      notifyListeners();
    }
  }

  void setMuteState(bool mute) {
    opponentInfo.muted = mute;
    notifyListeners();
  }

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
    } else if (msg is MsgLobbyClosing && !this.leaving && !this.opponentInfo.hasLeft) {
      return IdleState(gsm);
      // TODO: do I need this?

      // return ErrorState(
      //     LobbyClosed(), widget.pMsgCtrl, widget.sMsgCtrl, widget.changeState));
    } else if (msg is MsgError && msg.maybeErr == MsgErrorType.NotInLobby) {
      var field = this.field;
      if (field is FieldFinished && field.waitingToPlayAgain) {
        this.gsm.hideViewer = true;
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
    opponentId = opponentId ?? opponentInfo.user?.id;
    if (opponentId == null) return;

    setOpponentUser(await gsm.userInfo.getUserInfo(userId: opponentId));
  }

  void _maybeShowRatingDialog() async {
    if (FiarSharedPrefs.shownRatingDialog.get().difference(DateTime.now()).inDays > 30 * 4) {
      // >4 months ago
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
      if (angery) {
        super.gsm.hideViewer = true;
      }
    });
    notifyListeners();
  }

  PlayingStateIntermediate toIntermediate() {
    return PlayingStateIntermediate(
      getShowRatingDialog: () => showRatingDialog,
      setShowRatingDialog: (b) => showRatingDialog = b,
      toastState: toastState,
      field: field,
      me: me,
      dropChip: dropChip,
      opponentInfo: opponentInfo,
      connectionLost: connectionLost,
      setOpponentUser: setOpponentUser,
      setMuteState: setMuteState,
      playAgain: playAgain,
    );
  }
}

class PlayingStateIntermediate {
  final bool Function() getShowRatingDialog;
  final void Function(bool) setShowRatingDialog;
  final ToastState? toastState;
  final Field field;
  final Player me;
  final void Function(int) dropChip;
  final OpponentInfo opponentInfo;
  final bool connectionLost;
  final void Function(PublicUser?) setOpponentUser;
  final void Function(bool) setMuteState;
  final void Function() playAgain;

  PlayingStateIntermediate({
    required this.getShowRatingDialog,
    required this.setShowRatingDialog,
    required this.toastState,
    required this.field,
    required this.me,
    required this.dropChip,
    required this.opponentInfo,
    required this.connectionLost,
    required this.setOpponentUser,
    required this.setMuteState,
    required this.playAgain,
  });
}

class OpponentInfo {
  PublicUser? user;
  bool hasLeft = false;
  bool muted = false;

  OpponentInfo();
}
