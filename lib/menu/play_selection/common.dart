import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/menu/common/play_button.dart';

class PlaySelectionScreen extends StatelessWidget {
  PlaySelectionScreen({
    @required this.index,
    @required this.title,
    @required this.description,
    @required this.offset,
    this.content,
    this.route,
    this.bgColor = Colors.white,
  }) : assert(content != null || route != null);

  final int index;
  final String title;
  final String description;
  final Widget content;
  final double offset;
  final PageRouteBuilder route;
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
        route: route,
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
    this.route,
    // this.navigateTo,
    this.bgColor = Colors.white,
    // this.ctrl,
  }) : assert(content != null || route != null);

  final String title;
  final String description;
  final Widget content;
  final PageRouteBuilder route;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Four in a Row",
                    style: TextStyle(
                      fontFamily: 'Arvo',
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
              ),
            ),
            Center(
              child: content ??
                  PlayButton(
                    label: 'Go!',
                    color: Colors.white38,
                    onTap: () => Navigator.of(context).push(route),
                  ),
            ),
            SizedBox(height: 64),
          ],
        ),
      ),
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
