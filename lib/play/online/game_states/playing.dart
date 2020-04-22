import 'package:flutter/material.dart';

import 'package:four_in_a_row/play/common/field_logic/common/player.dart';
import 'package:four_in_a_row/play/common/field_logic/online_field.dart';
import 'package:four_in_a_row/play/common/common.dart';
import 'package:four_in_a_row/play/online/messages.dart';
import 'package:four_in_a_row/util/vibration.dart';

import 'all.dart';

class Playing extends GameState {
  final bool myTurn;
  final _PlayingState state;

  Playing(this.myTurn, Sink<PlayerMessage> sink)
      : state = _PlayingState(myTurn),
        super(sink);

  @override
  createState() => state;

  @override
  GameState handleMessage(ServerMessage msg) {
    return state.handleMessage(msg) ?? super.handleMessage(msg);
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return state.handlePlayerMessage(msg);
  }
}

class _PlayingState extends State<Playing> {
  OnlineField field;

  _PlayingState(bool myTurn) {
    field = OnlineField();
    field.turn = myTurn ? field.me : field.me.other;
  }

  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgPlaceChip) {
      setState(() {
        field.dropChipNamed(msg.row, field.me.other);
      });
    } else if (msg is MsgGameStart) {
      this._reset(msg.myTurn);
    }
    return null;
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgPlayAgain) {
      setState(() => field.waitingToPlayAgain = true);
    }
    return null;
  }

  void _reset(bool myTurn) {
    setState(() {
      field = OnlineField();
      field.turn = myTurn ? field.me : field.me.other;
    });
  }

  void _dropChip(int column) {
    // print("drop-tap registered");
    if (field.turn == field.me) {
      // print("sending named drop");
      setState(() {
        field.dropChipNamed(column, field.me);
      });
      widget.sink.add(PlayerMsgPlaceChip(column));
    } else {
      print("not my turn");
    }
    if (field.checkWin() != null) {
      Vibrations.win();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        widget.sink.add(PlayerMsgLeave());
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
                OnlineTurnIndicator(field.turn == field.me),
                Expanded(
                  child: Center(
                    child: Board(field, dropChip: _dropChip),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: LeaveOnlineButton(() {}),
                ),
                // LeaveOnlineButton(() => {}),
              ],
            ),
          ),
          WinnerOverlay(
            field.checkWin(),
            onTap: () => widget.sink.add(PlayerMsgPlayAgain()),
            board: Board(field, dropChip: (_) {}),
            bottomText:
                field.waitingToPlayAgain ? "Waiting for opponent..." : null,
          ),
        ],
      ),
    );
  }
}

class LeaveOnlineButton extends StatelessWidget {
  LeaveOnlineButton(this._fieldReset);

  final Function _fieldReset;

  @override
  Widget build(BuildContext context) {
    // final borderColor = _turn.color().withOpacity(0.5);
    return BorderButton(
      "Reset",
      icon: Icons.refresh,
      callback: _fieldReset,
      borderColor: Colors.black26,
    );
  }
}

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
    this.myTurn, {
    Key key,
  }) : super(key: key);

  final bool myTurn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 32),
      width: double.infinity,
      child: AnimatedSwitcher(
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
              position:
                  Tween<Offset>(begin: begin, end: Offset(0, 0)).animate(anim),
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
    );
  }
}
