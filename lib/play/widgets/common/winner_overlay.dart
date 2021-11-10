import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:provider/provider.dart';

import 'board.dart';

class WinnerOverlay extends StatefulWidget {
  const WinnerOverlay(
    this.winDetails, {
    this.playerNames = defaultPlayerNames,
    required this.onTap,
    required this.board,
    this.bottomText,
    this.ranked = false,
    Key? key,
  }) : super(key: key);

  final WinDetails? winDetails;
  final String Function(Player) playerNames;
  final Function() onTap;
  final Board board;
  final String? bottomText;
  final bool ranked;

  static String defaultPlayerNames(Player p) => p.colorWord;

  @override
  _WinnerOverlayState createState() => _WinnerOverlayState();
}

class _WinnerOverlayState extends State<WinnerOverlay> {
  @override
  void didUpdateWidget(WinnerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.winDetails == null && widget.winDetails != null) {
      SystemUiStyle.playSelection();
    } else if (oldWidget.winDetails != null && widget.winDetails == null) {
      SystemUiStyle.mainMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    var winDetails = this.widget.winDetails;

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
      child: winDetails == null
          ? SizedBox()
          : GestureDetector(
              onTap: widget.onTap,
              child: Consumer<ThemesProvider>(
                builder: (_, themeProvider, child) => Container(
                    decoration: BoxDecoration(
                      color: winDetails is WinDetailsWinner
                          ? winDetails.winner.color(themeProvider.selectedTheme)
                          : Color.lerp(
                              Colors.grey[700], Colors.blueAccent, 0.5),
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
                    child: child),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // SizedBox(height: 64),

                    ConstrainedBox(
                      constraints: BoxConstraints.expand(
                          height: MediaQuery.of(context).size.height * 0.2),
                      child: FittedBox(
                        child: (winDetails is WinDetailsDraw)
                            ? Text(
                                "DRAW",
                                style: TextStyle(
                                  fontSize: 98,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              )
                            : winDetails is WinDetailsWinner
                                ? Column(
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
                                        widget
                                            .playerNames(winDetails.winner)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 98,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white,
                                        ),
                                      ),
                                      widget.ranked
                                          ? TweenAnimationBuilder(
                                              tween:
                                                  IntTween(begin: 1, end: 25),
                                              curve: Curves.easeInOutQuart,
                                              duration:
                                                  Duration(milliseconds: 1800),
                                              builder: (ctx, int value, child) {
                                                if (value % 3 == 0)
                                                  Vibrations.tiny();
                                                return Text(
                                                  (winDetails.me ? "+" : "-") +
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
                                  )
                                : throw UnimplementedError(
                                    "Another WinDetails class?"),
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
                          child: IgnorePointer(child: widget.board),
                        ),
                      ),
                    ),
                    // SizedBox(height: 64),
                    Text(
                      widget.bottomText ?? "Tap to continue",
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
