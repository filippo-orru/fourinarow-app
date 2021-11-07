//https://github.com/pkmangukiya/SwipeDetector/blob/main/swipedetector.dart

import 'package:flutter/material.dart';

class SwipeConfiguration {
  //Vertical swipe configuration options
  final double verticalSwipeMaxWidthThreshold;
  final double verticalSwipeMinDisplacement;
  final double verticalSwipeMinVelocity;

  //Horizontal swipe configuration options
  final double horizontalSwipeMaxHeightThreshold;
  final double horizontalSwipeMinDisplacement;
  final double horizontalSwipeMinVelocity;

  const SwipeConfiguration({
    this.verticalSwipeMaxWidthThreshold = 50.0,
    this.verticalSwipeMinDisplacement = 100.0,
    this.verticalSwipeMinVelocity = 300.0,
    this.horizontalSwipeMaxHeightThreshold = 50.0,
    this.horizontalSwipeMinDisplacement = 100.0,
    this.horizontalSwipeMinVelocity = 300.0,
  });
}

class SwipeDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final SwipeConfiguration swipeConfiguration;

  const SwipeDetector({
    required this.child,
    this.onTap,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.swipeConfiguration = const SwipeConfiguration(),
  });

  @override
  Widget build(BuildContext context) {
    //Vertical drag details
    DragStartDetails? startVerticalDragDetails;
    DragUpdateDetails? updateVerticalDragDetails;

    //Horizontal drag details
    DragStartDetails? startHorizontalDragDetails;
    DragUpdateDetails? updateHorizontalDragDetails;

    return GestureDetector(
      child: child,
      onTap: onTap,
      onVerticalDragStart: (dragDetails) {
        startVerticalDragDetails = dragDetails;
      },
      onVerticalDragUpdate: (dragDetails) {
        updateVerticalDragDetails = dragDetails;
      },
      onVerticalDragEnd: (endDetails) {
        double dx = updateVerticalDragDetails?.globalPosition.dx ??
            0 - (startVerticalDragDetails?.globalPosition.dx ?? 0);
        double dy = updateVerticalDragDetails?.globalPosition.dy ??
            0 - (startVerticalDragDetails?.globalPosition.dy ?? 0);
        double velocity = endDetails.primaryVelocity ?? 0.0;

        //Convert values to be positive
        if (dx < 0) dx = -dx;
        if (dy < 0) dy = -dy;
        double positiveVelocity = velocity < 0 ? -velocity : velocity;

        if (dx > swipeConfiguration.verticalSwipeMaxWidthThreshold) return;
        if (dy < swipeConfiguration.verticalSwipeMinDisplacement) return;
        if (positiveVelocity < swipeConfiguration.verticalSwipeMinVelocity) return;

        if (velocity < 0) {
          //Swipe Up
          if (onSwipeUp != null) {
            onSwipeUp?.call();
          }
        } else {
          //Swipe Down
          if (onSwipeDown != null) {
            onSwipeDown?.call();
          }
        }
      },
      onHorizontalDragStart: (dragDetails) {
        startHorizontalDragDetails = dragDetails;
      },
      onHorizontalDragUpdate: (dragDetails) {
        updateHorizontalDragDetails = dragDetails;
      },
      onHorizontalDragEnd: (endDetails) {
        double dx = (updateHorizontalDragDetails?.globalPosition.dx ?? 0) -
            (startHorizontalDragDetails?.globalPosition.dx ?? 0);
        double dy = (updateHorizontalDragDetails?.globalPosition.dy ?? 0) -
            (startHorizontalDragDetails?.globalPosition.dy ?? 0);
        double velocity = endDetails.primaryVelocity ?? 0.0;

        if (dx < 0) dx = -dx;
        if (dy < 0) dy = -dy;
        double positiveVelocity = velocity < 0 ? -velocity : velocity;

        if (dx < swipeConfiguration.horizontalSwipeMinDisplacement) return;
        if (dy > swipeConfiguration.horizontalSwipeMaxHeightThreshold) return;
        if (positiveVelocity < swipeConfiguration.horizontalSwipeMinVelocity) return;

        if (velocity < 0) {
          //Swipe Left
          onSwipeLeft?.call();
        } else {
          //Swipe Right
          onSwipeRight?.call();
        }
      },
    );
  }
}
