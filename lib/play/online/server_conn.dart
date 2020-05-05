import 'package:flutter/material.dart';
import 'package:four_in_a_row/models/user.dart';
import '../play_online.dart';
import 'conn_states/all.dart';

class ServerConn extends StatefulWidget {
  final OnlineRequest req;
  final UserinfoProviderState userInfo;

  ServerConn(this.req, this.userInfo);

  createState() => ServerConnState();
}

class ServerConnState extends State<ServerConn> {
  ConnState state = ConnStateWaiting();

  @override
  void initState() {
    super.initState();
    this.state = ConnStateConnected(widget.req,
        changeStateCallback: this.changeState, userInfo: widget?.userInfo);
  }

  changeState(ConnState newState) {
    setState(() {
      this.state = newState;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
        duration: Duration(milliseconds: 200), child: this.state);
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
