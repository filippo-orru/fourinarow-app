import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/play/models/online/current_game_state.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/widgets/online/playing.dart';
import 'package:four_in_a_row/play/widgets/online/idle.dart';
import 'package:four_in_a_row/play/widgets/online/other.dart';
import 'package:four_in_a_row/play/widgets/online/in_lobby.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:provider/provider.dart';

export 'playing.dart';

class GameStateViewer extends StatelessWidget {
  Widget getViewer(GameState cgs) {
    if (cgs is PlayingState) {
      return PlayingViewer(cgs);
    } else if (cgs is IdleState) {
      return IdleViewer(cgs);
    } else if (cgs is InLobbyState) {
      return InLobbyViewer(cgs);
    } else if (cgs is InLobbyReadyState) {
      return InLobbyReadyViewer(cgs);
    } else if (cgs is WaitingForWWOkayState) {
      return WaitingForWWOkayViewer(cgs);
    } else if (cgs is WaitingForLobbyInfoState) {
      return WaitingForLobbyInfoViewer(cgs);
    } else if (cgs is WaitingForWWOpponentState) {
      return WaitingForWWOpponentViewer(cgs);
    }
    throw UnimplementedError("Missing viewer for game state $cgs");
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ServerConnection, GameStateManager>(
      builder: (_, serverConnection, gameStateManager, __) => WillPopScope(
        onWillPop: () {
          gameStateManager.closingViewer();
          return Future.value(true);
        },
        child: Scaffold(
          body: Stack(children: [
            getViewer(gameStateManager.currentGameState),
            serverConnection.connected
                ? SizedBox()
                : IgnorePointer(
                    // ignoring: !serverConnection.connected,
                    child: Container(
                      constraints: BoxConstraints.expand(),
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          // width: 230,
                          // height: 120,
                          padding: EdgeInsets.symmetric(
                              vertical: 24, horizontal: 48),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 24),
                              Text('Trying to reconnect')
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ]),
        ),
      ),
    );
  }
}
