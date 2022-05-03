import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:four_in_a_row/menu/account/friends.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';

class NotificationsProvider {
  late final FlutterLocalNotificationsPlugin flutterNotifications;

  final StreamController<String> _selectedStreamCtrl = StreamController.broadcast();

  Stream<String> get selectedStream => _selectedStreamCtrl.stream;

  bool get canNotify => !kIsWeb;
  bool get shouldNotify => canNotify && FiarSharedPrefs.settingsAllowNotifications;

  NotificationsProvider() {
    initialize();
  }

  void initialize() async {
    if (!shouldNotify) return;

    flutterNotifications = FlutterLocalNotificationsPlugin();
    var androidSettings = AndroidInitializationSettings('ic_stat_ic_launcher_notification');
    var iosSettings = IOSInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: true,
    );
    await flutterNotifications
        .initialize(InitializationSettings(android: androidSettings, iOS: iosSettings),
            onSelectNotification: (str) {
      if (str != null) {
        _selectedStreamCtrl.add(str);
      }
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
    if (!shouldNotify) return;

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
    if (!shouldNotify) return;

    this.flutterNotifications.cancel(FiarNotifications.battleRequest);
  }
}

class FiarNotifications {
  static const allNotificationIds = [battleRequest, gameFound, searchingGame];

  static const battleRequest = 1;
  static final battleRequestSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
      '1',
      'Battle Requests',
      channelDescription: 'Shown when someone wants to battle with you.',
      category: 'CATEGORY_MESSAGE',
      importance: Importance.high,
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
      channelDescription: 'Shown when you find an online game while the app is in the background.',
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
      channelDescription: 'Shown persistently while searching for a game.',
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
