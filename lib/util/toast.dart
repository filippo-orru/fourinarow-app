import 'package:flutter/material.dart';

class ToastState {
  static const DEFAULT_DURATION = const Duration(milliseconds: 3000);

  final String text;
  final Duration duration;
  final bool angery;
  final VoidCallback? onComplete;

  ToastState(
    this.text, {
    Key? key,
    this.duration = DEFAULT_DURATION,
    this.angery = false,
    this.onComplete,
  }) {
    Future.delayed(duration, () => onComplete?.call());
  }
}

class Toast extends StatefulWidget {
  final ToastState toastState;

  Toast(this.toastState, {Key? key}) : super(key: key);

  @override
  _ToastState createState() => _ToastState();
}

class _ToastState extends State<Toast> with TickerProviderStateMixin {
  late AnimationController opacityCtrl;
  late Animation<double> opacity;

  late AnimationController wiggleCtrl;
  late Animation<Offset> wiggle;
  final int maxWiggles = 3;

  @override
  void initState() {
    super.initState();
    opacityCtrl = AnimationController(
        vsync: this, duration: widget.toastState.duration * 0.2);
    opacity = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(opacityCtrl);
    Future.delayed(widget.toastState.duration * 0.6, () {
      if (this.mounted) opacityCtrl.reverse();
    });

    wiggleCtrl = AnimationController(
        vsync: this, value: 0.5, duration: Duration(milliseconds: 50));
    wiggle = Tween<Offset>(begin: Offset(-4, 0), end: Offset(4, 0))
        .animate(wiggleCtrl);

    opacityCtrl.forward();
    startWiggle();
  }

  void startWiggle() async {
    if (widget.toastState.angery) {
      await Future.delayed(widget.toastState.duration * 0.07);
      if (!mounted) return;

      for (int i = 0; i < maxWiggles; i++) {
        await wiggleCtrl.forward();
        await wiggleCtrl.reverse();
      }
      wiggleCtrl.animateTo(0.5);
    }
  }

  @override
  void dispose() {
    opacityCtrl.dispose();
    wiggleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          widget.toastState.angery ? Alignment.center : Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: wiggle,
        builder: (ctx, child) => Transform.translate(
          offset: wiggle.value,
          child: child,
        ),
        child: FadeTransition(
          opacity: opacity,
          child: Container(
            margin: EdgeInsets.only(bottom: widget.toastState.angery ? 0 : 64),
            padding: EdgeInsets.all(widget.toastState.angery ? 24 : 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color:
                    widget.toastState.angery ? Colors.red : Colors.grey[600]!,
                width: widget.toastState.angery ? 4 : 1,
              ),
              borderRadius: BorderRadius.all(
                  Radius.circular(widget.toastState.angery ? 8 : 4)),
            ),
            child: Text(widget.toastState.text),
          ),
        ),
      ),
    );
  }
}
