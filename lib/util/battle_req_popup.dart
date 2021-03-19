import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:four_in_a_row/menu/account/friends.dart';

class BattleRequestPopup extends StatefulWidget {
  static const DURATION = BattleRequestDialog.TIMEOUT;

  BattleRequestPopup({
    required this.username,
    required this.joinCallback,
    required this.leaveCallback,
  });

  final String username;
  final VoidCallback joinCallback;
  final VoidCallback leaveCallback;

  @override
  _BattleRequestPopupState createState() => _BattleRequestPopupState();
}

class _BattleRequestPopupState extends State<BattleRequestPopup>
    with SingleTickerProviderStateMixin {
  final Duration slideDuration = Duration(milliseconds: 250);

  late AnimationController animCtrl;
  late Animation<Offset> slideAnim;
  Ticker? remainingTicker;
  Duration? remaining;

  void join() async {
    await hide();
    widget.joinCallback();
  }

  Future<void> leave() async {
    await hide();
    widget.leaveCallback();
  }

  Future<void> hide() async {
    if (!mounted) return;

    await animCtrl.animateTo(1.0,
        duration: slideDuration, curve: Curves.easeIn);
  }

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(vsync: this, duration: slideDuration);
    slideAnim = Tween<Offset>(begin: Offset(0.5, 0), end: Offset(-0.5, 0))
        .animate(animCtrl);
    animCtrl.animateTo(0.5, curve: Curves.easeOut);

    Future.delayed(BattleRequestPopup.DURATION - slideDuration, hide);

    remaining = BattleRequestPopup.DURATION;

    remainingTicker = Ticker((dur) {
      if (dur > BattleRequestPopup.DURATION) {
        remainingTicker?.stop();
        remaining = Duration.zero;
      } else {
        remaining = BattleRequestPopup.DURATION - dur;
      }
      if (!mounted) return;
      setState(() {});
    });

    remainingTicker?.start();
  }

  @override
  void dispose() {
    animCtrl.dispose();
    remainingTicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animCtrl,
      builder: (ctx, Widget? child) {
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
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 6,
              color: Colors.black.withOpacity(0.2),
            )
          ],
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 32),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Text(
                      widget.username,
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
                        splashColor: Colors.blueAccent.withOpacity(0.3),
                        highlightColor: Colors.transparent,
                        icon: Icon(Icons.close),
                        onPressed: leave,
                      ),
                    ),
                    IconButton(
                      splashColor: Colors.blueAccent.withOpacity(0.4),
                      highlightColor: Colors.transparent,
                      icon: Icon(
                        Icons.check,
                        color: Colors.blue,
                      ),
                      onPressed: join,
                    ),

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
                value: remaining!.inMilliseconds /
                    BattleRequestPopup.DURATION.inMilliseconds),
          ],
        ),
      ),
    );
  }
}

class CountDownBar extends StatelessWidget {
  const CountDownBar({
    Key? key,
    required this.value,
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
