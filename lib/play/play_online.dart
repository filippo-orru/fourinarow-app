import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/online/server_conn.dart';

class PlayingOnline extends StatelessWidget {
  final ServerConn serverConn;

  PlayingOnline({@required OnlineRequest req, Key key})
      : serverConn = ServerConn(req),
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: serverConn);
  }
}

abstract class OnlineRequest {}

class ORqLobby extends OnlineRequest {
  final String lobbyCode;
  ORqLobby(this.lobbyCode);
}

class ORqWorldwide extends OnlineRequest {}

class PlayingOnlineWW extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text("coming soon")));
  }
}
