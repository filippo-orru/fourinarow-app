import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/models/online/game_states/other.dart';
import 'package:four_in_a_row/play/widgets/online/loading_screen.dart';

class WaitingForLobbyInfoViewer extends StatelessWidget {
  final WaitingForLobbyInfoState state;

  const WaitingForLobbyInfoViewer(this.state, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title =
        state.code == null ? "Contacting Server..." : "Joining Lobby...";
    String label = "This may take some time";
    return LoadingScreen(title: title, label: label);
  }
}

class WaitingForWWOkayViewer extends StatelessWidget {
  final WaitingForWWOkayState state;

  const WaitingForWWOkayViewer(this.state, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = "Contacting Server...";
    return LoadingScreen(title: title);
  }
}

class WaitingForWWOpponentViewer extends StatelessWidget {
  final WaitingForWWOpponentState state;

  const WaitingForWWOpponentViewer(this.state, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = "Searching for opponent...";
    String label =
        "This may take some time. You will receive a notification when a game is found.";
    return LoadingScreen(title: title, label: label);
  }
}
