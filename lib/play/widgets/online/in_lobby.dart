import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/util/vibration.dart';

class InLobbyViewer extends StatelessWidget {
  final InLobbyState state;

  const InLobbyViewer(this.state, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: state.code == null
          ? Text(
              'Wait for your opponent to join',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Share this code with your friend:",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 18),
                Text(
                  state.code,
                  style: TextStyle(fontSize: 48),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class InLobbyReadyViewer extends StatefulWidget {
  final InLobbyReadyState state;

  const InLobbyReadyViewer(this.state, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InLobbyReadyViewerState();
}

class _InLobbyReadyViewerState extends State<InLobbyReadyViewer> {
  bool longerThanExpected = false;
  Timer longerThanExpectedTimer;

  @override
  initState() {
    super.initState();
    Vibrations.gameFound();
    longerThanExpectedTimer = Timer(
        Duration(seconds: 3), () => setState(() => longerThanExpected = true));
  }

  @override
  dispose() {
    longerThanExpectedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: longerThanExpected
            ? CircularProgressIndicator()
            : TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                curve: Curves.slowMiddle,
                duration: Duration(milliseconds: 1500),
                builder: (ctx, value, child) {
                  double opacity = value;
                  if (value >= 0.5) opacity = 1 - opacity;
                  return Opacity(
                    opacity: 2 * opacity,
                    child: Transform.translate(
                      offset:
                          Offset.lerp(Offset(-100, 0), Offset(100, 0), value),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  "Game starting!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}
