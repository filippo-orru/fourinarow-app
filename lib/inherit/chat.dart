import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';

class ChatState with ChangeNotifier {
  final ServerConnection _serverConnection;

  final List<ChatMessage> messages = [];

  ChatState(this._serverConnection) {
    _serverConnection.serverMsgStream.listen((msg) {
      if (msg is MsgChatMessage) {
        if (msg.isGlobal) {
          messages.add(ChatMessage(SenderOther(msg.senderName), msg.content));
          unread += 1;
        }
        notifyListeners();
      }
    });
  }

  int unread = 0;

  // StreamSubscription _serverMsgSub; // TODO cancel

  Future<bool> sendMessage(String msg) async {
    messages.add(ChatMessage(Sender.me, msg));
    _serverConnection.send(PlayerMsgChatMessage(msg));
    bool success = await _serverConnection.waitForOkay(
        duration: Duration(milliseconds: 500));
    if (success) {
      messages.last.state = ConfirmationState.Received;
    } else {
      messages.last.state = ConfirmationState.Error;
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
  final TimeOfDay time;
  final Sender sender;
  final String content;
  ConfirmationState state = ConfirmationState.Sent;

  ChatMessage(this.sender, this.content) : time = TimeOfDay.now();
}

enum ConfirmationState { Sent, Received, Seen, Error }

abstract class Sender {
  static Sender get me => SenderMe();

  static Sender other([String? name]) => SenderOther(name);
}

class SenderMe extends Sender {}

class SenderOther extends Sender {
  final String? name;

  SenderOther(this.name);
}
