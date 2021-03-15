import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _canVibrate = true;

  @override
  void initState() {
    super.initState();
    _setCanVibrate();
  }

  void _setCanVibrate() async {
    _canVibrate = await Vibrations.canVibrate;
  }

  @override
  Widget build(BuildContext context) {
    bool showNotifications = FiarSharedPrefs.settingsAllowNotifications;
    bool vibrate = FiarSharedPrefs.settingsAllowVibrate;

    return Scaffold(
      appBar: FiarAppBar(
        title: "Settings",
        threeDots: [
          FiarThreeDotItem(
            'Feedback',
            onTap: () {
              showFeedbackDialog(context);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Consumer<UserInfo>(
            builder: (_, userInfo, __) => ListTile(
              leading: Container(
                height: 64,
                width: 32,
                alignment: Alignment.center,
                child: Icon(Icons.person_outline_rounded),
              ),
              title: Text('Account'),
              subtitle:
                  userInfo.loggedIn ? Text(userInfo.user!.username) : null,
              enabled: userInfo.loggedIn,
            ),
          ),
          ListTile(
            leading: Container(
              height: 64,
              width: 32,
              alignment: Alignment.center,
              child: Icon(Icons.vibration_rounded),
            ),
            title: Text('Vibration'),
            trailing: Switch(
              value: vibrate,
              onChanged: (shouldVibrate) {
                setState(
                    () => FiarSharedPrefs.settingsAllowVibrate = shouldVibrate);
              },
            ),
            enabled: _canVibrate,
          ),
          ListTile(
            leading: Container(
              height: 64,
              width: 32,
              alignment: Alignment.center,
              child: Icon(showNotifications
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded),
            ),
            title: Text('Notifications'),
            subtitle: Text(
                "Notify when a game was found or a friend wants to battle"),
            trailing: Switch(
              value: showNotifications,
              onChanged: (shouldShowNotifications) {
                setState(() {
                  FiarSharedPrefs.settingsAllowNotifications =
                      shouldShowNotifications;
                });
              },
            ),
            enabled: _canVibrate,
          ),
        ],
      ),
    );
  }
}
