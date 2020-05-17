import '../game_logic/player.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/game_logic/field.dart';
import 'package:four_in_a_row/util/vibration.dart';

import 'board.dart';

class WinnerOverlay extends StatelessWidget {
  const WinnerOverlay(
    this.winner, {
    this.useColorNames = true,
    @required this.onTap,
    @required this.board,
    this.bottomText = 'Tap to play again!',
    this.ranked = false,
    Key key,
  }) : super(key: key);

  final WinDetails winner;
  final bool useColorNames;
  final Function() onTap;
  final Board board;
  final String bottomText;
  final bool ranked;

  @override
  Widget build(BuildContext context) {
    // print("checkwin: $winner");
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 280),
      reverseDuration: Duration(milliseconds: 350),
      transitionBuilder: (Widget child, Animation<double> anim) {
        final opacityTween = TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem(tween: ConstantTween(0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
        ]).chain(CurveTween(curve: Curves.easeInOutCirc));
        final scaleTween = Tween<double>(
          begin: 0.9,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOutQuint));
        final slideTween = Tween<Offset>(
          begin: Offset(0, 0.2),
          end: Offset(0, 0),
        ).chain(CurveTween(curve: Curves.easeInOutCubic));
        // anim.addStatusListener((s) {
        //   if (s == AnimationStatus.dismissed ||
        //       s == AnimationStatus.completed) {
        //     Offset begin = slideTween.begin;
        //     slideTween.begin = slideTween.end;
        //     slideTween.end = begin;
        //   }
        // });
        return SlideTransition(
          position: slideTween.animate(anim),
          child: FadeTransition(
            opacity: opacityTween.animate(anim),
            child: ScaleTransition(
              scale: scaleTween.animate(anim),
              child: child,
              // Opacity(
              //   opacity: opacityTween.evaluate(anim),
              //   child: Transform.scale(
              //     scale: scaleTween.evaluate(anim),
              //     child: child,
              //   ),
              // ),
            ),
          ),
        );
      },
      child: winner == null
          ? SizedBox()
          : GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: winner.winner.color(),
                  // borderRadius: BorderRadius.all(Radius.circular(8)),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black38,
                  //     offset: Offset(0, 4),
                  //     blurRadius: 12,
                  //     spreadRadius: 2,
                  //   ),
                  // ]
                ),
                padding: EdgeInsets.fromLTRB(24, 64, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // SizedBox(height: 64),

                    ConstrainedBox(
                      constraints: BoxConstraints.expand(
                          height: MediaQuery.of(context).size.height * 0.2),
                      child: FittedBox(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Winner',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white
                                  // .withOpacity(0.9),
                                  ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              (useColorNames
                                      ? winner.winner.colorWord
                                      : winner.winner.playerWord)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 98,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                            ranked
                                ? TweenAnimationBuilder(
                                    tween: IntTween(begin: 1, end: 25),
                                    curve: Curves.easeInOutQuart,
                                    duration: Duration(milliseconds: 1800),
                                    builder: (ctx, value, child) {
                                      if (value % 3 == 0) Vibrations.tiny();
                                      return Text(
                                        (winner.me ? "+" : "-") +
                                            value.toString() +
                                            " SR",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          // fontStyle: FontStyle.italic,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : SizedBox()
                          ],
                        ),
                      ),
                    ),
                    // Expanded(child: Container()),
                    // SizedBox(height: 48),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            color: Colors.white,
                          ),
                          child: IgnorePointer(child: board),
                        ),
                      ),
                    ),
                    // SizedBox(height: 64),
                    Text(
                      bottomText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
