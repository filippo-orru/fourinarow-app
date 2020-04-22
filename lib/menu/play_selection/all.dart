// export 'play_locally.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/menu/common/play_button.dart';
import 'package:four_in_a_row/menu/play_selection/common.dart';
import 'package:four_in_a_row/menu/play_selection/online_friends.dart';
import 'package:four_in_a_row/play/play_local.dart';
import 'package:four_in_a_row/play/play_online.dart';

import '../common/menu_common.dart';

// abstract class PlaySelection extends StatefulWidget {
//   PlaySelection({Key key}) : super(key: key);
// }

class PlaySelection extends StatefulWidget {
  createState() => _PlaySelectionState();

  static PageRouteBuilder route() {
    return fadeRoute(child: PlaySelection());
  }
}

class _PlaySelectionState extends State<PlaySelection> {
  final PageController pageCtrl = PageController(
    initialPage: 0,
  );
  _PlaySelectionState() {
    pageCtrl.addListener(() {
      setState(() => offset = pageCtrl.position.pixels);
    });
  }

  double offset = 0;

  void backgroundTapped() {
    // TODO speed up waves?
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GestureDetector(
            onTap: backgroundTapped,
            child: PageView(
              children: <Widget>[
                Container(
                  constraints: BoxConstraints.expand(),
                  color: Colors.redAccent,
                ),
                Container(
                  constraints: BoxConstraints.expand(),
                  color: Colors.blueAccent,
                ),
                Container(
                  constraints: BoxConstraints.expand(),
                  color: Colors.purpleAccent,
                ),
              ],
              controller: pageCtrl,
            ),
          ),
          Waves(MediaQuery.of(context).size.height),
          Stack(
            children: [
              PlaySelectionScreen(
                index: 0,
                title: 'Local',
                description: 'Two players, one device!',
                offset: offset,
                route: fadeRoute(child: PlayingLocal()),
                bgColor: Colors.redAccent,
              ),
              PlaySelectionScreen(
                index: 1,
                title: 'Online (Friends)',
                description: 'Play with your friends!',
                content: PlayOnlineFriends(),
                bgColor: Colors.blueAccent,
                offset: offset,
              ),
              PlaySelectionScreen(
                index: 2,
                title: 'Online (WW)',
                description: 'You against the world!',
                route: fadeRoute(
                    child: PlayingOnline(
                  req: ORqWorldwide(),
                )),
                bgColor: Colors.purpleAccent,
                offset: offset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Waves extends StatefulWidget {
  final initialViewHeight;
  Waves(this.initialViewHeight);

  @override
  _WavesState createState() => _WavesState(initialViewHeight);
}

class _WavesState extends State<Waves> with SingleTickerProviderStateMixin {
  _WavesState(this.viewHeight);

  double viewHeight;

  AnimationController offsetAnim;
  Tween<Offset> offsetTween;

  @override
  void initState() {
    super.initState();
    offsetAnim =
        new AnimationController(duration: Duration(seconds: 6), vsync: this);
    offsetTween = Tween(
      begin: Offset(0, viewHeight),
      end: Offset.zero,
    );
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
        position: offsetAnim.drive(offsetTween),
        child: Image.asset("assets/img/wave_bg.png"));
  }

  @override
  void dispose() {
    offsetAnim.dispose();
    super.dispose();
  }
}
