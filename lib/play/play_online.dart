import 'package:flutter/material.dart';
import 'package:four_in_a_row/online/server_conn.dart';

class PlayingOnline extends StatefulWidget {
  final String lobbyCode;

  PlayingOnline({this.lobbyCode, Key key}) : super(key: key);

  @override
  _PlayingOnlineState createState() => _PlayingOnlineState(lobbyCode);
}

class _PlayingOnlineState extends State<PlayingOnline> {
  ServerConn serverConn;

  _PlayingOnlineState(String lobbyCode) {
    this.serverConn = ServerConn(lobbyCode, setState);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: serverConn.state);
  }
}
