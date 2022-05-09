import 'dart:async';

import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:four_in_a_row/lottie/reaction.dart';
import 'package:four_in_a_row/util/extensions.dart';

abstract class RateDialogState {}

class RDSIdle extends RateDialogState {}

class RDSLowRating extends RateDialogState {}

class RDSHighRating extends RateDialogState {
  final int number;

  RDSHighRating(this.number);
}

class RDSDonate extends RateDialogState {}

class RateTheGameDialog extends StatefulWidget {
  static show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => RateTheGameDialog(),
    );
  }

  @override
  _RateTheGameDialogState createState() => _RateTheGameDialogState();
}

class _RateTheGameDialogState extends State<RateTheGameDialog> with SingleTickerProviderStateMixin {
  RateDialogState state = RDSIdle();

  void highRating() {
    setState(() => state = RDSHighRating(5));
  }

  void lowRating() {
    // show feedback
    setState(() => state = RDSLowRating());
  }

  List<Widget> buildBody() {
    var state = this.state;

    if (state is RDSIdle) {
      return [
        Text.rich(
          TextSpan(children: [
            TextSpan(
                text:
                    "My name's Filippo and I develop this game in my free time. Help me make it even better by donating or "),
            TextSpan(text: "rating the game", style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            LottieReaction(
              name: 'sad',
              onTap: () => lowRating(),
            ),
            LottieReaction(
              name: 'neutral',
              onTap: () => lowRating(),
            ),
            LottieReaction(
              name: 'happy',
              startsGrey: false,
              onTap: () => highRating(),
            ),
          ],
        ),
        // FiveStarsPicker(
        //   onPick: (number) {
        //     print("Picked $number stars");
        //     if (number < 3) {
        //       this.state = RDSLowRating();
        //     } else {
        //       this.state = RDSHighRating(number);
        //     }
        //     setState(() {});
        //   },
        // ),
      ];
    } else if (state is RDSLowRating) {
      return [Text('Thanks! Do you have feedback for me?'), TextField()];
    } else if (state is RDSHighRating) {
      return [
        FiveStarsPicker(number: state.number),
        Text('Thanks!\nWould you also rate on the Google Play Store?\nIt helps me a lot! 🙂'),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No thanks', style: TextStyle(color: Colors.grey[500])),
            ),
            ElevatedButton(
              child: Text('Rate!'),
              onPressed: () async {
                AndroidIntent intent = AndroidIntent(
                  action: 'action_view',
                  data: 'https://play.google.com/store/apps/details?'
                      'id=ml.fourinarow',
                );
                await intent.launch();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ];
    } else {
      throw UnimplementedError("This state is not implemented");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
        'Enjoyed that Game?',
        style: TextStyle(
          fontFamily: 'RobotoSlab',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        AnimatedSize(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: Column(key: ValueKey(state), children: buildBody()),
          ),
        ),
      ],
    );
  }
}

class FiveStarsPicker extends StatefulWidget {
  final int? number;
  final void Function(int)? onPick;

  const FiveStarsPicker({Key? key, this.number, this.onPick})
      : assert((number != null) != (onPick != null)),
        super(key: key);

  @override
  _FiveStarsPickerState createState() => _FiveStarsPickerState();
}

class _FiveStarsPickerState extends State<FiveStarsPicker> with SingleTickerProviderStateMixin {
  final Duration perStarDuration = Duration(milliseconds: 150);

  Timer? selectedDelay;

  int animSelectionGoalDelta = 0; // 0: idle, -5: go down five stars
  late final AnimationController changeSelectionAnim;

  Timer? starBounceDelay;
  int? starBounceIndex;

  @override
  void initState() {
    super.initState();

    changeSelectionAnim = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 5,
    )..addListener(() {
        checkAnimation();
      });

    if (widget.number != null) {
      this.changeSelectionAnim.value = widget.number!.toDouble();
    }
  }

  @override
  void dispose() {
    changeSelectionAnim.dispose();
    super.dispose();
  }

  void checkAnimation() {
    if (!changeSelectionAnim.isAnimating && animSelectionGoalDelta != 0) {
      double val = changeSelectionAnim.value;
      int delta = animSelectionGoalDelta > 0 ? 1 : -1;
      animSelectionGoalDelta -= delta;
      changeSelectionAnim.animateTo(
        val + delta,
        duration: perStarDuration,
      );
      // starBounceDelay?.cancel();
      // starBounceDelay = Timer(animDuration, () {
      setState(() {
        starBounceIndex = val.toInt() + delta;
      });
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Align(
        alignment: Alignment.center,
        child: widget.number != null
            ? Container(
                width: 150 + 12,
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.yellow[800]!.withOpacity(0.13),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: 1.to(5).map((i) {
                    return Icon(
                      Icons.star,
                      size: 28,
                      color: Colors.yellow[700],
                    );
                  }).toList(),
                ),
              )
            : Container(
                width: 150,
                child: Stack(
                  children: [
                    WidgetMask(
                      maskChild: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: 1.to(5).map((i) {
                          return BounceWidget(
                            active: starBounceIndex == i,
                            child: Icon(
                              Icons.star,
                              size: 28,
                              color: Colors.yellow[700],
                            ),
                          );
                        }).toList(),
                      ),
                      child: AnimatedBuilder(
                        animation: changeSelectionAnim.drive(CurveTween(curve: Curves.easeInOut)),
                        builder: (_, __) => Container(
                          width: ((changeSelectionAnim.value) / 5) * 150,
                          height: 24,
                          color: Colors.yellow[700],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: 1.to(5).map((i) {
                        return Flexible(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              var onPick = widget.onPick;
                              if (onPick != null) {
                                // print("ONTAP: $i");
                                animSelectionGoalDelta = i - changeSelectionAnim.value.ceil();
                                checkAnimation();

                                selectedDelay?.cancel();
                                selectedDelay = Timer(
                                    perStarDuration * (animSelectionGoalDelta.abs() + 2.5), () {
                                  onPick(i);
                                });
                              }
                            },
                            child: () {
                              bool active = false;
                              if (starBounceIndex == i) {
                                active = true;
                                if (animSelectionGoalDelta != 0) {
                                  // print("star $i setting bounce to null");
                                  setState(() => starBounceIndex = null);
                                }
                              }
                              return BounceWidget(
                                active: active,
                                child: Icon(
                                  Icons.star_border,
                                  size: 28,
                                  color: Colors.yellow[700],
                                ),
                              );
                            }(),
                          ),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),
      ),
    );
  }
}

class BounceWidget extends StatefulWidget {
  final bool active;
  final int duration;
  final double maxScaleFactor;
  final Widget child;

  const BounceWidget({
    Key? key,
    required this.active,
    required this.child,
    this.duration = 60,
    this.maxScaleFactor = 1.33,
  }) : super(key: key);

  @override
  _BounceWidgetState createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<BounceWidget> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1, end: widget.active ? widget.maxScaleFactor : 1),
      duration: Duration(milliseconds: widget.duration),
      builder: (ctx, value, child) => Transform.scale(scale: value as double, child: child),
      child: widget.child,
    );
  }
}

class RenderWidgetMask extends RenderStack {
  RenderWidgetMask({
    List<RenderBox> children = const [],
    required AlignmentGeometry alignment,
    required TextDirection textDirection,
    required StackFit fit,
    required Clip clipBehavior,
  }) : super(
          children: children,
          alignment: alignment,
          textDirection: textDirection,
          fit: fit,
          clipBehavior: clipBehavior,
        );

  @override
  void paintStack(context, offset) {
    // Early exit on no children
    if (firstChild == null) return;

    final paintContent = (PaintingContext context, Offset offset) {
      // Paint all but the first child
      RenderBox? child = (firstChild!.parentData as StackParentData?)?.nextSibling;
      while (child != null) {
        final childParentData = child.parentData as StackParentData;
        context.paintChild(lastChild!, offset + childParentData.offset);
        child = childParentData.nextSibling;
      }
    };

    final paintMask = (PaintingContext context, Offset offset) {
      context.paintChild(firstChild!, offset + (firstChild!.parentData as StackParentData).offset);
    };

    final paintEverything = (PaintingContext context, Offset offset) {
      paintContent(context, offset);
      context.canvas.saveLayer(offset & size, Paint()..blendMode = BlendMode.dstIn);
      paintMask(context, offset);
      context.canvas.restore();
    };

    // Force the foreground content to be composited onto this layer
    context.pushOpacity(offset, 255, paintEverything);
  }
}

/// Is a simple wrapper around the `Stack` widget that creates a custom stack based render object
class WidgetMask extends Stack {
  WidgetMask({
    Key? key,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection textDirection = TextDirection.ltr,
    StackFit fit = StackFit.loose,
    Clip clipBehavior = Clip.antiAlias,
    required Widget maskChild,
    required Widget child,
  }) : super(
          key: key,
          alignment: alignment,
          textDirection: textDirection,
          fit: fit,
          clipBehavior: clipBehavior,
          children: [maskChild, child],
        );

  @override
  RenderStack createRenderObject(context) {
    return RenderWidgetMask(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.of(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderWidgetMask renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}
