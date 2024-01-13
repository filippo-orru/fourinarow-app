import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/providers/global_provider.dart';
import 'package:provider/provider.dart';

class ScreenShaker extends StatefulWidget {
  final Widget child;
  const ScreenShaker({super.key, required this.child});

  @override
  State<ScreenShaker> createState() => _ScreenShakerState();
}

class _ScreenShakerState extends State<ScreenShaker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 200),
  );
  late final Animation<double> _animation;
  final double speed = 9;
  final double amplitude = 10;

  @override
  void initState() {
    super.initState();
    _animation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(_controller);

    context.read<GlobalProvider>().screenShakeAnimCtrl = _controller;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(
          amplitude * sin(speed * _animation.value),
          0.2 * amplitude * sin(speed * _animation.value),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
