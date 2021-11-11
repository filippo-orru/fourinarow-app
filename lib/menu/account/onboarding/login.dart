// import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'common.dart';

class LoginPage extends StatefulWidget {
  final title = 'Login';
  final usernameCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final VoidCallback callback;

  LoginPage({required this.callback});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<int>? loginFuture;

  void onPressed() async {
    loginFuture = context.read<UserInfo>().login(widget.usernameCtrl.text, widget.pwCtrl.text);

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
          accentColor: context.watch<ThemesProvider>().selectedTheme.chatThemeColor,
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
                                  margin: EdgeInsets.symmetric(horizontal: 24),
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      snapshot.data == 200
                                          ? Icon(
                                              Icons.check,
                                              color: context
                                                  .watch<ThemesProvider>()
                                                  .selectedTheme
                                                  .chatThemeColor,
                                            )
                                          : Icon(Icons.close, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text(
                                        textFromStatuscode(snapshot.data),
                                        style: TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : snapshot.hasError
                                  ? Container(
                                      color: Colors.white,
                                      padding: EdgeInsets.all(12),
                                      child: Text("${snapshot.error}\nTry again!"),
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
