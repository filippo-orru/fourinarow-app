import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/constants.dart' as constants;

import 'common.dart';

class LoginPage extends StatefulWidget {
  final title = 'Login';
  final Color accentColor = Colors.blueAccent;
  final usernameCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final void Function(BuildContext context, String, String) callback;

  LoginPage({@required this.callback});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<http.Response> loginFuture;

  void onPressed() {
    setState(() {
      Map<String, String> body = {
        "username": widget.usernameCtrl.text,
        "password": widget.pwCtrl.text,
      };
      loginFuture = http.post(
        '${constants.URL}/api/users/login',
        body: body,
      )..then((response) {
          if (response.statusCode == 200 && context != null) {
            widget.callback(
                context, widget.usernameCtrl.text, widget.pwCtrl.text);
          } else {
            print(response);
          }
        });
    });
  }

  String textFromStatuscode(int code) {
    if (code == 200) {
      return "You have been logged in successfully!";
    } else if (code == 403) {
      return "Username or password are incorrect!";
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
                  builder: (ctx, AsyncSnapshot<http.Response> snapshot) {
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
                                    textFromStatuscode(
                                        snapshot.data.statusCode),
                                    style: TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                )
                              : snapshot.hasError
                                  ? Text("${snapshot.error}")
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
