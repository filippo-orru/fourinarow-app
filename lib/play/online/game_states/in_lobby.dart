import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/connection/messages.dart';
import 'package:four_in_a_row/inherit/lifecycle.dart';
import 'package:four_in_a_row/inherit/notifications.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'all.dart';

class InLobby extends GameState {
  final String code;
  StreamSubscription sMsgListen;

  InLobby(this.code, StreamController<PlayerMessage> p,
      StreamController<ServerMessage> s, CGS change)
      : super(p, s, change) {
    sMsgListen = sMsgCtrl.stream.listen(handleMessage);
  }

  get build => InLobbyWidget(code);

  dispose() => sMsgListen.cancel();

  void handleMessage(ServerMessage msg) {
    if (msg is MsgOppJoined) {
      changeState(
          InLobbyReady(super.pMsgCtrl, super.sMsgCtrl, super.changeState));
    } else {
      super.handleServerMessageSuper(msg);
    }
  }
}

class InLobbyWidget extends StatefulWidget {
  final String code;
  InLobbyWidget(this.code);

  createState() => InLobbyState();
}

class InLobbyState extends State<InLobbyWidget> {
  @override
  initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: widget.code == null
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
  StreamSubscription sMsgListen;

  InLobbyReady(StreamController<PlayerMessage> p,
      StreamController<ServerMessage> s, CGS change)
      : super(p, s, change) {
    sMsgListen = sMsgCtrl.stream.listen(handleMessage);
  }

  // @override
  void handleMessage(ServerMessage msg) {
    if (msg is MsgGameStart) {
      changeState(Playing(msg.myTurn, msg.opponentId, super.pMsgCtrl,
          super.sMsgCtrl, super.changeState));
    } else {
      super.handleServerMessageSuper(msg);
    }
  }

  get build => InLobbyReadyWidget();

  dispose() {
    sMsgListen.cancel();
  }
}

class InLobbyReadyWidget extends StatefulWidget {
  createState() => InLobbyReadyState();
}

class InLobbyReadyState extends State<InLobbyReadyWidget> {
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
