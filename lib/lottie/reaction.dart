import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/color_filter.dart';
import 'package:lottie/lottie.dart';

class LottieReaction extends StatefulWidget {
  final String name;
  final VoidCallback onTap;
  final bool startsGrey;

  const LottieReaction({
    Key? key,
    required this.name,
    required this.onTap,
    this.startsGrey = true,
  }) : super(key: key);

  @override
  _LottieReactionState createState() => _LottieReactionState();
}

class _LottieReactionState extends State<LottieReaction> with SingleTickerProviderStateMixin {
  bool active = false;

  late final AnimationController _controller;
  late bool _grey;

  @override
  void initState() {
    super.initState();

    _grey = widget.startsGrey;
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // print("active: $active");
        this.active = !active;
        setState(() => _grey = !active);
        if (active) {
          // actually inactive
          _controller.animateTo(1).then((_) {
            _controller.value = 0;
          });
        }
      },
      child: Container(
        height: 80,
        width: 80,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: _grey ? -0.85 : 0),
          duration: Duration(milliseconds: 200),
          child: Lottie.asset(
            'assets/lottie/reactions/${widget.name}.json',
            controller: _controller,
            onLoaded: (comp) {
              _controller.duration = comp.duration;
            },
          ),
          builder: (_, val, child) => ColorFiltered(
            colorFilter: ColorFilter.matrix(
              ColorFilterGenerator.saturationAdjustMatrix(value: val as double),
            ),
            child: child as Widget,
          ),
        ),
      ),
    );
  }
}
