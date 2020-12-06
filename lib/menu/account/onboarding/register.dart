import 'package:http/http.dart' as http;
import 'package:four_in_a_row/util/constants.dart' as constant;
import 'package:flutter/material.dart';
import 'common.dart';

class RegisterPage extends StatefulWidget {
  final title = 'Register';
  final Color accentColor = Colors.redAccent;
  final usernameCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final void Function(BuildContext context, String, String) callback;

  RegisterPage({required this.callback});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Future<http.Response>? registerFuture;

  void onPressed() {
    setState(() {
      Map<String, String> body = {
        "username": widget.usernameCtrl.text,
        "password": widget.pwCtrl.text,
      };
      registerFuture = http.post(
        '${constant.URL}/api/users/register',
        body: body,
      )..then((response) {
          if (response.statusCode == 200 && context != null) {
            widget.callback(
                context, widget.usernameCtrl.text, widget.pwCtrl.text);
          }
        });
    });
  }

  String textFromStatuscode(int? code) {
    if (code == 200) {
      return "Your account has been created!";
    } else if (code == 403) {
      return """Username or password are invalid!
- Password must be at least 8 characters long
- Password must not contain colon or pound symbols""";
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
          registering: true,
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: registerFuture != null
              ? FutureBuilder(
                  future: registerFuture,
                  builder: (ctx, AsyncSnapshot<http.Response> snapshot) {
                    return GestureDetector(
                      onTap: () => setState(() => registerFuture = null),
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
                                        snapshot.data?.statusCode),
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
