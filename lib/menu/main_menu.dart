import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:four_in_a_row/inherit/chat.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/main.dart';
import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:four_in_a_row/menu/account/onboarding/onboarding.dart';
import 'package:four_in_a_row/menu/account/offline.dart';
import 'package:four_in_a_row/menu/chat.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_login_state.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'common/play_button.dart';

import 'package:provider/provider.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({
    Key? key,
  }) : super(key: key);

  @override
  _MainMenuState createState() => _MainMenuState();

  static PageRouteBuilder route() {
    final opacityTween =
        Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.ease));
    // final sizeTween =
    //     Tween<double>(begin: 0.9, end: 1).chain(CurveTween(curve: Curves.ease));
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => PlaySelection(),
      transitionDuration: Duration(milliseconds: 100),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(opacityTween),
          child: child,
        );
      },
    );
  }
}

PageRouteBuilder slideUpRoute(Widget content) {
  final offset = Tween<Offset>(begin: Offset(0, 0.25), end: Offset.zero)
      .chain(CurveTween(curve: Curves.ease));

  final opacity = Tween<double>(begin: 0, end: 1).chain(
    CurveTween(curve: Curves.easeInOut),
  );
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => content,
    transitionDuration: Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(opacity),
        child: SlideTransition(
          position: animation.drive(offset),
          child: child,
        ),
      );
    },
  );
}

class _MainMenuState extends State<MainMenu> with RouteAware {
  bool loadingUserInfo = false;

  void accountCheck({bool force = false}) async {
    var gsm = context.read<UserInfo>();
    if (gsm.offline) {
      Navigator.of(context).push(slideUpRoute(OfflineScreen()));
    } else if (gsm.loggedIn) {
      Navigator.of(context).push(slideUpRoute(FriendsList()));
    } else {
      Navigator.of(context).push(slideUpRoute(AccountOnboarding()));
    }

    // TODO move this to friendslist (show loading -> okay(list) / notLoggedIn )
    /*if (widget._userInfo.loggedIn ?? false) {
    } else if (widget._userInfo.offline ?? true) {
      Navigator.of(context)
          .push(slideUpRoute(OfflineScreen(OfflineCaller.Friends)));
    } else if ((widget._userInfo.refreshing ?? false) && !force) {
      setState(() => loadingUserInfo = true);

      Future.delayed(
          Duration(milliseconds: 1800), () => accountCheck(force: true));
    } else {
      setState(() => loadingUserInfo = false);
    }*/
  }

  void showChat() {
    Navigator.of(context).push(slideUpRoute(ChatScreen()));
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    RouteObserverProvider.of(context)
        .observer
        .subscribe(this, ModalRoute.of(context)!);
    SystemUiStyle.mainMenu();
  }

  @override
  void didPopNext() {
    SystemUiStyle.mainMenu();
  }

  @override
  void dispose() {
    RouteObserverProvider.of(context).observer.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 10,
              fit: FlexFit.tight,
              child:
                  // SizedBox( height :)
                  buildTitle(context),
            ),
            // Flexible(flex: 4, child: Container()),
            Expanded(child: SizedBox()),
            // Flexible(
            //   flex: 4,
            //   fit: FlexFit.tight,
            // child:
            SizedBox(
              height: 150,
              child: buildPlayButton(context),
            ),
            // ),
            SizedBox(height: 96),
            Container(
              alignment: Alignment.center,
              constraints: BoxConstraints(maxWidth: 600),
              margin: EdgeInsets.only(bottom: 32, left: 24, right: 24),
              child: buildBottomBar(context),
            ),
          ],
        ),
      ),
    );
  }

  Stack buildBottomBar(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Selector<ChatState, int>(
              selector: (_, chatState) => chatState.unread,
              builder: (_, unread, Widget? child) => Stack(children: [
                child!,
                unread > 0
                    ? Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 18,
                          width: 18,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.all(Radius.circular(32)),
                          ),
                          alignment: Alignment.center,
                          child: Text(unread.toString(),
                              style: TextStyle(color: Colors.white)),
                        ))
                    : SizedBox(),
              ]),
              child: SmallColorButton(
                icon: Icons.chat,
                color: Colors.blueAccent,
                onTap: showChat,
              ),
            ),
            Stack(
              children: [
                SmallColorButton(
                  icon: Icons.people,
                  color: Colors.purple[300]!,
                  onTap: () => accountCheck(),
                ),
                loadingUserInfo ? CircularProgressIndicator() : SizedBox(),
              ],
            ),
          ],
        ),
        Text('• Filippo Orru, 2020 •'.toUpperCase(),
            style: TextStyle(
              letterSpacing: 0.5,
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              // fontStyle: FontStyle.italic,
            )),
      ],
    );
  }

  Widget buildPlayButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: PlayButton(
        label: 'Play',
        color: Colors.redAccent,
        diameter: 128,
        onTap: () {
          // _buttonExpanded = true;
          Navigator.of(context).push(PlaySelection.route());
        },
      ),
    );
  }

  Container buildTitle(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      // constraints: BoxConstraints.expand(
      // width: max(0, MediaQuery.of(context).size.width - 48),
      // padding: EdgeInsets.symmetric(vertical: 48),
      // height: 48,
      // child:
      // FittedBox(
      // fit: BoxFit.contain,
      child: Text(
        "Four in a Row".toUpperCase(),
        style: TextStyle(
          fontSize: 40,
          fontFamily: "RobotoSlab",
          letterSpacing: 1.01,
          // fontWeight: FontWeight.w900,
          // fontStyle: FontStyle.italic
        ),
      ),
      // ),
    );
  }
}

class SmallColorButton extends StatefulWidget {
  final String? label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SmallColorButton({
    Key? key,
    this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  _SmallColorButtonState createState() => _SmallColorButtonState();
}

class _SmallColorButtonState extends State<SmallColorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController animCtrl;

  bool expanded = false;

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 125),
      reverseDuration: Duration(milliseconds: 280),
    );
    animCtrl.drive(CurveTween(curve: Curves.easeOutQuart));
  }

  @override
  void dispose() {
    this.animCtrl.dispose();
    super.dispose();
  }
  // TODO : make container go wide on first tap if label is specified

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => animCtrl.forward(),
      onTapUp: (_) => animCtrl.reverse(),
      onTapCancel: animCtrl.reverse,
      onTap: this.widget.onTap,
      child: AnimatedBuilder(
        animation: animCtrl,
        builder: (_, child) => Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(scale: 1 + animCtrl.value / 4, child: child),
            Transform.scale(
                scale: 1 + animCtrl.value / 8,
                child: Icon(widget.icon, color: Colors.white)),
          ],
        ),
        child: Container(
          width: 48,
          height: 48,
          padding: EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.all(Radius.circular(100)),
          ),
        ),
      ),
    );
  }
}

class SearchingGameNotification extends StatefulWidget {
  @override
  _SearchingGameNotificationState createState() =>
      _SearchingGameNotificationState();
}

class _SearchingGameNotificationState extends State<SearchingGameNotification> {
  bool collapsed = false;

  Widget buildCollapseButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        InkResponse(
          // containedInkWell: true,
          onTap: () {
            setState(() {
              collapsed = !collapsed;
            });
          },
          child: Container(
            padding: EdgeInsets.all(8),
            child: Icon(
              collapsed ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          accentColor: Colors.white70, colorScheme: ColorScheme.light()),
      child: Container(
        margin: EdgeInsets.all(12),
        child: AnimatedSwitcher(
          layoutBuilder: (currentChild, previousChildren) => Stack(
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
            alignment: Alignment.topLeft,
          ),
          duration: Duration(milliseconds: 180),
          child: collapsed
              ? Padding(
                  padding: EdgeInsets.only(top: 14, left: 10),
                  child: Material(
                    borderRadius: BorderRadius.circular(100),
                    color: Colors.black.withOpacity(0.8),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 48,
                          child: AspectRatio(
                            aspectRatio: 1,
                          ),
                        ),
                        buildCollapseButton(),
                      ],
                    ),
                  ),
                )
              : Material(
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  color: Colors.black.withOpacity(0.8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        left: 0,
                        child: Container(
                          constraints: BoxConstraints.expand(),
                          decoration: BoxDecoration(),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(18),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: buildCollapseButton(),
                            ),
                            Text(
                                'Searching for opponent\nThis might take a while',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Material(
                                borderRadius: BorderRadius.circular(6),
                                clipBehavior: Clip.antiAlias,
                                color: Colors.black87,
                                child: InkWell(
                                  onTap: () =>
                                      context.read<GameStateManager>().leave(),
                                  splashColor: Colors.white70,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white60),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
