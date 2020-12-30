import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/util/vibration.dart';

import '../common/common.dart';
import '../common/board.dart';
import '../common/winner_overlay.dart';

class PlayingLocal extends StatefulWidget {
  const PlayingLocal({Key? key}) : super(key: key);

  @override
  _PlayingLocalState createState() => _PlayingLocalState();
}

class _PlayingLocalState extends State<PlayingLocal> {
  FieldPlaying field = FieldPlaying();

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
                              field.dropChip(Random().nextInt(Field.size));
                              if (mounted) setState(() {});
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

  final void Function() _fieldReset;
  final Player _turn;

  @override
  Widget build(BuildContext context) {
    final borderColor = _turn.color().withOpacity(0.5);
    return BorderButton("Reset",
        icon: Icons.refresh, callback: _fieldReset, borderColor: borderColor);
  }
}
