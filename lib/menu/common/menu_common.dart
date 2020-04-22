import 'package:flutter/material.dart';

class MenuWrapper extends StatelessWidget {
  final Widget child;
  MenuWrapper({@required this.child, Key key}) : super(key: key);

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
  final Function callback;

  ArmsButton(this.label, {Key key, this.callback}) : super(key: key);

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

PageRouteBuilder fadeRoute({@required Widget child, int millDuration = 300}) {
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
