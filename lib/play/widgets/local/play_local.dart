import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/providers/route.dart';

import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:provider/src/provider.dart';

import '../common/common.dart';
import '../common/board.dart';
import '../common/winner_overlay.dart';

class PlayingLocal extends StatefulWidget {
  const PlayingLocal({Key? key}) : super(key: key);

  @override
  _PlayingLocalState createState() => _PlayingLocalState();
}

class _PlayingLocalState extends State<PlayingLocal> with RouteAware {
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

  late RouteObserver _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = RouteObserverProvider.of(context).observer
      ..subscribe(this, ModalRoute.of(context)!);
    SystemUiStyle.mainMenu();
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    SystemUiStyle.mainMenu();
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
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blueGrey,
                        ),
                        child: Text('Undo'),
                        onPressed: () => setState(() => field.undo()),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blueGrey,
                        ),
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
                  ),
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
    final borderColor = _turn.color(context.watch<ThemesProvider>().selectedTheme).withOpacity(0.5);
    return BorderButton("Reset",
        icon: Icons.refresh, callback: _fieldReset, borderColor: borderColor);
  }
}
