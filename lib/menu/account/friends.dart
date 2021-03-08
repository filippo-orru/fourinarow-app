import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide BottomSheet;
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:four_in_a_row/util/battle_req_popup.dart';
import 'package:four_in_a_row/util/constants.dart' as constants;
import 'package:four_in_a_row/inherit/user.dart';
import 'package:four_in_a_row/menu/common/overlay_dialog.dart';
import 'package:four_in_a_row/util/extensions.dart';
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
    // Navigator.of(context).push(slideUpRoute());
    setState(() => showBattleRequest = id);
    bool? opponentJoined = await gsm
        .startGame(ORqBattle(id))
        .toNullable()
        .timeout(BattleRequestDialog.TIMEOUT, onTimeout: () => null);

    // if (msg == null) {
    //   hideBattleRequestDialog();
    // } else
    if (opponentJoined == true) {
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
        appBar: CustomAppBar(
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
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              print('object');
                            },
                            // leading: Icon(Icons.sentiment_satisfied),
                            title: Text(userInfo.username!),
                            subtitle: Text('Change username (soon)'),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              print('object');
                            },
                            title: Text(
                                userInfo.user?.email ?? "Set email (soon)"),
                            subtitle: Text(userInfo.user?.email == null
                                ? 'You haven\'t set an email yet'
                                : 'Change email (soon)'),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ),
                        Divider(
                          indent: 12,
                          endIndent: 12,
                        ),
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
                              print('object');
                            },
                            leading: Icon(Icons.delete_forever),
                            title: Text('Delete Account (soon)'),
                            // subtitle: Text('Change email'),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ),
                        ListTile(
                          title: Text('Credits'),
                          subtitle:
                              Text('Sword icon made by Freepik @ flaticon.com'),
                          contentPadding: EdgeInsets.symmetric(horizontal: 24),
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
    return RefreshIndicator(
      onRefresh: () => widget.userInfo.refresh().then((_) => setState(() {})),
      key: widget.refreshKey,
      child: ListView.builder(
        itemCount: (widget.userInfo.user?.friends.length ?? 0) + 1,
        itemBuilder: (_, index) {
          if (widget.userInfo.user?.friends.isEmpty == true) {
            return Container(
              height: MediaQuery.of(context).size.height -
                  FiarBottomSheet.HEIGHT -
                  92,
              alignment: Alignment.center,
              child: Text("No friends yet. Add some to get started!"),
            );
          } else {
            bool isLast = index != widget.userInfo.user!.friends.length - 1;
            return FriendsListTile(widget.userInfo.user!.friends[index],
                widget.onBattleRequest, isLast);
          }
        },
        padding: EdgeInsets.only(bottom: 164),
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
    var tile = ListTile(
      enabled: true,
      title: Text(
        friend.name,
        style: TextStyle(fontSize: 17),
      ),
      subtitle: Text("SR: ${friend.gameInfo.skillRating}"),
      contentPadding: EdgeInsets.fromLTRB(16, 0, 24, 0),
      trailing: friend.isPlaying
          ? Transform.scale(
              alignment: Alignment.center,
              scale: 0.75,
              child: IconButton(
                icon: Opacity(
                  opacity: 0.54,
                  child: Image.asset(
                    "assets/img/swords.png",
                    color: Colors.black,
                    colorBlendMode: BlendMode.src,
                  ),
                ),
                onPressed: () => battleRequest(friend.id),
              ),
            )
          : SizedBox(),
    );
    if (isLast) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
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

      searchResults!.forEach((publicUser) {
        if (widget.userInfo.user?.friends.any((f) => f.id == publicUser.id) ==
            true) {
          publicUser.friendState = FriendState.IsFriend;
        } else {
          FriendRequest? fr = widget.userInfo.user?.friendRequests
              .map<FriendRequest?>((x) => x)
              .singleWhere((f) => f?.other.id == publicUser.id,
                  orElse: () => null);
          if (fr != null) {
            publicUser.friendState =
                fr.direction == FriendRequestDirection.Incoming
                    ? FriendState.HasRequestedMe
                    : FriendState.IsRequestedByMe;
          }
        }
      });
    }
    setState(() {
      searching = false;
    });
  }

  void addFriend(String id, int index) async {
    setState(() => addingFriend = index);
    // if (
    await widget.userInfo.addFriend(id);

    //ree
    searchResults!.forEach((publicUser) {
      if (widget.userInfo.user?.friends.any((f) => f.id == publicUser.id) ==
          true) {
        publicUser.friendState = FriendState.IsFriend;
      } else {
        FriendRequest? fr = widget.userInfo.user?.friendRequests
            .map<FriendRequest?>((x) => x)
            .singleWhere((f) => f?.other.id == publicUser.id,
                orElse: () => null);
        if (fr != null) {
          publicUser.friendState =
              fr.direction == FriendRequestDirection.Incoming
                  ? FriendState.HasRequestedMe
                  : FriendState.IsRequestedByMe;
        }
      }
    });
    //end:ree

    searchResults?.forEach((publicUser) {
      if (widget.userInfo.user?.friends.any((f) => f.id == publicUser.id) ==
          true) {
        publicUser.friendState =
            publicUser.friendState == FriendState.IsRequestedByMe ||
                    publicUser.friendState == FriendState.HasRequestedMe
                ? FriendState.IsFriend
                : FriendState.IsRequestedByMe;
      }
    });

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
