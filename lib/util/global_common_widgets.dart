import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/swipe_detector.dart';

class FiarBottomSheet extends StatefulWidget {
  static const double HEIGHT = _CONT_HEIGHT + _MARGIN;
  static const double _CONT_HEIGHT = 78;
  static const double _MARGIN = 24;
  static const double DEFAULT_EXPANDED_HEIGHT = 400;

  final List<Widget> children;
  final List<Widget> topChildren;
  final ColorSwatch<int> color;
  final double expandedHeight;
  final bool disabled;

  const FiarBottomSheet({
    required this.topChildren,
    required this.children,
    required this.color,
    this.expandedHeight = DEFAULT_EXPANDED_HEIGHT,
    this.disabled = false,
    Key? key,
  }) : super(key: key);

  @override
  _FiarBottomSheetState createState() => _FiarBottomSheetState();
}

class _FiarBottomSheetState extends State<FiarBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController animCtrl;
  late Animation<double> moveUpAnim;
  late Animation<double> rotateAnim;
  late Animation<double> opacityAnim;
  bool expanded = false;

  Future<void> show() async {
    await Future.delayed(Duration(milliseconds: 30));

    setState(() => expanded = true);
    await animCtrl.forward();
  }

  Future<void> hide() async {
    await animCtrl.reverse();
    setState(() => expanded = false);
  }

  @override
  void initState() {
    super.initState();

    animCtrl = AnimationController(
      vsync: this,
      duration:
          Duration(milliseconds: (widget.expandedHeight * 0.3).toInt() + 140),
    );

    moveUpAnim = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeInOutQuart))
        .animate(animCtrl);

    rotateAnim = Tween<double>(begin: 0, end: 0.5)
        .chain(CurveTween(curve: Curves.easeInOutQuart))
        .animate(animCtrl);

    opacityAnim = Tween<double>(begin: 0, end: 0.3)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(animCtrl);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));

    return WillPopScope(
      onWillPop: () async {
        if (expanded) {
          await hide();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        top: 0,
        // width: double.infinity,
        child: Stack(
          fit: StackFit.loose,
          alignment: Alignment.bottomCenter,
          children: [
            expanded
                ? GestureDetector(
                    behavior: expanded
                        ? HitTestBehavior.opaque
                        : HitTestBehavior.translucent,
                    onTap: () {
                      if (expanded) hide();
                    },
                    child: AnimatedBuilder(
                      animation: animCtrl,
                      builder: (ctx, child) => Container(
                        constraints: BoxConstraints.expand(),
                        color: Colors.black.withOpacity(opacityAnim.value),
                      ),
                    ),
                  )
                : SizedBox(),
            AnimatedBuilder(
              animation: animCtrl,
              builder: (ctx, child) => SizedOverflowBox(
                alignment: Alignment.topCenter,
                size: Size(
                  double.infinity,
                  FiarBottomSheet._CONT_HEIGHT +
                      moveUpAnim.value * widget.expandedHeight,
                ),
                child: child,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height,
                // height: HEIGHT,
                // padding: EdgeInsets.only(top: 12),
                // height: double.infinity,
                // constraints: BoxConstraints.expand(),
                // color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.all(6),
                      // margin: EdgeInsets.only(left: 6, top: 6, right: 6, bottom: 6),
                      // padding: EdgeInsets.only(top: 5),
                      height: FiarBottomSheet._CONT_HEIGHT - 12,
                      // constraints:
                      //     BoxConstraints.tightFor(height: FiarBottomSheet._CONT_HEIGHT),
                      child: Container(
                        // margin: EdgeInsets.only(top: 6),
                        constraints: BoxConstraints.expand(),
                        // padding: EdgeInsets.only(left: 24, right: 24),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 5,
                              color: Colors.black12,
                            )
                          ],
                          borderRadius: BorderRadius.all(
                              // topLeft: Radius.circular(24),
                              Radius.circular(24)),
                          color: Colors.white,
                        ),
                        // child:
                        // AbsorbPointer(
                        //   absorbing: widget.disabled,
                        child: SwipeDetector(
                          swipeConfiguration: SwipeConfiguration(
                            verticalSwipeMinDisplacement: 40,
                            verticalSwipeMinVelocity: 220,
                          ),
                          onSwipeUp: () {
                            if (!expanded) show();
                          },
                          onSwipeDown: () {
                            if (expanded) hide();
                          },
                          child: Material(
                            type: MaterialType.transparency,
                            // color: Colors.red,

                            child:
                                // widget.disabled
                                //     ? Container(child: buildTopChildren())
                                //     :
                                InkResponse(
                              containedInkWell: true,
                              highlightShape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(24)),
                              onTap: widget.disabled
                                  ? null
                                  : () {
                                      if (expanded)
                                        hide();
                                      else
                                        show();
                                    },
                              splashColor:
                                  (widget.color[300] ?? widget.color[200]!)
                                      .withOpacity(0.5),
                              // focusColor: Colors.blue,
                              highlightColor:
                                  widget.color[100]!.withOpacity(0.5),
                              // hoverColor: Colors.green,
                              child: Padding(
                                padding: EdgeInsets.only(left: 24, right: 24),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: widget.topChildren +
                                      [
                                        RotationTransition(
                                          turns: rotateAnim,
                                          child: IconButton(
                                            onPressed: widget.disabled
                                                ? () {
                                                    if (expanded)
                                                      hide();
                                                    else
                                                      show();
                                                  }
                                                : null,
                                            icon: Icon(Icons.arrow_drop_up,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                ),
                              ),
                            ),
                            // ),
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: 24),
                    Container(
                      height: widget.expandedHeight,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 5,
                            color: Colors.black12.withOpacity(0.06),
                          )
                        ],
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        color: Colors.white,
                      ),
                      // height: MediaQuery.of(context).size.height / 8,
                      margin: EdgeInsets.symmetric(vertical: 12),
                      // child: InkWell(
                      // When the user taps the button, show a snackbar.
                      child: ListView(
                        // padding: EdgeInsets.zero,
                        padding: EdgeInsets.only(top: 24, bottom: 32),
                        children: widget.children,
                        // ),
                      ),
                    ),
                    // Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
