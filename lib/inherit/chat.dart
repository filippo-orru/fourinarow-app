import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'connection/messages.dart';
import 'connection/server_conn.dart';

class ChatProvider extends StatefulWidget {
  ChatProvider({Key key, this.child}) : super(key: key);
  final Widget child;

  @override
  createState() => ChatProviderState();

  static ChatProviderState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ChatProviderInherit>()
        ?.state;
  }
}

class ChatProviderState extends State<ChatProvider> {
  final List<ChatMessage> messages = List<ChatMessage>();

  int unread = 0;

  ValueNotifier<int>
      notifier; // dirty ass hack to notify chat screen of new msg

  ServerConnState _serverConn;
  StreamSubscription _serverMsgSub;

  Future<bool> sendMessage(String msg) async {
    _serverConn.outgoing.add(PlayerMsgChatMessage(msg));
    ServerMessage serverMsg = await _serverConn.incoming.stream
        .firstWhere((serverMsg) => serverMsg is MsgOkay)
        .timeout(Duration(milliseconds: 750), onTimeout: () => null);
    bool success = serverMsg != null && serverMsg is MsgOkay;
    if (success) {
      messages.add(ChatMessage(true, msg));
      _notify();
    }
    return success;
  }

  void _notify() {
    notifier.value += 1;
  }

  void read() {
    if (unread != 0) {
      unread = 0;
      Future.delayed(Duration.zero, _notify);
    }
  }

  @override
  void initState() {
    super.initState();
    notifier = ValueNotifier(0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serverMsgSub?.cancel();

    _serverConn = ServerConnProvider.of(context);
    _serverMsgSub = _serverConn.incoming.stream.listen((serverMsg) {
      if (serverMsg is MsgChatMessage) {
        messages.add(ChatMessage(false, serverMsg.message));
        unread += 1;
        _notify();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ChatProviderInherit(widget.child, this);
  }

  @override
  void dispose() {
    _serverMsgSub?.cancel();
    super.dispose();
  }
}

class _ChatProviderInherit extends InheritedWidget {
  _ChatProviderInherit(Widget child, this.state, {Key key})
      : super(key: key, child: child);

  final ChatProviderState state;

  @override
  bool updateShouldNotify(_ChatProviderInherit oldWidget) {
    // return oldWidget.state.messages != this.state.messages;
    return true;
  }
}

class ChatMessage {
  final bool mine;
  final String content;

  ChatMessage(this.mine, this.content);
}
