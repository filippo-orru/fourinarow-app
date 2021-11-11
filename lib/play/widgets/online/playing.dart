import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/providers/chat.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:four_in_a_row/menu/common/rate_dialog.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/game_state.dart';
import 'package:four_in_a_row/play/models/online/game_states/playing.dart';
import 'package:four_in_a_row/play/widgets/common/board.dart';
import 'package:four_in_a_row/play/widgets/common/winner_overlay.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/toast.dart';
import 'package:four_in_a_row/util/extensions.dart';
import 'package:four_in_a_row/util/global_common_widgets.dart';

import 'package:provider/provider.dart';

class PlayingViewer extends AbstractGameStateViewer {
  final PlayingStateIntermediate _playingState;

  PlayingViewer(this._playingState, {Key? key}) : super(key: key) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_playingState.getShowRatingDialog()) {
      _playingState.setShowRatingDialog(false);
      RateTheGameDialog.show(context);
    }

    Toast? toast;
    if (_playingState.toastState != null) {
      toast = Toast(_playingState.toastState!);
    }
    Field _field = _playingState.field;

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
                  child: Board(_playingState.field, dropChip: _playingState.dropChip),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: FiarBottomSheet.HEIGHT,
          left: 24,
          right: 24,
          child: _playingState.opponentInfo.muted
              ? SizedBox()
              : Consumer<ChatState>(
                  builder: (_, chatState, __) => ScrollingChatMiniview(
                    messages: chatState.ingameMessages
                        .map(
                          (chatMessage) =>
                              MiniviewMessage(chatMessage.sender is SenderMe, chatMessage.content),
                        )
                        .toList(),
                  ),
                ),
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
        _BottomSheetWidget(
          _playingState.opponentInfo,
          setOpponentUser: _playingState.setOpponentUser,
          toggleMuteState: () {
            _playingState.setMuteState(!_playingState.opponentInfo.muted);
          },
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
  final OpponentInfo opponentInfo;
  final void Function(PublicUser?) setOpponentUser;
  final VoidCallback toggleMuteState;

  _BottomSheetWidget(
    this.opponentInfo, {
    required this.setOpponentUser,
    required this.toggleMuteState,
  });

  @override
  _BottomSheetState createState() => _BottomSheetState();
}

enum ReportedState { None, Loading, Reported }

class _BottomSheetState extends State<_BottomSheetWidget> {
  ReportedState reported = ReportedState.None;

  bool reactionPickerOpen = false;

  @override
  Widget build(BuildContext context) {
    bool iAmLoggedIn = context.read<GameStateManager>().userInfo.loggedIn;

    String? listTileSubtitle = widget.opponentInfo.user?.friendState.subTitle();
    Widget leadingIcon = Icon(Icons.person_add_disabled_outlined);
    if (iAmLoggedIn && widget.opponentInfo.user != null) {
      leadingIcon = widget.opponentInfo.user!.friendState.icon();
    }

    return FiarBottomSheet(
      onlyOpenUsingButton: !widget.opponentInfo.muted && reactionPickerOpen,
      color: Colors.blueAccent,
      expandedHeight: 232,
      topChildren: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  PlayerIcon(widget.opponentInfo.user),
                  SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        widget.opponentInfo.user?.username ?? "Player",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'RobotoSlab',
                          color: widget.opponentInfo.user == null
                              ? Colors.black.withOpacity(0.50)
                              : Colors.black87,
                        ),
                      ),
                      SizedBox(width: 6),
                      widget.opponentInfo.user != null
                          ? Text(
                              "${widget.opponentInfo.user!.gameInfo.skillRating} SR",
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
              widget.opponentInfo.muted
                  ? SizedBox()
                  : ReactionPicker(
                      open: reactionPickerOpen,
                      onOpen: () {
                        setState(() => reactionPickerOpen = true);
                      },
                      onClose: () {
                        setState(() => reactionPickerOpen = false);
                      },
                      onChoose: (reaction) {
                        reactionPickerOpen = false;
                        context.read<ChatState>().sendMessage(reaction, ingameMessage: true);
                      },
                    ),
            ],
          ),
        ),
      ],
      children: [
        ListTile(
          leading: leadingIcon,
          title: Text(
              widget.opponentInfo.user?.friendState.title(widget.opponentInfo.user!.username) ??
                  "Add friend"),
          subtitle: !iAmLoggedIn
              ? Text("Cant add as friend, you are not logged in")
              : widget.opponentInfo.user == null
                  ? Text("Cant add as friend, they are not logged in")
                  : listTileSubtitle != null
                      ? Text(listTileSubtitle)
                      : null,
          enabled: iAmLoggedIn && widget.opponentInfo.user != null,
          onTap: () async {
            if (widget.opponentInfo.user == null || !iAmLoggedIn) return;

            PublicUser? opponent = await context
                .read<GameStateManager>()
                .userInfo
                .addFriend(widget.opponentInfo.user!.id);
            widget.setOpponentUser(opponent);
          },
        ),
        ListTile(
          leading: Icon(Icons.report_gmailerrorred_outlined),
          title: Text(reported == ReportedState.None
              ? 'Report'
              : reported == ReportedState.Loading
                  ? "Sending report..."
                  : "User was reported"),
          enabled: reported == ReportedState.None,
          onTap: reported == ReportedState.None
              ? () async {
                  setState(() => reported = ReportedState.Loading);
                  await Future.delayed(Duration(milliseconds: 600));
                  setState(() => reported = ReportedState.Reported);

                  if (widget.opponentInfo.user == null) return; // Can't report anon users for now

                  Map body = {"content": "Reported user: \"${widget.opponentInfo.user!.id}\""};
                  var userMe = context.read<GameStateManager>().userInfo.user;
                  if (userMe != null) {
                    body["user_id"] = userMe.id;
                  }
                  await FeedbackDialog.sendRequest(body);
                }
              : null,
        ),
        ListTile(
          leading: Icon(
              widget.opponentInfo.muted ? Icons.volume_off_outlined : Icons.volume_up_outlined),
          title: Text(widget.opponentInfo.muted ? "Unmute chat" : "Mute chat"),
          onTap: widget.toggleMuteState,
        ),
      ],

      //   ),
      // ),
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

class MiniviewMessage {
  final bool senderIsMe;
  final String content;

  MiniviewMessage(this.senderIsMe, this.content);
}

class ScrollingChatMiniview extends StatefulWidget {
  final List<MiniviewMessage> messages;

  const ScrollingChatMiniview({Key? key, required this.messages}) : super(key: key);

  @override
  _ScrollingChatMiniviewState createState() => _ScrollingChatMiniviewState();
}

class _ScrollingChatMiniviewState extends State<ScrollingChatMiniview>
    with SingleTickerProviderStateMixin {
  void startScrollingToBottom() {
    int iterations = 0;
    while (ctrl.position.pixels ~/ ScrollingChatMiniviewMessage.HEIGHT < widget.messages.length &&
        iterations < 5) {
      // We need to scroll down
      ctrl.position.animateTo(ctrl.position.maxScrollExtent + ScrollingChatMiniviewMessage.HEIGHT,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
      iterations++;
    }
  }

  late final ScrollController ctrl;
  late final AnimationController opacityCtrl;
  Timer? fadeTimer;

  @override
  void initState() {
    super.initState();
    ctrl = ScrollController();
    opacityCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 150))
      ..value = 0.3;
  }

  @override
  void didUpdateWidget(ScrollingChatMiniview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      opacityCtrl.animateTo(1);
      fadeTimer?.cancel();
      fadeTimer = Timer(Duration(milliseconds: 2500), () {
        fadeTimer?.cancel();
        opacityCtrl.animateTo(0.3, duration: Duration(milliseconds: 600));
      });
      // new message
      startScrollingToBottom();
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ScrollingChatMiniviewMessage.HEIGHT,
      width: double.infinity,
      child: IgnorePointer(
        child: ListView(
          // reverse: true,
          itemExtent: ScrollingChatMiniviewMessage.HEIGHT,
          padding: EdgeInsets.zero,
          controller: ctrl,
          children: widget.messages
              .map(
                (message) => AnimatedBuilder(
                  animation: opacityCtrl,
                  builder: (_, child) => Opacity(opacity: opacityCtrl.value, child: child),
                  child: ScrollingChatMiniviewMessage(message),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class ScrollingChatMiniviewMessage extends StatelessWidget {
  static const double HEIGHT = 48;

  final MiniviewMessage message;

  const ScrollingChatMiniviewMessage(this.message, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: HEIGHT,
      child: Align(
        alignment: message.senderIsMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints.expand(width: 48),
          padding: EdgeInsets.all(2),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              message.content,
              style: TextStyle(
                  // fontSize: 18,
                  ),
            ),
          ),
        ),
      ),
    );
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

class ReactionPicker extends StatefulWidget {
  final List<String> reactions = FiarSharedPrefs.settingsQuickchatEmojis;
  final bool open;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final void Function(String) onChoose;

  ReactionPicker({
    Key? key,
    required this.open,
    required this.onOpen,
    required this.onClose,
    required this.onChoose,
  }) : super(key: key);

  @override
  _ReactionPickerState createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> {
  final Animatable<double> openCloseFade = Tween<double>(begin: 0, end: 1);
  final Animatable<double> openCloseRotate =
      Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeOutQuart));

  final Animatable<Offset> emojiSlideTween = Tween<Offset>(begin: Offset(0.2, 0), end: Offset.zero);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: AnimatedSwitcher(
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim.drive(CurveTween(curve: Curves.easeOutCubic)),
              child: SlideTransition(
                  position:
                      emojiSlideTween.chain(CurveTween(curve: Curves.easeOutCubic)).animate(anim),
                  child: child),
            ),
            duration: Duration(milliseconds: 170),
            child: widget.open
                ? Container(
                    constraints: BoxConstraints.expand(),
                    color: Colors.white.withOpacity(0.8),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: widget.reactions
                          .asMap()
                          .map((index, reaction) {
                            return MapEntry<int, Widget>(
                              index,
                              // Row(
                              //   children: [
                              _ReactionSmiley(
                                reaction,
                                onTapped: () => widget.onChoose(reaction),
                              ),
                              //  index != reactions.length - 1 ? 12 : 0),
                              //   ],
                              // ),
                            );
                          })
                          .values
                          .toList()
                        ..insert(0, SizedBox(width: 24)),
                    ),
                  )
                : SizedBox(),
          ),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> anim) {
            final bool isNewWidget = child.key == ValueKey(widget.open);
            final Curve opacityCurve = widget.open
                ? Curves.easeInOutCubic // when opening
                : isNewWidget
                    ? Curves.easeOutCubic
                    : Curves.easeInCubic;
            final tween = isNewWidget
                ? Tween<double>(begin: 0.0, end: 1.0)
                : Tween<double>(begin: 1.0, end: 0.0);
            return FadeTransition(
              opacity: openCloseFade.animate(anim.drive(CurveTween(curve: opacityCurve))),
              child: RotationTransition(
                  turns: openCloseRotate.animate(anim.drive(tween)), child: child),
            );
          },
          switchInCurve: Curves.easeInOutCubic,
          child: widget.open
              ? IconButton(
                  key: ValueKey(widget.open),
                  splashRadius: Material.defaultSplashRadius * 0.8,
                  icon: Icon(Icons.close, color: Colors.black54),
                  onPressed: widget.onClose,
                )
              : IconButton(
                  key: ValueKey(widget.open),
                  splashRadius: Material.defaultSplashRadius * 0.8,
                  icon: Icon(Icons.sentiment_satisfied_outlined, color: Colors.black87),
                  onPressed: widget.onOpen,
                ),
        )
      ],
    );
  }
}

class _ReactionSmiley extends StatefulWidget {
  final String content;
  final VoidCallback onTapped;

  const _ReactionSmiley(
    this.content, {
    Key? key,
    required this.onTapped,
  }) : super(key: key);

  @override
  _ReactionSmileyState createState() => _ReactionSmileyState();
}

class SplashingWidgetState {
  final double degree;
  final double speed;

  SplashingWidgetState({required this.degree, required this.speed});
}

class _ReactionSmileyState extends State<_ReactionSmiley> with SingleTickerProviderStateMixin {
  static const double DEGREE_RANGE = 1;

  static Random rng = Random();
  List<SplashingWidgetState> splashingCopies = [];

  void _generateSplashingCopies() {
    int copiesAmount = 3;
    for (int i in 0.to(copiesAmount)) {
      double thisDegreeRangeFrom = (i / copiesAmount) * DEGREE_RANGE - DEGREE_RANGE / 2;
      double thisDegreeRangeTo = ((i + 1) / copiesAmount) * DEGREE_RANGE - DEGREE_RANGE / 2;
      double thisDegreeRange = thisDegreeRangeTo - thisDegreeRangeFrom;
      splashingCopies.add(SplashingWidgetState(
          degree: thisDegreeRangeFrom +
              thisDegreeRange * (rng.nextDouble() * 0.5 - 0.25), // between 0.25 and 0.75
          speed: rng.nextDouble() + 1.5));
    }
  }

  late final AnimationController splashesAnimCtrl;
  @override
  void initState() {
    super.initState();
    splashesAnimCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 350))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          splashesAnimCtrl.value = 0;
          setState(() => splashingCopies = []);
        }
      });
  }

  @override
  void dispose() {
    splashesAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double fadeOffThreshold = 0.5;
    return IconButton(
      splashRadius: Material.defaultSplashRadius * 0.8,
      highlightColor: Colors.yellow[200]!.withOpacity(0.8),
      splashColor: Colors.orange[300]!.withOpacity(0.9),
      hoverColor: Colors.yellow[200],
      focusColor: Colors.orange[300]!.withOpacity(0.3),
      icon: Stack(
        children: <Widget>[] +
            (splashingCopies.map((splash) {
              //return _ReactionSmileyStatic(content: widget.content);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(0.88)
                  ..rotateZ(splash.degree),
                child: AnimatedBuilder(
                  animation: splashesAnimCtrl,
                  builder: (_, child) {
                    double x = splashesAnimCtrl.value;
                    double initialOpacity = 0.5;
                    double opacity = initialOpacity;
                    if (x > fadeOffThreshold) {
                      opacity = (x - fadeOffThreshold) * initialOpacity;
                    }

                    return Opacity(
                      opacity: opacity,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..translate(0.0, -x * splash.speed * 45),
                        child: child,
                      ),
                    );
                  },
                  child: _ReactionSmileyStatic(content: widget.content),
                ),
              );
            }).toList()) +
            [_ReactionSmileyStatic(content: widget.content)],
      ),
      onPressed: () {
        setState(() => _generateSplashingCopies());
        // print("Splangicopies: ${splashingCopies.map((s) => s.degree)}");
        splashesAnimCtrl.forward();
        Future.delayed(Duration(milliseconds: 150), widget.onTapped);
      },
    );
  }
}

class _ReactionSmileyStatic extends StatelessWidget {
  const _ReactionSmileyStatic({
    Key? key,
    required this.content,
  }) : super(key: key);

  final String content;

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 24,
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
              final begin = child.key == ValueKey(myTurn) ? Offset(1, 0) : Offset(-1, 0);
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(begin: begin, end: Offset(0, 0)).animate(anim),
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
                color: Player.values[myTurn ? 0 : 1]
                    .color(context.watch<ThemesProvider>().selectedTheme),
              ),
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

class _ConnectionIndicatorState extends State<ConnectionIndicator> with TickerProviderStateMixin {
  late AnimationController breatheCtrl;
  late AnimationController turnRed;
  late Animation<Color> colorAnim;
  late Animation<double> breatheAnim;
  Timer? delayedExecution;

  @override
  void initState() {
    super.initState();
    turnRed = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    colorAnim = Tween<Color>(begin: Colors.green, end: Colors.red).animate(turnRed);
    breatheCtrl = AnimationController(vsync: this, duration: Duration(seconds: 2))
      // brea
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && turnRed.status != AnimationStatus.completed) {
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
      builder: (_, child) => AnimatedBuilder(
        animation: breatheAnim,
        builder: (_, child) => Stack(
          alignment: Alignment.center,
          children: [
            child!,
            Transform.scale(
              scale: breatheAnim.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                  color: Colors.white,
                ),
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(100)),
            color: colorAnim.value,
          ),
          width: 24,
          height: 24,
        ),
        // child
      ),
    );
  }
}
