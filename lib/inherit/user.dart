import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:four_in_a_row/util/constants.dart' as constants;

class _InheritedUserinfoProvider extends InheritedWidget {
  _InheritedUserinfoProvider({Key key, this.child, this.data})
      : super(key: key, child: child);

  final Widget child;
  final UserinfoProviderState data;

  @override
  bool updateShouldNotify(_InheritedUserinfoProvider oldWidget) {
    // bool shouldNotify = oldWidget.data.user != this.data.user ||
    //     oldWidget.data.refreshing != this.data.refreshing ||
    //     oldWidget.data.offline != this.data.offline;
    // print("User info should notify: $shouldNotify");
    // return shouldNotify;
    return true;
  }
}

class UserinfoProvider extends StatefulWidget {
  UserinfoProvider({Key key, @required this.child}) : super(key: key);

  final Widget child;

  @override
  createState() => UserinfoProviderState();

  static UserinfoProviderState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedUserinfoProvider>()
        ?.data;
  }
}

class UserinfoProviderState extends State<UserinfoProvider> {
  SharedPreferences _prefs;
  http.Client _client = http.Client();

  // bool _ok = false;
  bool refreshing = false;
  bool offline = false;
  // bool loadedInfo = false;

  String username;
  String password;

  User user;

  bool get loggedIn => username != null && password != null && user != null;

  // void rebuild() {
  //   // print("rebuilding user info");
  //   if (mounted) setState(() {});
  // }
  //  && _username != null && _password != null;

  Map<String, String> get _body => {
        "username": username,
        "password": password,
      };

  void logOut() async {
    // this._ok = false;
    this.username = null;
    this.password = null;
    this.user = null;

    // _prefs = _prefs;
    if (_prefs.containsKey('username') && _prefs.containsKey('password')) {
      _prefs.remove('username');
      _prefs.remove('password');
    }
  }

  void loadCredentials() async {
    // _prefs = _prefs ?? await SharedPreferences.getInstance();
    if (_prefs.containsKey('username') && _prefs.containsKey('password')) {
      this.setCredentials(
          _prefs.getString('username'), _prefs.getString('password'));
    }
  }

  void setCredentials(String username, String password) async {
    _prefs.setString('username', username);
    _prefs.setString('password', password);

    this.username = username;
    this.password = password;
    _loadInfo();
  }

  Future<bool> addFriend(String id, [VoidCallback callback]) async {
    var response = await _client
        .post("${constants.URL}/api/users/me/friends?id=$id", body: _body);
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

  Future<UserinfoProviderState> refresh({shouldSetState: true}) {
    return _loadInfo(delay: true, shouldSetState: shouldSetState);
  }

  Future<UserinfoProviderState> _loadInfo({
    delay = false,
    shouldSetState = false,
  }) async {
    if (this.mounted == true && shouldSetState == true) {
      setState(() {
        refreshing = true;
      });
    }

    if (username == null || password == null) {
      return null;
    }
    // rebuild();

    var req = http.Request('GET', Uri.parse('${constants.URL}/api/users/me'))
      ..bodyFields = _body;

    try {
      var response = await _client.send(req);
      if (response.statusCode == 200) {
        User user =
            User.fromMap(jsonDecode(await response.stream.bytesToString()));

        this.user = user;
      }
      offline = false;
    } on SocketException catch (e) {
      if (e.osError.errorCode == 7) {
        offline = true;
      }
    } on http.ClientException {
      offline = true;
    }

    refreshing = false;
    if (this.loggedIn && delay) {
      await Future.delayed(Duration(milliseconds: 300));
    }
    this.setState(() => print("set state in userinfo refresh"));
    // print("reloaded user info");
    return Future.value(this);

    // .catchError(() {});
  }

  Future<PublicUser> getUserInfo({@required String userId}) async {
    var resp = await _client.get("${constants.URL}/api/users/$userId");
    if (resp.statusCode == 200) {
      return PublicUser.fromMap(jsonDecode(resp.body));
    } else {
      throw HttpException("Not found");
    }
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      loadCredentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    // print(" user info: build");
    return _InheritedUserinfoProvider(child: widget.child, data: this);
  }

  // @override
  // bool operator ==(Object other) {
  // if (other is UserinfoProviderState) {
  //   return other.friends == friends &&
  //       other.gameInfo == gameInfo &&
  //       other.email == email &&
  //       other.username == username &&
  //       other.loggedIn == loggedIn;
  // }
  //   return other.hashCode == this.hashCode;
  // }

  // @override
  // int get hashCode =>
  //     friends.hashCode +
  //     gameInfo.hashCode +
  //     email.hashCode +
  //     username.hashCode +
  //     loggedIn.hashCode;
}

// class Friend {
//   final String id;
//   final String name;
//   final int sr;
//   const Friend(this.id, this.name, this.sr);

//   factory Friend.fromMap(Map<String, dynamic> map) {
//     for (String key in ['username', 'game_info', 'id']) {
//       if (!map.containsKey(key)) return null;
//     }
//     return Friend(
//       map['id'],
//       map['username'],
//       (map['game_info'] as Map<String, dynamic>)['skill_rating'] as int,
//     );
//   }
// }

// class UserinfoResponse {
//   UserinfoResponse(this.id, this.name, this.friends, this.email, this.gameInfo);

//   final String id;
//   final String name;
//   final List<PublicUser> friends;
//   final String email;
//   final GameInfo gameInfo;

// }

class GameInfo extends Equatable {
  final int skillRating;
  final int playerRank;

  GameInfo(this.skillRating, this.playerRank);

  factory GameInfo.fromMap(Map<String, dynamic> map) {
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

class PublicUser {
  final String id;
  final String name;
  final GameInfo gameInfo;
  bool isFriend;
  bool isPlaying;

  PublicUser(
    this.id,
    this.name,
    this.gameInfo, {
    this.isFriend = false,
    this.isPlaying = false,
  });

  factory PublicUser.fromMap(Map<String, dynamic> map) {
    for (String key in ['username', 'game_info', 'id']) {
      if (!map.containsKey(key)) return null;
    }

    return PublicUser(
      map['id'],
      map['username'],
      GameInfo.fromMap(map['game_info']),
      isPlaying: map['playing'] ?? false,
    );
  }
}

class User extends Equatable {
  User({
    this.id,
    this.username,
    // this.password,
    this.email,
    this.friends,
    this.gameInfo,
  });

  final String id;
  final String username;
  // final String password;
  final String email;
  final List<PublicUser> friends;
  final GameInfo gameInfo;

  factory User.fromMap(Map<String, dynamic> map) {
    for (String key in ['id', 'username', 'game_info', 'friends', 'email']) {
      if (!map.containsKey(key)) return null;
    }

    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      friends: (map['friends'] as List<dynamic>)
          .map((dynamic friendMap) =>
              PublicUser.fromMap(friendMap as Map<String, dynamic>))
          .toList(),
      gameInfo: GameInfo.fromMap(map['game_info']),
    );
  }

  @override
  List<Object> get props => [id, username, email, friends, gameInfo];
  // String get id => _id;
  // String get username => _username;
  // String get password => _password;
  // String get email => _email;
  // List<PublicUser> get friends => _friends;
  // GameInfo get gameInfo => _gameInfo;
}
