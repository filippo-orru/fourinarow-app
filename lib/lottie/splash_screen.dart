import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'package:lottie/lottie.dart';

enum SplashScreenState { Loading, LottieRunning, LottieDone, Fading, Done }

class SplashScreen extends StatefulWidget {
  final void Function(SplashScreenState) onAnimationState;

  const SplashScreen({Key? key, required this.onAnimationState}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _lottieAnimCtrl;
  late AnimationController _moveUpAnimCtrl;
  Animation? _moveUpAnim;
  late AnimationController _crossfadeAnimCtrl;

  @override
  void initState() {
    super.initState();
    _lottieAnimCtrl = AnimationController(vsync: this);
    _moveUpAnimCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 240),
    );
    _crossfadeAnimCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _lottieAnimCtrl.dispose();
    _moveUpAnimCtrl.dispose();
    _crossfadeAnimCtrl.dispose();
    super.dispose();
  }

  void _onAnimationLoaded() async {
    widget.onAnimationState(SplashScreenState.LottieRunning);

    TickerFuture lottieAnimation = _lottieAnimCtrl.forward();

    // Check if the animation actually started running. If not (screen is probably off), skip
    //  all animations.
    await Future.delayed(Duration(milliseconds: 100));
    if (_lottieAnimCtrl.value == 0.0) {
      widget.onAnimationState(SplashScreenState.Done);
      return;
    } else {
      await lottieAnimation;
    }

    widget.onAnimationState(SplashScreenState.LottieDone);

    // Short delay between animations because preloading causes jank
    await Future.delayed(Duration(milliseconds: STARTUP_DELAY_MS));

    widget.onAnimationState(SplashScreenState.Fading);
    // Move up & fade to app
    await _moveUpAnimCtrl.forward();
    await Future.delayed(Duration(milliseconds: 100));
    await _crossfadeAnimCtrl.forward();

    widget.onAnimationState(SplashScreenState.Done);
  }

  @override
  Widget build(BuildContext context) {
    if (_moveUpAnim == null) {
      double viewHeight = MediaQuery.of(context).size.height;
      double begin = max(0, viewHeight * 0.5 - 110 / 2);
      double end = max(0, viewHeight * 0.22);

      _moveUpAnim = _moveUpAnimCtrl.drive(
        Tween<double>(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOutCubic)),
      );
    }

    return Container(
      constraints: BoxConstraints(maxWidth: 600),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _crossfadeAnimCtrl,
        builder: (_, child) => Opacity(
          opacity: 1 - _crossfadeAnimCtrl.value,
          child: child,
        ),
        child: Container(
          constraints: BoxConstraints.expand(),
          alignment: Alignment.center,
          color: Colors.white,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
              animation: _moveUpAnimCtrl,
              builder: (_, child) => Container(
                padding: EdgeInsets.only(left: 32, right: 32, top: _moveUpAnim!.value),
                child: child,
              ),
              child: Lottie.asset(
                "assets/lottie/main_menu/wide logo banner anim.json",
                fit: BoxFit.contain,
                controller: _lottieAnimCtrl,
                onLoaded: (c) {
                  _lottieAnimCtrl.duration = c.duration * 0.85;
                  _onAnimationLoaded();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
