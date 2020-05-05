import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/models/user.dart';
import 'package:four_in_a_row/util/toast.dart';

import '../../play_online.dart';
import 'all.dart';
import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/play/online/game_states/all.dart' as game_state;
import 'package:four_in_a_row/play/online/messages.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ConnStateConnected extends ConnState {
  ConnStateConnected(
    this.req, {
    @required this.changeStateCallback,
    @required this.userInfo,
    Key key,
  }) : super(key: key);

  final Function(ConnState) changeStateCallback;
  final OnlineRequest req;
  final UserinfoProviderState userInfo;

  createState() => ConnStateConnectedState(req, this.userInfo);

  // static IOWebSocketChannel createConnection() {
  //   return
  // }
}

class ConnStateConnectedState extends State<ConnStateConnected> {
  bool _awaitingConfirmation = false;

  IOWebSocketChannel _connection;
  StreamController<PlayerMessage> _outgoingCtrl;
  Sink<PlayerMessage> _outgoing;
  Timer delayedExecution;
  VoidCallback awaitingLogin;
  Toast popup;

  game_state.GameState gameState;
  // Stream<ServerMessage> get stream => _incoming;
  StreamSink<PlayerMessage> get sink => _outgoing;

  ConnStateConnectedState(OnlineRequest req, UserinfoProviderState userInfo) {
    this._connection = IOWebSocketChannel.connect("wss://fourinarow.ml/game/",
        pingInterval: Duration(seconds: 1));

    this._outgoing = _mapSink(_connection.sink);
    // this._incoming =
    _mapStream(_connection.stream);
    this.gameState = game_state.Idle(_outgoing);
    if (userInfo.loggedIn) {
      this.sink.add(PlayerMsgLogin(userInfo.username, userInfo.password));
      this.awaitingLogin = () => _requestGame(req);
    } else {
      _requestGame(req);
    }
  }

  void showPopup(String text) {
    this.popup = Toast(text);
    Future.delayed(this.popup.duration, () => this.popup = null);
  }

  void _requestGame(OnlineRequest req) {
    if (req is ORqLobby) {
      this.sink?.add(req.lobbyCode == null
          ? PlayerMsgLobbyRequest()
          : PlayerMsgLobbyJoin(req.lobbyCode));
    } else if (req is ORqWorldwide) {
      this.sink?.add(PlayerMsgWorldwideRequest());
    }
  }

  // Stream<ServerMessage>
  void _mapStream(Stream<dynamic> wsStream) {
    // return
    wsStream.listen((msg) {
      if (msg is String) {
        print(">> \"$msg\"");
        var onlineMsg = OnlineMessageExt.parse(msg);
        if (awaitingLogin != null) {
          if (onlineMsg is MsgOkay) {
            awaitingLogin();
            showPopup("Logged in as ${widget.userInfo.username}.");
          } else if (onlineMsg is MsgError) {
            if (onlineMsg.maybeErr == MsgErrorType.IncorrectCredentials) {
              widget.userInfo.logOut();
              showPopup("You have been logged out.");
            } else if (onlineMsg.maybeErr == MsgErrorType.AlreadyLoggedIn) {
              awaitingLogin();
              showPopup("Logged in as ${widget.userInfo.username}.");
            } else {
              setState(() {
                gameState = gameState?.handleMessage(onlineMsg) ?? gameState;
              });
            }
          }
          awaitingLogin = null;
          this._awaitingConfirmation = false;
          this.delayedExecution?.cancel();
          return;
        }

        if (onlineMsg is MsgOkay ||
            onlineMsg is MsgLobbyResponse ||
            onlineMsg is MsgError) {
          this._awaitingConfirmation = false;
          this.delayedExecution?.cancel();
        }
        if (super.mounted) {
          setState(() {
            gameState = gameState?.handleMessage(onlineMsg) ?? gameState;
          });
        } else {
          this.dispose();
        }
        return;
      }
      // else {
      //   print("Received other message: " + msg);
      // }
      return;
    }, onError: (dynamic err) {
      print(">> #ERR# \"${err.toString()}\"");
      var inner = err.inner.inner;
      if (inner is SocketException) {
        if (inner.osError?.errorCode == 7) {
          gameState = game_state.Error(game_state.NoConnection(), this.sink);

          return;
        }
      }
      this.delayedExecution?.cancel();
      gameState = game_state.Error(game_state.Internal(false), this.sink);
    });
    // .asBroadcastStream();
  }

  Sink<PlayerMessage> _mapSink(WebSocketSink wsSink) {
    this._outgoingCtrl = StreamController<PlayerMessage>.broadcast();
    this._outgoingCtrl.stream.listen((pmsg) {
      _awaitingConfirmation = true;
      this.delayedExecution = Timer(Duration(seconds: 8), () {
        if (this.mounted && this._awaitingConfirmation) {
          if (!(this.gameState is game_state.Error)) {
            setState(() {
              this.gameState =
                  game_state.Error(game_state.Timeout(), this.sink);
            });
            print("Confirmation timeout!");
          }
        }
      });

      setState(() {
        this.gameState = gameState?.handlePlayerMessage(pmsg) ?? gameState;
      });
      String msg = pmsg.serialize();
      print("<< \"$msg\"");
      wsSink.add(msg);
    });
    return this._outgoingCtrl.sink;
  }

  @override
  void initState() {
    super.initState();
    gameState = game_state.Idle(sink);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
            duration: Duration(milliseconds: 200), child: this.gameState),
        this.popup ?? SizedBox(),
      ],
    );
  }

  @override
  void dispose() {
    print("disposed connection");
    _connection.sink.close();
    _outgoing.close();
    _outgoingCtrl.close();
    _connection = null;
    _outgoing = null;
    _outgoingCtrl = null;
    super.dispose();
  }
}
