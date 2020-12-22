import 'dart:math';

import 'package:four_in_a_row/menu/play_selection/online.dart';
import 'package:flutter/material.dart';

import 'package:four_in_a_row/util/constants.dart' as constants;

class AccountTextField extends StatelessWidget {
  const AccountTextField({
    Key? key,
    required this.txtCtrl,
    required this.hint,
    this.password = false,
    this.focusNode,
    this.nextFocus,
    this.onSubmit,
  }) : super(key: key);

  final TextEditingController txtCtrl;
  final String hint;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final VoidCallback? onSubmit;
  final bool password;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          nextFocus!.requestFocus();
        } else {
          onSubmit?.call();
        }
      },
      controller: txtCtrl,
      focusNode: focusNode,
      obscureText: this.password,
      keyboardType: TextInputType.visiblePassword,
      textInputAction:
          nextFocus == null ? TextInputAction.done : TextInputAction.next,
      decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black45, width: 2),
            borderRadius: BorderRadius.circular(2),
          ),
          contentPadding:
              EdgeInsets.only(left: 15, bottom: 11, top: 11, right: 15)),
    );
  }
}

class AccessAccountScreen extends StatefulWidget {
  AccessAccountScreen({
    Key? key,
    required this.title,
    required this.usernameCtrl,
    required this.pwCtrl,
    required this.accentColor,
    required this.onSubmit,
    this.registering = false,
  })  : usernameFocusNode = FocusNode(),
        passwordFocusNode = FocusNode(),
        super(key: key);

  final String title;
  final TextEditingController usernameCtrl;
  final TextEditingController pwCtrl;
  final Color accentColor;
  final VoidCallback onSubmit;
  final bool registering;

  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;

  @override
  _AccessAccountScreenState createState() => _AccessAccountScreenState();
}

class _AccessAccountScreenState extends State<AccessAccountScreen> {
  bool oldEnough = false;
  bool remindAge = false;

  bool okay = false;

  bool showUsernameHint = true;
  bool showPwHint = true;

  void _checkInputs() {
    showUsernameHint = widget.usernameCtrl.text.length < 4 ||
        widget.usernameCtrl.text.length > 16;

    showPwHint = widget.pwCtrl.text.length < 8 ||
        widget.pwCtrl.text.length > 64 ||
        !widget.pwCtrl.text
            .split("")
            .any((c) => !constants.alphabet.contains(c.toLowerCase()));
    okay = !showUsernameHint &&
        !showPwHint &&
        (widget.registering && oldEnough || !widget.registering);

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.pwCtrl.addListener(_checkInputs);
    widget.usernameCtrl.addListener(_checkInputs);
  }

  @override
  Widget build(BuildContext context) {
    double width80 = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      body: Center(
        child: Container(
          width: max(width80, 220),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.title,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                AccountTextField(
                  txtCtrl: widget.usernameCtrl,
                  hint: 'Username',
                  focusNode: widget.usernameFocusNode,
                  nextFocus: widget.passwordFocusNode,
                ),
                showUsernameHint
                    ? Text('Between 4 and 16 characters.')
                    : SizedBox(),
                SizedBox(height: 8),
                AccountTextField(
                  txtCtrl: widget.pwCtrl,
                  hint: 'Password',
                  password: true,
                  focusNode: widget.passwordFocusNode,
                  onSubmit: widget.onSubmit,
                ),
                showPwHint
                    ? Text('At least 8 characters, one special symbol.')
                    : SizedBox(),
                SizedBox(height: 8),
                buildSubmitButton(),
                buildAskAge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSubmitButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: FlatIconButton(
          enabled: okay,
          bgColor: widget.accentColor,
          icon: Icons.arrow_forward,
          onPressed: () {
            if (!widget.registering || (widget.registering && oldEnough)) {
              widget.passwordFocusNode.unfocus();
              widget.usernameFocusNode.unfocus();
              widget.onSubmit();
            } else {
              setState(() => remindAge = true);
              Future.delayed(
                Duration(seconds: 2),
                () => setState(() => remindAge = false),
              );
            }
          }),
    );
  }

  Widget buildAskAge() {
    return widget.registering
        ? Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {
                setState(() => oldEnough = !oldEnough);
                _checkInputs();
              },
              child: Row(
                children: [
                  Checkbox(
                    focusColor: widget.accentColor,
                    value: oldEnough,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => oldEnough = v);
                      _checkInputs();
                    },
                  ),
                  Text(
                    'I\'m more than 13 years old',
                    style: TextStyle(
                        fontWeight:
                            remindAge ? FontWeight.bold : FontWeight.normal),
                  ),
                ],
              ),
            ),
          )
        : SizedBox();
  }
}
