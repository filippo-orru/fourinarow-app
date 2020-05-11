import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/user.dart';

import '../friends.dart';
import 'login.dart';
import 'register.dart';

class AccountOnboarding extends StatefulWidget {
  @override
  _AccountOnboardingState createState() => _AccountOnboardingState();
}

class _AccountOnboardingState extends State<AccountOnboarding> {
  void successfullyLoggedIn(
      BuildContext context, String username, String password) async {
    var userInfo = UserinfoProvider.of(context);
    if (userInfo != null) {
      userInfo.setCredentials(username, password);
      Future.delayed(Duration(milliseconds: 1500), () {
        Navigator.of(context)
          ..pop()
          ..pushReplacement(MaterialPageRoute(
              builder: (BuildContext context) => FriendsList(userInfo)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          margin: EdgeInsets.all(48),
          width:
              min((MediaQuery.of(context).size.height * 0.8).toDouble(), 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Text('Hi!', style: TextStyle(fontSize: 48))),
              SizedBox(height: 12),
              Text(
                'To play ranked games, you need to create an account!',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 48),
              RaisedButton(
                color: Colors.blueAccent,
                elevation: 1,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          LoginPage(callback: successfullyLoggedIn)));
                  // .push(PageRouteBuilder(pageBuilder: () => RegisterPage())());
                },
                child: Text('Log in'.toUpperCase(),
                    style: TextStyle(color: Colors.white)),
              ),
              RaisedButton(
                color: Colors.redAccent,
                elevation: 1,
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          RegisterPage(callback: successfullyLoggedIn)));
                },
                child: Text('Register'.toUpperCase(),
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
