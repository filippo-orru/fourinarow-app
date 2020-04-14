import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

import 'package:four_in_a_row/play/online/game_states/all.dart' as game_state;
import 'conn_states/all.dart';
import 'messages.dart';

class ServerConn extends StatefulWidget {
  final String lobbyCode;
  ServerConn(this.lobbyCode);

  createState() => ServerConnState(lobbyCode);
}

class ServerConnState extends State<ServerConn> {
  ConnState state = ConnStateWaiting();

  ServerConnState(String lobbyCode) {
    this.state =
        ConnStateConnected(lobbyCode, changeStateCallback: this.changeState);
  }

  changeState(ConnState newState) {
    setState(() {
      this.state = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return this.state;
  }

  // _setupConnection(String lobbyCode) {
  // }

  // void send(PlayerMessage msg, {int i = 1}) {
  //   var connState = this.state;
  //   if (connState is ConnStateConnected) {
  //   } else {
  //     print("Tried to send \"$msg\" before connection is established ($i)");
  //     if (i <= 10) {
  //       Future.delayed(Duration(seconds: 1), () {
  //         send(msg, i: i + 1);
  //       });
  //     } else {
  //       print("Exceeded retries.");
  //     }
  //   }
  // }

  // void _startListening({int i = 1}) async {
  //   // var connState = await this.connectionComplete;
  //   var state = this.state;
  //   if (state is ConnStateConnected) {
  //     state.state.stream.listen((smsg) {

  //     });
  //   } else {
  //     if (i >= 10) {
  //       setState(() => this.state = ConnStateError(ConnErrorTimeout()));
  //     } else {
  //       Future.delayed(Duration(seconds: 1), () {
  //         _startListening(i: i + 1);
  //       });
  //     }
  //   }
  // }
}
