import 'package:flutter/material.dart';

class MenuWrapper extends StatelessWidget {
  final Widget child;
  MenuWrapper({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgCol = Color(0xFFFDFDFD);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Theme(
        data: ThemeData(
          backgroundColor: bgCol,
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            color: bgCol,
            child: Center(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class ArmsButton extends StatefulWidget {
  final String label;
  final void Function()? callback;

  ArmsButton(this.label, {Key? key, this.callback}) : super(key: key);

  @override
  _ArmsButtonState createState() => _ArmsButtonState();
}

class _ArmsButtonState extends State<ArmsButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: widget.callback,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          decoration: BoxDecoration(
              // color: Colors.black,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              )),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              // color: Theme.of(context).backgroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder fadeRoute({required Widget child, int millDuration = 300}) {
  final opacityTween =
      Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.ease));
  // final sizeTween =
  //     Tween<double>(begin: 0.9, end: 1).chain(CurveTween(curve: Curves.ease));
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(opacityTween),
        child: child,
      );
    },
  );
}

class CustomAppBar extends AppBar {
  CustomAppBar({
    required String title,
    bool refreshing = false,
    Key? key,
  }) : super(
          key: key,
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          iconTheme: IconThemeData(color: Colors.black),
          title: Text(title,
              style: TextStyle(
                fontFamily: "RobotoSlab",
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          actions: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: refreshing
                  ? Transform.scale(
                      scale: 0.7, child: CircularProgressIndicator())
                  : SizedBox(),
            ),
          ],
        );

  // final String title;
  // final bool refreshing;

  /*@override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      // margin: EdgeInsets.only(
      //     bottom: 4, left: 4, right: 4, top: 4),
      // alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        // color: Colors.purple[300],
        // color: Colors.grey[300],
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            color: Colors.black12,
          )
        ],
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const BackButtonIcon(),
                splashColor: Colors.grey[400],
                color: Colors.black,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
              ),
              SizedBox(width: 24),
              Text(title,
                  style: TextStyle(
                    fontFamily: "RobotoSlab",
                    // color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: refreshing
                        ? Transform.scale(
                            scale: 0.7, child: CircularProgressIndicator())
                        // Container(
                        //     constraints: BoxConstraints.expand(),
                        //     color: Colors.black26,
                        //     child: Center(child: C),
                        //   )
                        : SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }*/
}
