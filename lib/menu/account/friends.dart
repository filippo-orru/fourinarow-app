import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart' hide BottomSheet;
import 'package:flutter/scheduler.dart';
import 'package:four_in_a_row/menu/play_selection/all.dart';
import 'package:four_in_a_row/menu/settings.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';

import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:four_in_a_row/util/constants.dart' as constants;
import 'package:four_in_a_row/util/extensions.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:four_in_a_row/menu/common/overlay_dialog.dart';
import 'package:four_in_a_row/util/global_common_widgets.dart';

import 'onboarding/onboarding.dart';

import 'package:provider/provider.dart';

class FriendsList extends StatefulWidget {
  @override
  _FriendsListState createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> with SingleTickerProviderStateMixin {
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
    expandMore = AnimationController(vsync: this, duration: Duration(milliseconds: 130));
    offsetTween = Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(expandMore);
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
                        backgroundColor:
                            context.watch<ThemesProvider>().selectedTheme.friendsThemeColor[300],
                        child: Icon(Icons.add),
                        onPressed: () => setState(() => showAddFriend = true),
                      ),
                    ),
                    FiarBottomSheet(
                      color: context.watch<ThemesProvider>().selectedTheme.friendsThemeColor,
                      expandedHeight: 218,
                      topChildren: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: userInfo.user!.username),
                              TextSpan(
                                  text: "   •   ",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                  )),
                              TextSpan(
                                text: "${userInfo.user!.gameInfo.skillRating} SR",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                            style: TextStyle(
                              fontFamily: 'RobotoSlab',
                              color: Colors.grey[900],
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: shareInviteFriends,
                            leading: Icon(Icons.share_rounded),
                            title: Text('Invite friends'),
                            contentPadding: EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              Navigator.of(context).push(slideUpRoute(SettingsScreen()));
                            },
                            leading: Icon(Icons.settings),
                            title: Text('Settings'),
                            trailing: Icon(Icons.chevron_right_rounded),
                            contentPadding: EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ),
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              userInfo.logOut();
                              Navigator.of(context)
                                  .pushReplacement(slideUpRoute(AccountOnboarding()));
                            },
                            leading: Icon(Icons.exit_to_app),
                            title: Text('Log out'),
                            contentPadding: EdgeInsets.symmetric(horizontal: 24),
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: context.watch<ThemesProvider>().selectedTheme.friendsThemeColor.shade200,
            ),
            onPressed: () {
              userInfo.logOut();
              Navigator.of(context).pop();
            },
            child: Text('Log out'),
          )
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
  final GlobalKey<RefreshIndicatorState> refreshKey = GlobalKey<RefreshIndicatorState>();

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

    List<PublicUser> onlineFriends = confirmedFriends.where((f) => f.isPlaying).toList();
    List<PublicUser> offlineFriends = confirmedFriends.where((f) => !f.isPlaying).toList();
    int headingsCount = onlineFriends.isNotEmpty
        ? offlineFriends.isNotEmpty
            ? 2 // both headings
            : 1 // only online heading
        : 1; // only offline heading

    return RefreshIndicator(
      onRefresh: () => widget.userInfo.refresh().then((_) => setState(() {})),
      key: widget.refreshKey,
      child: ListView.builder(
        itemCount: confirmedFriends.isEmpty
            ? friendRequests.isEmpty
                ? 1 // -> show 'no friends'
                : 1 + friendRequests.length // show friend requests with title
            : confirmedFriends.length +
                headingsCount +
                (friendRequests.isEmpty ? 0 : 1 // 'x pending requests at the top'
                ),
        itemBuilder: (_, index) {
          if (confirmedFriends.isNotEmpty) {
            if (friendRequests.isNotEmpty && index == 0) {
              String s = friendRequests.length == 1 ? '' : 's';
              return ListTile(
                  trailing: Icon(Icons.chevron_right_rounded, color: Colors.black54),
                  title: Text(
                    '${friendRequests.length.toNumberWord().capitalize()} pending friend request$s',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      // fontStyle: FontStyle.italic,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (BuildContext context) =>
                          FriendRequestsScreen(widget.onBattleRequest),
                    ));
                  });
            } else {
              if (friendRequests.isNotEmpty) index -= 1;

              if (index == 0 && onlineFriends.isNotEmpty) {
                // return FriendListHeading(title: 'Offline');
                return FriendListHeading(title: 'Online');
              }

              if (offlineFriends.isNotEmpty) {
                if ((onlineFriends.isNotEmpty && index - 1 == onlineFriends.length) ||
                    (onlineFriends.isEmpty && index == 0)) {
                  return FriendListHeading(title: 'Offline');
                }
              }

              if (onlineFriends.isNotEmpty && index - 1 < onlineFriends.length) {
                index -= onlineFriends.isNotEmpty ? 1 : 0;
                bool isLast = index != onlineFriends.length - 1;
                return FriendsListTile(onlineFriends[index], widget.onBattleRequest, isLast);
              } else {
                index -= onlineFriends.length + headingsCount;

                bool isLast = index != offlineFriends.length - 1;
                return FriendsListTile(offlineFriends[index], widget.onBattleRequest, isLast);
              }
            }
          } else if (friendRequests.isNotEmpty) {
            if (index == 0) {
              return FriendListHeading(title: 'Friend Requests');
            } else {
              bool isLast = index - 1 != friendRequests.length - 1;
              return FriendsListTile(friendRequests[index - 1], widget.onBattleRequest, isLast);
            }
          } else {
            return Container(
              height: MediaQuery.of(context).size.height - FiarBottomSheet.HEIGHT - 92,
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

class FriendListHeading extends StatelessWidget {
  final String title;

  const FriendListHeading({
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 12, left: 8, right: 12),
      child: Row(
        children: [
          Container(height: 2, width: 12, color: Colors.grey.shade300),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 6),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: "RobotoSlab",
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: Colors.grey.shade300,
            ),
          ),
        ],
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
                    child: Text('Something went wrong. Please restart the app or log out.'))
                : ListView(
                    children: friendRequests.isEmpty
                        ? [
                            Container(
                              height: MediaQuery.of(context).size.height - FiarBottomSheet.HEIGHT,
                              alignment: Alignment.center,
                              child: Text("No friend requests at the moment",
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                  )),
                            ),
                          ]
                        : friendRequests
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: context.watch<ThemesProvider>().selectedTheme.friendsThemeColor[200],
        shape: StadiumBorder(),
      ),
      onPressed: () => onTap,
      child: Text(label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
            fontWeight: FontWeight.bold,
          )),
    );
  }
}

class FriendsListTile extends StatefulWidget {
  final PublicUser friend;
  final void Function(String) battleRequest;
  final bool isLast;

  FriendsListTile(this.friend, this.battleRequest, this.isLast, {Key? key}) : super(key: key);

  @override
  _FriendsListTileState createState() => _FriendsListTileState();
}

class _FriendsListTileState extends State<FriendsListTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    bool isFriendRequest = widget.friend.friendState == FriendState.IsRequestedByMe ||
        widget.friend.friendState == FriendState.HasRequestedMe;
    var tile = Material(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: isFriendRequest
                      ? widget.friend.friendState.icon(color: Colors.grey[500])
                      : PlayerIcon(widget.friend),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.friend.username,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                        // softWrap: true,
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      SizedBox(height: 4),
                      Text(
                        isFriendRequest
                            ? widget.friend.friendState == FriendState.HasRequestedMe
                                ? "Waiting for your response"
                                : "Awaiting response"
                            : "${widget.friend.gameInfo.skillRating} SR",
                        style: Theme.of(context)
                            .textTheme
                            .bodyText2!
                            .copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                isFriendRequest
                    ? IconButton(
                        tooltip: widget.friend.friendState == FriendState.HasRequestedMe
                            ? 'Accept'
                            : 'Delete',
                        icon: Icon(
                          widget.friend.friendState == FriendState.HasRequestedMe
                              ? Icons.check
                              : Icons.clear,
                          color: Colors.grey[600],
                          //   ),
                          // ],
                        ),
                        onPressed: () {
                          var userInfo = context.read<UserInfo>();
                          widget.friend.friendState == FriendState.HasRequestedMe
                              ? userInfo.addFriend(widget.friend.id)
                              : userInfo.removeFriend(widget.friend.id);
                        },
                      )
                    : widget.friend.isPlaying
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
                              onPressed: () => widget.battleRequest(widget.friend.id),
                            ),
                          )
                        : null,
                isFriendRequest
                    ? null
                    : TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: _expanded ? 1 : 0),
                        duration: Duration(milliseconds: 120),
                        builder: (_, val, child) =>
                            Transform.rotate(angle: pi * (val as double), child: child),
                        child: IconButton(
                          onPressed: () {
                            setState(() => _expanded = !_expanded);
                          },
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
              ].filterNotNull(),
            ),
            SizedBox(height: _expanded ? 8 : 0),
            isFriendRequest
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _expanded
                        ? [
                            IconButton(
                              icon: Icon(Icons.cancel_outlined, color: Colors.grey.shade600),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => SimpleDialog(
                                    title: Text(
                                      "Remove Friend",
                                      style: TextStyle(
                                        fontFamily: 'RobotoSlab',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.all(16),
                                    children: [
                                      Text(
                                          'Do you really want to remove \"${widget.friend.username}\"?'),
                                      SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              primary: Colors.black87,
                                            ),
                                            child: Text('Cancel'),
                                            onPressed: () => Navigator.of(ctx).pop(),
                                          ),
                                          SizedBox(width: 16),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              primary: Colors.red,
                                            ),
                                            onPressed: () {
                                              context
                                                  .read<UserInfo>()
                                                  .removeFriend(widget.friend.id);
                                              Navigator.of(ctx).pop();
                                            },
                                            child: Text('Remove'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            SizedBox(width: 12),
                            IconButton(
                              icon: Icon(Icons.chat_outlined, color: Colors.grey.shade600),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => FiarSimpleDialog(
                                    title: "Chat",
                                    content: 'Chatting with friends is coming soon! Stay tuned 😊',
                                  ),
                                );
                              },
                            ),
                          ]
                        : [],
                    //   ),
                  ),
          ].filterNotNull(),
        ),
      ),
    );
    if (widget.isLast) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: tile,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            constraints: BoxConstraints.expand(height: 2),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      );
    } else {
      return tile;
    }
  }
}

class BattleRequestDialog extends StatefulWidget {
  static const TIMEOUT = Duration(seconds: 20);

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
          timerVal = time.inMilliseconds / BattleRequestDialog.TIMEOUT.inMilliseconds;
        }));
    ticker.start();
  }

  @override
  didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBattleRequest != null && oldWidget.showBattleRequest == null) {
      ticker.stop();
      ticker = Ticker((time) {
        setState(() => timerVal = time.inMilliseconds / BattleRequestDialog.TIMEOUT.inMilliseconds);
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
  String? errorMessage;

  void setSearchText(String text) {
    this.searchText = text;
  }

  void search() async {
    if (searchText.length < AddFriendDialog.MIN_SEARCH_LEN) {
      setState(() => errorMessage = "Enter at least ${AddFriendDialog.MIN_SEARCH_LEN} characters.");
      return;
    }

    setState(() {
      searching = true;
    });
    if (searchText == "####") {
      searchText = "";
    }

    Uri url = Uri.parse("${constants.HTTP_URL}/api/users?search=$searchText");
    late final response;
    try {
      response = await http.get(url).timeout(Duration(milliseconds: 4000));
    } on Exception {
      return;
    }

    if (response.statusCode == 200) {
      Map<int, PublicUser> temp =
          (jsonDecode(response.body) as List<dynamic>).asMap().map<int, PublicUser?>((i, dyn) {
        PublicUser? user =
            PublicUser.fromMapPublic(widget.userInfo.user, dyn as Map<String, dynamic>);
        if (user == null) return MapEntry(i, null);
        return MapEntry(i, user);
      }).filterNotNull();
      searchResults = temp.values.toList();

      searchResults!.removeWhere((publicUser) => publicUser.id == widget.myId);

      setState(() => errorMessage = null);
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
          return;
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
    if (oldWidget.visible == false && widget.visible == true) {
      // just shown
      searchText = "";
      searching = false;
      addingFriend = -1;
      searchResults = null;
    }
    // widget.searchbarFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);

    return Stack(
      children: [
        OverlayDialog(
          widget.visible,
          hide: () {
            widget.searchbarFocusNode.unfocus();
            widget.hide();
          },
          child: Container(
            // constraints: BoxConstraints(
            //   minHeight: 100, maxHeight: 400),
            //  232.0 +
            //     (searchResults == null
            //         ? 0
            //         : (mediaQuery.viewInsets.bottom > 20
            //             ? double.infinity
            //             : 350)),
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
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Consumer<ThemesProvider>(
                  builder: (_, themeProvider, child) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Add friend',
                              style: TextStyle(
                                fontFamily: 'RobotoSlab',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Consumer<ThemesProvider>(
                            builder: (_, themeProvider, child) => IconButton(
                              icon: Icon(
                                Icons.close,
                                color: themeProvider.selectedTheme.friendsThemeColor.shade200,
                              ),
                              splashColor:
                                  themeProvider.selectedTheme.friendsThemeColor.withOpacity(0.2),
                              hoverColor: Colors.transparent,
                              highlightColor: themeProvider.selectedTheme.friendsThemeColor.shade100
                                  .withOpacity(0.2),
                              onPressed: () => widget.hide(),
                            ),
                          ),
                        ],
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
                                  Expanded(
                                    child: TextField(
                                      autofocus: true,
                                      onChanged: setSearchText,
                                      onSubmitted: (_) => search(),
                                      focusNode: widget.searchbarFocusNode,
                                      decoration: InputDecoration(
                                        errorText: errorMessage,
                                        hintText: 'Search for users',
                                        border: InputBorder.none,
                                        counterText: null,
                                        counter: null,
                                        counterStyle: null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    iconSize: 24,
                                    splashColor: themeProvider.selectedTheme.friendsThemeColor[300]!
                                        .withOpacity(0.5),
                                    highlightColor: themeProvider
                                        .selectedTheme.friendsThemeColor[200]!
                                        .withOpacity(0.5),
                                    icon: searching
                                        ? CircularProgressIndicator()
                                        : Icon(Icons.search),
                                    onPressed: search,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      searchResults != null ? buildSearchresults(searchResults!) : SizedBox(),
                      Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                              primary: themeProvider.selectedTheme.friendsThemeColor.shade300),
                          onPressed: shareInviteFriends,
                          icon: Icon(Icons.share_rounded),
                          label: Text('Invite friends'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSearchresults(List<PublicUser> searchResults) {
    return
        // Expanded(
        //   child:
        searchResults.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: Text("No users found for \"$searchText\"",
                        style: TextStyle(
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ))),
              )
            : Flexible(
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (_, index) {
                      PublicUser? publicUser = searchResults[index];
                      return FriendSearchResult(publicUser, addingFriend, index, addFriend);
                    },
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                  ),
                  // ),
                ),
              );
  }
}

void shareInviteFriends() {
  Share.share(
    "Wanna play a round of Four in a Row with me?\n" +
        "Google Play: https://play.google.com/store/apps/details?id=ml.fourinarow\n" +
        "Web: https://play.fourinarow.ffactory.me/",
  );
}

class FriendSearchResult extends StatelessWidget {
  const FriendSearchResult(this.publicUser, this.addingFriend, this.index, this.addFriend,
      {Key? key})
      : super(key: key);

  final int? addingFriend;
  final PublicUser publicUser;
  final int index;
  final void Function(String, int) addFriend;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(publicUser.username),
      subtitle: Text("${publicUser.gameInfo.skillRating} SR"),
      trailing: Consumer<ThemesProvider>(
        builder: (_, themeProvider, child) => IconButton(
          splashColor: themeProvider.selectedTheme.friendsThemeColor.shade500.withOpacity(0.2),
          highlightColor: themeProvider.selectedTheme.friendsThemeColor.shade300.withOpacity(0.2),
          icon: addingFriend == index ? CircularProgressIndicator() : publicUser.friendState.icon(),
          onPressed: publicUser.friendState == FriendState.None ||
                  publicUser.friendState == FriendState.HasRequestedMe
              ? () => addFriend(publicUser.id, index)
              : null,
        ),
      ),
    );
  }
}
