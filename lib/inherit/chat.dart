import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';

class ChatState with ChangeNotifier {
  final ServerConnection _serverConnection;

  final List<ChatMessage> messages = [];

  final List<ChatMessage> ingameMessages = [];

  ChatState(this._serverConnection) {
    _serverConnection.playerMsgStream.listen((msg) {
      if (msg is PlayerMsgLeave) {
        ingameMessages.clear();
      }
    });
    _serverConnection.serverMsgStream.listen((msg) {
      if (msg is MsgChatMessage) {
        if (msg.isGlobal) {
          messages.add(ChatMessage(SenderOther(msg.senderName), msg.content));
          if (_viewing) {
            _serverConnection.send(PlayerMsgChatRead());
          } else {
            unread += 1;
          }
        } else {
          ingameMessages.add(ChatMessage(SenderOther(msg.senderName), msg.content));
        }
        notifyListeners();
      } else if (msg is MsgChatRead) {
        if (msg.isGlobal) {
          _setMessagesSeen();
        }
      }
    });
  }

  int _unread = 0;
  int get unread => _unread;
  set unread(int u) {
    if (_viewing) {
      _unread = 0;
    } else {
      _unread = u;
    }
  }

  bool _viewing = false;

  Future<bool> sendMessage(String msgStr, {bool ingameMessage = false}) async {
    var msg = ChatMessage(Sender.me, msgStr);
    (ingameMessage ? ingameMessages : messages).add(msg);

    await Future.delayed(Duration(milliseconds: 85));
    var success = await _serverConnection.send(PlayerMsgChatMessage(msg.content));

    if (success) {
      (ingameMessage ? ingameMessages : messages).last.state = ConfirmationState.Received;
    } else {
      (ingameMessage ? ingameMessages : messages).last.state = ConfirmationState.Error;
    }
    notifyListeners();
    return success;
  }

  void resendMessage(ChatMessage msg) {
    if (msg.sender is! SenderMe) {
      return;
    }

    try {
      messages.remove(messages.singleWhere((m) => m.uid == msg.uid));
    } on StateError {
      print("err");
    }

    sendMessage(msg.content + Random().nextInt(100).toString());
  }

  void startViewing() {
    _serverConnection.send(PlayerMsgChatRead());
    this._viewing = true;
  }

  void stopViewing() {
    this._viewing = false;
  }

  void read() {
    unread = 0;
  }

  void _setMessagesSeen() {
    for (ChatMessage message in this.messages) {
      if (message.state == ConfirmationState.Received) {
        message.state = ConfirmationState.Seen;
      }
    }
    notifyListeners();
  }
}

class ChatMessage {
  final int uid; // random unique id
  final TimeOfDay time;
  final Sender sender;
  final String content;
  ConfirmationState state = ConfirmationState.Sent;

  ChatMessage(this.sender, this.content)
      : uid = Random().nextInt(1 << 32),
        time = TimeOfDay.now();
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
