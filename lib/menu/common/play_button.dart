import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/main.dart';

class PlayButton extends StatefulWidget {
  const PlayButton({
    this.label = 'Play',
    required this.color,
    required this.onTap,
    // this.stayExpanded = false,
    this.diameter = 128,
    Key? key,
  }) : super(key: key);

  final String label;
  final Color color;
  // final bool stayExpanded;
  final double diameter;
  final void Function() onTap;

  @override
  _PlayButtonState createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton>
    with TickerProviderStateMixin, RouteAware {
  late AnimationController sizeAnimController;
  late Animation<double> circleSize;
  late Animation<double> textSize;
  late AnimationController growSizeAnimController;
  late Animation<double> growSize;
  late Animation<double> ceilOpacity;
  late Animation<double> growFade;

  static const int GROW_ANIM_DURATION = 240;

  RouteObserverProvider? observerProvider;

  @override
  void didChangeDependencies() {
    observerProvider = RouteObserverProvider.of(context);
    super.didChangeDependencies();
    observerProvider!.observer.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    observerProvider?.observer.unsubscribe(this);
    growSizeAnimController.dispose();
    sizeAnimController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    sizeAnimController.reverse();
    growSizeAnimController.reverse();
  }

  @override
  void initState() {
    super.initState();
    sizeAnimController = AnimationController(
        duration: Duration(milliseconds: (GROW_ANIM_DURATION / 3).floor()),
        vsync: this);
    final sizeCurvedAnimation = CurvedAnimation(
      parent: sizeAnimController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    circleSize =
        Tween<double>(begin: 1, end: 0.85).animate(sizeCurvedAnimation);
    textSize = Tween<double>(begin: 1, end: 0.92).animate(sizeCurvedAnimation);
    // sizeAnimController.reset();

    growSizeAnimController = AnimationController(
        duration: Duration(milliseconds: GROW_ANIM_DURATION),
        reverseDuration: Duration(milliseconds: 2 * GROW_ANIM_DURATION),
        vsync: this);
    final growSizeCurvedAnimation = CurvedAnimation(
      parent: growSizeAnimController,
      curve: Curves.easeIn,
      // reverseCurve: Curves.easeOut,
    );
    growSize =
        Tween<double>(begin: 1, end: 13).animate(growSizeCurvedAnimation);
    ceilOpacity = Tween<double>(begin: widget.color.opacity, end: 1)
        .animate(growSizeCurvedAnimation);
    growFade = Tween<double>(begin: 1, end: 0)
        .chain(CurveTween(curve: Curves.easeOutExpo))
        .animate(growSizeAnimController);
    growSizeAnimController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        sizeAnimController.forward();
        growSizeAnimController.reverse();
      },
      onTapUp: (_) {
        // if (!widget.stayExpanded) {
        sizeAnimController.reverse();
        growSizeAnimController.forward();
        // widget.onTap();
        Future.delayed(
          Duration(milliseconds: (GROW_ANIM_DURATION / 3).floor()),
          widget.onTap,
        );
      },
      onTapCancel: () => sizeAnimController.reverse(),
      child: SizedOverflowBox(
        size: Size(
          widget.diameter,
          widget.diameter,
        ),
        child: ScaleTransition(
          scale: growSize,
          child: Container(
            child: Stack(
              children: [
                ScaleTransition(
                  scale: circleSize,
                  child: FadingRing(
                    startingDiameter: widget.diameter,
                    color: widget.color,
                    child: AnimatedBuilder(
                      animation: ceilOpacity,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.color.withOpacity(
                              min(1, ceilOpacity.value),
                            ),
                          ),
                          constraints: BoxConstraints.expand(),
                        );
                      },
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: growFade,
                  child: ScaleTransition(
                    scale: textSize,
                    child: Center(
                      child: Text(
                        widget.label.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'RobotoSlab',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            width: widget.diameter,
            height: widget.diameter,
          ),
        ),
      ),
    );
  }
}

class FadingRing extends StatefulWidget {
  FadingRing(
      {required this.child,
      this.color = Colors.redAccent,
      this.startingDiameter = 128});

  final Widget child;
  final Color color;
  final double startingDiameter;

  @override
  _FadingRingState createState() => _FadingRingState();
}

class _FadingRingState extends State<FadingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController sizeAnimController;
  late Animation<double> size;
  late Animation<double> opacity;

  @override
  void dispose() {
    this.sizeAnimController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    sizeAnimController =
        AnimationController(duration: Duration(milliseconds: 900), vsync: this)
          ..repeat();
    // sizeAnimController.addStatusListener((status) {
    //   if (status == AnimationStatus.completed) {
    //     Future.delayed(Duration(milliseconds: 330), () {
    //       sizeAnimController.forward(from: 0);
    //     });
    //   }
    // });
    size = Tween<double>(begin: 1, end: 2)
        .chain(CurveTween(curve: Curves.easeOutQuad))
        .animate(sizeAnimController);
    opacity = Tween<double>(begin: 1, end: 0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(sizeAnimController);
  }

  @override
  Widget build(BuildContext context) {
    return SizedOverflowBox(
      size: Size(
        widget.startingDiameter,
        widget.startingDiameter,
      ),
      child: Stack(alignment: Alignment.center, children: [
        FadeTransition(
          opacity: opacity,
          child: ScaleTransition(
            scale: size,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 4, color: widget.color),
              ),
              height: widget.startingDiameter,
              width: widget.startingDiameter,
            ),
          ),
        ),
        widget.child,
      ]),
    );
  }
}
