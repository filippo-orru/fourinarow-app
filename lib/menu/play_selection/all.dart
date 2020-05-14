// export 'play_locally.dart';
import 'dart:math';
import 'package:four_in_a_row/inherit/connection/server_conn.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/menu/account/offline.dart';
import 'package:four_in_a_row/menu/main_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/menu/play_selection/common.dart';
import 'package:four_in_a_row/menu/play_selection/online.dart';
import 'package:four_in_a_row/play/local/play_local.dart';
import 'package:four_in_a_row/play/online/play_online.dart';

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
      setState(() {
        offset = pageCtrl.position.pixels;
        page = pageCtrl.page;
      });
    });
  }

  double offset = 0;
  double page = 0;

  void backgroundTapped() {
    // TODO speed up waves?
  }

  void playOnline() {
    var serverConn = ServerConnProvider.of(context);
    if (serverConn.connected) {
      serverConn.startGame(ORqWorldwide());
      // Navigator.of(context).push(fadeRoute(child: PlayingOnline()));
    } else {
      Navigator.of(context)
          .push(slideUpRoute(OfflineScreen(OfflineCaller.OnlineMatch)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
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
              // Container(
              //   constraints: BoxConstraints.expand(),
              //   color: Colors.purpleAccent,
              // ),
            ],
            controller: pageCtrl,
          ),
        ),
        Waves(MediaQuery.of(context).size.height),
        Stack(
          children: [
            PlaySelectionScreen(
              index: 0,
              title: 'Online',
              description: 'You against the world!',
              content: PlayOnline(),
              pushRoute: playOnline,
              offset: offset,
              bgColor: Colors.redAccent,
            ),
            PlaySelectionScreen(
              index: 1,
              title: 'Local',
              description: 'Two players, one device!',
              offset: offset,
              pushRoute: () =>
                  Navigator.of(context).push(fadeRoute(child: PlayingLocal())),
              bgColor: Colors.blueAccent,
            ),
            // PlaySelectionScreen(
            //   index: 2,
            //   title: 'Online (WW)',
            //   description: 'You against the world!',
            //   route: fadeRoute(
            //       child: PlayingOnline(
            //     req: ORqWorldwide(),
            //   )),
            //   bgColor: Colors.purpleAccent,
            //   offset: offset,
            // ),
          ],
        ),
        PageIndicator(page, 2),
        SwipeDialog(),
      ],
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
        new AnimationController(duration: Duration(seconds: 12), vsync: this);
    offsetTween = Tween(
      begin: Offset.fromDirection(pi / 2, viewHeight / 128 + 4),
      end: Offset(0, -1),
    );
    offsetAnim.repeat();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: offsetAnim.drive(offsetTween),
      child: Image.asset("assets/img/wave_bg.png"),
    );
  }

  @override
  void dispose() {
    offsetAnim.dispose();
    super.dispose();
  }
}

class PageIndicator extends StatelessWidget {
  PageIndicator(this.page, this.pagesCount);

  final double page;
  final int pagesCount;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: (40 * pagesCount).toDouble(),
        // height: 20,
        margin: EdgeInsets.symmetric(vertical: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(pagesCount, (index) {
            double factor = 0;
            if ((index - page).abs() < 1) {
              factor = (1 - (index - page).abs());
            }

            return Container(
              width: 12,
              height: 12,
              child: Center(
                child: Container(
                  height: 7 + 5 * factor,
                  width: 7 + 5 * factor,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white54.withOpacity(1 / 3 + 2 * factor / 3),
                  ),
                  child: SizedBox(),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class SwipeDialog extends StatefulWidget {
  @override
  _SwipeDialogState createState() => _SwipeDialogState();
}

class _SwipeDialogState extends State<SwipeDialog>
    with SingleTickerProviderStateMixin {
  SharedPreferences _prefs;
  bool _show = false;
  bool _triedItOut = false;

  AnimationController animCtrl;

  @override
  void initState() {
    super.initState();
    _checkPrefs();

    animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
      reverseDuration: Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(Duration(milliseconds: 700), animCtrl.reverse);
        }
      });

    animCtrl.drive(CurveTween(curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    this.animCtrl.dispose();
    super.dispose();
  }

  void remindToTryOut() {
    this.animCtrl.reverse();
    this.animCtrl.forward();
  }

  void _checkPrefs() async {
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    if (_prefs.containsKey('shown_swype_dialog')) {
      // this._show = true;
      this._show = !_prefs.getBool('shown_swype_dialog');
    } else {
      this._show = true;
      await _prefs.setBool('shown_swype_dialog', false);
    }
    setState(() {});
  }

  void tappedDialog() async {
    if (_triedItOut) {
      if (_prefs != null) {
        setState(() => this._show = false);
        await _prefs.setBool('shown_swype_dialog', true);
      }
    } else {
      remindToTryOut();
    }
  }

  void triedItOut(DragEndDetails d) {
    setState(() => this._triedItOut = true);
    Future.delayed(Duration(milliseconds: 750), tappedDialog);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 330),
      child: _show
          ? GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: triedItOut,
              onTapDown: (_) => tappedDialog(),
              child: Container(
                constraints: BoxConstraints.expand(),
                color: Colors.black38,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        // constraints: BoxConstraints.expand(),
                        //  BoxConstraints.tightFor(
                        // height:
                        //
                        // ),
                        width:
                            min(MediaQuery.of(context).size.width * 0.8, 256),
                        height:
                            min(MediaQuery.of(context).size.height * 0.4, 130),
                        // height: double.infinity,
                        // width: double.infinity,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 5,
                              color: Colors.black26,
                              offset: Offset(0, 4),
                            )
                          ],
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Swipe horizontally to play online!',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 24),
                            _triedItOut
                                ? Text('Great!',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                    ))
                                : Text(
                                    'Try it out!',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 18,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Spacer(flex: 20),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SlideIndicator(),
                        ),
                        Spacer(flex: 1),
                        AnimatedBuilder(
                          animation: animCtrl,
                          builder: (ctx, child) =>
                              Opacity(child: child, opacity: animCtrl.value),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            // width: 190,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                              color: Colors.white.withOpacity(0.82),
                            ),
                            child: Text('Try swyping from side to side!',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87)),
                          ),
                        ),
                        Spacer(flex: 2),
                      ],
                    )
                  ],
                ),
              ),
            )
          : SizedBox(),
    );
  }
}

class SlideIndicator extends StatefulWidget {
  const SlideIndicator({
    Key key,
  }) : super(key: key);

  @override
  _SlideIndicatorState createState() => _SlideIndicatorState();
}

class _SlideIndicatorState extends State<SlideIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController animCtrl;
  // Animation<double> moveLeft;
  CurveTween fade;

  @override
  void initState() {
    super.initState();
    animCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1400))
          ..forward()
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Future.delayed(Duration(milliseconds: 500), () {
                animCtrl.reset();
                animCtrl.forward();
              });
            }
          });
    fade = CurveTween(curve: Curves.easeOutCubic);

    // moveLeft = Tween<double>(begin: 0, )
  }

  @override
  void dispose() {
    this.animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.55,
      height: 25,
      child: Stack(
        // alignment: Alignment.center,
        // children: [
        // Center(
        //     child: Container(
        //   decoration: BoxDecoration(
        //     color: Colors.white12,
        //     borderRadius: BorderRadius.all(Radius.circular(100)),
        //   ),
        //   height: 8,
        // )),
        // Center(
        children: [
          AnimatedBuilder(
            animation: animCtrl,
            builder: (ctx, child) => Opacity(
              opacity: 1 - animCtrl.value,
              child: Transform.translate(
                offset: Offset(
                  MediaQuery.of(context).size.width *
                      0.5 *
                      (1 - fade.animate(animCtrl).value),
                  0,
                ),
                child: child,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.all(Radius.circular(100)),
              ),
              width: 25,
              height: 25,
            ),
          ),
        ],
        // ),
      ),
    );
  }
}
