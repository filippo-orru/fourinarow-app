import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/online/server_conn.dart';
import 'package:four_in_a_row/models/user.dart';

class PlayingOnline extends StatelessWidget {
  final ServerConn serverConn;

  PlayingOnline(UserinfoProviderState userInfo,
      {@required OnlineRequest req, Key key})
      : serverConn = ServerConn(req, userInfo),
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
