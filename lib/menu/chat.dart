import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/chat.dart';

class ChatScreen extends StatefulWidget {
  final ChatProviderState chatProviderState;

  const ChatScreen({Key key, @required this.chatProviderState})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ScrollController _scrollController = new ScrollController();
  bool _scrollToBottomOnNextBuild = false;

  void _sendMessage(String msg, void Function(bool) callback) async {
    bool success = await widget.chatProviderState.sendMessage(msg);
    callback(success);
    _scrollToBottomOnNextBuild = true;
  }

  void _scrollToBottom() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  }

  @override
  void initState() {
    super.initState();
    widget.chatProviderState.notifier.addListener(() {
      _scrollToBottomOnNextBuild = true;
    });
    widget.chatProviderState.read();
  }

  @override
  Widget build(BuildContext context) {
    if (_scrollToBottomOnNextBuild) {
      _scrollToBottomOnNextBuild = false;
      Future.delayed(Duration(milliseconds: 500 ~/ 6), _scrollToBottom);
    }
    return ValueListenableBuilder(
      valueListenable: widget.chatProviderState.notifier,
      builder: (ctx, x, child) {
        widget.chatProviderState.read();
        return child;
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Chat")),
        body: Container(
          constraints: BoxConstraints.expand(),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  children: <Widget>[] +
                      widget.chatProviderState.messages
                          .map((message) => ChatMessageWidget(message))
                          .toList() +
                      [SizedBox(height: 16)],
                ),
              ),
              CreateMessageWidget(
                onMessageSent: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum WidgetChangeApplyCycle { IDLE, REQUESTED, BUILT }

class CreateMessageWidget extends StatefulWidget {
  final void Function(String, void Function(bool)) onMessageSent;

  const CreateMessageWidget({Key key, @required this.onMessageSent})
      : super(key: key);

  @override
  _CreateMessageWidgetState createState() => _CreateMessageWidgetState();
}

class _CreateMessageWidgetState extends State<CreateMessageWidget> {
  TextEditingController _textEditCtrl = TextEditingController();

  bool _sendingMessage = false;

  bool _errorSending = false;

  // _CreateMessageWidgetState() {
  //   _textEditCtrl.addListener(() {
  //     _textEditCtrl.
  //   })
  // }

  void sendMessage() {
    setState(() => _sendingMessage = true);
    widget.onMessageSent(this._textEditCtrl.text, (success) {
      setState(() {
        _errorSending = !success;
        _sendingMessage = false;
        this._textEditCtrl.text = "";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide()),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black.withOpacity(0.18),
            offset: Offset(0, -4),
          )
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: TextField(
              // autofocus: true,
              // onChanged: setText,
              onSubmitted: (_) => sendMessage(),
              controller: _textEditCtrl,
              enabled: !this._sendingMessage,
              decoration: InputDecoration(
                hintText: 'Chat with others!',
                border: InputBorder.none,
                counterText: null,
                counter: null,
                counterStyle: null,
              ),
              style: TextStyle(
                color: this._sendingMessage ? Colors.black54 : Colors.black,
              ),
              maxLines: 1,
            ),
          ),
          this._errorSending
              ? Container(
                  child: Icon(Icons.error_outline, color: Colors.red[600]),
                )
              : SizedBox(),
          Container(
            margin: EdgeInsets.all(8),
            child: GestureDetector(
              onTap: sendMessage,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: Colors.blueAccent,
                ),
                child: Transform.translate(
                    offset: Offset(1.5, 0),
                    child: Icon(
                      Icons.send,
                      color: Colors.white.withOpacity(0.9),
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget(this.message, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 60,
      width: double.infinity,

      child: Row(
        children: [
          message.mine ? Expanded(child: SizedBox()) : SizedBox(),
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(
                  style: message.mine ? BorderStyle.solid : BorderStyle.none),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Text(message.content),
          ),
          message.mine ? SizedBox() : Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}
