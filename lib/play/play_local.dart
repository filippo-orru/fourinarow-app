import 'package:flutter/material.dart';
import 'package:four_in_a_row/field_logic/localField.dart';
import 'package:four_in_a_row/field_logic/common/player.dart';
import 'package:four_in_a_row/play/common/common.dart';

import 'package:four_in_a_row/util/vibration.dart';

class PlayingLocal extends StatefulWidget {
  const PlayingLocal({Key key}) : super(key: key);

  @override
  _PlayingLocalState createState() => _PlayingLocalState();
}

class _PlayingLocalState extends State<PlayingLocal> {
  LocalField field;
  _PlayingLocalState() {
    field = LocalField();
  }

  _dropChip(int column) {
    setState(() {
      field.dropChip(column);

      if (field.checkWin() != null) {
        Vibrations.win();
      }
    });
  }

  _fieldReset() {
    setState(() => field.reset());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
                  child: FieldResetButton(_fieldReset, field.turn),
                ),
                // LeaveOnlineButton(() => {}),
              ],
            ),
          ),
          WinnerOverlay(
            field.checkWin(),
            fieldReset: _fieldReset,
            field: Board(field, dropChip: _dropChip),
          ),
        ],
      ),
    );
  }
}

class FieldResetButton extends StatelessWidget {
  FieldResetButton(this._fieldReset, this._turn);

  final Function _fieldReset;
  final Player _turn;

  @override
  Widget build(BuildContext context) {
    final borderColor = _turn.color().withOpacity(0.5);
    return BorderButton("Reset",
        icon: Icons.refresh, callback: _fieldReset, borderColor: borderColor);
  }
}
