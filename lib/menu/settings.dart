import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/menu/common/overlay_dialog.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:four_in_a_row/util/constants.dart';
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
          ListTile(
            leading: Container(
              height: 64,
              width: 32,
              alignment: Alignment.center,
              child: Icon(Icons.emoji_emotions_outlined),
            ),
            title: Text('Quick Chat Emojis'),
            subtitle: Text("Communicate with your opponent"),
            onTap: () {
              showDialog(
                  context: context, builder: (_) => ChooseQuickchatEmojis());
            },
          ),
        ],
      ),
    );
  }
}

class ChooseQuickchatEmojis extends StatefulWidget {
  @override
  _ChooseQuickchatEmojisState createState() => _ChooseQuickchatEmojisState();
}

class _ChooseQuickchatEmojisState extends State<ChooseQuickchatEmojis> {
  Map<String, bool> emojiSelectState = {};

  @override
  void initState() {
    super.initState();

    emojiSelectState = ALLOWED_QUICKCHAT_EMOJIS.asMap().map((_, emoji) =>
        MapEntry(
            emoji, FiarSharedPrefs.settingsQuickchatEmojis.contains(emoji)));
  }

  @override
  Widget build(BuildContext context) {
    return OverlayDialog(
      true,
      hide: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.white,
        height: MediaQuery.of(context).size.height - 64,
        width: MediaQuery.of(context).size.width - 64,
        padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          children: [
            Text(
              'Quick Chat Emojis',
              style: TextStyle(
                fontFamily: 'RobotoSlab',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              height: 32,
              width: 32,
              color: Colors.green,
            ),
            Expanded(
              child: CustomScrollView(shrinkWrap: true, slivers: <Widget>[
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4),
                  delegate: SliverChildListDelegate(
                    ALLOWED_QUICKCHAT_EMOJIS.map<Widget>((emoji) {
                      bool isSelected = emojiSelectState[emoji] ?? false;
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: GestureDetector(
                          onTap: () {
                            setState(
                                () => emojiSelectState[emoji] = !isSelected);
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: (isSelected
                                      ? Colors.blue.shade500
                                      : Colors.blue.shade50)
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.all(14),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child:
                                  Text(emoji, style: TextStyle(fontSize: 300)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // SizedBox(height: 64),
              ]),
            ),
            Container(
              height: 32,
              width: 32,
              color: Colors.green,
            ),
            Container(
              width: 64,
              height: 32,
              color: Colors.red,
              child: Row(
                children: [
                  Text('lalalala'),
                  TextButton(
                    child: Text('Save'),
                    style: TextButton.styleFrom(),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
