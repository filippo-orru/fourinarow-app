import 'package:flutter/widgets.dart';

class MyScrollConfiguration extends ScrollConfiguration {
  final Widget child;

  MyScrollConfiguration({required this.child, required Color color})
      : super(child: child, behavior: _MyScrollBehavior(color));
}

class _MyScrollBehavior extends ScrollBehavior {
  final Color color;

  _MyScrollBehavior(this.color);

  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
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
          axisDirection: axisDirection,
          color: color,
        );
    }
  }
}

class MyColorTween extends Tween<Color> {
  /// Creates a [Color] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as transparent.
  ///
  /// We recommend that you do not pass [Colors.transparent] as [begin]
  /// or [end] if you want the effect of fading in or out of transparent.
  /// Instead prefer null. [Colors.transparent] refers to black transparent and
  /// thus will fade out of or into black which is likely unwanted.
  MyColorTween({Color? begin, Color? end}) : super(begin: begin, end: end);

  /// Returns the value this variable has at the given animation clock value.
  @override
  Color lerp(double t) => Color.lerp(begin, end, t)!;
}
