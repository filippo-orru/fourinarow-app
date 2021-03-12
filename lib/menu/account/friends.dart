import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide BottomSheet;
import 'package:flutter/scheduler.dart';
import 'package:four_in_a_row/menu/settings.dart';
import 'package:http/http.dart' as http;

import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:four_in_a_row/util/battle_req_popup.dart';
import 'package:four_in_a_row/util/constants.dart' as constants;
import 'package:four_in_a_row/util/extensions.dart';
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/menu/common/overlay_dialog.dart';
import 'package:four_in_a_row/util/global_common_widgets.dart';

import '../main_menu.dart';
import 'onboarding/onboarding.dart';

import 'package:provider/provider.dart';

class FriendsList extends StatefulWidget {
  @override
  _FriendsListState createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList>
    with SingleTickerProviderStateMixin {
  late AnimationController expandMore;
  late Animation<Offset> offsetTween;

  bool showAddFriend = false;
  String? showBattleRequest;

  void battleRequest(String id) async {
    var gsm = context.read<GameStateManager>();

    setState(() => showBattleRequest = id);
    await gsm.startGame(ORqBattle(id));

    bool opponentJoined = await context
            .read<ServerConnection>()
            .serverMsgStream
            .firstWhere((msg) => msg is MsgOppJoined)
            .toNullable()
            .timeout(BattleRequestDialog.TIMEOUT, onTimeout: () => null) !=
        null;

    if (opponentJoined) {
      Navigator.of(context).push(slideUpRoute(GameStateViewer()));
      await Future.delayed(Duration(milliseconds: 180));
      hideBattleRequestDialog(leave: false);
      // serverConn.startGame(ORq(msg.lobbyCode));
    }
  }

  void hideBattleRequestDialog({leave = true}) {
    if (leave) context.read<GameStateManager>().leave();
    setState(() => showBattleRequest = null);
  }

  @override
  void initState() {
    super.initState();
    expandMore =
        AnimationController(vsync: this, duration: Duration(milliseconds: 130));
    offsetTween =
        Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(expandMore);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserInfo>(
      builder: (_, userInfo, __) => Scaffold(
        appBar: FiarAppBar(
          title: 'Friends',
          refreshing: userInfo.refreshing,
          threeDots: [
            FiarThreeDotItem(
              'Feedback',
              onTap: () {
                showFeedbackDialog(context);
              },
            ),
          ],
        ),
        resizeToAvoidBottomInset: false,
        body: userInfo.loggedIn
            ? Container(
                child: Stack(
                  fit: StackFit.loose,
                  children: [
                    _FriendsListInner(
                      userInfo: userInfo,
                      onBattleRequest: battleRequest,
                    ),
                    Positioned(
                      right: 24,
                      bottom: FiarBottomSheet.HEIGHT,
                      child: FloatingActionButton(
                        backgroundColor: Colors.purple[300],
                        child: Icon(Icons.add),
                        onPressed: () => setState(() => showAddFriend = true),
                      ),
                    ),
                    FiarBottomSheet(
                      color: Colors.purple,
                      expandedHeight: 218,
                      topChildren: [
                        Text(userInfo.user!.username,
                            style: TextStyle(
                                fontFamily: 'RobotoSlab',
                                color: Colors.grey[900],
                                fontSize: 18)),
                      ],
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              userInfo.logOut();
                              Navigator.of(context).pushReplacement(
                                  slideUpRoute(AccountOnboarding()));
                            },
                            leading: Icon(Icons.exit_to_app),
                            title: Text('Log out'),
                            // subtitle: Text('Change email'),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context)
                                  .push(slideUpRoute(SettingsScreen()));
                            },
                            leading: Icon(Icons.settings),
                            title: Text('More settings'),
                            trailing: Icon(Icons.chevron_right_rounded),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ),
                        SizedBox(height: 32),
                        Text(
                          'Sword icon made by Freepik @ flaticon.com',
                          style: Theme.of(context).textTheme.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    AddFriendDialog(
                      visible: showAddFriend,
                      hide: () => setState(
                        () => showAddFriend = false,
                      ),
                      myId: userInfo.user!.id,
                      userInfo: userInfo,
                    ),
                    BattleRequestDialog(
                      showBattleRequest,
                      hide: hideBattleRequestDialog,
                    )
                  ],
                ),
              )
            : buildErrScreen(userInfo),
      ),
    );
  }

  Center buildErrScreen(UserInfo userInfo) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('An error has occurred. Please log out and try again.'),
          SizedBox(height: 18),
          RaisedButton(
              color: Colors.grey[100],
              elevation: 2,
              onPressed: () {
                userInfo.logOut();
                Navigator.of(context).pop();
              },
              child: Text('Log out'))
        ],
      ),
    );
  }
}

class _FriendsListInner extends StatefulWidget {
  _FriendsListInner({
    Key? key,
    required this.userInfo,
    required this.onBattleRequest,
  }) : super(key: key);

  final UserInfo userInfo;
  final GlobalKey<RefreshIndicatorState> refreshKey =
      GlobalKey<RefreshIndicatorState>();

  final void Function(String) onBattleRequest;

  @override
  __FriendsListInnerState createState() => __FriendsListInnerState();
}

class __FriendsListInnerState extends State<_FriendsListInner> {
  List<int> expanded = List.empty();

  @override
  Widget build(BuildContext context) {
    List<PublicUser> confirmedFriends = widget.userInfo.user?.friends
            .where((f) => f.friendState == FriendState.IsFriend)
            .toList() ??
        [];
    List<PublicUser> friendRequests = widget.userInfo.user?.friends
            .where((f) => f.friendState != FriendState.IsFriend)
            .toList() ??
        [];
    return RefreshIndicator(
      onRefresh: () => widget.userInfo.refresh().then((_) => setState(() {})),
      key: widget.refreshKey,
      child: ListView.builder(
        itemCount: confirmedFriends.isEmpty
            ? friendRequests.isEmpty
                ? 1 // -> show 'no friends'
                : 1 + friendRequests.length // show requests with title
            : confirmedFriends.length +
                (friendRequests.isEmpty
                    ? 0 // -> show 'x pending requests at the top'
                    : 1),
        itemBuilder: (_, index) {
          if (confirmedFriends.isNotEmpty) {
            if (friendRequests.isNotEmpty && index == 0) {
              String s = friendRequests.length == 1 ? '' : 's';
              return ListTile(
                  trailing: Icon(Icons.chevron_right_rounded),
                  title: Text(
                      '${friendRequests.length.toNumberWord().capitalize()} pending friend request$s'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          FriendRequestsScreen(widget.onBattleRequest),
                    ));
                  });
            } else {
              if (friendRequests.isNotEmpty) index -= 1;
              bool isLast = index != confirmedFriends.length - 1;
              return FriendsListTile(
                  confirmedFriends[index], widget.onBattleRequest, isLast);
            }
          } else if (friendRequests.isNotEmpty) {
            if (index == 0) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Friend Requests',
                      style: TextStyle(
                        fontFamily: "RobotoSlab",
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        // constraints: BoxConstraints.expand(
                        height: 2,
                        // ),
                        color: Color.lerp(
                            Colors.purple[100], Colors.grey[200], 0.5),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              bool isLast = index - 1 != friendRequests.length - 1;
              return FriendsListTile(
                  friendRequests[index - 1], widget.onBattleRequest, isLast);
            }
          } else {
            return Container(
              height: MediaQuery.of(context).size.height -
                  FiarBottomSheet.HEIGHT -
                  92,
              alignment: Alignment.center,
              child: Text("No friends yet. Add some to get started!"),
            );
          }
        },
        padding: EdgeInsets.only(bottom: 164),
      ),
    );
  }
}

class FriendRequestsScreen extends StatelessWidget {
  final void Function(String) battleRequest;

  const FriendRequestsScreen(this.battleRequest, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FiarAppBar(
        title: "Friend Requests",
        threeDots: [
          FiarThreeDotItem(
            'Feedback',
            onTap: () {
              showFeedbackDialog(context);
            },
          ),
        ],
      ),
      body: Container(
        child: Consumer<UserInfo>(
          builder: (_, userInfo, __) {
            List<PublicUser> friendRequests = userInfo.user?.friends
                    .where((f) =>
                        f.friendState == FriendState.HasRequestedMe ||
                        f.friendState == FriendState.IsRequestedByMe)
                    .toList() ??
                [];
            return !userInfo.loggedIn
                ? Container(
                    height: 128,
                    child: Text(
                        'Something went wrong. Please restart the app or log out.'))
                : ListView(
                    children: friendRequests
                        .asMap()
                        .map<int, Widget?>((i, friend) {
                          bool isLast = i == friendRequests.length - 1;

                          return MapEntry(
                            i,
                            FriendsListTile(friend, battleRequest, isLast),
                          );
                        })
                        .values
                        .toList()
                        .filterNotNull());
          },
        ),
      ),
    );
  }
}

class MoreButton extends StatelessWidget {
  const MoreButton({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: () => onTap,
      color: Colors.purple[200],
      shape: StadiumBorder(),
      child: Text(label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
            fontWeight: FontWeight.bold,
          )),
    );
    // GestureDetector(
    //   child: Container(
    //     // width: 96,
    //     // height: 48,
    //     padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    //     decoration: BoxDecoration(
    //       color: Colors.blue[500],
    //       borderRadius: BorderRadius.all(Radius.circular(100)),
    //       boxShadow: [
    //         BoxShadow(
    //           color: Colors.black26,
    //           blurRadius: 3,
    //           offset: Offset(0, 2),
    //         )
    //       ],
    //     ),
    //   ),

    //   // Icon(Icons.backspace),
    // );
  }
}

class FriendsListTile extends StatelessWidget {
  final PublicUser friend;
  final void Function(String) battleRequest;
  final bool isLast;

  FriendsListTile(this.friend, this.battleRequest, this.isLast, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isFriendRequest = friend.friendState == FriendState.IsRequestedByMe ||
        friend.friendState == FriendState.HasRequestedMe;
    var tile = Material(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 24, 16),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              isFriendRequest
                  // ?
                  ? Container(
                      alignment: Alignment.center,
                      child: friend.friendState.icon(color: Colors.grey[500]),
                    )
                  : null,
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  SizedBox(height: 4),
                  Text(
                    isFriendRequest
                        ? friend.friendState == FriendState.HasRequestedMe
                            ? "Waiting for your response"
                            : "Awaiting response"
                        : "SR: ${friend.gameInfo.skillRating}",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2!
                        .copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
              Expanded(child: SizedBox()),
              isFriendRequest
                  ?
                  // TextButton(
                  //     child: Row(
                  //       children: [
                  //         Text(friend.friendState == FriendState.HasRequestedMe
                  //             ? 'Accept'
                  //             : 'Delete'),
                  IconButton(
                      tooltip: friend.friendState == FriendState.HasRequestedMe
                          ? 'Accept'
                          : 'Delete',
                      icon: Icon(
                        friend.friendState == FriendState.HasRequestedMe
                            ? Icons.check
                            : Icons.clear,
                        color: Colors.grey[600],
                        //   ),
                        // ],
                      ),
                      onPressed: () {
                        var userInfo = context.read<UserInfo>();
                        friend.friendState == FriendState.HasRequestedMe
                            ? userInfo.addFriend(friend.id)
                            : userInfo.removeFriend(friend.id);
                      },
                    )
                  : friend.isPlaying
                      ? Transform.scale(
                          alignment: Alignment.center,
                          scale: 0.75,
                          child: IconButton(
                            icon: Opacity(
                              opacity: 0.54,
                              child: Image.asset(
                                "assets/img/swords.png",
                                color: Colors.black.withOpacity(0.8),
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),
                            onPressed: () => battleRequest(friend.id),
                          ),
                        )
                      : SizedBox(),
            ].filterNotNull()),
      ),
    );
    if (isLast) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // ListTile(
          //     // leading: Icon(Icons.mail_outline),
          //     title: Text('Tite'),
          //     subtitle: Text('stirne'),
          //     trailing: IconButton(
          //       icon: Icon(Icons.clear),
          //       onPressed: () {},
          //     )),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: tile,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            constraints: BoxConstraints.expand(height: 2),
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      );
    } else {
      return tile;
    }
  }
}

class BattleRequestDialog extends StatefulWidget {
  static const TIMEOUT = BattleRequestPopup.DURATION;

  final String? showBattleRequest;
  final VoidCallback hide;

  BattleRequestDialog(
    this.showBattleRequest, {
    required this.hide,
  });

  @override
  _BattleRequestDialogState createState() => _BattleRequestDialogState();
}

class _BattleRequestDialogState extends State<BattleRequestDialog> {
  double timerVal = 1;
  late Ticker ticker;

  @override
  initState() {
    super.initState();

    ticker = Ticker((time) => setState(() {
          timerVal =
              time.inMilliseconds / BattleRequestDialog.TIMEOUT.inMilliseconds;
        }));
    ticker.start();
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBattleRequest != null &&
        oldWidget.showBattleRequest == null) {
      ticker.stop();
      ticker = Ticker((time) {
        setState(() => timerVal =
            time.inMilliseconds / BattleRequestDialog.TIMEOUT.inMilliseconds);
        if (timerVal >= 1) {
          timerVal = 1;
          ticker.stop();
          if (mounted && widget.showBattleRequest != null) {
            widget.hide();
          }
        }
      });
      ticker.start();
    }
  }

  @override
  dispose() {
    ticker.stop();
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayDialog(
      widget.showBattleRequest != null,
      hide: widget.hide,
      child: Container(
        height: 130,
        width: min(450, MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black12,
            )
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Battle Request',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoSlab',
              ),
            ),
            SizedBox(height: 6),
            Text('Waiting for friend to accept...'),
            SizedBox(height: 24),
            LinearProgressIndicator(value: 1 - timerVal),
          ],
        ),
      ),
    );
  }
}

class AddFriendDialog extends StatefulWidget {
  static const int MIN_SEARCH_LEN = 3;

  AddFriendDialog({
    Key? key,
    // @required this.searchResults,
    required this.visible,
    required this.myId,
    required this.userInfo,
    required this.hide,
    // @required this.searching,
    // @required this.addingFriend,
    // @required this.searchText,
    // @required this.widget,
  }) : super(key: key);

  final bool visible;
  final String myId;
  final UserInfo userInfo;
  final FocusNode searchbarFocusNode = FocusNode();
  final VoidCallback hide;

  @override
  _AddFriendDialogState createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  List<PublicUser>? searchResults;
  bool searching = false;
  int? addingFriend;
  String searchText = "";
  List<int> successfullyAdded = new List.empty();

  void setSearchText(String text) {
    this.searchText = text;
  }

  void search() async {
    if (searchText.length < AddFriendDialog.MIN_SEARCH_LEN) {
      return;
    }

    setState(() {
      searching = true;
    });
    if (searchText == "####") {
      searchText = "";
    }

    String url = "${constants.HTTP_URL}/api/users?search=$searchText";
    late final response;
    try {
      response = await http.get(url).timeout(Duration(milliseconds: 4000));
    } on Exception {
      return;
    }

    if (response.statusCode == 200) {
      Map<int, PublicUser> temp = (jsonDecode(response.body) as List<dynamic>)
          .asMap()
          .map<int, PublicUser?>((i, dyn) {
        PublicUser? user = PublicUser.fromMap(dyn as Map<String, dynamic>);
        if (user == null) return MapEntry(i, null);
        return MapEntry(i, user);
      }).filterNotNull();
      searchResults = temp.values.toList();

      searchResults!.removeWhere((publicUser) => publicUser.id == widget.myId);

      await setFriendStates();
    }
    setState(() {
      searching = false;
    });
  }

  Future<void> setFriendStates() async {
    await widget.userInfo.refresh();
    searchResults!.forEach((publicUser) {
      for (var friend in widget.userInfo.user?.friends ?? <PublicUser>[]) {
        if (friend.id == publicUser.id) {
          publicUser.friendState = friend.friendState;
        }
      }
    });
    setState(() {});
  }

  void addFriend(String id, int index) async {
    setState(() => addingFriend = index);

    await widget.userInfo.addFriend(id);

    await setFriendStates();

    addingFriend = null;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(AddFriendDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    searching = false;
    // widget.searchbarFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);

    return OverlayDialog(
      widget.visible,
      hide: () {
        widget.searchbarFocusNode.unfocus();
        widget.hide();
      },
      child: Container(
        height: 170.0 +
            (searchResults == null
                ? 0
                : (mediaQuery.viewInsets.bottom > 20 ? double.infinity : 350)),
        margin: EdgeInsets.symmetric(vertical: 20),
        width: max(200, min(450, mediaQuery.size.width * 0.85)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              color: Colors.black12,
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Add friend',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () => widget.searchbarFocusNode.requestFocus(),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    color: Colors.grey[100],
                  ),
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(18, 8, 8, 8),
                      child: Row(
                        children: <Widget>[
                          buildSearchfield(),
                          buildSearchbutton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              searchResults != null
                  ? buildSearchresults(searchResults!)
                  : SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  IconButton buildSearchbutton() {
    return IconButton(
      iconSize: 24,
      splashColor: Colors.purple[300]!.withOpacity(0.5),
      highlightColor: Colors.purple[200]!.withOpacity(0.5),
      icon: searching ? CircularProgressIndicator() : Icon(Icons.search),
      onPressed: search,
    );
  }

  Expanded buildSearchfield() {
    return Expanded(
      child: TextField(
        autofocus: true,
        onChanged: setSearchText,
        onSubmitted: (_) => search(),
        focusNode: widget.searchbarFocusNode,
        decoration: InputDecoration(
          hintText: 'Search for users',
          border: InputBorder.none,
          counterText: null,
          counter: null,
          counterStyle: null,
        ),
      ),
    );
  }

  Widget buildSearchresults(List<PublicUser> searchResults) {
    return Expanded(
      child: searchResults.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: Text("No users found for \"$searchText\"",
                      style: TextStyle(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                      ))),
            )
          : Scrollbar(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (_, index) {
                  PublicUser? publicUser = searchResults[index];
                  return FriendSearchResult(
                      publicUser, addingFriend, index, addFriend);
                },
                padding: EdgeInsets.zero,
                shrinkWrap: true,
              ),
            ),
    );
  }
}

class FriendSearchResult extends StatelessWidget {
  const FriendSearchResult(
      this.publicUser, this.addingFriend, this.index, this.addFriend,
      {Key? key})
      : super(key: key);

  final int? addingFriend;
  final PublicUser publicUser;
  final int index;
  final void Function(String, int) addFriend;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(publicUser.name),
      subtitle: Text("SR: ${publicUser.gameInfo.skillRating}"),
      trailing: IconButton(
        splashColor: Colors.red[700]!.withOpacity(0.5),
        highlightColor: Colors.red[700]!.withOpacity(0.5),
        icon: addingFriend == index
            ? CircularProgressIndicator()
            : publicUser.friendState.icon(),
        onPressed: publicUser.friendState == FriendState.None ||
                publicUser.friendState == FriendState.HasRequestedMe
            ? () => addFriend(publicUser.id, index)
            : () {},
      ),
    );
  }
}

// class SearchResults extends StatelessWidget {
//   const SearchResults(
//     this.searchResults,
//     this.addingFriend, {
//     Key key,
//     @required this.searchTerm,
//     @required this.friends,
//     @required this.addFriend,
//   }) : super(key: key);

//   final String searchTerm;
//   final Map<int, PublicUser> searchResults;
//   final List<PublicUser> friends;
//   final int addingFriend;
//   final void Function(String, int) addFriend;

//   @override
//   Widget build(BuildContext context) {

//   }
// }
