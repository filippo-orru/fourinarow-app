import 'package:flutter/material.dart';

import 'package:four_in_a_row/field_logic/common/player.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:four_in_a_row/field_logic/online_field.dart';
import 'package:four_in_a_row/play/common/common.dart';
import 'package:four_in_a_row/online/messages.dart';

import 'all.dart';

class Playing extends GameState {
  final PlayingState state;

  Playing(bool myTurn, Sink<PlayerMessage> sink)
      : state = PlayingState(myTurn),
        super(sink);

  createState() => state;

  @override
  GameState handleMessage(ServerMessage msg) {
    state.handleMessage(msg);
    return super.handleMessage(msg);
  }
}

class PlayingState extends State<Playing> {
  OnlineField field;

  PlayingState(bool myTurn) {
    field = OnlineField();
    field.turn = myTurn ? field.me : field.me.other;
  }

  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgPlaceChip) {
      print("Placing opponent chip in row " + msg.row.toString());
      field.dropChipNamed(msg.row, field.me.other);
      setState(() {});
    }
    return null;
  }

  _dropChip(int column) {
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
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TurnIndicator(turn: field.turn),
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
          fieldReset: () => Navigator.of(context).popUntil((route) => true),
          field: Board(field, dropChip: (_) {}),
        ),
      ],
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
