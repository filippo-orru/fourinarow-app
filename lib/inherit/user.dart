import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/logger.dart';
import 'package:http/http.dart' as http;
import 'package:four_in_a_row/util/constants.dart' as constants;

import 'package:four_in_a_row/util/extensions.dart';

class UserInfo with ChangeNotifier {
  http.Client _client = http.Client();

  bool refreshing = false;
  bool offline = false;

  String? get sessionToken => FiarSharedPrefs.sessionToken;
  set sessionToken(String? s) => FiarSharedPrefs.sessionToken = s;

  User? user;

  bool get loggedIn => sessionToken != null && user != null;
  //  {
  //   if ((sessionToken == null) != (user == null)) {
  //     // something is fucked up
  //     logOut();
  //   }
  //   return ;
  // }

  UserInfo() {
    _loadInfo();
  }

  Map<String, String>? _headers() {
    if (sessionToken == null) return null;
    return {"SessionToken": sessionToken!};
  }

  Future<int> register(String username, String password) {
    Map<String, String> body = {
      "username": username,
      "password": password,
    };

    return _client
        .post(Uri.parse('${constants.HTTP_URL}/api/users/register'), body: body)
        .timeout(Duration(seconds: 4))
        .then((response) {
      if (response.statusCode == 200) {
        String sessionToken = jsonDecode(response.body)['content']!;
        setCredentials(sessionToken);
      }
      return response.statusCode;
    }, onError: (_) {
      print("Error registering!");
      return 0;
    });
  }

  /// Return 200 if successful, 403 if credentials are wrong and 0 on network error.
  Future<int> login(String username, String password) {
    Logger.i("Logging in...");
    Map<String, String> body = {
      "username": username,
      "password": password,
    };
    return _client
        .post(Uri.parse("${constants.HTTP_URL}/api/users/login"), body: body)
        .timeout(Duration(seconds: 4))
        .then((response) {
      if (response.statusCode == 200) {
        String sessionToken = jsonDecode(response.body)['content']!;
        setCredentials(sessionToken);
        Logger.i("Logged in!");
      }
      return response.statusCode;
    }, onError: (e) {
      Logger.e("Error while logging in!", e);
      return false;
    });
  }

  void logOut() async {
    // debugPrintStack();

    if (sessionToken != null) {
      http
          .post(Uri.parse("${constants.HTTP_URL}/api/users/logout"),
              headers: _headers()!)
          .toNullable()
          .timeout(Duration(seconds: 4), onTimeout: () => null)
          .onError((e, __) {
        Logger.e("Error logging out!", e);
      });
    }
    this.sessionToken = null;
    this.user = null;

    notifyListeners();
  }

  void setCredentials(String sessionToken) async {
    this.sessionToken = sessionToken;
    _loadInfo();
  }

  Future<PublicUser?> addFriend(String id, [VoidCallback? callback]) async {
    if (!loggedIn) return null;

    var response = await _client
        .post(
          Uri.parse("${constants.HTTP_URL}/api/users/me/friends?id=$id"),
          headers: _headers(),
        )
        .timeout(Duration(seconds: 4));
    if (response.statusCode == 200) {
      if (callback != null) {
        callback();
      }
      await _loadInfo();
      return this.user!.friends.firstWhere((u) => u.id == id);
    } else {
      _loadInfo();
      return null;
    }
  }

  Future<bool> removeFriend(String id, [VoidCallback? callback]) async {
    var headers = _headers();
    if (headers == null) return false;

    var response = await _client.delete(
        Uri.parse("${constants.HTTP_URL}/api/users/me/friends/$id"),
        headers: headers);
    if (response.statusCode == 200) {
      if (callback != null) {
        callback();
      }
      await _loadInfo();
      // _friends.firstWhere((u) => u.id == id)?.isFriend = true;
      return true;
    } else {
      _loadInfo();
      return false;
    }
  }

  Future<UserInfo?> _loadInfo({
    delay = false,
    shouldSetState = false,
  }) async {
    if (shouldSetState == true) {
      refreshing = true;
    }

    if (sessionToken == null) return null;

    if (sessionToken!.startsWith("migration")) {
      // migrate from old username + pw storage
      // Let's hope users don't have ":::" in their password
      List<String> parts = sessionToken!.split(":::");
      if (parts.length != 3) {
        sessionToken = null;
        return null;
      }
      if (await login(parts[1], parts[2]) != 200) {
        sessionToken = null;
        return null;
      }
    }

    try {
      var response = await http
          .get(
            Uri.parse('${constants.HTTP_URL}/api/users/me'),
            headers: _headers()!,
          )
          .toNullable()
          .timeout(Duration(seconds: 4), onTimeout: () => null);
      if (response?.statusCode == 200) {
        User? user = User.fromMap(jsonDecode(response!.body));

        this.user = user;
      } else if (response?.statusCode == 403) {
        // incorrect credentials
        debugPrint(
            "Logging out. Session token $sessionToken seems to have expired");
        this.logOut();
      }
      offline = false;
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 7) {
        offline = true;
      }
    } on TimeoutException {
      offline = true;
    } on http.ClientException {
      offline = true;
    }

    refreshing = false;
    if (this.loggedIn && delay) {
      await Future.delayed(Duration(milliseconds: 300));
    }
    // print("set state in userinfo refresh");
    // print("userInfo.notifyListeners()");
    notifyListeners();
    // print("reloaded user info");
    return Future.value(this);

    // .catchError(() {});
  }

  Future<UserInfo?> refresh({shouldSetState: true}) {
    return _loadInfo(delay: true, shouldSetState: shouldSetState);
  }

  Future<PublicUser?> getUserInfo({required String userId}) async {
    var response;
    try {
      response = await http
          .get(Uri.parse("${constants.HTTP_URL}/api/users/$userId"))
          .timeout(Duration(seconds: 4));
      if (response.statusCode == 200) {
        return PublicUser.fromMapPublic(user, jsonDecode(response.body));
      }
    } on Exception {
      print("Error trying to get user info");
    }

    return null;
  }
}

class GameInfo extends Equatable {
  final int skillRating;
  final int playerRank;

  GameInfo(this.skillRating, this.playerRank);

  static GameInfo? fromMap(Map<String, dynamic> map) {
    for (String key in ['skill_rating']) {
      if (!map.containsKey(key)) return null;
    }

    return GameInfo(
      map['skill_rating'] as int,
      255,
    );
  }

  @override
  List<Object> get props => [skillRating, playerRank];
}

enum FriendState { IsFriend, IsRequestedByMe, HasRequestedMe, None, Loading }

extension FriendStateExtension on FriendState {
  static FriendState fromString(String s) {
    switch (s) {
      case "IsFriend":
        return FriendState.IsFriend;
      case "IsRequestedByMe":
        return FriendState.IsRequestedByMe;
      case "HasRequestedMe":
        return FriendState.HasRequestedMe;
      default:
        return FriendState.None;
    }
  }

  Widget icon({Color? color}) {
    switch (this) {
      case FriendState.IsFriend:
        return Icon(Icons.check, color: color ?? Colors.black45);
      case FriendState.IsRequestedByMe:
        return Icon(Icons.outgoing_mail, color: color ?? Colors.black45);
      case FriendState.HasRequestedMe:
        return Icon(Icons.move_to_inbox_rounded,
            color: color ?? Colors.black45);
      case FriendState.None:
        return Icon(Icons.person_add, color: color ?? Colors.black45);
      case FriendState.Loading:
        return Container(
          width: 24,
          height: 24,
          child: Theme(
              data: ThemeData(accentColor: color),
              child: CircularProgressIndicator()),
        );
      default:
        throw new UnimplementedError();
    }
  }

  String title(String name) {
    switch (this) {
      case FriendState.IsFriend:
        return "You're already friends with $name";
      case FriendState.IsRequestedByMe:
        return "Waiting for $name to accept your friend request...";
      case FriendState.HasRequestedMe:
        return "$name wants to be your friend";
      case FriendState.None:
        return 'Add $name as friend';
      case FriendState.Loading:
        return "Loading...";
      default:
        throw new UnimplementedError();
    }
  }

  String? subTitle() {
    switch (this) {
      case FriendState.IsFriend:
        return null;
      case FriendState.IsRequestedByMe:
        return "Wait for them to accept your request";
      case FriendState.HasRequestedMe:
        return 'Tap to accept their request';
      case FriendState.None:
        return 'You will become friends once they accept your request';
      case FriendState.Loading:
        return "...";
      default:
        throw new UnimplementedError();
    }
  }
}

class PublicUser {
  final String id;
  final String username;
  final GameInfo gameInfo;
  FriendState friendState;
  bool isPlaying;

  PublicUser(this.id, this.username, this.gameInfo, this.friendState,
      {this.isPlaying = false});

  static PublicUser? fromMapPublic(User? me, Map<String, dynamic> map) {
    for (String key in ['username', 'game_info', 'id', 'playing']) {
      if (!map.containsKey(key)) return null;
    }

    GameInfo? gameInfo = GameInfo.fromMap(map['game_info']);
    if (gameInfo == null) return null;

    String userId = map['id'];
    FriendState? friendState = me?.friends
        .toNullable()
        .firstWhere((friend) => friend?.id == userId, orElse: () => null)
        ?.friendState;

    return PublicUser(
      userId,
      map['username'],
      gameInfo,
      friendState ?? FriendState.None,
      isPlaying: map['playing'] ?? false,
    );
  }

  static PublicUser? fromMapFriends(Map<String, dynamic> map) {
    for (String key in ['user', 'friend_state']) {
      if (!map.containsKey(key)) return null;
    }

    Map<String, dynamic> userMap = map['user'];
    for (String key in ['username', 'game_info', 'id', 'playing']) {
      if (!userMap.containsKey(key)) return null;
    }

    GameInfo? gameInfo = GameInfo.fromMap(userMap['game_info']);
    if (gameInfo == null) return null;

    return PublicUser(
      userMap['id'],
      userMap['username'],
      gameInfo,
      FriendStateExtension.fromString(map['friend_state']),
      isPlaying: userMap['playing'] ?? false,
    );
  }
}

class User extends Equatable {
  User({
    required this.id,
    required this.username,
    required this.email,
    required this.friends,
    required this.gameInfo,
  });

  final String id;
  final String username;
  final String email;
  final List<PublicUser> friends;
  final GameInfo gameInfo;

  static User? fromMap(Map<String, dynamic> map) {
    for (String key in [
      'id',
      'username',
      'game_info',
      'friendships',
      'email'
    ]) {
      if (!map.containsKey(key)) return null;
    }

    List<PublicUser> friends = (map['friendships'] as List<dynamic>)
        .map((dynamic friendMap) =>
            PublicUser.fromMapFriends(friendMap as Map<String, dynamic>))
        .toList()
        .filterNotNull();

    GameInfo? gameInfo = GameInfo.fromMap(map['game_info']);
    if (gameInfo == null) return null;

    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      friends: friends,
      gameInfo: gameInfo,
    );
  }

  @override
  List<Object> get props => [id, username, email, friends, gameInfo];
}
