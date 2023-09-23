import 'package:flutter/widgets.dart';

class MyScrollConfiguration extends ScrollConfiguration {
  final Widget child;

  MyScrollConfiguration({required this.child, required Color color})
      : super(child: child, behavior: MyScrollBehavior(color: color));
}

class MyScrollBehavior extends ScrollBehavior {
  final Color color;

  MyScrollBehavior({required this.color});

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // _MaterialScrollBehavior as well.
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return GlowingOverscrollIndicator(
          child: child,
          axisDirection: details.direction,
          color: color,
        );
    }
  }
}

class MyColorTween extends Tween<Color> {
  MyColorTween({Color? begin, Color? end}) : super(begin: begin, end: end);

  @override
  Color lerp(double t) => Color.lerp(begin, end, t)!;
}
