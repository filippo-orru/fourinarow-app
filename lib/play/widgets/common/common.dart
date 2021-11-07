import 'package:flutter/material.dart';

import 'dart:math';

import 'package:four_in_a_row/play/models/common/player.dart';

class BorderButton extends StatelessWidget {
  const BorderButton(
    this.label, {
    Key? key,
    required this.icon,
    required this.callback,
    required this.borderColor,
  }) : super(key: key);

  final String label;
  final IconData icon;
  final void Function() callback;
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
              Text(label, style: TextStyle(fontSize: 16, color: Colors.black87)),
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
    Key? key,
    required this.turn,
    this.playerNames = defaultPlayerName,
  }) : super(key: key);

  final Player turn;
  final String Function(Player) playerNames;

  static String defaultPlayerName(Player p) => p.colorWord;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(children: [
        Text("Now playing", style: TextStyle(fontSize: 22, color: Colors.black.withOpacity(0.7))),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 170),
          switchInCurve: Curves.easeInOutExpo,
          switchOutCurve: Curves.easeInOutExpo,
          transitionBuilder: (Widget child, Animation<double> anim) {
            final begin = child.key == ValueKey(turn) ? Offset(1, 0) : Offset(-1, 0);
            return ClipRect(
              child: SlideTransition(
                position: Tween<Offset>(begin: begin, end: Offset(0, 0)).animate(anim),
                child: child,
              ),
            );
          },
          child: Text(
            playerNames(turn),
            key: ValueKey(turn),
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                // fontStyle: FontStyle.italic,
                color: turn.color()),
          ),
        ),
      ]),
    );
  }
}
