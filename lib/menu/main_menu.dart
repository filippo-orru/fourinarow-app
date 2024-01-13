import 'package:four_in_a_row/menu/ThemeSelectPage.dart';
import 'package:four_in_a_row/providers/global_provider.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'package:four_in_a_row/util/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/providers/chat.dart';
import 'package:four_in_a_row/providers/route.dart';
import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:four_in_a_row/menu/account/onboarding/onboarding.dart';
import 'package:four_in_a_row/menu/account/offline.dart';
import 'package:four_in_a_row/menu/chat.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/global_common_widgets.dart';
import 'package:four_in_a_row/util/system_ui_style.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import '../util/logger.dart';
import 'common/play_button.dart';

import 'package:provider/provider.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({
    Key? key,
  }) : super(key: key);

  @override
  _MainMenuState createState() => _MainMenuState();

  static PageRouteBuilder route() {
    final opacityTween = Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.ease));
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
  }

  void showChat() async {
    switch (FiarSharedPrefs.socialFeatures.get()) {
      case SocialFeatures.NotAsked:
        // Shouldn't happen, the age is verified on app launch
        return;
      case SocialFeatures.DontAllow:
        // Shouldn't happen, the button is hidden if the user isn't allowed to chat
        return;
      case SocialFeatures.Allow:
        Navigator.of(context).push(slideUpRoute(ChatScreen()));
    }
  }

  void shake() {
    Vibrations.screenShake();
    context.read<GlobalProvider>().screenShakeAnimCtrl.forward(from: 0);
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
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          child: Stack(
            children: [
              buildTitle(context),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 10,
                    fit: FlexFit.tight,
                    child: SizedBox(),
                  ),
                  Expanded(child: SizedBox()),
                  SizedBox(
                    height: 150,
                    child: Align(
                      alignment: Alignment.center,
                      child: PlayButton(
                        label: 'Play',
                        color: context.watch<ThemesProvider>().selectedTheme.playOnlineThemeColor,
                        diameter: 128,
                        onTap: () {
                          Navigator.of(context).push(PlaySelection.route());
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 96),
                  Container(
                    alignment: Alignment.center,
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
      ),
    );
  }

  Widget buildBottomBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Selector<FiarSharedPrefs, SocialFeatures>(
          selector: (_, prefs) => FiarSharedPrefs.socialFeatures.get(),
          builder: (context, socialFeatures, _) => socialFeatures == SocialFeatures.Allow
              ? Selector<ChatState, int>(
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
                              child: Text(unread.toString(), style: TextStyle(color: Colors.white)),
                            ))
                        : SizedBox(),
                  ]),
                  child: SmallColorButton(
                    iconData: Icons.chat,
                    color: context.watch<ThemesProvider>().selectedTheme.chatThemeColor,
                    onTap: showChat,
                  ),
                )
              : SmallColorButton(
                  iconData: Icons.celebration_rounded,
                  color: context.read<ThemesProvider>().selectedTheme.chatThemeColor,
                  onTap: shake,
                ),
        ),
        // ThemesButton(),
        Stack(
          children: [
            SmallColorButton(
              iconData: Icons.people,
              color: context.watch<ThemesProvider>().selectedTheme.friendsThemeColor,
              onTap: () => accountCheck(),
            ),
            loadingUserInfo ? CircularProgressIndicator() : SizedBox(),
          ],
        ),
      ],
    );
  }

  Widget buildTitle(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).size.height * 0.22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Hero(
              tag: "wide_logo_banner",
              child: Image.asset(
                "assets/img/wide_logo_banner.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 6),
          TextButton(
            child: Text(
              'Filippo Orru, '.toUpperCase() + DateTime.now().year.toString(),
              style: TextStyle(
                letterSpacing: 0.5,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              // ignore: deprecated_member_use
              if (!await launch(LINKEDIN_PROFILE)) {
                Logger.e("Could not launch $LINKEDIN_PROFILE");
              }
            },
          ),
        ],
      ),
    );
  }
}

class ThemesButton extends StatefulWidget {
  const ThemesButton({
    Key? key,
  }) : super(key: key);

  @override
  State<ThemesButton> createState() => _ThemesButtonState();
}

class _ThemesButtonState extends State<ThemesButton> with TickerProviderStateMixin {
  static final List<Color> colors = [
    Color(0xfff13f3f),
    Color(0xfffc417a),
    Color(0xfff25ab2),
    Color(0xffd479e0),
    Color(0xffa796fe),
    Color(0xff6fadff),
    Color(0xff30c0ff),
    Color(0xff11cefb),
    Color(0xff11cefb),
    Color(0xff30c0ff),
    Color(0xff6fadff),
    Color(0xffa796fe),
    Color(0xffd479e0),
    Color(0xfff25ab2),
    Color(0xfffc417a),
    Color(0xfff13f3f),
  ];

  final _visiblePointsCount = 3;

  late List<AnimationController> _controllers;

  Animatable<Color?> _colorTween = TweenSequence(
    colors
        .asMap()
        .map((index, color) {
          Color lastColor = colors[(index - 1) % colors.length];
          return MapEntry(
            index,
            TweenSequenceItem(
              weight: 1.0,
              tween: ColorTween(begin: lastColor, end: color),
            ),
          );
        })
        .values
        .toList(),
  );

  List<Animation<Color?>> _colorAnims = [];

  @override
  void initState() {
    super.initState();

    _controllers = [for (var i = 0; i < _visiblePointsCount; i += 1) i].map((index) {
      AnimationController controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 4000),
      );
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // print("Ticker $index completed");
          controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          controller.forward();
        }
      });
      Animation<Color?> colorAnim = _colorTween.animate(controller);
      controller.value = index / (colors.length);
      // print("Ticker $index started");
      _colorAnims.add(colorAnim);
      return controller;
    }).toList();
    _controllers.forEach((c) => c.forward());
  }

  @override
  void dispose() {
    _controllers.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controllers[0],
      builder: (_, __) => SmallColorButton(
        iconData: Icons.brush,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _colorAnims.map((anim) => anim.value).toList().filterNotNull(),
          tileMode: TileMode.mirror,
        ),
        onTap: () {
          Navigator.of(context).push(
            slideUpRoute(
              ThemeSelectPage(themes: context.read<ThemesProvider>()),
            ),
          );
        },
      ),
    );
  }
}

class SmallColorButton extends StatefulWidget {
  final String? label;
  final Widget icon;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback onTap;

  SmallColorButton({
    Key? key,
    this.label,
    IconData? iconData,
    Widget? icon,
    this.color,
    this.gradient,
    required this.onTap,
  })  : this.icon = iconData != null ? Icon(iconData, color: Colors.white) : icon!,
        assert((color != null) ^ (gradient != null)),
        super(key: key);

  @override
  _SmallColorButtonState createState() => _SmallColorButtonState();
}

class _SmallColorButtonState extends State<SmallColorButton> with SingleTickerProviderStateMixin {
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
              child: SizedBox(
                height: 32,
                width: 32,
                child: widget.icon,
              ),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          width: 48,
          height: 48,
          padding: EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            gradient: widget.gradient,
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
  _SearchingGameNotificationState createState() => _SearchingGameNotificationState();
}

class _SearchingGameNotificationState extends State<SearchingGameNotification> {
  bool collapsed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      collapsed ? Icons.arrow_downward : Icons.arrow_upward,
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
                                            color: context
                                                .watch<ThemesProvider>()
                                                .selectedTheme
                                                .accentColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(
                                            collapsed ? Icons.arrow_downward : Icons.arrow_upward,
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
                                        onTap: () => context.read<GameStateManager>().leave(),
                                        splashColor: Colors.white70,
                                        child: Container(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
    );
  }
}
