import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/inherit/route.dart';

import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/cpu/cpu.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:rive/rive.dart';

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
  final Random _random = Random(DateTime.now().millisecond);

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
    _startThinkingAnimation();
    int column = await widget.cpuPlayer.chooseCol(field);
    waitingForCpu = false;
    _stopThinkingAnimation();
    setState(() {
      field.dropChipNamed(column, Player.Two);
    });
  }

  _fieldReset() {
    setState(() => field.reset());
  }

  String playerNames(Player p) => p == Player.One ? "You" : "CPU";

  late RouteObserver _routeObserver;

  Artboard? _riveArtboard;
  late final RiveAnimationController _rotatingChipsController;
  late final RiveAnimationController _chipsFadeInController;
  late final RiveAnimationController _chipsFadeOutController;
  late final RiveAnimationController _moveBodyController;
  late final RiveAnimationController _blinkController;
  late final RiveAnimationController _moveEyesController;
  // late final RiveAnimationController _tapped1Ctrl;
  late final RiveAnimationController _tapped2Ctrl;

  void _startAnimations() {
    // _moveBodyController.isActive = false;
    // _blinkController.isActive = false;
    // _moveEyesController.isActive = false;
    _moveBodyController.isActive = true;
    _blinkController.isActive = true;
    _moveEyesController.isActive = true;

    _rotatingChipsController.isActive = true;
    _chipsFadeInController.isActive = false;
    _chipsFadeOutController.isActive = false;
    // _tapped1Ctrl.isActive = false;
    _tapped2Ctrl.isActive = false;
  }

  void _startThinkingAnimation() {
    setState(() => _chipsFadeInController.isActive = true);
    // setState(() => _rotatingChipsController.isActive = true);
  }

  void _stopThinkingAnimation() {
    setState(() => _chipsFadeOutController.isActive = true);
    // Future.delayed(Duration(milliseconds: 500),
    //     () => setState(() => _rotatingChipsController.isActive = false));
  }

  bool get _tappedAnimPlaying =>
      _tapped2Ctrl.isActive; // _tapped1Ctrl.isActive ||

  void _tappedRobot() {
    if (!_tappedAnimPlaying) {
      // RiveAnimationController tappedCtrl;
      // tappedCtrl = _random.nextBool() ? _tapped1Ctrl : _tapped2Ctrl;
      setState(() => _tapped2Ctrl.isActive = true);
    }
  }

  @override
  void initState() {
    super.initState();
    rootBundle.load('assets/animations/robots/robot_medium.riv').then(
      (data) async {
        final file = RiveFile();

        // Load the RiveFile from the binary data.
        if (file.import(data)) {
          final artboard = file.mainArtboard;
          // Add a controller to play back a known animation on the main/default
          // artboard. We store a reference to it so we can toggle playback.
          artboard
            ..addController(
                _rotatingChipsController = SimpleAnimation('Rotating Chips'))
            ..addController(
                _chipsFadeInController = SimpleAnimation('chips fade in'))
            ..addController(
                _chipsFadeOutController = SimpleAnimation('chips fade out'))
            ..addController(_moveBodyController = SimpleAnimation('move body'))
            ..addController(_blinkController = SimpleAnimation('eyes blink'))
            ..addController(
                _moveEyesController = SimpleAnimation('eyes movement'))
            // ..addController(_tapped1Ctrl = SimpleAnimation('tapped_1'))
            ..addController(_tapped2Ctrl = SimpleAnimation('tapped_2'));

          setState(() => _riveArtboard = artboard);

          _startAnimations();
        }
      },
    );
  }

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
                TurnIndicator(turn: field.turn, playerNames: playerNames),
                Expanded(
                  child: Center(
                    child: Board(field, dropChip: _dropChip),
                  ),
                ),
                Container(
                  height: 130,
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _riveArtboard == null
                        ? null
                        : GestureDetector(
                            onTap: _tappedRobot,
                            child: Rive(artboard: _riveArtboard),
                          ),
                  ),
                )
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
