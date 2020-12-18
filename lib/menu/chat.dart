import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/chat.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatState>(
        builder: (_, chatState, __) => _ChatScreenInternal(chatState));
  }
}

class _ChatScreenInternal extends StatefulWidget {
  final ChatState chatState;

  const _ChatScreenInternal(this.chatState, {Key? key}) : super(key: key);

  @override
  _ChatScreenInternalState createState() => _ChatScreenInternalState();
}

class _ChatScreenInternalState extends State<_ChatScreenInternal> {
  ScrollController _scrollController = new ScrollController();
  bool _scrollToBottomOnNextBuild = false;
  int _lastBottomInset = 0;
  // ChatState _chatState = context.watch ChatState

  void _sendMessage(String msg, void Function(bool) callback) async {
    msg = msg.trim();
    bool success = await widget.chatState.sendMessage(msg);
    callback(success);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    _scrollToBottomOnNextBuild = true;
    Future.delayed(Duration.zero, () {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.chatState.unread > 0) {
      _scrollToBottom();
    }
    widget.chatState.read();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_scrollToBottomOnNextBuild) {
      _scrollToBottomOnNextBuild = false;
      Future.delayed(Duration(milliseconds: 500 ~/ 6), () {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      });
    }
    int newBottomInset = MediaQuery.of(context).viewInsets.bottom.toInt();
    if (newBottomInset > 40 && newBottomInset > _lastBottomInset) {
      Future.delayed(Duration(milliseconds: 500), () {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      });
      _lastBottomInset = newBottomInset;
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: "Chat",
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    FocusScope.of(context).requestFocus(new FocusNode()),
                child: ListView(
                  controller: _scrollController,
                  children: <Widget>[] +
                      widget.chatState.messages
                          .map((message) => ChatMessageWidget(message))
                          .toList() +
                      [SizedBox(height: 16)],
                ),
              ),
            ),
            CreateMessageWidget(
              onMessageSent: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

enum WidgetChangeApplyCycle { IDLE, REQUESTED, BUILT }

class CreateMessageWidget extends StatefulWidget {
  final void Function(String, void Function(bool)) onMessageSent;

  const CreateMessageWidget({Key? key, required this.onMessageSent})
      : super(key: key);

  @override
  _CreateMessageWidgetState createState() => _CreateMessageWidgetState();
}

class _CreateMessageWidgetState extends State<CreateMessageWidget> {
  TextEditingController _textEditCtrl = TextEditingController();
  late FocusNode _textFieldFocus;

  bool _sendingMessage = false;

  bool _errorSending = false;

  void sendMessage(bool requestFocus) {
    if (this._textEditCtrl.text.trim() == "") {
      return;
    }
    setState(() => _sendingMessage = true);
    widget.onMessageSent(this._textEditCtrl.text, (success) {
      _errorSending = !success;
      _sendingMessage = false;
      this._textEditCtrl.text = "";
      if (mounted) setState(() {});
    });
    if (requestFocus) {
      Future.delayed(Duration(milliseconds: 700 ~/ 6),
          () => _textFieldFocus.requestFocus());
    }
  }

  @override
  void initState() {
    super.initState();
    _textFieldFocus = FocusNode();
  }

  @override
  void dispose() {
    _textFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        // border: Border(top: BorderSide()),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
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
              focusNode: _textFieldFocus,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => sendMessage(true),
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
              onTap: () => sendMessage(true),
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
  final Radius borderRadius = Radius.circular(8);

  ChatMessageWidget(this.message, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String senderStr = "Anonymous";
    if (message.sender is SenderMe) {
      senderStr = "You";
    } else if (message.sender is SenderOther &&
        (message.sender as SenderOther).name != null) {
      senderStr = "Player \"${(message.sender as SenderOther).name!}\"";
    }
    return Container(
      // height: 60,
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: (message.sender is SenderMe)
            ? Border(bottom: BorderSide(color: Colors.black26))
            : null,
        color: (message.sender is SenderMe)
            ? Colors.grey[100]
            : Colors.transparent,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                    border: (message.sender is SenderMe)
                        ? Border(bottom: BorderSide(color: Colors.black45))
                        : null),
                child: Text(
                  senderStr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,

                    // decoration:  TextDecoration.underline
                    //     : null,
                  ),
                ),
              ),
            ],
          ),
          // message.mine ? Expanded(child: SizedBox()) : SizedBox(),
          Container(
            margin: EdgeInsets.fromLTRB(8, 6, 8, 12),
            // decoration: BoxDecoration(
            //     color: Colors.grey[100],

            /*borderRadius: message.mine
                    ? BorderRadius.only(
                        topLeft: borderRadius,
                        bottomRight: borderRadius,
                        bottomLeft: borderRadius)
                    : BorderRadius.only(
                        topRight: borderRadius,
                        bottomRight: borderRadius,
                        bottomLeft: borderRadius)),*/
            child: Text(message.content),
          ),
        ],
      ),
    );
  }
}
