import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/connection/server_conn.dart';

class PlayingOnline extends StatelessWidget {
  // final ServerConnState serverConn;

  PlayingOnline({
    Key key,
    // @required this.serverConn,
    // @required OnlineRequest req,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var serverConn = ServerConnProvider.of(context);
    return Scaffold(body: OnlineViewer(serverConn));
  }
}
