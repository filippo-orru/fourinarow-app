import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';

class NotificationsProvider extends StatefulWidget {
  NotificationsProvider({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  createState() => NotificationsProviderState();

  static NotificationsProviderState? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_NotificationsProviderInherit>()
        ?.state;
  }
}

class NotificationsProviderState extends State<NotificationsProvider> {
  late final FlutterLocalNotificationsPlugin flutterNotifications;

  final StreamController<String> _selectedStreamCtrl =
      StreamController.broadcast();

  Stream<String> get selectedStream => _selectedStreamCtrl.stream;

  bool get canNotify => !kIsWeb;
  bool get shouldNotify =>
      canNotify && FiarSharedPrefs.settingsAllowNotifications;

  void initialize() async {
    if (!shouldNotify) return;

    flutterNotifications = FlutterLocalNotificationsPlugin();
    var androidSettings =
        AndroidInitializationSettings('mipmap/ic_launcher_notification');
    var iosSettings = IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: true,
    );
    await flutterNotifications.initialize(
        InitializationSettings(android: androidSettings, iOS: iosSettings),
        onSelectNotification: (str) {
      if (str != null) {
        _selectedStreamCtrl.add(str);
      }
      return Future.value();
    });

    for (var notificationId in FiarNotifications.allNotificationIds) {
      flutterNotifications.cancel(notificationId);
    }
  }

  void comeToPlay() {
    if (!shouldNotify) return;

    this.flutterNotifications.cancel(FiarNotifications.gameFound);
    this.flutterNotifications.show(
          FiarNotifications.gameFound,
          'Game Starting!',
          'Come back quickly to play!',
          FiarNotifications.gameFoundSpecifics,
        );

/* TODO add callback for timeout and switch to provider<mynotifications> with functions like comeToPlay()
    // Cancel notification after a minute
    Timer cancelNotificationTimer = Timer(
      Duration(seconds: 60),
      () {
        this.flutterNotifications?.cancel(MyNotifications.gameFound);
        leaveGame();
      },
    );
    lifecycle.onReady = () {
      cancelNotificationTimer?.cancel();
      notifProv.flutterNotifications?.cancel(MyNotifications.gameFound);
    };
    */
  }

  void searchingGame() {
    if (!shouldNotify) return;

    this.flutterNotifications.cancel(FiarNotifications.searchingGame);
    this.flutterNotifications.show(
          FiarNotifications.searchingGame,
          'Searching for game...',
          'This might take a while.',
          FiarNotifications.searchingGameSpecifics,
        );
  }

  void cancelSearchingGame() {
    this.flutterNotifications.cancel(FiarNotifications.searchingGame);
  }

  void battleRequest(String name) {
    if (!shouldNotify) return;

    this.flutterNotifications.cancel(FiarNotifications.battleRequest);
    this.flutterNotifications.show(
          FiarNotifications.battleRequest,
          '$name wants to play a round of Four in a Row!',
          'Tap to join them!',
          FiarNotifications.battleRequestSpecifics,
        );
  }

  void cancelBattleRequest() {
    this.flutterNotifications.cancel(FiarNotifications.battleRequest);
  }

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return _NotificationsProviderInherit(widget.child, this);
  }

  @override
  dispose() {
    _selectedStreamCtrl.close();
    super.dispose();
  }
}

class _NotificationsProviderInherit extends InheritedWidget {
  _NotificationsProviderInherit(Widget child, this.state, {Key? key})
      : super(key: key, child: child);

  final NotificationsProviderState state;

  @override
  bool updateShouldNotify(oldWidget) {
    return false;
  }
}

class FiarNotifications {
  static const allNotificationIds = [battleRequest, gameFound, searchingGame];

  static const battleRequest = 1;
  static final battleRequestSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
      '1',
      'Battle Requests',
      'Shown when someone requests a battle.',
      category: 'CATEGORY_MESSAGE',
      importance: Importance.max,
      priority: Priority.max,
      timeoutAfter: BattleRequestDialog.TIMEOUT.inMilliseconds,
    ),
    iOS: IOSNotificationDetails(),
  );

  static const gameFound = 2;
  static const gameFoundSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
      '2',
      'Game Started',
      'Shown when you find an online game while the app is in the background.',
      category: 'CATEGORY_MESSAGE',
      importance: Importance.max,
      priority: Priority.max,
    ),
    iOS: IOSNotificationDetails(),
  );

  static const searchingGame = 3;
  static const searchingGameSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
      '3',
      'Searching Game',
      'Shown persistently while searching for a game',
      category: 'CATEGORY_SERVICE',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      usesChronometer: true,
      visibility: NotificationVisibility.public,
      timeoutAfter: 1000 * 60 * 10, // 10 min
    ),
    iOS: IOSNotificationDetails(),
  );
}
