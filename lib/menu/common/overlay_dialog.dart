import 'package:flutter/material.dart';

class OverlayDialog extends StatefulWidget {
  OverlayDialog(
    this.show, {
    required this.hide,
    required this.child,
    this.showCloseButton = true,
    Key? key,
  }) : super(key: key);

  final bool show;
  final VoidCallback hide;
  final Widget child;
  final bool showCloseButton;
  // final String myId;
  // final UserinfoProviderState userInfo;

  @override
  _OverlayDialogState createState() => _OverlayDialogState();
}

class _OverlayDialogState extends State<OverlayDialog>
    with SingleTickerProviderStateMixin {
  static const Duration DURATION = Duration(milliseconds: 200);
  late AnimationController animCtrl;
  late Animation<double> opacityAnim;
  late Animation<Offset> offsetAnim;
  bool show = false;

  void _hide([selfInitiated = false]) {
    animCtrl.reverse().then((_) {
      setState(() => show = false);
      if (selfInitiated) widget.hide();
    });
  }

  void _show() {
    setState(() => show = true);
    animCtrl.forward();
  }

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(
      vsync: this,
      duration: DURATION,
    );
    opacityAnim = CurveTween(curve: Curves.easeIn).animate(animCtrl);
    offsetAnim = Tween(begin: Offset(0, 30), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(animCtrl);
  }

  @override
  void didUpdateWidget(OverlayDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.show && !widget.show) {
      // animCtrl.reverse();
      _hide();
    } else if (!oldWidget.show && widget.show) {
      _show();
      // this.searchbarFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    this.animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: animCtrl,
          builder: (ctx, child) =>
              Opacity(opacity: opacityAnim.value, child: child),
          child: this.show
              ? GestureDetector(
                  onTap: () => _hide(true),
                  child: Container(
                    constraints: BoxConstraints.expand(),
                    color: Colors.black26,
                    alignment: Alignment.center,
                    child: SizedBox(),
                  ),
                )
              : SizedBox(),
        ),
        WillPopScope(
          onWillPop: () {
            if (widget.show) {
              _hide(true);
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 80),
            margin: MediaQuery.of(context).viewInsets,
            child: AnimatedBuilder(
              animation: animCtrl,
              builder: (ctx, child) =>
                  Opacity(opacity: opacityAnim.value, child: child),
              child: this.show
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AnimatedBuilder(
                        animation: animCtrl,
                        builder: (ctx, child) => Transform.translate(
                          offset: offsetAnim.value,
                          child: child,
                        ),
                        child: widget.child,
                      ),
                    )
                  : SizedBox(),
            ),
          ),
        ),
      ],
    );
  }
}
