import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsProvider extends InheritedWidget {
  NotificationsProvider({Key key, this.child}) : super(key: key, child: child) {
    initialize();
  }

  final FlutterLocalNotificationsPlugin flutterNotifications =
      FlutterLocalNotificationsPlugin();
  final Widget child;
  final StreamController<String> _selectedStreamCtrl =
      StreamController.broadcast();

  Stream<String> get selectedStream => _selectedStreamCtrl.stream;

  void initialize() async {
    var androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

  static NotificationsProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NotificationsProvider>();
  }

  dispose() {
    _selectedStreamCtrl.close();
  }

  @override
  bool updateShouldNotify(NotificationsProvider oldWidget) {
    return false;
  }
}

class MyNotifications {
  static const battleRequest = 1;
  static const battleRequestSpecifics = NotificationDetails(
    AndroidNotificationDetails(
      '0',
      'Battle Requests',
      'Shown when someone requests a battle.',
      importance: Importance.Max,
      priority: Priority.Max,
    ),
    IOSNotificationDetails(),
  );

  static const gameFound = 1;
  static const gameFoundSpecifics = NotificationDetails(
    AndroidNotificationDetails(
      '1',
      'Game Started',
      'Shown when you find an online game while the app is in the background.',
      importance: Importance.High,
      priority: Priority.Max,
    ),
    IOSNotificationDetails(),
  );
}
