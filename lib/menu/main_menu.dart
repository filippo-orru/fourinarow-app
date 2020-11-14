import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/chat.dart';
import 'package:four_in_a_row/inherit/connection/server_conn.dart';
import 'package:four_in_a_row/main.dart';
import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:four_in_a_row/menu/account/onboarding/onboarding.dart';
import 'package:four_in_a_row/menu/account/offline.dart';
import 'package:four_in_a_row/menu/chat.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'common/play_button.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({
    Key key,
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

class _MainMenuState extends State<MainMenu> {
  RouteObserverProvider observerProvider;
  bool loadingUserInfo = false;

  void accountCheck(BuildContext context, {bool force = false}) async {
    var userInfo = UserinfoProvider.of(context);
    if (userInfo?.loggedIn ?? false) {
      Navigator.of(context).push(slideUpRoute(FriendsList(userInfo)));
    } else if (userInfo?.offline ?? true) {
      Navigator.of(context)
          .push(slideUpRoute(OfflineScreen(OfflineCaller.Friends)));
    } else if ((userInfo?.refreshing ?? false) && !force) {
      setState(() => loadingUserInfo = true);

      Future.delayed(Duration(milliseconds: 1800),
          () => accountCheck(context, force: true));
    } else {
      setState(() => loadingUserInfo = false);
      Navigator.of(context).push(slideUpRoute(AccountOnboarding()));
    }
  }

  void showChat(BuildContext context) {
    Navigator.of(context).push(slideUpRoute(ChatScreen(
      chatProviderState: ChatProvider.of(context),
    )));
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ServerConnProvider.of(context).menuContext = context;

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
    ChatProviderState chatProviderState = ChatProvider.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder(
              valueListenable: chatProviderState.notifier,
              builder: (ctx, x, child) => Stack(children: [
                child,
                chatProviderState.unread > 0
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
                          child: Text(chatProviderState.unread.toString(),
                              style: TextStyle(color: Colors.white)),
                        ))
                    : SizedBox(),
              ]),
              child: SmallColorButton(
                label: 'donate',
                icon: Icons.chat,
                color: Colors.green[300],
                onTap: () => showChat(context),
              ),
            ),
            Stack(
              children: [
                SmallColorButton(
                  icon: Icons.people,
                  color: Colors.purple[300],
                  onTap: () => accountCheck(context),
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
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SmallColorButton({
    Key key,
    this.label,
    @required this.icon,
    @required this.color,
    @required this.onTap,
  }) : super(key: key);

  @override
  _SmallColorButtonState createState() => _SmallColorButtonState();
}

class _SmallColorButtonState extends State<SmallColorButton>
    with SingleTickerProviderStateMixin {
  AnimationController animCtrl;

  bool expanded = false;

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 90),
      reverseDuration: Duration(milliseconds: 125),
    );
    animCtrl.drive(CurveTween(curve: Curves.linear));
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
