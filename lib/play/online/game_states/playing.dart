import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:http/http.dart' as http;
import 'package:four_in_a_row/util/constants.dart' as constants;

import 'package:four_in_a_row/play/common/field_logic/common/player.dart';
import 'package:four_in_a_row/play/common/field_logic/online_field.dart';
import 'package:four_in_a_row/play/common/common.dart';
import 'package:four_in_a_row/play/online/messages.dart';
import 'package:four_in_a_row/models/user.dart';
import 'package:four_in_a_row/util/toast.dart';
import 'package:four_in_a_row/util/vibration.dart';

import 'all.dart';

class Playing extends GameState {
  final _PlayingState state;

  Playing(bool myTurn, String opponentId, Sink<PlayerMessage> sink)
      : state = _PlayingState(myTurn, opponentId),
        super(sink);

  @override
  createState() => state;

  @override
  GameState handleMessage(ServerMessage msg) {
    if (state?.leaving == false)
      return state.handleMessage(msg) ?? super.handleMessage(msg);
    else
      return null;
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return state.handlePlayerMessage(msg);
  }
}

class _PlayingState extends State<Playing> {
  final String opponentId;
  OnlineField field;
  bool awaitingConfirmation;
  bool leaving = false;
  Toast toast;
  Timer toastTimer;
  BuildContext context;
  PublicUser opponentInfo;

  _PlayingState(bool myTurn, [this.opponentId]) {
    field = OnlineField();
    field.turn = myTurn ? field.me : field.me.other;
    if (opponentId != null) {
      _loadOpponentInfo();
    }
  }

  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgPlaceChip) {
      setState(() {
        this._dropChipNamed(msg.row, field.me.other);
      });
    } else if (msg is MsgGameStart) {
      this._reset(msg.myTurn);
    } else if (msg.isConfirmation) {
      setState(() => awaitingConfirmation = false);
    } else if (msg is MsgOppLeft) {
      this.leaving = true;
      showPopup("Opponent left.", angery: true);
      Future.delayed(this.toast.duration * 0.6, () => this.pop());
      // return Idle(widget.sink);
    } else if (msg is MsgLobbyClosing && !this.leaving) {
      return Error(LobbyClosed(), widget.sink);
    }
    return null;
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgPlayAgain) {
      setState(() => field.waitingToPlayAgain = true);
      _loadOpponentInfo();
    } else if (msg is PlayerMsgPlaceChip) {
      setState(() => awaitingConfirmation = true);
    } else if (msg is PlayerMsgLeave) {
      leaving = true;
    }
    return null;
  }

  void _loadOpponentInfo() async {
    http.Response response =
        await http.get("${constants.URL}/api/users/$opponentId");
    if (response.statusCode == 200) {
      this.opponentInfo = PublicUser.fromMap(jsonDecode(response.body));
    }
  }

  void pop() {
    if (this.context != null) {
      Navigator.of(context).pop();
    }
  }

  void showPopup(String text, {bool angery = false}) {
    setState(() => this.toast = Toast(text, angery: angery));
    toastTimer?.cancel();
    toastTimer = Timer(this.toast.duration, () => this.toast = null);
  }

  void _reset(bool myTurn) {
    setState(() {
      field = OnlineField();
      field.turn = myTurn ? field.me : field.me.other;
    });
  }

  void _dropChipNamed(int column, Player player) {
    setState(() {
      field.dropChipNamed(column, player);
    });
    var winDetails = field.checkWin();
    if (winDetails?.player == field.me) {
      Vibrations.win();
    } else if (winDetails?.player == field.me.other) {
      Vibrations.loose();
    }
    // showPopup('SR: $field');
  }

  void _dropChip(int column) {
    if (field.turn == field.me) {
      this._dropChipNamed(column, field.me);

      widget.sink.add(PlayerMsgPlaceChip(column));
    }
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    return WillPopScope(
      onWillPop: () {
        widget.sink.add(PlayerMsgLeave());
        UserinfoProvider.of(context).refresh();
        return Future.value(true);
      },
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 32, vertical: 64),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OnlineTurnIndicator(
                    field.turn == field.me, awaitingConfirmation),
                Expanded(
                  child: Center(
                    child: Board(field, dropChip: _dropChip),
                  ),
                ),
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: LeaveOnlineButton(() {}),
                // ),
                // LeaveOnlineButton(() => {}),
              ],
            ),
          ),
          this.opponentInfo == null
              ? SizedBox()
              : Positioned(
                  left: 0,
                  bottom: 32,
                  right: 0,
                  child: OpponentInfo(this.opponentInfo),
                ),
          Positioned(
            bottom: 32,
            right: 32,
            child: ConnectionIndicator(awaitingConfirmation),
          ),
          WinnerOverlay(
            field.checkWin(),
            useColorNames: false,
            onTap: () => widget.sink.add(PlayerMsgPlayAgain()),
            board: Board(field, dropChip: (_) {}),
            ranked: opponentInfo != null,
            bottomText:
                field.waitingToPlayAgain ? "Waiting for opponent..." : null,
          ),
          this.toast ?? SizedBox(),
        ],
      ),
    );
  }
}

class OpponentInfo extends StatelessWidget {
  OpponentInfo(this.opponentInfo);

  final PublicUser opponentInfo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              "Enemy:",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              opponentInfo.name,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            Text(
              "${opponentInfo.gameInfo.skillRating} SR",
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class LeaveOnlineButton extends StatelessWidget {
//   LeaveOnlineButton(this._fieldReset);

//   final Function _fieldReset;

//   @override
//   Widget build(BuildContext context) {
//     // final borderColor = _turn.color().withOpacity(0.5);
//     return BorderButton(
//       "Reset",
//       icon: Icons.refresh,
//       callback: _fieldReset,
//       borderColor: Colors.black26,
//     );
//   }
// }

// class OpponentJoined extends GameState {
//   @override
//   GameState handleMessage(ServerMessage msg) {
//     super.handleMessage(msg);
//     return null;
//     // TODuO: implement handleMessage
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Text("Opponent has joined!");
//   }
// }
class OnlineTurnIndicator extends StatelessWidget {
  const OnlineTurnIndicator(
    this.myTurn,
    this.awaitingConfirmation, {
    Key key,
  }) : super(key: key);

  final bool myTurn;
  final bool awaitingConfirmation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 32),
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        // alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 170),
            switchInCurve: Curves.easeInOutExpo,
            switchOutCurve: Curves.easeInOutExpo,
            // layoutBuilder: (Widget child, List<Widget> prevChildren) {
            //   return child;
            // },
            transitionBuilder: (Widget child, Animation<double> anim) {
              final begin =
                  child.key == ValueKey(myTurn) ? Offset(1, 0) : Offset(-1, 0);
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(begin: begin, end: Offset(0, 0))
                      .animate(anim),
                  child: child,
                ),
              );
            },
            child: Text(
              myTurn ? "Your turn" : "Opponent's turn",
              key: ValueKey(myTurn),
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Player.values[myTurn ? 0 : 1].color()),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionIndicator extends StatefulWidget {
  final bool awaitingConfirmation;

  ConnectionIndicator(this.awaitingConfirmation);

  @override
  _ConnectionIndicatorState createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator>
    with TickerProviderStateMixin {
  AnimationController breatheCtrl;
  AnimationController turnRed;
  Animation<Color> colorAnim;
  Animation<double> opacityAnim;
  Timer delayedExecution;

  @override
  void initState() {
    super.initState();
    turnRed =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    colorAnim =
        Tween<Color>(begin: Colors.green, end: Colors.red).animate(turnRed);

    breatheCtrl =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed &&
                turnRed.status != AnimationStatus.completed) {
              breatheCtrl.reverse();
            } else if (status == AnimationStatus.dismissed) {
              breatheCtrl.forward();
            }
          });
    opacityAnim = Tween<double>(begin: 0.7, end: 1)
        .chain(CurveTween(curve: Curves.easeInOutSine))
        .animate(breatheCtrl);
    breatheCtrl.forward();
  }

  @override
  void dispose() {
    turnRed.dispose();
    breatheCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConnectionIndicator oldWidget) {
    if (widget.awaitingConfirmation == true) {
      if (oldWidget.awaitingConfirmation != true) {
        this.delayedExecution = Timer(Duration(milliseconds: 500), () {
          if (this.mounted && widget.awaitingConfirmation) {
            turnRed.forward();
          }
        });
      }
    } else {
      this.turnRed.reverse();
      this.breatheCtrl.forward();
      this.delayedExecution?.cancel();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacityAnim,
      child: AnimatedBuilder(
        animation: colorAnim,
        builder: (ctx, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(100)),
            color: colorAnim.value,
          ),
          width: 18,
          height: 18,
        ),
        // child:
      ),
    );
  }
}
