import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:four_in_a_row/util/constants.dart' as constants;

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

  bool ok = false;
  bool refreshing = false;
  bool loadedInfo = false;

  String _id;
  String _username;
  String _password;
  String _email;
  List<PublicUser> _friends;
  GameInfo _gameInfo;

  String get id => _id;
  String get username => _username;
  String get password => _password;
  String get email => _email;
  List<PublicUser> get friends => _friends;
  GameInfo get gameInfo => _gameInfo;

  bool get loggedIn => ok && _username != null && _password != null;

  Map<String, String> get _body => {
        "username": username,
        "password": password,
      };

  void logOut() async {
    this.ok = false;
    this._username = null;
    this._password = null;

    _prefs = _prefs ?? await SharedPreferences.getInstance();
    if (_prefs.containsKey('username') && _prefs.containsKey('password')) {
      _prefs.remove('username');
      _prefs.remove('password');
    }
  }

  void loadCredentials() async {
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    if (_prefs.containsKey('username') && _prefs.containsKey('password')) {
      this.setCredentials(
          _prefs.getString('username'), _prefs.getString('password'));
    }
  }

  void setCredentials(String username, String password) async {
    _prefs.setString('username', username);
    _prefs.setString('password', password);

    this._username = username;
    this._password = password;
    _loadInfo();
  }

  Future<bool> addFriend(String id, [VoidCallback callback]) async {
    var response = await http
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

  Future<UserinfoProviderState> refresh() async {
    return _loadInfo();
  }

  Future<UserinfoProviderState> _loadInfo() async {
    refreshing = true;
    var req = http.Request('GET', Uri.parse('${constants.URL}/api/users/me'))
      ..bodyFields = _body;

    var response = await req.send();
    if (response.statusCode == 200) {
      UserinfoResponse info = UserinfoResponse.fromMap(
          jsonDecode(await response.stream.bytesToString()));
      // _friends = info._friends;
      _id = info.id;
      _email = info.email;
      _friends = info.friends;
      _gameInfo = info.gameInfo;
      this.ok = true;
    }
    refreshing = false;
    if (this.loadedInfo) {
      await Future.delayed(Duration(milliseconds: 900));
    }
    loadedInfo = true;
    return Future.value(this);

    // .catchError(() {});
  }

  @override
  void initState() {
    super.initState();
    loadCredentials();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedUserinfoProvider(child: widget.child, data: this);
  }
}

class _InheritedUserinfoProvider extends InheritedWidget {
  _InheritedUserinfoProvider({Key key, this.child, this.data})
      : super(key: key, child: child);

  final Widget child;
  final UserinfoProviderState data;

  @override
  bool updateShouldNotify(_InheritedUserinfoProvider oldWidget) {
    return oldWidget.data != this.data;
  }
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

class UserinfoResponse {
  UserinfoResponse(this.id, this.name, this.friends, this.email, this.gameInfo);

  final String id;
  final String name;
  final List<PublicUser> friends;
  final String email;
  final GameInfo gameInfo;

  factory UserinfoResponse.fromMap(Map<String, dynamic> map) {
    for (String key in ['id', 'username', 'game_info', 'friends', 'email']) {
      if (!map.containsKey(key)) return null;
    }

    return UserinfoResponse(
      map['id'] as String,
      map['username'] as String,
      (map['friends'] as List<dynamic>)
          .map((dynamic friendMap) =>
              PublicUser.fromMap(friendMap as Map<String, dynamic>))
          .toList(),
      map['email'] as String,
      GameInfo.fromMap(map['game_info']),
    );
  }
}

class GameInfo {
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
}

class PublicUser {
  final String id;
  final String name;
  final GameInfo gameInfo;
  bool isFriend;

  PublicUser(this.id, this.name, this.gameInfo, [this.isFriend = false]);

  factory PublicUser.fromMap(Map<String, dynamic> map) {
    for (String key in ['username', 'game_info', 'id']) {
      if (!map.containsKey(key)) return null;
    }

    return PublicUser(
      map['id'],
      map['username'],
      GameInfo.fromMap(map['game_info']),
    );
  }
}
