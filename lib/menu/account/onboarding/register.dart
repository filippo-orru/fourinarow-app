import 'package:flutter/material.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:provider/provider.dart';

import 'package:four_in_a_row/providers/user.dart';
import 'common.dart';

class RegisterPage extends StatefulWidget {
  final title = 'Register';
  final usernameCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  final VoidCallback callback;

  RegisterPage({required this.callback});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Future<int>? registerFuture;

  void onPressed() async {
    registerFuture = context
        .read<UserInfo>()
        .register(widget.usernameCtrl.text, widget.pwCtrl.text);

    setState(() {});
    if (await registerFuture == 200) {
      widget.callback();
    }
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
          accentColor: context
              .watch<ThemesProvider>()
              .selectedTheme
              .accountRegisterAccentColor,
          onSubmit: onPressed,
          registering: true,
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: registerFuture != null
              ? FutureBuilder(
                  future: registerFuture,
                  builder: (ctx, AsyncSnapshot<int> snapshot) {
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
