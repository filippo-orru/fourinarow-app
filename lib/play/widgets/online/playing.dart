import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/models/online/game_states/playing.dart';
import 'package:four_in_a_row/play/widgets/common/board.dart';
import 'package:four_in_a_row/play/widgets/common/winner_overlay.dart';
import 'package:four_in_a_row/util/toast.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:provider/provider.dart';

class PlayingViewer extends AbstractGameStateViewer {
  final PlayingState _playingState;

  PlayingViewer(this._playingState, {Key? key}) : super(key: key) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
  }

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
        Positioned(
          left: 0,
          bottom: 0,
          right: 0,
          child: _BottomSheetWidget(_playingState.opponentInfo.user),
        ),
        Positioned(
          top: 32 + 16,
          left: 24,
          child: ConnectionIndicator(_playingState.connectionLost),
        ),
        Positioned(
          top: 32 + 16,
          right: 24,
          child: _ThreeDotMenu(),
        ),
        WinnerOverlay(
          winDetails,
          playerNames: (p) => p.playerWord,
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

class _ThreeDotMenu extends StatefulWidget {
  @override
  _ThreeDotMenuState createState() => _ThreeDotMenuState();
}

class _ThreeDotMenuState extends State<_ThreeDotMenu> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(color: Colors.black26),
        ],
      ),
      child: FiarPopupMenuButton(
        [
          FiarThreeDotItem(
            'Feedback',
            onTap: () => showFeedbackDialog(context),
          ),
          FiarThreeDotItem('Leave', onTap: () {
            Navigator.of(context).pop();
          }),
        ],
      ),
    );
  }
}

class _BottomSheetWidget extends StatefulWidget {
  final PublicUser? user;

  _BottomSheetWidget(this.user);

  @override
  _BottomSheetState createState() => _BottomSheetState();
}

enum AddedState { NotAdded, Adding, Added }

class _BottomSheetState extends State<_BottomSheetWidget> {
  AddedState added = AddedState.NotAdded;
  bool errorAdding = false;

  bool reactionPickerOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.user?.isFriend == true) {
      added = AddedState.Added;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10)
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: reactionPickerOpen
                    ? SizedBox()
                    : Row(
                        children: [
                          PlayerIcon(widget.user),
                          SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                widget.user?.name ?? "Guest",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'RobotoSlab',
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 6),
                              widget.user != null
                                  ? Text(
                                      "${widget.user!.gameInfo.skillRating} SR",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontFamily: 'RobotoSlab',
                                        color: Colors.black54,
                                      ),
                                    )
                                  : SizedBox(),
                            ],
                          ),
                        ],
                      ),
              ),
              ReactionPicker(
                open: reactionPickerOpen,
                onOpen: () {
                  setState(() => reactionPickerOpen = true);
                },
                onClose: () {
                  setState(() => reactionPickerOpen = false);
                },
                onChoose: (reaction) {
                  print("chose reaction: $reaction");
                },
              ),
            ],
          ),
        ),
      ),
    );

    // IconButton(
    //     icon: errorAdding
    //         ? Icon(Icons.close)
    //         : added == AddedState.Adding
    //             ? CircularProgressIndicator()
    //             : added == AddedState.Added
    //                 ? Icon(Icons.check)
    //                 : Icon(Icons.add),
    //     onPressed: () {
    //       if (added == AddedState.NotAdded && errorAdding == false) {
    //         setState(() => added = AddedState.Adding);
    //         context
    //             .read<UserInfo>()
    //             .addFriend(widget.user!.id)
    //             .then((ok) => setState(() {
    //                   if (ok) {
    //                     added = AddedState.Added;
    //                   } else {
    //                     errorAdding = true;
    //                     added = AddedState.NotAdded;
    //                   }
    //                 }));
    //         // }
    //       }
    //     });
  }
}

class PlayerIcon extends StatelessWidget {
  final PublicUser? player;

  const PlayerIcon(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.ac_unit_outlined,
      color: Colors.grey[700],
      size: 24,
    );
  }
}

class ReactionPicker extends StatelessWidget {
  final bool open;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final void Function(String) onChoose;

  const ReactionPicker({
    Key? key,
    required this.open,
    required this.onOpen,
    required this.onClose,
    required this.onChoose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> reactions = ["😀", "🤔", "😐"];
    return open
        ? Row(
            children: reactions
                .map<Widget>((reaction) => _ReactionSmiley(reaction,
                    onTapped: () => onChoose(reaction)))
                .toList()
                  ..add(IconButton(
                    icon: Icon(Icons.sentiment_satisfied_outlined),
                    onPressed: () => onClose,
                  )),
          )
        : IconButton(
            icon: Icon(Icons.sentiment_satisfied_outlined),
            onPressed: () => onOpen,
          );
  }
}

class _ReactionSmiley extends StatelessWidget {
  final String content;
  final VoidCallback onTapped;

  const _ReactionSmiley(
    this.content, {
    Key? key,
    required this.onTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return
        // GestureDetector(
        //   onTap: onTapped,
        //   child:
        IconButton(
      icon: Text(content),
      onPressed: () => onTapped,
      // ),
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
    breatheAnim = Tween<double>(begin: 0.5, end: 0.7)
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
            builder: (_, child) =>
                Transform.scale(scale: breatheAnim.value, child: child),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(100)),
                color: Colors.white,
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
