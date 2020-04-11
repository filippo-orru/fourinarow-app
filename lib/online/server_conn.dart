import 'package:web_socket_channel/io.dart';

import 'conn_states/all.dart';
import 'messages.dart';

class ServerConn {
  ConnState state = ConnStateWaiting();
  bool _awaitingConfirmation = false;
  Function setState;

  ServerConn(String lobbyCode, this.setState) {
    // , Function() onConnectionComplete
    // _setupConnection(lobbyCode);
    var connection = IOWebSocketChannel.connect("wss://fourinarow.ml/ws/",
        pingInterval: Duration(seconds: 1));
    this.state = ConnStateConnected(connection);

    _startListening();

    send(lobbyCode == null
        ? PlayerMsgLobbyRequest()
        : PlayerMsgLobbyJoin(lobbyCode));
  }

  // _setupConnection(String lobbyCode) {
  // }

  void send(PlayerMessage msg, {int i = 1}) {
    var connState = this.state;
    if (connState is ConnStateConnected) {
      connState.state.sink.add(msg);

      if (msg is PlayerMsgLeaving) {
        connState.state.sink.close();
        this.state = ConnStateWaiting();
        return;
      }

      _awaitingConfirmation = true;
      Future.delayed(Duration(seconds: 2), () {
        if (this._awaitingConfirmation) {
          var connState = this.state;
          if (connState is ConnStateConnected) {
            connState.state.dispose();
          }
          setState(() => this.state = ConnStateError(ConnErrorTimeout()));
          print("Confirmation timeout!");
        }
      });
    } else {
      print("Tried to send \"$msg\" before connection is established ($i)");
      if (i <= 10) {
        Future.delayed(Duration(seconds: 1), () {
          send(msg, i: i + 1);
        });
      } else {
        print("Exceeded retries.");
      }
    }
  }

  void _startListening({int i = 1}) async {
    // var connState = await this.connectionComplete;
    var state = this.state;
    if (state is ConnStateConnected) {
      state.state.stream.listen((smsg) {
        if (smsg is MsgOkay || smsg is MsgLobbyResponse) {
          this._awaitingConfirmation = false;
        }
      });
    } else {
      if (i >= 10) {
        setState(() => this.state = ConnStateError(ConnErrorTimeout()));
      } else {
        Future.delayed(Duration(seconds: 1), () {
          _startListening(i: i + 1);
        });
      }
    }
  }
}
