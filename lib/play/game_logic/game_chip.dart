import 'package:flutter/material.dart';

class WinningGameChip extends StatefulWidget {
  WinningGameChip(Color cellColor)
      : _cellColor = cellColor,
        super(key: ValueKey(cellColor));

  final Color _cellColor;

  @override
  _WinningGameChipState createState() => _WinningGameChipState();
}

class _WinningGameChipState extends State<WinningGameChip>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController animController;

  @override
  initState() {
    super.initState();
    animController =
        AnimationController(duration: Duration(milliseconds: 700), vsync: this);
    animation =
        CurvedAnimation(curve: Curves.easeInOutQuint, parent: animController);

    // Future.delayed(Duration(milliseconds: 200), () {
    animController.forward();
    // });
  }

  @override
  dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GameChip(widget._cellColor),
        ScaleTransition(
          scale: Tween<double>(begin: 0, end: 0.7).animate(animation),
          child: GameChipStatic(Colors.white54),
        ),
      ],
    );
  }
}

class GameChip extends StatefulWidget {
  GameChip(Color cellColor)
      : _cellColor = cellColor,
        super(key: ValueKey(cellColor));

  final Color _cellColor;

  @override
  _GameChipState createState() => _GameChipState();
}

class _GameChipState extends State<GameChip>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController animController;

  @override
  initState() {
    super.initState();

    animController = AnimationController(
      duration: Duration(milliseconds: 380),
      lowerBound: 0.1,
      upperBound: 1,
      value: 0.3,
      vsync: this,
    );

    animation =
        CurvedAnimation(curve: Curves.easeOutSine, parent: animController);

    animController.forward();
  }

  @override
  dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.2, end: 1).animate(animation),
      child: GameChipStatic(widget._cellColor),
    );
  }
}

class GameChipStatic extends StatelessWidget {
  const GameChipStatic(Color color, {Key key})
      : _color = color,
        super(key: key);

  final Color _color;

  @override
  Widget build(BuildContext context) {
    return Container(
      // constraints: BoxConstraints.tightFor(height: 40, width: 40),
      // constraints: BoxConstraints(
      //     minWidth: 10, maxWidth: 40, minHeight: 10, maxHeight: 40),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color,
          ),
        ),
      ),
    );
  }
}
