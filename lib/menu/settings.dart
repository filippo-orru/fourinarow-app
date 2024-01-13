import 'package:flutter/material.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/menu/common/overlay_dialog.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/global_common_widgets.dart';
import 'package:four_in_a_row/util/logger.dart';
import 'package:four_in_a_row/util/vibration.dart';
import 'package:four_in_a_row/util/constants.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'account/onboarding/onboarding.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _canVibrate;

  @override
  void initState() {
    super.initState();
    _setCanVibrate();
  }

  void _setCanVibrate() async {
    bool canVibrate = await Vibrations.canVibrate;
    setState(() => _canVibrate = canVibrate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FiarAppBar(
        title: "Settings",
      ),
      body: Consumer<FiarSharedPrefs>(
        builder: (_, __, ___) => ListView(
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
                  subtitle: Text(
                    userInfo.loggedIn ? userInfo.user!.username : 'Log in',
                  ),
                  onTap: () {
                    if (userInfo.loggedIn) {
                      showDialog(
                          context: context,
                          builder: (_) => SimpleDialog(
                                title: Text('Do you want to log out?'),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            primary: Colors.black87,
                                          ),
                                          child: Text('Cancel'),
                                          onPressed: () => Navigator.of(context).pop(),
                                        ),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            primary: context
                                                .watch<ThemesProvider>()
                                                .selectedTheme
                                                .accentColor,
                                          ),
                                          onPressed: () {
                                            context.read<UserInfo>().logOut();
                                            Navigator.of(context).pop();
                                            // TODO fix bug: when logging out here,
                                            //  the user can go back and sees the
                                            //  "something went wrong" friends list
                                            //  screen
                                          },
                                          child: Text('Log out'),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ));
                    } else {
                      Navigator.of(context).push(slideUpRoute(AccountOnboarding()));
                    }
                  }),
            ),
            ListTile(
              leading: Container(
                height: 64,
                width: 32,
                alignment: Alignment.center,
                child: Icon(Icons.vibration_rounded),
              ),
              title: Text('Vibration'),
              subtitle:
                  _canVibrate == false ? Text('Your device does not support vibration') : null,
              onTap: () {
                setState(() => FiarSharedPrefs.settingsAllowVibrate
                    .set(!FiarSharedPrefs.settingsAllowVibrate.get()));
              },
              trailing: Switch(
                value: _canVibrate == true ? FiarSharedPrefs.settingsAllowVibrate.get() : false,
                activeColor: context.watch<ThemesProvider>().selectedTheme.accentColor,
                onChanged: _canVibrate == true
                    ? (v) {
                        FiarSharedPrefs.settingsAllowVibrate.set(v);
                        if (v) {
                          Vibrations.tiny();
                        }
                      }
                    : null,
              ),
              enabled: _canVibrate == true,
            ),
            ListTile(
              leading: Container(
                height: 64,
                width: 32,
                alignment: Alignment.center,
                child: Icon(FiarSharedPrefs.settingsAllowNotifications.get()
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded),
              ),
              title: Text('Notifications'),
              subtitle: Text("Notify when a game was found or a friend wants to battle"),
              onTap: () {
                setState(() {
                  FiarSharedPrefs.settingsAllowNotifications
                      .set(!FiarSharedPrefs.settingsAllowNotifications.get());
                });
              },
              trailing: Switch(
                value: FiarSharedPrefs.settingsAllowNotifications.get(),
                activeColor: context.watch<ThemesProvider>().selectedTheme.accentColor,
                onChanged: (v) => FiarSharedPrefs.settingsAllowNotifications.set(v),
              ),
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
                showDialog(context: context, builder: (_) => ChooseQuickchatEmojis());
              },
            ),
            ListTile(
              leading: Container(
                height: 64,
                width: 32,
                alignment: Alignment.center,
                child: Icon(Icons.privacy_tip_outlined),
              ),
              title: Text('Privacy Policy'),
              onTap: () async {
                if (!await launchUrl(Uri.parse(PRIVACY_POLICY))) {
                  Logger.e("Could not launch $PRIVACY_POLICY");
                }
              },
            ),
            ListTile(
              leading: Container(
                height: 64,
                width: 32,
                alignment: Alignment.center,
                child: Icon(Icons.feedback_outlined),
              ),
              title: Text('Feedback'),
              onTap: () {
                showFeedbackDialog(context);
              },
            ),
          ],
        ),
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

  bool _allowSave() =>
      emojiSelectState.values.where((selected) => selected).length == QUICKCHAT_EMOJI_COUNT;

  List<String> get _selectedEmojis =>
      emojiSelectState.entries.where((entry) => entry.value).map((entry) => entry.key).toList();

  String get _selectedEmojisString => _selectedEmojis.join(" ");

  @override
  void initState() {
    super.initState();

    emojiSelectState = ALLOWED_QUICKCHAT_EMOJIS.asMap().map((_, emoji) =>
        MapEntry(emoji, FiarSharedPrefs.settingsQuickchatEmojis.get().contains(emoji)));
  }

  @override
  Widget build(BuildContext context) {
    var mediaQ = MediaQuery.of(context);
    return OverlayDialog(
      true,
      hide: () => Navigator.of(context).pop(),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            height: mediaQ.size.height - 64,
            width: mediaQ.size.width - 64,
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Text(
                    'Quick Chat Emojis',
                    style: TextStyle(
                      color: Colors.black87,
                      fontFamily: 'RobotoSlab',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(shrinkWrap: true, slivers: <Widget>[
                    SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                      delegate: SliverChildListDelegate(
                        ALLOWED_QUICKCHAT_EMOJIS.map<Widget>((emoji) {
                          bool isSelected = emojiSelectState[emoji] ?? false;
                          return Padding(
                            padding: const EdgeInsets.all(4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => emojiSelectState[emoji] = !isSelected);
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: (isSelected
                                          ? context
                                              .watch<ThemesProvider>()
                                              .selectedTheme
                                              .accentColor
                                              .shade500
                                          : context
                                              .watch<ThemesProvider>()
                                              .selectedTheme
                                              .accentColor
                                              .shade50)
                                      .withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.all(14),
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Text(emoji, style: TextStyle(fontSize: 300)),
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
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            child: child,
                            position: Tween<Offset>(begin: Offset(0.1, 0), end: Offset(0.0, 0.0))
                                .animate(animation),
                          ),
                        );
                      },
                      child: Text(
                        _selectedEmojisString,
                        key: ValueKey(_selectedEmojis),
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                              fontSize: 18,
                            ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              primary: Colors.black87,
                            ),
                            child: Text('Cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              primary: context.watch<ThemesProvider>().selectedTheme.accentColor,
                            ),
                            child: Text('Save'),
                            onPressed: _allowSave()
                                ? () {
                                    FiarSharedPrefs.settingsQuickchatEmojis.set(_selectedEmojis);
                                    Navigator.of(context).pop();
                                  }
                                : null,
                          ),
                        ],
                      ),
                      TweenAnimationBuilder(
                        tween: ColorTween(
                            begin: Colors.black54,
                            end: _allowSave() ? Colors.black54 : Colors.red.shade400),
                        duration: Duration(milliseconds: 220),
                        builder: (_, color, __) => Text(
                          'Selected ${_selectedEmojis.length} of $QUICKCHAT_EMOJI_COUNT',
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: (color as Color)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
