import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  late FlutterLocalNotificationsPlugin flutterNotifications;

  final StreamController<String> _selectedStreamCtrl =
      StreamController.broadcast();

  Stream<String> get selectedStream => _selectedStreamCtrl.stream;

  bool web = false;

  void initialize() async {
    if (!kIsWeb) {
      flutterNotifications = FlutterLocalNotificationsPlugin();
      var androidSettings = AndroidInitializationSettings('mipmap/ic_launcher');
      var iosSettings = IOSInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      );
      await flutterNotifications.initialize(
          InitializationSettings(android: androidSettings, iOS: iosSettings),
          onSelectNotification: (str) {
        _selectedStreamCtrl.add(str);
        return Future.value();
      });
    }
  }

  void comeToPlay() {
    this.flutterNotifications.cancel(MyNotifications.gameFound);
    this.flutterNotifications.show(
          MyNotifications.gameFound,
          'Game Starting!',
          'Come back quickly to play!',
          MyNotifications.gameFoundSpecifics,
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

class MyNotifications {
  static const battleRequest = 1;
  static const battleRequestSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
      '1',
      'Battle Requests',
      'Shown when someone requests a battle.',
      category: 'CATEGORY_MESSAGE',
      importance: Importance.max,
      priority: Priority.max,
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
    ),
    iOS: IOSNotificationDetails(),
  );
}
