import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/models/online/game_states/playing.dart';
import 'package:four_in_a_row/play/widgets/common/board.dart';
import 'package:four_in_a_row/play/widgets/common/winner_overlay.dart';
import 'package:four_in_a_row/util/toast.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:provider/provider.dart';

class PlayingViewer extends AbstractGameStateViewer {
  final PlayingState _playingState;

  const PlayingViewer(this._playingState, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Toast? toast;
    if (_playingState.toastState != null) {
      toast = Toast(_playingState.toastState!);
    }
    var _field = _playingState.field;

    WinDetails? winDetails;
    bool waitingToPlayAgain = false;
    if (_field is FieldFinished) {
      waitingToPlayAgain = _field.waitingToPlayAgain;
      winDetails = _field.winDetails;
    }

    Player turn = _playingState.me;
    if (_field is FieldPlaying) {
      turn = _field.turn;
    }

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OnlineTurnIndicator(turn == _playingState.me),
              Expanded(
                child: Center(
                  child: Board(_playingState.field,
                      dropChip: _playingState.dropChip),
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
        _playingState.opponentInfo.user != null
            ? OpponentInfoWidget(_playingState.opponentInfo.user!)
            : SizedBox(),
        Positioned(
          bottom: 32,
          right: 32,
          child: ConnectionIndicator(_playingState.connectionLost),
        ),
        WinnerOverlay(
          winDetails,
          useColorNames: false,
          onTap: () {
            if (_playingState.opponentInfo.hasLeft) {
              Navigator.of(context).pop();
            } else {
              _playingState.playAgain();
            }
          },
          board: Board(_playingState.field, dropChip: (_) {}),
          ranked: _playingState.opponentInfo.user != null, // TODO rework
          bottomText: _playingState.opponentInfo.hasLeft
              ? 'Tap to leave'
              : waitingToPlayAgain
                  ? 'Waiting for opponent...'
                  : 'Tap to play again!',
        ),
        toast ?? SizedBox(),
      ],
    );
  }
}

class OpponentInfoWidget extends StatefulWidget {
  final PublicUser user;

  OpponentInfoWidget(this.user);

  @override
  _OpponentInfoState createState() => _OpponentInfoState();
}

enum AddedState { NotAdded, Adding, Added }

class _OpponentInfoState extends State<OpponentInfoWidget> {
  AddedState added = AddedState.NotAdded;
  bool errorAdding = false;

  @override
  void initState() {
    super.initState();
    if (widget.user.isFriend == true) {
      added = AddedState.Added;
    }
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
                      widget.user.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'RobotoSlab',
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "${widget.user.gameInfo.skillRating} SR",
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
                        : added == AddedState.Adding
                            ? CircularProgressIndicator()
                            : added == AddedState.Added
                                ? Icon(Icons.check)
                                : Icon(Icons.add),
                    onPressed:
                        added == AddedState.NotAdded && errorAdding == false
                            ? () {
                                // if () {
                                setState(() => added = AddedState.Adding);
                                context
                                    .read<UserInfo>()
                                    .addFriend(widget.user.id)
                                    .then((ok) => setState(() {
                                          if (ok) {
                                            added = AddedState.Added;
                                          } else {
                                            errorAdding = true;
                                            added = AddedState.NotAdded;
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

class OnlineTurnIndicator extends StatelessWidget {
  const OnlineTurnIndicator(
    this.myTurn, {
    Key? key,
  }) : super(key: key);

  final bool myTurn;

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
  late AnimationController breatheCtrl;
  late AnimationController turnRed;
  late Animation<Color> colorAnim;
  late Animation<double> breatheAnim;
  Timer? delayedExecution;

  @override
  void initState() {
    super.initState();
    turnRed =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    colorAnim =
        Tween<Color>(begin: Colors.green, end: Colors.red).animate(turnRed);

    breatheCtrl =
        AnimationController(vsync: this, duration: Duration(seconds: 2))
          // brea
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed &&
                turnRed.status != AnimationStatus.completed) {
              breatheCtrl.reverse();
            } else if (status == AnimationStatus.dismissed) {
              breatheCtrl.forward();
            }
          });
    breatheAnim = Tween<double>(begin: 0.6, end: 0.9)
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
    return AnimatedBuilder(
      animation: colorAnim,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(100)),
              color: colorAnim.value,
            ),
            width: 24,
            height: 24,
          ),
          AnimatedBuilder(
            animation: breatheAnim,
            builder: (_, child) => Opacity(
              opacity: breatheAnim.value,
              child: Transform.scale(scale: breatheAnim.value, child: child),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(100)),
                color: Colors.white30,
              ),
              width: 24,
              height: 24,
            ),
            // child:
          ),
        ],
      ),
    );
  }
}
