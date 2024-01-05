import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:four_in_a_row/menu/settings.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/util/global_common_widgets.dart';
import 'package:provider/provider.dart';
import 'login.dart';
import 'register.dart';

class AccountOnboarding extends StatefulWidget {
  @override
  _AccountOnboardingState createState() => _AccountOnboardingState();
}

class _AccountOnboardingState extends State<AccountOnboarding> {
  void successfullyLoggedIn() async {
    Future.delayed(Duration(milliseconds: 1500), () {
      Navigator.of(context)
        ..pop()
        ..pushReplacement(MaterialPageRoute(builder: (BuildContext context) => FriendsList()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.all(48),
              width: min((MediaQuery.of(context).size.height * 0.8).toDouble(), 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Text('Hi!', style: TextStyle(fontSize: 48))),
                  SizedBox(height: 12),
                  Text(
                    'Create an account to add friends and earn points for playing',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 48),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          context.watch<ThemesProvider>().selectedTheme.accountLoginAccentColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              LoginPage(callback: successfullyLoggedIn)));
                      // .push(PageRouteBuilder(pageBuilder: () => RegisterPage())());
                    },
                    child: Text('Log in'.toUpperCase(), style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          context.watch<ThemesProvider>().selectedTheme.accountRegisterAccentColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) =>
                              RegisterPage(callback: successfullyLoggedIn)));
                    },
                    child: Text('Register'.toUpperCase(), style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: TextButton(
                child: Text('Settings'),
                style: TextButton.styleFrom(
                  primary: context.watch<ThemesProvider>().selectedTheme.accentColor,
                ),
                onPressed: () => Navigator.of(context).push(slideUpRoute(SettingsScreen())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
