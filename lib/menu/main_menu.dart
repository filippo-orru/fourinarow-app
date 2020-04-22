import 'package:flutter/material.dart';
import 'package:four_in_a_row/main.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';

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

class _MainMenuState extends State<MainMenu> {
  RouteObserverProvider observerProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          // mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 3,
              fit: FlexFit.tight,
              child: Center(
                // padding: EdgeInsets.symmetric(vertical: 48),
                // height: 48,
                child: Text(
                  "Four in a Row".toUpperCase(),
                  style: TextStyle(
                    fontSize: 40,
                    fontFamily: "RobotoSlab",
                    letterSpacing: 1,
                    // fontWeight: FontWeight.w900,
                    // fontStyle: FontStyle.italic
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 2,
              fit: FlexFit.tight,
              child: Center(
                child: PlayButton(
                  label: 'Play',
                  color: Colors.redAccent,
                  diameter: 128,
                  onTap: () {
                    // _buttonExpanded = true;
                    Navigator.of(context).push(PlaySelection.route());
                  },
                ),
              ),
            ),
            SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
