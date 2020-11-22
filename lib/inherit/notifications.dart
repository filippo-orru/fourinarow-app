import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsProvider extends StatefulWidget {
  NotificationsProvider({Key key, this.child}) : super(key: key);
  final Widget child;

  @override
  createState() => NotificationsProviderState();

  static NotificationsProviderState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_NotificationsProviderInherit>()
        .state;
  }
}

class NotificationsProviderState extends State<NotificationsProvider> {
  FlutterLocalNotificationsPlugin flutterNotifications;

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
      await flutterNotifications
          .initialize(InitializationSettings(androidSettings, iosSettings),
              onSelectNotification: (str) {
        _selectedStreamCtrl.add(str);
        return Future.value();
      });
    }
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
  _NotificationsProviderInherit(Widget child, this.state, {Key key})
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
    AndroidNotificationDetails(
      '1',
      'Battle Requests',
      'Shown when someone requests a battle.',
      category: 'CATEGORY_MESSAGE',
      importance: Importance.Max,
      priority: Priority.Max,
    ),
    IOSNotificationDetails(),
  );

  static const gameFound = 2;
  static const gameFoundSpecifics = NotificationDetails(
    AndroidNotificationDetails(
      '2',
      'Game Started',
      'Shown when you find an online game while the app is in the background.',
      category: 'CATEGORY_MESSAGE',
      importance: Importance.Max,
      priority: Priority.Max,
    ),
    IOSNotificationDetails(),
  );

  static const searchingGame = 3;
  static const searchingGameSpecifics = NotificationDetails(
    AndroidNotificationDetails(
      '3',
      'Searching Game',
      'Shown persistently while searching for a game',
      category: 'CATEGORY_SERVICE',
      importance: Importance.Low,
      priority: Priority.Low,
      ongoing: true,
    ),
    IOSNotificationDetails(),
  );
}
