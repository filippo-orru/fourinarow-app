import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
// import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:http/http.dart' as http;
import 'package:four_in_a_row/util/constants.dart' as constants;

import '../../game_logic/player.dart';
import '../../common/board.dart';
import '../../common/winner_overlay.dart';
import '../online_field.dart';
import 'package:four_in_a_row/inherit/connection/messages.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/util/toast.dart';
import 'package:four_in_a_row/util/vibration.dart';

import 'all.dart';

class Playing extends GameState {
  final bool myTurn;
  final String opponentId;

  Playing(this.myTurn, this.opponentId, StreamController<PlayerMessage> p,
      StreamController<ServerMessage> s, CGS change)
      : super(p, s, change);

  get build => PlayingWidget(
        this.myTurn,
        this.opponentId,
        super.pMsgCtrl,
        super.sMsgCtrl,
        super.changeState,
      );

  dispose() {}
}

class PlayingWidget extends StatefulWidget {
  final bool myTurn;
  final String opponentId;
  final StreamController<PlayerMessage> pMsgCtrl;
  final StreamController<ServerMessage> sMsgCtrl;
  final CGS changeState;

  PlayingWidget(this.myTurn, this.opponentId, this.pMsgCtrl, this.sMsgCtrl,
      this.changeState);

  @override
  createState() => _PlayingState(myTurn, opponentId);
}

class _PlayingState extends State<PlayingWidget> {
  final String opponentId;
  OnlineField field;
  bool awaitingConfirmation;
  bool leaving = false;
  Toast toast;
  Timer toastTimer;
  BuildContext context;
  PublicUser opponentInfo;
  bool opponentLeft = false;

  StreamSubscription sMsgListen;
  StreamSubscription pMsgListen;

  _PlayingState(bool myTurn, [this.opponentId]) {
    field = OnlineField();
    field.turn = myTurn ? field.me : field.me.other;
    if (opponentId != null) {
      _loadOpponentInfo();
    }
  }

  void handleServerMessage(ServerMessage msg) {
    if (msg is MsgPlaceChip) {
      setState(() {
        this._dropChipNamed(msg.row, field.me.other);
      });
    } else if (msg is MsgGameStart) {
      this._reset(msg.myTurn);
    } else if (msg.isConfirmation) {
      setState(() => awaitingConfirmation = false);
    } else if (msg is MsgOppLeft) {
      setState(() => opponentLeft = true);
      if (field.checkWin() == null) {
        this.leaving = true;
        showPopup("Opponent left", angery: true);
        Future.delayed(this.toast.duration * 0.6, () => this.pop());
      } else {
        showPopup("Opponent left");
      }
      // return Idle(widget.sink);
    } else if (msg is MsgLobbyClosing && !this.leaving && !this.opponentLeft) {
      widget.changeState(Error(
          LobbyClosed(), widget.pMsgCtrl, widget.sMsgCtrl, widget.changeState));
    } else if (msg is MsgError && msg.maybeErr == MsgErrorType.NotInLobby) {
      widget.changeState(Error(
          LobbyClosed(), widget.pMsgCtrl, widget.sMsgCtrl, widget.changeState));
    }
  }

  void handlePlayerMessage(PlayerMessage msg) {
    if (msg is PlayerMsgPlayAgain) {
      setState(() => field.waitingToPlayAgain = true);
      _loadOpponentInfo();
    } else if (msg is PlayerMsgPlaceChip) {
      setState(() => awaitingConfirmation = true);
    } else if (msg is PlayerMsgLeave) {
      leaving = true;
    }
  }

  void _loadOpponentInfo() async {
    http.Response response =
        await http.get("${constants.URL}/api/users/$opponentId");
    if (response.statusCode == 200) {
      this.opponentInfo = PublicUser.fromMap(jsonDecode(response.body));
      if (UserinfoProvider.of(context)
          .user
          .friends
          .any((friend) => friend.id == opponentInfo.id)) {
        opponentInfo.isFriend = true;
      }
    }
    setState(() {});
  }

  void pop() {
    if (this.context != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  void showPopup(String text, {bool angery = false}) {
    setState(() => this.toast = Toast(text, angery: angery));
    toastTimer?.cancel();
    toastTimer = Timer(this.toast.duration, () => this.toast = null);
  }

  void _reset(bool myTurn) {
    setState(() {
      field = OnlineField();
      field.turn = myTurn ? field.me : field.me.other;
    });
  }

  void _dropChipNamed(int column, Player player) {
    setState(() {
      field.dropChipNamed(column, player);
    });
    var winDetails = field.checkWin();
    if (winDetails?.winner == field.me) {
      Vibrations.win();
    } else if (winDetails?.winner == field.me.other) {
      Vibrations.loose();
    }
    // showPopup('SR: $field');
  }

  void _dropChip(int column) {
    if (field.turn == field.me) {
      this._dropChipNamed(column, field.me);

      widget.pMsgCtrl.add(PlayerMsgPlaceChip(column));
    }
  }

  @override
  void initState() {
    super.initState();
    sMsgListen = widget.sMsgCtrl.stream.listen(handleServerMessage);
    pMsgListen = widget.pMsgCtrl.stream.listen(handlePlayerMessage);
  }

  @override
  void dispose() {
    sMsgListen.cancel();
    pMsgListen.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OnlineTurnIndicator(field.turn == field.me, awaitingConfirmation),
              Expanded(
                child: Center(
                  child: Board(field, dropChip: _dropChip),
                ),
              ),
              // Align(
              //   alignment: Alignment.centerRight,
              //   child: LeaveOnlineButton(() {}),
              // ),
              // LeaveOnlineButton(() => {}),
            ],
          ),
        ),
        opponentInfo != null ? OpponentInfo(this.opponentInfo) : SizedBox(),
        Positioned(
          bottom: 32,
          right: 32,
          child: ConnectionIndicator(awaitingConfirmation),
        ),
        WinnerOverlay(
          field.checkWin(),
          useColorNames: false,
          onTap: () {
            if (!opponentLeft) {
              widget.pMsgCtrl.add(PlayerMsgPlayAgain());
            } else {
              Navigator.of(context).pop();
            }
          },
          board: Board(field, dropChip: (_) {}),
          ranked: opponentInfo != null,
          bottomText: opponentLeft
              ? "Tap to leave"
              : field.waitingToPlayAgain ? "Waiting for opponent..." : null,
        ),
        this.toast ?? SizedBox(),
      ],
    );
  }
}

class OpponentInfo extends StatefulWidget {
  OpponentInfo(this.opponentInfo);

  final PublicUser opponentInfo;

  @override
  _OpponentInfoState createState() => _OpponentInfoState();
}

class _OpponentInfoState extends State<OpponentInfo> {
  bool added = false;
  bool errorAdding = false;

  @override
  void initState() {
    super.initState();
    added = widget.opponentInfo.isFriend;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 32,
      right: 0,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              // color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            // width: 100,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // Text(
                    //   "Enemy".toUpperCase(),
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     letterSpacing: 0.5,
                    //     color: Colors.white,
                    //   ),
                    // ),
                    SizedBox(width: 6),
                    Text(
                      widget.opponentInfo.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'RobotoSlab',
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "${widget.opponentInfo.gameInfo.skillRating} SR",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'RobotoSlab',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 6),
                IconButton(
                    icon: errorAdding
                        ? Icon(Icons.close)
                        : added == null
                            ? CircularProgressIndicator()
                            : added == true
                                ? Icon(Icons.check)
                                : Icon(Icons.add),
                    onPressed: added == false && errorAdding == false
                        ? () {
                            // if () {
                            setState(() => added = null);
                            UserinfoProvider.of(context)
                                .addFriend(widget.opponentInfo.id)
                                .then((ok) => setState(() {
                                      if (ok) {
                                        added = true;
                                      } else {
                                        errorAdding = true;
                                        added = false;
                                      }
                                    }));
                            // }
                          }
                        : null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class LeaveOnlineButton extends StatelessWidget {
//   LeaveOnlineButton(this._fieldReset);

//   final Function _fieldReset;

//   @override
//   Widget build(BuildContext context) {
//     // final borderColor = _turn.color().withOpacity(0.5);
//     return BorderButton(
//       "Reset",
//       icon: Icons.refresh,
//       callback: _fieldReset,
//       borderColor: Colors.black26,
//     );
//   }
// }

// class OpponentJoined extends GameState {
//   @override
//   GameState handleMessage(ServerMessage msg) {
//     super.handleMessage(msg);
//     return null;
//     // TODuO: implement handleMessage
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Text("Opponent has joined!");
//   }
// }
class OnlineTurnIndicator extends StatelessWidget {
  const OnlineTurnIndicator(
    this.myTurn,
    this.awaitingConfirmation, {
    Key key,
  }) : super(key: key);

  final bool myTurn;
  final bool awaitingConfirmation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 32),
      width: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        // alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 170),
            switchInCurve: Curves.easeInOutExpo,
            switchOutCurve: Curves.easeInOutExpo,
            // layoutBuilder: (Widget child, List<Widget> prevChildren) {
            //   return child;
            // },
            transitionBuilder: (Widget child, Animation<double> anim) {
              final begin =
                  child.key == ValueKey(myTurn) ? Offset(1, 0) : Offset(-1, 0);
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(begin: begin, end: Offset(0, 0))
                      .animate(anim),
                  child: child,
                ),
              );
            },
            child: Text(
              myTurn ? "Your turn" : "Opponent's turn",
              key: ValueKey(myTurn),
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Player.values[myTurn ? 0 : 1].color()),
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionIndicator extends StatefulWidget {
  final bool awaitingConfirmation;

  ConnectionIndicator(this.awaitingConfirmation);

  @override
  _ConnectionIndicatorState createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator>
    with TickerProviderStateMixin {
  AnimationController breatheCtrl;
  AnimationController turnRed;
  Animation<Color> colorAnim;
  Animation<double> opacityAnim;
  Timer delayedExecution;

  @override
  void initState() {
    super.initState();
    turnRed =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    colorAnim =
        Tween<Color>(begin: Colors.green, end: Colors.red).animate(turnRed);

    breatheCtrl =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          // brea
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed &&
                turnRed.status != AnimationStatus.completed) {
              breatheCtrl.reverse();
            } else if (status == AnimationStatus.dismissed) {
              breatheCtrl.forward();
            }
          });
    opacityAnim = Tween<double>(begin: 0.6, end: 1)
        .chain(CurveTween(curve: Curves.easeInOutSine))
        .animate(breatheCtrl);
    breatheCtrl.forward();
  }

  @override
  void dispose() {
    turnRed.dispose();
    breatheCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.awaitingConfirmation == true) {
      if (oldWidget.awaitingConfirmation != true) {
        this.delayedExecution = Timer(Duration(milliseconds: 500), () {
          if (this.mounted && widget.awaitingConfirmation) {
            turnRed.forward();
          }
        });
      }
    } else {
      this.turnRed.reverse();
      // this.breatheCtrl.forward();
      this.delayedExecution?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacityAnim,
      child: AnimatedBuilder(
        animation: colorAnim,
        builder: (ctx, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(100)),
            color: colorAnim.value,
          ),
          width: 18,
          height: 18,
        ),
        // child:
      ),
    );
  }
}
