import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';

class ChatState with ChangeNotifier {
  final ServerConnection _serverConnection;
  ChatState(this._serverConnection);

  final List<ChatMessage> messages = List.empty();

  int unread = 0;

  // StreamSubscription _serverMsgSub; // TODO cancel

  Future<bool> sendMessage(String msg) async {
    _serverConnection.send(PlayerMsgChatMessage(msg));
    ServerMessage? serverMsg;
    serverMsg = await _serverConnection.serverMessages
        .map<ServerMessage?>((e) => e)
        .firstWhere((serverMsg) => serverMsg is MsgOkay)
        .timeout(Duration(milliseconds: 750), onTimeout: () => null);

    bool success = serverMsg != null && serverMsg is MsgOkay;
    if (success) {
      messages.add(ChatMessage(true, msg));
    }
    return success;
  }

  void read() {
    unread = 0;
  }

/*
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serverMsgSub?.cancel();

    _serverMsgSub = widget._serverConnection.incoming.listen((serverMsg) {
      if (serverMsg is MsgChatMessage) {
        messages.add(ChatMessage(false, serverMsg.message));
        unread += 1;
        _notify();
      }
    });
  }*/
}

class ChatMessage {
  final bool mine;
  final String content;

  ChatMessage(this.mine, this.content);
}
