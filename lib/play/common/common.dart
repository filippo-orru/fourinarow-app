import 'package:flutter/material.dart';
import 'package:four_in_a_row/field_logic/common/field.dart';
import 'package:four_in_a_row/field_logic/common/player.dart';
import 'package:four_in_a_row/field_logic/common/game_chip.dart';

import 'dart:math';

class BorderButton extends StatelessWidget {
  const BorderButton(
    this.label, {
    Key key,
    @required this.icon,
    @required this.callback,
    @required this.borderColor,
  }) : super(key: key);

  final String label;
  final IconData icon;
  final Function callback;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOutBack,
        switchOutCurve: Curves.easeInOutBack,
        child: Container(
          key: ValueKey(borderColor),
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            border: Border.all(width: 2, color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label,
                  style: TextStyle(fontSize: 16, color: Colors.black87)),
              SizedBox(width: 8),
              Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

class TurnIndicator extends StatelessWidget {
  const TurnIndicator({
    Key key,
    @required this.turn,
  }) : super(key: key);

  final Player turn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(children: [
        Text("Your turn,",
            style: TextStyle(fontSize: 24, color: Colors.black87)),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 170),
          switchInCurve: Curves.easeInOutExpo,
          switchOutCurve: Curves.easeInOutExpo,
          // layoutBuilder: (Widget child, List<Widget> prevChildren) {
          //   return child;
          // },
          transitionBuilder: (Widget child, Animation<double> anim) {
            final begin =
                child.key == ValueKey(turn) ? Offset(1, 0) : Offset(-1, 0);
            return ClipRect(
              child: SlideTransition(
                position: Tween<Offset>(begin: begin, end: Offset(0, 0))
                    .animate(anim),
                child: child,
              ),
            );
          },
          child: Text(
            turn.word,
            key: ValueKey(turn),
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: turn.color()),
          ),
        ),
      ]),
    );
  }
}

class Board extends StatelessWidget {
  final Field _field;
  final Function(int) _dropChip;

  Board(this._field, {Key key, @required Function(int) dropChip})
      : _dropChip = dropChip,
        super(key: key);

  // Function(Color color, AnimationController c) gameChipCurry =
  //     (Color col, AnimationController con) => GameChip(col, controller: con);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        constraints: BoxConstraints.expand(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _field
              .get()
              .asMap()
              .map((x, column) {
                return MapEntry(
                  x,
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _dropChip(x);
                      },
                      child: Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: column.map((cell) {
                            // Color cellColor = Colors.black38;
                            Widget chip = Container();
                            if (cell == Player.One) {
                              chip = GameChip(Colors.red);
                            } else if (cell == Player.Two) {
                              chip = GameChip(Colors.blue);
                            }
                            return Expanded(
                              child: Stack(children: [
                                GameChipStatic(Color(0xFFDEDEDE)),
                                chip,
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .values
              .toList(),
        ),
      ),
    );
  }
}

class WinnerOverlay extends StatelessWidget {
  const WinnerOverlay(
    this.winner, {
    @required Function() fieldReset,
    @required Widget field,
    Key key,
  })  : this.fieldReset = fieldReset,
        this.field = field,
        super(key: key);

  final Player winner;
  final Function() fieldReset;
  final Widget field;

  @override
  Widget build(BuildContext context) {
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
          ? SizedBox(
              key: ValueKey(0),
              // margin: EdgeInsets.all(32),
              // child: field,
            )
          : Container(
              key: ValueKey(1),
              constraints: BoxConstraints.expand(),
              // color: Colors.black26,
              child: Center(
                child: GestureDetector(
                  onTap: () => fieldReset(),
                  child: Container(
                    // margin:
                    //     EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    decoration: BoxDecoration(
                      color: winner.color(),
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
                    // height: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // SizedBox(height: 64),
                        Column(
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
                              winner.word.toUpperCase(),
                              style: TextStyle(
                                fontSize: 98,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        // Expanded(child: Container()),
                        // SizedBox(height: 48),
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                              color: Colors.white,
                            ),
                            child: IgnorePointer(child: field),
                          ),
                        ),
                        // SizedBox(height: 64),
                        Text(
                          'Tap to play again!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            fontSize: 24,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
