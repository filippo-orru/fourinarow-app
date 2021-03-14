// import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class LoginPage extends StatefulWidget {
  final title = 'Login';
  final Color accentColor = Colors.blueAccent;
  final usernameCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final VoidCallback callback;

  LoginPage({required this.callback}) {
    // TODO: remove
    if (kDebugMode) {
      usernameCtrl.text = "fefe";
      pwCtrl.text = "00000000";
    }
  }

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<int>? loginFuture;

  void onPressed() async {
    loginFuture = context
        .read<UserInfo>()
        .login(widget.usernameCtrl.text, widget.pwCtrl.text);

    setState(() {});
    if (await loginFuture == 200) {
      widget.callback();
    }
  }

  String textFromStatuscode(int? code) {
    if (code == 200) {
      return "You have been logged in successfully! :)";
    } else if (code == 403) {
      return "Username or password are incorrect!";
    } else if (code == 0) {
      // my special case
      return "Network error! Could not connect or server is down. Please try again later.";
    } else {
      return "Error! (Code: $code)";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AccessAccountScreen(
          title: widget.title,
          usernameCtrl: widget.usernameCtrl,
          pwCtrl: widget.pwCtrl,
          accentColor: widget.accentColor,
          onSubmit: onPressed,
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: loginFuture != null
              ? FutureBuilder(
                  future: loginFuture,
                  builder: (ctx, AsyncSnapshot<int> snapshot) {
                    return GestureDetector(
                      onTap: () => setState(() => loginFuture = null),
                      child: Container(
                        color: Colors.black38,
                        constraints: BoxConstraints.expand(),
                        child: Center(
                          child: snapshot.hasData
                              ? Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 18),
                                  // height: 100,
                                  width: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                  ),
                                  child: Text(
                                    textFromStatuscode(snapshot.data),
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                )
                              : snapshot.hasError
                                  ? Container(
                                      color: Colors.white,
                                      padding: EdgeInsets.all(12),
                                      child:
                                          Text("${snapshot.error}\nTry again!"),
                                    )
                                  : CircularProgressIndicator(),
                        ),
                      ),
                    );
                  },
                )
              : SizedBox(),
        ),
      ],
    );
  }
}
