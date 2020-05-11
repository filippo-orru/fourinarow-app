import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/menu/common/play_button.dart';

class PlaySelectionScreen extends StatelessWidget {
  PlaySelectionScreen({
    @required this.index,
    @required this.title,
    @required this.description,
    @required this.offset,
    this.content,
    this.pushRoute,
    this.bgColor = Colors.white,
  }) : assert(content != null || pushRoute != null);

  final int index;
  final String title;
  final String description;
  final Widget content;
  final double offset;
  final VoidCallback pushRoute;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    double viewWidth = MediaQuery.of(context).size.width;
    return ClipRect(
      clipper: PageClipper(max(index * viewWidth - offset, 0),
          max((index + 1) * viewWidth - offset, 0)),
      child: PlaySelectionContent(
        title: title,
        description: description,
        pushRoute: pushRoute,
        content: content,
        bgColor: bgColor,
      ),
    );
  }
}

class PlaySelectionContent extends StatelessWidget {
  PlaySelectionContent({
    @required this.title,
    @required this.description,
    this.content,
    this.pushRoute,
    // this.navigateTo,
    this.bgColor = Colors.white,
    // this.ctrl,
  }) : assert(content != null || pushRoute != null);

  final String title;
  final String description;
  final Widget content;
  final VoidCallback pushRoute;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints.expand(),
        padding:
            EdgeInsets.all(min(MediaQuery.of(context).size.width * 0.08, 36)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Flexible(
            //   flex: 4,
            //   child:
            // FittedBox(
            //   child:
            buildHeading(),
            // ),
            // ),
            SizedBox(height: 12),
            // ),
            // Flexible(
            //   flex: 5,
            //   child:
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.center,
                child: content ?? SizedBox(),
              ),
            ),
            // ),
            // Flexible(child:
            // LimitedBox(
            //   maxHeight: 48,
            //   child:
            SizedBox(height: 12),
            // ),
            // Flexible(
            //   flex: 4,
            //   child:
            Align(
              alignment: Alignment.bottomCenter,
              child: FittedBox(
                child: PlayButton(
                  label: 'Go!',
                  color: Colors.white38,
                  onTap: pushRoute,
                ),
              ),
            ),
            // Flexible(child:
            SizedBox(height: 96)
            // ),
          ],
        ),
      ),
    );
  }

  Column buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Four in a Row",
          style: TextStyle(
            fontFamily: 'RobotoSlab',
            color: Colors.white.withOpacity(0.8),
            fontSize: 24,
          ),
        ),
        Text(
          this.title,
          style: TextStyle(
            fontFamily: 'RobotoSlab',
            color: Colors.white,
            fontSize: 42,
            // fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          this.description,
          style: TextStyle(
            // fontFamily: 'RobotoSlab',
            color: Colors.white70,
            fontSize: 20,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class PageClipper extends CustomClipper<Rect> {
  PageClipper(this.left, this.right);

  final double left;
  final double right;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(left, 0, right, 1000);
  }

  @override
  bool shouldReclip(oldClipper) => oldClipper != this;
}
