import 'package:flutter/foundation.dart';
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
      appBar: AppBar(
        title: Text('Account & Settings', style: TextStyle(fontFamily: 'RobotoSlab')),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.all(48),
              width: clampDouble(MediaQuery.of(context).size.height * 0.8, 220, 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Welcome to Four in a Row!', style: TextStyle(fontSize: 32)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "If you want to add friends and earn points for playing, create an account now!",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 48),
                  FilledButton.icon(
                    icon: Icon(Icons.add),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          context.watch<ThemesProvider>().selectedTheme.accountRegisterAccentColor,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              RegisterPage(callback: successfullyLoggedIn),
                        ),
                      );
                    },
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Register'.toUpperCase()),
                    ),
                  ),
                  SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: Icon(Icons.login),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: BorderSide(
                          color:
                              context.watch<ThemesProvider>().selectedTheme.accountLoginAccentColor,
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              LoginPage(callback: successfullyLoggedIn),
                        ),
                      );
                    },
                    label: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Log in'.toUpperCase()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: FilledButton.tonalIcon(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
                onPressed: () => Navigator.of(context).push(slideUpRoute(SettingsScreen())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
