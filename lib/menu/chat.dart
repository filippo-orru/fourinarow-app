import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/inherit/chat.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/util/widget_extensions.dart';
// ignore: import_of_legacy_library_into_null_safe
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

class _ChatScreenInternalState extends State<_ChatScreenInternal>
    with SingleTickerProviderStateMixin {
  late final Tween<Offset> connectionSlideTween;

  ScrollController _scrollController = new ScrollController();
  bool _scrollToBottomOnNextBuild = false;
  int _lastBottomInset = 0;
  // Alignment smoothKeyboardAligment = Alignment.center;
  // StreamSubscription? smoothKeyboardAligmentStream;
  bool _retrying = false;
  // ChatState _chatState = context.watch ChatState

  void _sendMessage(String msg) {
    _scrollToBottom();
    msg = msg.trim();
    widget.chatState.sendMessage(msg);
  }

  void _scrollToBottom() {
    _scrollToBottomOnNextBuild = true;
    Future.delayed(Duration.zero, () {
      setState(() {});
    });
  }

  void _retryConnecting() async {
    setState(() {
      _retrying = true;
    });
    await Future.delayed(
      Duration(milliseconds: 2800),
    );
    if (mounted)
      setState(() {
        _retrying = false;
      });
  }

  void _resendMessage(ChatMessage msg) {
    widget.chatState.resendMessage(msg);
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
  void initState() {
    super.initState();
    connectionSlideTween = Tween(begin: Offset(0, 1), end: Offset(0, 0));
    widget.chatState.startViewing();

    // smoothKeyboardAligmentStream =
    //     KeyboardVisibilityController().onChange.listen((visible) {
    //   setState(() {
    //     smoothKeyboardAligment =
    //         visible ? Alignment.topCenter : Alignment.center;
    //   });
    // });
  }

  @override
  void dispose() {
    widget.chatState.stopViewing();
    // smoothKeyboardAligmentStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);

    if (widget.chatState.messages.isNotEmpty) {
      if (_scrollToBottomOnNextBuild) {
        _scrollToBottomOnNextBuild = false;
        Future.delayed(Duration(milliseconds: 500 ~/ 6), () {
          _scrollController.animateTo(
              _scrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut);
        });
      }
      int newBottomInset = MediaQuery.of(context).viewInsets.bottom.toInt();
      if (newBottomInset > 40 && newBottomInset > _lastBottomInset) {
        Future.delayed(Duration(milliseconds: 500), () {
          _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut);
        });
        _lastBottomInset = newBottomInset;
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: FiarAppBar(
        title: "Chat",
        threeDots: [
          FiarThreeDotItem(
            'Feedback',
            onTap: () {
              showFeedbackDialog(context);
            },
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: mediaQuery.viewInsets,
        constraints: BoxConstraints.expand(),
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: widget.chatState.messages.isEmpty
                      ? Container(
                          child: Center(
                              child: Text('No messages yet!',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                  ))),
                        )
                      : ScrollConfiguration(
                          behavior: MyScrollBehavior(
                            color: Colors.blueAccent.withOpacity(0.1),
                          ),
                          child: ListView(
                              reverse: true,
                              controller: _scrollController,
                              children: <Widget>[
                                    // AnimatedContainer(
                                    //     duration: Duration(milliseconds: 120),
                                    //     height: max(
                                    //         0,
                                    //         mediaQuery.size.height -
                                    //             mediaQuery.viewInsets.bottom -
                                    //             180 -
                                    //             widget.chatState.messages
                                    //                     .length *
                                    //                 88)),
                                    Selector<ServerConnection, bool>(
                                      selector: (_, serverConnection) =>
                                          serverConnection.connected,
                                      builder: (_, isConnected, __) => SizedBox(
                                          height: isConnected ? 16 : 72),
                                    ),
                                  ] +
                                  widget.chatState.messages.reversed
                                      .map<Widget>((message) =>
                                          ChatMessageWidget(message,
                                              resendMessage: () =>
                                                  _resendMessage(message)))
                                      .toList()),
                        ),
                ),
                Selector<ServerConnection, bool>(
                  selector: (_, serverConnection) => serverConnection.connected,
                  builder: (_, isConnected, __) => CreateMessageWidget(
                    connected: isConnected,
                    onMessageSent: _sendMessage,
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Selector<ServerConnection, bool>(
                selector: (_, serverConnection) => serverConnection.connected,
                builder: (_, isConnected, __) => AnimatedSwitcher(
                  duration: Duration(milliseconds: 150),
                  transitionBuilder: (child, anim) {
                    return SlideTransition(
                      position: connectionSlideTween.animate(anim),
                      child: child,
                    );
                    //  Transform.translate(
                    //     offset: Offset(0, anim.value), child: child);
                  },
                  child: isConnected
                      ? SizedBox()
                      : GestureDetector(
                          onTap: _retryConnecting,
                          child: Container(
                            width: double.infinity,
                            margin: EdgeInsets.all(6),
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning, color: Colors.white54),
                                    SizedBox(width: 16),
                                    Text(
                                      'No Connection',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                                    SizedBox(width: 16),
                                    Icon(Icons.warning, color: Colors.white54),
                                  ],
                                ),
                                SizedBox(height: 8),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: 18,
                                    minWidth: 0,
                                  ),
                                  child: _retrying
                                      ? Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                              Container(
                                                  height: 18,
                                                  width: 18,
                                                  child:
                                                      CircularProgressIndicator()),
                                              SizedBox(width: 12),
                                              Text(
                                                'Retrying...',
                                                style: TextStyle(
                                                    color: Colors.grey[300],
                                                    fontSize: 14),
                                              )
                                            ])
                                      : Text(
                                          'You cannnot send or receive messages. Tap to retry.',
                                          style: TextStyle(
                                              color: Colors.grey[300],
                                              fontSize: 14),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum WidgetChangeApplyCycle { IDLE, REQUESTED, BUILT }

class CreateMessageWidget extends StatefulWidget {
  final void Function(String) onMessageSent;
  final bool connected;

  const CreateMessageWidget(
      {Key? key, required this.connected, required this.onMessageSent})
      : super(key: key);

  @override
  _CreateMessageWidgetState createState() => _CreateMessageWidgetState();
}

class _CreateMessageWidgetState extends State<CreateMessageWidget> {
  TextEditingController _textEditCtrl = TextEditingController();

  bool get enabled => widget.connected && _textEditCtrl.text.trim().isNotEmpty;

  void sendMessage(bool requestFocus) {
    if (this._textEditCtrl.text.trim() == "") {
      return;
    }
    widget.onMessageSent(this._textEditCtrl.text);
    _textEditCtrl.clear();
  }

  Widget? buildCounter(BuildContext context,
          {required int currentLength,
          required int? maxLength,
          required bool isFocused}) =>
      null;

  @override
  void initState() {
    _textEditCtrl.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom < 12 ? 12 : 4),
      // height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.max, children: [
            Expanded(child: SizedBox()),
            // AnimatedSwitcher(
            //   duration: Duration(milliseconds: 80),
            //   switchInCurve: Curves.easeOutQuad,
            //   child: _textEditCtrl.text.isEmpty
            //       ? SizedBox() :
            // TweenAnimationBuilder(
            //   tween: Tween<double>(
            //       begin: 0, end: _textEditCtrl.text.isEmpty ? 0.0 : 0.0),
            //   duration: Duration(milliseconds: 190),
            //   curve: Curves.easeOut,
            //   builder: (_, double val, child) => SizedOverflowBox(
            //     alignment: Alignment.centerRight,
            //     size: Size(val, 0),
            //     child: child,
            //   ),
            //   child:
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: () {
                  sendMessage(false);
                },
                child: AnimatedContainer(
                  // constraints: BoxConstraints.expand(width: 48),
                  duration: Duration(milliseconds: 90),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: enabled
                        ? Colors.blueAccent.withOpacity(0.9)
                        : Colors.grey[300],
                  ),
                  child: Transform.translate(
                    offset: Offset(1.5, 0),
                    child: TweenAnimationBuilder<Color>(
                        tween: MyColorTween(
                            begin: Colors.grey[600],
                            end: this.enabled
                                ? Colors.white.withOpacity(0.95)
                                : Colors.grey[600]!),
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        builder: (_, Color color, child) => Icon(
                              Icons.send,
                              color: color,
                            )),
                  ),
                ),
              ),
              // ),
              // ),
            ),
            SizedBox(width: 8),
          ]),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.grey[200]!,
                    // border: Border.all(
                    // color: Colors.blueAccent.withOpacity(0.5), width: 2),
                  ),
                  child: TextField(
                    controller: _textEditCtrl,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    onEditingComplete: () => sendMessage(true),
                    enabled: widget.connected,
                    maxLength: 1000,
                    buildCounter: buildCounter,
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        letterSpacing: 0.15,
                        // fontStyle: FontStyle.italic,
                      ),
                      hintText: 'Chat with other players…',
                      border: InputBorder.none,
                      counterText: null,
                      counterStyle: null,
                    ),
                    // style: TextStyle(
                    //   color: this._sendingMessage ? Colors.black54 : Colors.black,
                    // ),
                    maxLines: 1,
                  ),
                ),
              ),
              TweenAnimationBuilder(
                  tween: Tween<double>(
                      begin: 0,
                      end: _textEditCtrl.text.isEmpty ? 0.0 : 48.0 + 8),
                  duration: Duration(milliseconds: 190),
                  curve: Curves.easeOut,
                  builder: (_, double val, child) => SizedOverflowBox(
                        alignment: Alignment.centerRight,
                        size: Size(val, 0),
                        child: child,
                      ),
                  child: SizedBox()),
              SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Radius borderRadius = Radius.circular(8);
  final VoidCallback resendMessage;

  ChatMessageWidget(this.message, {required this.resendMessage, Key? key})
      : super(key: key);

  Widget buildMessageStateIndicator() {
    switch (message.state) {
      case ConfirmationState.Sent:
        return Transform.scale(scale: 0.5, child: CircularProgressIndicator());
      case ConfirmationState.Received:
        return Icon(
          Icons.check,
          size: 18,
          color: Colors.grey,
          key: ValueKey(1),
        );
      case ConfirmationState.Error:
        return Icon(
          Icons.warning_outlined,
          size: 18,
          color: Colors.red[900],
          key: ValueKey(2),
        );
      case ConfirmationState.Seen:
        return Stack(
          key: ValueKey(3),
          children: [
            Icon(
              Icons.check,
              color: Colors.blueAccent,
              size: 18,
            ),
            Transform.translate(
              offset: Offset(6.5, 0),
              child: Icon(
                Icons.check,
                color: Colors.blueAccent.withOpacity(0.6),
                size: 18,
              ),
            ),
          ],
        );
      default:
        return SizedBox();
    }
  }

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
      decoration: BoxDecoration(
          // border: (message.sender is SenderMe)
          //     ? Border(bottom: BorderSide(color: Colors.black26))
          //     : null,
          // color: (message.sender is SenderMe)
          //     ? Colors.grey[100]
          //     : Colors.transparent,
          ),

      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          splashColor: Colors.blueAccent.withOpacity(0.35),
          highlightColor: Colors.blueAccent.withOpacity(0.35),
          onTap: () {
            if (message.state == ConfirmationState.Error) {
              resendMessage();
            }
          },
          onLongPress: () {
            Clipboard.setData(new ClipboardData(text: message.content));
          },
          child: Padding(
            padding: EdgeInsets.all(16),
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
                              ? Border(
                                  bottom: BorderSide(color: Colors.black45))
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
                  child: Row(
                    children: [
                      Expanded(child: Text(message.content)),
                      message.sender is SenderMe
                          ? Container(
                              height: 24,
                              width: 24,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: Duration(milliseconds: 350),
                                  child: buildMessageStateIndicator(),
                                ),
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                ),
                message.state == ConfirmationState.Error
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Text('Failed to send, tap to try again.'))
                    : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
