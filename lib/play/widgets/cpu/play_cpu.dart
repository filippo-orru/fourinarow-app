import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/main.dart';

import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/cpu/cpu.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:four_in_a_row/util/vibration.dart';

import '../common/common.dart';
import '../common/board.dart';
import '../common/winner_overlay.dart';

class PlayingCPU extends StatefulWidget {
  late final Cpu cpuPlayer;

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

  String playerNames(Player p) => p == Player.One ? "You" : "CPU";

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
                TurnIndicator(turn: field.turn, playerNames: playerNames),
                Expanded(
                  child: Center(
                    child: Board(field, dropChip: _dropChip),
                  ),
                ),
              ],
            ),
          ),
          WinnerOverlay(
            field.checkWin(),
            onTap: _fieldReset,
            playerNames: playerNames,
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
    final borderColor = _turn.color().withOpacity(0.5);
    return BorderButton("Reset",
        icon: Icons.refresh, callback: _fieldReset, borderColor: borderColor);
  }
}
