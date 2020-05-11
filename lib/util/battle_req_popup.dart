import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class BattleRequestPopup extends StatefulWidget {
  static const DURATION = Duration(seconds: 12);

  BattleRequestPopup(
    this.username,
    // this.lobbyCode,
    this.joinCallback,
    //  {
    // this.hideCallback,
    // this.acceptCallback,
    // }
  );

  final String username;
  // final String lobbyCode;
  final VoidCallback joinCallback;

  // final VoidCallback hideCallback;

  @override
  _BattleRequestPopupState createState() => _BattleRequestPopupState();
}

class _BattleRequestPopupState extends State<BattleRequestPopup>
    with SingleTickerProviderStateMixin {
  final Duration slideDuration = Duration(milliseconds: 250);

  AnimationController animCtrl;
  Animation<Offset> slideAnim;
  bool show = false;
  Ticker remainingTicker;
  Duration remaining;
  Timer timeoutTimer;
  Timer animationTimer;

  String usernameOverride;
  VoidCallback joinCallbackOverride;

  void join() async {
    await hide();
    if (joinCallbackOverride != null) {
      joinCallbackOverride();
    } else {
      widget.joinCallback();
    }
  }

  Future<void> hide() async {
    await animCtrl.animateTo(1.0,
        duration: slideDuration, curve: Curves.easeIn);
    setState(() => show = false);
  }

  @override
  initState() {
    super.initState();
    animCtrl = AnimationController(vsync: this, duration: slideDuration);
    slideAnim = Tween<Offset>(begin: Offset(0.5, 0), end: Offset(-0.5, 0))
        .animate(animCtrl);
    // tween = Tween<Offset>(begin: Offset(0.5, 0), end: Offset.zero);
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    rebuild(oldWidget);
  }

  void rebuild(BattleRequestPopup oldWidget) async {
    setState(() {
      usernameOverride = oldWidget.username;
      joinCallbackOverride = oldWidget.joinCallback;
    });
    await hide();
    setState(() {
      usernameOverride = null;
      joinCallbackOverride = null;
    });

    animCtrl.reset();
    animationTimer?.cancel();
    timeoutTimer?.cancel();
    // animCtrl.
    animCtrl.animateTo(0.5, duration: slideDuration, curve: Curves.easeOut);

    remaining = BattleRequestPopup.DURATION;
    remainingTicker?.stop();

    remainingTicker = Ticker((dur) {
      setState(() {
        if (dur > BattleRequestPopup.DURATION) {
          remainingTicker.stop();
          remaining = Duration.zero;
        } else {
          remaining = BattleRequestPopup.DURATION - dur;
        }
      });
    });
    // tween = Tween<Offset>(begin: Offset(0.5, 0), end: Offset.zero);
    animationTimer = Timer(BattleRequestPopup.DURATION - slideDuration, hide);

    remainingTicker.start();

    setState(() => show = true);
    timeoutTimer = Timer(BattleRequestPopup.DURATION, () {
      setState(() => show = false);
      remainingTicker.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 72,
      left: 0,
      right: 0,
      child: show
          ? AnimatedBuilder(
              animation: animCtrl,
              builder: (ctx, Widget child) {
                // print("slideAnim.value: ${slideAnim.value}");
                return Opacity(
                  opacity: animCtrl.value <= 0.5
                      ? 2 * animCtrl.value
                      : 2 - 2 * animCtrl.value,
                  child: Transform.translate(
                    offset: slideAnim.value * 150,
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  // color: Colors.purple[300],
                  // color: Colors.grey[300],
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 1),
                      blurRadius: 6,
                      color: Colors.black.withOpacity(0.2),
                    )
                  ],
                  // border: Border.all(
                  //   color: Colors.grey[500],
                  //   width: 3,
                  // ),
                  // border: Border(
                  //   top: BorderSide(
                  //     color: Colors.grey[500],
                  //     width: 3,
                  //   ),
                  //   bottom: BorderSide(
                  //     color: Colors.grey[500],
                  //     width: 3,
                  //   ),
                  // ),
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
                margin: EdgeInsets.symmetric(horizontal: 32),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Text(
                              usernameOverride ?? widget.username,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'requested a match!',
                              style: TextStyle(color: Colors.black87),
                            ),
                            Spacer(),
                            Opacity(
                              opacity: 0.5,
                              child: IconButton(
                                splashColor: Colors.blueAccent.withOpacity(0.5),
                                icon: Icon(Icons.close),
                                onPressed: hide,
                              ),
                            ),
                            IconButton(
                                splashColor: Colors.redAccent.withOpacity(0.5),
                                icon: Icon(Icons.check, color: Colors.black87),
                                onPressed: join),

                            // FlatIconButton(
                            //     bgColor: Colors.black12,
                            //     onPressed: () {
                            //       // route: slideUpRoute(PlayingOnline()));
                            //     },
                            //     icon: Icons.check),
                            // FlatIconButton(onPressed: () {}, icon: Icons.close),
                          ],
                        ),
                      ),
                    ),
                    CountDownBar(
                        value: remaining.inMilliseconds /
                            BattleRequestPopup.DURATION.inMilliseconds),
                  ],
                ),
              ),
            )
          : SizedBox(),
    );
  }
}

class CountDownBar extends StatelessWidget {
  const CountDownBar({
    Key key,
    @required this.value,
  }) : super(key: key);

  final double value;

  @override
  Widget build(BuildContext context) {
    // print("value: $value");
    return Container(
      height: 4,
      width: double.infinity,
      color: Colors.blueAccent,
      child: LinearProgressIndicator(value: value),
    );
  }
}
