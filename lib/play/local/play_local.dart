import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/common/board.dart';
import 'package:four_in_a_row/play/common/winner_overlay.dart';
import 'package:four_in_a_row/play/game_logic/field.dart';

import 'package:four_in_a_row/util/vibration.dart';
import '../game_logic/player.dart';
import '../common/common.dart';
import 'local_field.dart';

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
  void reassemble() {
    super.reassemble();
    field.checkWin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(32, 64, 32, 32),
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
            onTap: _fieldReset,
            board: Board(field, dropChip: _dropChip),
          ),
          kDebugMode
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    RaisedButton(
                      child: Text('Undo'),
                      onPressed: () => setState(() => field.undo()),
                    ),
                    RaisedButton(
                      child: Text('Fill random'),
                      onPressed: () async {
                        for (int i = 0; i < 10; i++) {
                          await Future.delayed(
                            Duration(milliseconds: 300),
                            () {
                              if (mounted)
                                setState(
                                  () => field.dropChip(
                                      Random().nextInt(Field.fieldSize)),
                                );
                            },
                          );
                        }
                      },
                    ),
                  ],
                )
              : SizedBox(),
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
