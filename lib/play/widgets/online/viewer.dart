import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/models/online/current_game_state.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/widgets/online/playing.dart';
import 'package:provider/provider.dart';

export 'playing.dart';

class GameStateViewer extends StatelessWidget {
  getViewer(GameState cgs) {
    Type<AbstractGameStateViewer> viewer;
    if (cgs is PlayingState) {
      viewer = PlayingViewer;
    }
    return viewer;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateManager>(
      builder: (_, gameStateManager, __) => WillPopScope(
        onWillPop: () {
          gameStateManager.closingViewer();
          return Future.value(true);
        },
        child: Scaffold(
          body: getViewer(gameStateManager.currentGameState),
        ),
      ),
    );
  }
}
