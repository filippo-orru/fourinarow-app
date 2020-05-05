import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../messages.dart';
import 'all.dart';

class InLobby extends GameState {
  final String code;

  InLobby(this.code, Sink<PlayerMessage> sink) : super(sink);

  createState() => InLobbyState();

  @override
  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgOppJoined) {
      return InLobbyReady(this.sink);
    }
    return super.handleMessage(msg);
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return null;
  }
}

class InLobbyState extends State<InLobby> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            "Share this code with your friend:",
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 18),
          Text(
            widget.code,
            style: TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class InLobbyReady extends GameState {
  InLobbyReady(Sink<PlayerMessage> sink) : super(sink);

  createState() => InLobbyReadyState();

  @override
  GameState handleMessage(ServerMessage msg) {
    if (msg is MsgGameStart) {
      return Playing(msg.myTurn, msg.opponentId, this.sink);
    }
    return super.handleMessage(msg);
  }

  GameState handlePlayerMessage(PlayerMessage msg) {
    return null;
  }
}

class InLobbyReadyState extends State<InLobbyReady> {
  bool longerThanExpected = false;
  Timer longerThanExpectedTimer;

  @override
  void initState() {
    super.initState();
    longerThanExpectedTimer = Timer(
        Duration(seconds: 3), () => setState(() => longerThanExpected = true));
  }

  @override
  void dispose() {
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
