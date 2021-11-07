import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/route.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/widgets/online/playing.dart';
import 'package:four_in_a_row/play/widgets/online/idle.dart';
import 'package:four_in_a_row/play/widgets/online/other.dart';
import 'package:four_in_a_row/play/widgets/online/in_lobby.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';

import 'package:provider/provider.dart';

export 'playing.dart';

class GameStateViewer extends StatefulWidget {
  @override
  _GameStateViewerState createState() => _GameStateViewerState();
}

class _GameStateViewerState extends State<GameStateViewer> with RouteAware {
  Widget getViewer(GameState cgs) {
    if (cgs is PlayingState) {
      return PlayingViewer(cgs);
    } else if (cgs is IdleState) {
      return IdleViewer(cgs);
    } else if (cgs is InLobbyState) {
      return InLobbyViewer(cgs);
    } else if (cgs is InLobbyReadyState) {
      return InLobbyReadyViewer(cgs);
    } else if (cgs is WaitingForLobbyInfoState) {
      return WaitingForLobbyInfoViewer(cgs);
    } else if (cgs is WaitingForWWOpponentState) {
      return WaitingForWWOpponentViewer(cgs);
    }
    throw UnimplementedError("Missing viewer for game state $cgs");
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
    context.read<GameStateManager>().showingViewer();
  }

  @override
  void didPop() {
    context.read<GameStateManager>().closingViewer();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateManager>(
      builder: (_, gameStateManager, __) {
        gameStateManager.showingViewer();
        return Scaffold(
          body: Stack(children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 100),
              child: getViewer(gameStateManager.currentGameState),
            ),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 120),
              child: gameStateManager.connected
                  ? SizedBox()
                  : GestureDetector(
                      behavior: HitTestBehavior.deferToChild,
                      child: Reconnecting(),
                    ),
            ),
          ]),
        );
      },
    );
  }
}

class Reconnecting extends StatefulWidget {
  @override
  _ReconnectingState createState() => _ReconnectingState();
}

class _ReconnectingState extends State<Reconnecting> {
  late final Timer timer;
  int s = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() => s++);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.expand(),
      color: Colors.black54,
      child: Center(
        child: Container(
          // width: 230,
          // height: 120,
          margin: EdgeInsets.symmetric(horizontal: 48),
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black38)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No Connection',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(width: 24),
                  Text('Trying to reconnect...'),
                  s > 10 ? Text('Closing in ${s}s') : SizedBox(),
                ],
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.grey.shade100,
                  ),
                  onPressed: (s > 5) ? () => Navigator.of(context).pop() : null,
                  child: Text(
                    'Leave',
                    style: TextStyle(color: s > 5 ? Colors.black87 : Colors.black45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
