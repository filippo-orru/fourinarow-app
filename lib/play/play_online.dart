import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/online/server_conn.dart';

class PlayingOnline extends StatelessWidget {
  final ServerConn serverConn;

  PlayingOnline({String lobbyCode, Key key})
      : serverConn = ServerConn(lobbyCode),
        super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: serverConn);
  }
}
