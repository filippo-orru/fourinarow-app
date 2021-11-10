import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/providers/route.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';

import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/cpu/cpu.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:provider/src/provider.dart';

import '../common/common.dart';
import '../common/board.dart';
import '../common/winner_overlay.dart';

class PlayingCPU extends StatefulWidget {
  final Cpu cpuPlayer;

  PlayingCPU({Key? key, required CpuDifficulty difficulty})
      : this.cpuPlayer = Cpu.fromDifficulty(difficulty),
        super(key: key);

  @override
  _PlayingCPUState createState() => _PlayingCPUState();
}

class _PlayingCPUState extends State<PlayingCPU> with RouteAware {
  FieldPlaying field = FieldPlaying();
  bool waitingForCpu = false;

  _dropChip(int column) {
    if (field.turn == Player.One) {
      setState(() {
        field.dropChip(column);

        if (field.checkWin() != null) {
          Vibrations.win();
        } else {
          _cpuTurn();
        }
      });
    }
  }

  void _cpuTurn() async {
    waitingForCpu = true;
    int column = await widget.cpuPlayer.chooseCol(field);
    waitingForCpu = false;
    setState(() {
      field.dropChipNamed(column, Player.Two);
    });
  }

  _fieldReset() {
    setState(() => field.reset());
  }

  String _playerNames(Player p) {
    if (p == Player.One)
      return "You";
    else
      return "CPU";
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
                TurnIndicator(turn: field.turn, playerNames: _playerNames),
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: waitingForCpu
                      ? SizedBox(
                          width: 64,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.red,
                          ))
                      : SizedBox(height: 4),
                ),
                Expanded(
                  child: Center(
                    child: Board(field, dropChip: _dropChip),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Difficulty: ${widget.cpuPlayer.difficultyString()}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Colors.grey.shade600),
                        iconSize: 20,
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (_) => FiarSimpleDialog(
                                    title: 'Cpu difficulty',
                                    content:
                                        "Right now, you can only play against the medium CPU.\nI'm working on adding harder CPU players soon!",
                                  ));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          WinnerOverlay(
            field.checkWin(),
            onTap: _fieldReset,
            playerNames: _playerNames,
            board: Board(field, dropChip: _dropChip),
          ),
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
