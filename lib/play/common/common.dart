import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/vibration.dart';
import '../game_logic/field.dart';
import '../game_logic/player.dart';
import '../game_logic/game_chip.dart';

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
            turn.colorWord,
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
    WinDetails details = _field.checkWin();

    return ConstrainedBox(
      // constraints: BoxConstraints.expand(),
      constraints: BoxConstraints.loose(Size(
        MediaQuery.of(context).size.width - 64,
        MediaQuery.of(context).size.width - 64,
      )),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          constraints: BoxConstraints.expand(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _field.array
                .asMap()
                .map((x, column) {
                  return MapEntry(
                    x,
                    _CreateRow(
                      x,
                      dropChip: _dropChip,
                      details: details,
                      column: column,
                    ),
                  );
                })
                .values
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _CreateRow extends StatelessWidget {
  const _CreateRow(
    this.x, {
    Key key,
    @required this.column,
    @required Function(int) dropChip,
    @required this.details,
  })  : _dropChip = dropChip,
        super(key: key);

  final int x;
  final List<Player> column;
  final Function(int) _dropChip;
  final WinDetails details;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _dropChip(x),
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: column
                .asMap()
                .map((y, cell) {
                  return MapEntry(
                    y,
                    _CreateCell(
                      Point<int>(x, y),
                      cell: cell,
                      details: details,
                    ),
                  );
                })
                .values
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _CreateCell extends StatelessWidget {
  _CreateCell(this.point,
      {@required this.cell, @required this.details, Key key})
      : super(key: key);

  final Point<int> point;
  final Player cell;
  final WinDetails details;
  @override
  Widget build(BuildContext context) {
    Widget chip = SizedBox();

    if (cell != null) {
      chip = GameChip(cell.color());
    }

    if (details != null) {
      if (details.player == cell) {
        Point<int> pointDelta = point - details.start;
        for (int i = -4; i < 4; i++) {
          if (pointDelta + details.delta * i == details.delta * 3) {
            chip = WinningGameChip(cell.color());
            break;
          }
        }
      }
    }
    return Expanded(
      child: Stack(children: [
        GameChipStatic(Color(0xFFDEDEDE)),
        chip,
      ]),
    );
  }
}

class WinnerOverlay extends StatelessWidget {
  const WinnerOverlay(
    this.winner, {
    this.useColorNames = true,
    @required this.onTap,
    @required this.board,
    this.bottomText,
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
                  color: winner.player.color(),
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
                                      ? winner.player.colorWord
                                      : winner.player.playerWord)
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
                      bottomText ?? 'Tap to play again!',
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
