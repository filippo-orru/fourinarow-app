import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/chat.dart';
import 'package:four_in_a_row/inherit/route.dart';
import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:four_in_a_row/menu/account/onboarding/onboarding.dart';
import 'package:four_in_a_row/menu/account/offline.dart';
import 'package:four_in_a_row/menu/chat.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    if (gsm.loggedIn) {
      if (gsm.offline) {
        Navigator.of(context).push(slideUpRoute(OfflineScreen(
          refreshCheckAction: () {
            return gsm.refresh().then((userInfo) => userInfo != null);
          },
        )));
      } else {
        Navigator.of(context).push(slideUpRoute(FriendsList()));
      }
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

  void showChat() async {
    if (FiarSharedPrefs.hasAcceptedChat) {
      Navigator.of(context).push(slideUpRoute(ChatScreen()));
    } else {
      bool? accepted = await showDialog(
          context: context,
          builder: (_) {
            return ChatAcceptDialog();
          });
      if (accepted == true) {
        FiarSharedPrefs.hasAcceptedChat = true;
        Navigator.of(context).push(slideUpRoute(ChatScreen()));
      }
    }
  }

  late RouteObserver _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = RouteObserverProvider.of(context).observer
      ..subscribe(this, ModalRoute.of(context)!);
    SystemUiStyle.mainMenu();
  }

  @override
  void didPopNext() {
    SystemUiStyle.mainMenu();
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        child: Stack(
          children: [
            buildTitle(context),
            Column(
              // mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 10,
                  fit: FlexFit.tight,
                  child: SizedBox(),
                ),
                // Flexible(flex: 4, child: Container()),
                Expanded(child: SizedBox()),
                SizedBox(
                  height: 150,
                  child: buildPlayButton(context),
                ),
                SizedBox(height: 96),
                Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints(maxWidth: 600),
                  margin: EdgeInsets.only(bottom: 32, left: 24, right: 24),
                  child: buildBottomBar(context),
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              right: 24,
              child: Opacity(
                opacity: 0.3,
                child: Container(
                  margin: EdgeInsets.all(16), //top: 32, right:
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.black12,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    kDebugMode ? '🛠 DEBUG 🛠' : 'BETA2',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
        Text('• Filippo Orru, 2021 •'.toUpperCase(),
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

  Widget buildTitle(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.22,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Hero(
          tag: "wide_logo_banner",
          child: Image.asset(
            "assets/img/wide_logo_banner.png",
            fit: BoxFit.contain,
          ),
        ),
      ),
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
  final bool connected;

  const SearchingGameNotification(this.connected, {Key? key}) : super(key: key);

  @override
  _SearchingGameNotificationState createState() =>
      _SearchingGameNotificationState();
}

class _SearchingGameNotificationState extends State<SearchingGameNotification> {
  bool collapsed = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          accentColor: Colors.white70, colorScheme: ColorScheme.light()),
      child: Container(
        margin: EdgeInsets.all(12).copyWith(top: 24),
        child: AnimatedSwitcher(
          layoutBuilder: (currentChild, previousChildren) => Stack(
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
            alignment: Alignment.topLeft,
          ),
          duration: Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutQuad,
          switchOutCurve: Curves.easeInQuad,
          child: widget.connected
              ? GestureDetector(
                  key: ValueKey(collapsed),
                  onTap: () {
                    setState(() {
                      collapsed = !collapsed;
                    });
                  },
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
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      width: 32,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        collapsed
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        size: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
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
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            height: 32,
                                            width: 32,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            child: Icon(
                                              collapsed
                                                  ? Icons.arrow_downward
                                                  : Icons.arrow_upward,
                                              size: 16,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                        'Searching for opponent\nThis might take a while\nTap to minimize',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white)),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Material(
                                        borderRadius: BorderRadius.circular(6),
                                        clipBehavior: Clip.antiAlias,
                                        color: Colors.black87,
                                        child: InkWell(
                                          onTap: () => context
                                              .read<GameStateManager>()
                                              .leave(),
                                          splashColor: Colors.white70,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 8),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: Colors.white60),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                  color: Colors.white70),
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
                )
              : Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'No Connection! Waiting to reconnect.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class ChatAcceptDialog extends StatefulWidget {
  @override
  _ChatAcceptDialogState createState() => _ChatAcceptDialogState();
}

class _ChatAcceptDialogState extends State<ChatAcceptDialog> {
  bool oldEnough = false;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
        'Access Chat',
        style: TextStyle(
          fontFamily: 'RobotoSlab',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: EdgeInsets.all(16),
      children: [
        Text(
          'The chat allows anonymous posting of short messages that can be read by anyone currently online and will be deleted once you close the app',
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Checkbox(
              focusColor: Colors.blueAccent.withOpacity(0.9),
              value: oldEnough,
              onChanged: (v) {
                if (v == null) return;
                setState(() => oldEnough = v);
              },
            ),
            GestureDetector(
              onTap: () {
                setState(() => oldEnough = !oldEnough);
              },
              child: Text(
                "I'm more than 13 years old",
                style: TextStyle(),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'.toUpperCase()),
            ),
            SizedBox(width: 12),
            FlatButton(
              color: Colors.blueAccent.withOpacity(1),
              disabledColor: Colors.grey[300],
              onPressed:
                  !oldEnough ? null : () => Navigator.of(context).pop(true),
              child: Text(
                'ACCEPT',
                style:
                    TextStyle(color: oldEnough ? Colors.white : Colors.black45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
