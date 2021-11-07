import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/util/extensions.dart';
import 'package:four_in_a_row/inherit/route.dart';
import 'package:four_in_a_row/menu/account/offline.dart';
import 'package:four_in_a_row/menu/main_menu.dart';
import 'package:four_in_a_row/menu/outdated.dart';
import 'package:four_in_a_row/play/models/cpu/cpu.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/other.dart';
import 'package:four_in_a_row/play/widgets/cpu/play_cpu.dart';
import 'package:four_in_a_row/menu/play_selection/common.dart';
import 'package:four_in_a_row/menu/play_selection/online.dart';
import 'package:four_in_a_row/play/widgets/local/play_local.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/swipe_detector.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:four_in_a_row/util/toast.dart';

import 'dart:math';

import 'package:provider/provider.dart';

import 'package:flutter/material.dart';

class PlaySelection extends StatefulWidget {
  const PlaySelection({Key? key}) : super(key: key);

  createState() => _PlaySelectionState();

  static PageRouteBuilder route() {
    return fadeRoute(PlaySelection());
  }
}

class _PlaySelectionState extends State<PlaySelection> with RouteAware {
  final PageController pageCtrl = PageController(
    initialPage: 0,
  );

  _PlaySelectionState() {
    pageCtrl.addListener(() {
      setState(() {
        offset = pageCtrl.position.pixels;
        page = pageCtrl.page ?? 0.0;
      });
    });
  }

  double offset = 0;
  double page = 0;

  ToastState? toast;

  CpuDifficulty _selectedDificulty = CpuDifficulty.HARD;

  void backgroundTapped() {
    // TODO speed up waves?
  }

  void tappedPlayOnline() async {
    if (!mounted) return;

    if (await context.read<ServerConnection>().serverIsDown) {
      await showDialog(
        context: context,
        builder: (ctx) => ServerIsDownDialog(),
      );
      return;
    }

    var shownDialogCount = FiarSharedPrefs.shownOnlineDialogCount;
    if (shownDialogCount <= 2) {
      await showDialog(
        context: context,
        builder: (ctx) =>
            OnlineInfoDialog(howManyMoreTimes: 2 - shownDialogCount),
      );
      FiarSharedPrefs.shownOnlineDialogCount = shownDialogCount + 1;
    }

    var gsm = context.read<GameStateManager>();
    if (gsm.outdated) {
      Navigator.of(context).push(slideUpRoute(OutDatedDialog()));
    } else if (gsm.connected) {
      await gsm.startGame(ORqWorldwide());
      // Navigator.of(context).push(slideUpRoute(OfflineScreen()));
      // Navigator.of(context).push(fadeRoute(GameStateViewer()));
    } else {
      Navigator.of(context).push(slideUpRoute(OfflineScreen()));
    }
  }

  late RouteObserver _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = RouteObserverProvider.of(context).observer
      ..subscribe(this, ModalRoute.of(context)!);
    SystemUiStyle.playSelection();
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    SystemUiStyle.playSelection();
  }

  @override
  void didPopNext() {
    SystemUiStyle.playSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // GestureDetector(
        //   behavior: HitTestBehavior.translucent,
        //   onTap: backgroundTapped,
        //   child:
        Material(
          child: PageView(
            children: [
              Container(
                constraints: BoxConstraints.expand(),
                color: Colors.redAccent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: SwitchPageButton(pageCtrl),
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints.expand(),
                color: Colors.blueAccent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Stack(children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: SwitchPageButton(pageCtrl, forward: false),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: SwitchPageButton(pageCtrl, forward: true),
                    ),
                  ]),
                ),
              ),
              Container(
                constraints: BoxConstraints.expand(),
                color: Colors.deepPurple,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: SwitchPageButton(pageCtrl, forward: false),
                  ),
                ),
              ),
            ],
            controller: pageCtrl,
          ),
        ),
        Waves(MediaQuery.of(context).size.height),
        Stack(
          children: [
            Selector<GameStateManager, bool>(
              selector: (_, gsm) =>
                  gsm.currentGameState is WaitingForWWOpponentState,
              builder: (_, isInQueue, __) => PlaySelectionScreen(
                index: 0,
                title: 'Online',
                description: 'You against the world!',
                loading: isInQueue,
                showTransition: false,
                content: MenuContentPlayOnline(),
                pushRoute: tappedPlayOnline,
                offset: offset,
                bgColor: Colors.redAccent,
              ),
            ),
            PlaySelectionScreen(
              index: 1,
              title: 'Local',
              loading: false,
              showTransition: true,
              description: 'Two players, one device!',
              offset: offset,
              pushRoute: () =>
                  Navigator.of(context).push(fadeRoute(PlayingLocal())),
              bgColor: Colors.blueAccent,
            ),
            PlaySelectionScreen(
              index: 2,
              title: 'CPU',
              loading: false,
              showTransition: true,
              description: 'You against the machine!',
              offset: offset,
              pushRoute: () => Navigator.of(context)
                  .push(fadeRoute(PlayingCPU(difficulty: _selectedDificulty))),
              bgColor: Colors.blueAccent,
            ),
          ],
        ),
        PageIndicator(page, 3),
        SwipeDialog(),
      ],
    );
  }
}

class FiarSimpleDialog extends StatelessWidget {
  final String title;
  final String content;
  final bool showOkay;

  const FiarSimpleDialog({
    Key? key,
    required this.title,
    required this.content,
    this.showOkay = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'RobotoSlab',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: EdgeInsets.all(16),
      children: [
        Text(
          content,
          style: TextStyle(color: Colors.black, fontSize: 16, height: 1.3),
        ),
        showOkay
            ? Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.lightBlue),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Okay'),
                ))
            : SizedBox(),
      ],
    );
  }
}

class OnlineInfoDialog extends StatelessWidget {
  const OnlineInfoDialog({
    Key? key,
    required this.howManyMoreTimes,
  }) : super(key: key);

  final int howManyMoreTimes;

  @override
  Widget build(BuildContext context) {
    return FiarSimpleDialog(
      title: 'Read before playing online',
      content: '''
▻ Finding another player could take a while, please be patient\n
▻ Chat or play locally while waiting\n
▻ Don't close the app so you will get a notification once a game is found

Dialog will show ${howManyMoreTimes.toNumberWord()} more time${howManyMoreTimes == 1 ? "" : "s"}.''',
    );
  }
}

class ServerIsDownDialog extends StatelessWidget {
  const ServerIsDownDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FiarSimpleDialog(
      title: 'Server is down!',
      content:
          'Sorry, the server is currently down for maintenance.\nPlease wait 10 minutes and try again',
    );
  }
}

class SwitchPageButton extends StatelessWidget {
  const SwitchPageButton(
    this.pageCtrl, {
    this.forward = true,
    Key? key,
  }) : super(key: key);

  final bool forward;
  final PageController pageCtrl;

  @override
  Widget build(BuildContext context) {
    final double page;
    if (pageCtrl.position.hasContentDimensions) {
      page = pageCtrl.page ?? pageCtrl.initialPage.toDouble();
    } else {
      page = 0.0;
    }

    return AnimatedBuilder(
      animation: pageCtrl,
      builder: (ctx, child) {
        var r = (page % 1).abs();
        return Opacity(
            opacity: r > 0.5 ? r : 1 - r, //> 0.5 ? r : 1, // !=  ? 0.5 : 1,
            child: child);
      },
      child: IconButton(
          icon: Transform.rotate(
              angle: forward ? pi : 0,
              child: Icon(
                Icons.arrow_back,
                color: Colors.white70,
              )),
          onPressed: () {
            forward
                ? pageCtrl.nextPage(
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeOutQuart)
                : pageCtrl.previousPage(
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeOutQuart);
          }),
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

  late AnimationController offsetAnim;
  late Tween<Offset> offsetTween;

  @override
  void initState() {
    super.initState();
    offsetAnim =
        new AnimationController(duration: Duration(seconds: 12), vsync: this);
    offsetTween = Tween(
      begin: Offset(0, viewHeight / 128 + 4),
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
    return GestureDetector(
      onTap: () {
        offsetAnim.animateTo(offsetAnim.value + 0.3,
            duration: Duration(milliseconds: 200));
      },
      child: SlideTransition(
        position: offsetAnim.drive(offsetTween),
        child: Image.asset("assets/img/wave_bg.png"),
      ),
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
  late AnimationController tooltipAnimCtrl;

  bool _show = false;
  bool _triedItOut = false;

  @override
  void initState() {
    super.initState();
    this._show = !FiarSharedPrefs.shownSwipeDialog;

    tooltipAnimCtrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 200),
        reverseDuration: Duration(milliseconds: 900))
      ..drive(CurveTween(curve: Curves.easeInOut))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // hide
          Future.delayed(Duration(milliseconds: 700), tooltipAnimCtrl.reverse);
        }
      });
  }

  @override
  void dispose() {
    this.tooltipAnimCtrl.dispose();
    super.dispose();
  }

  void showTooltip() {
    this.tooltipAnimCtrl.reverse();
    this.tooltipAnimCtrl.forward();
  }

  void triedItOut() {
    setState(() => this._triedItOut = true);
    Future.delayed(Duration(milliseconds: 750), () {
      setState(() => this._show = false);
      FiarSharedPrefs.shownSwipeDialog = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 330),
      child: _show
          ? SwipeDetector(
              onTap: showTooltip,
              onSwipeLeft: () => triedItOut(),
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
                              'Swipe horizontally to play locally!',
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
                          animation: tooltipAnimCtrl,
                          builder: (ctx, child) => Opacity(
                              child: child, opacity: tooltipAnimCtrl.value),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            // width: 190,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(6)),
                              color: Colors.white.withOpacity(0.82),
                            ),
                            child: Text('Try swiping from side to side!',
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
    Key? key,
  }) : super(key: key);

  @override
  _SlideIndicatorState createState() => _SlideIndicatorState();
}

class _SlideIndicatorState extends State<SlideIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController animCtrl;
  late CurveTween fade;

  @override
  void initState() {
    super.initState();
    animCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1400))
          ..forward()
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted) {
                  animCtrl.reset();
                  animCtrl.forward();
                }
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
