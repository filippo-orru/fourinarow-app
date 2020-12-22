import 'dart:convert';
import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:four_in_a_row/connection/messages.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:four_in_a_row/util/battle_req_popup.dart';
import 'package:http/http.dart' as http;
import 'package:four_in_a_row/util/constants.dart' as constants;
import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/user.dart';
import '../common/overlay_dialog.dart';
import 'package:four_in_a_row/util/extensions.dart';

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

  // @override
  // didUpdateWidget(Widget oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   context
  //       .read<UserInfo>()
  //       .refresh(shouldSetState: false)
  //       .then((_) => setState(() {}));
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserInfo>(
      builder: (_, userInfo, __) => Scaffold(
        appBar: CustomAppBar(
          title: 'Friends',
          refreshing: userInfo.refreshing,
        ),
        resizeToAvoidBottomInset: false,
        body: userInfo.loggedIn
            ? Container(
                child: Stack(
                  fit: StackFit.loose,
                  children: [
                    Expanded(
                        child: _FriendsListInner(
                      userInfo: userInfo,
                      onBattleRequest: battleRequest,
                    )),
                    Positioned(
                      right: 24,
                      bottom: BottomSheet.HEIGHT,
                      child: FloatingActionButton(
                        backgroundColor: Colors.purple[300],
                        child: Icon(Icons.add),
                        onPressed: () => setState(() => showAddFriend = true),
                      ),
                    ),
                    BottomSheet(userInfo),
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
    var elements = widget.userInfo.user?.friends
        .asMap()
        .map((i, PublicUser f) {
          var tile = FriendListDisplay(f, widget.onBattleRequest);
          if (i != widget.userInfo.user!.friends.length - 1) {
            return MapEntry(
              i,
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  tile,
                  Container(
                    // indent: 12,
                    // endIndent: 12,
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    constraints: BoxConstraints.expand(height: 2),
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
            );
          } else {
            return MapEntry(i, tile);
          }
        })
        .values
        .toList();
    return RefreshIndicator(
      onRefresh: () => widget.userInfo.refresh().then((_) => setState(() {})),
      // () {
      // refreshKey.currentState?.show(atTop: false);
      //   return userInfo.refresh();
      // },
      key: widget.refreshKey,
      child: ListView(
        padding: EdgeInsets.only(bottom: 0), // BottomSheet.HEIGHT + 128
        children: elements == null || elements.isEmpty
            ? [
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top: 24),
                  child: Text("No friends yet. Add some to get started!"),
                )
              ]
            : elements + [SizedBox(height: 192)],
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

class BottomSheet extends StatefulWidget {
  static const double HEIGHT = _CONT_HEIGHT + _MARGIN;
  static const double _CONT_HEIGHT = 78;
  static const double _MARGIN = 24;

  final UserInfo userInfo;

  const BottomSheet(
    this.userInfo, {
    Key? key,
  }) : super(key: key);

  @override
  _BottomSheetState createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheet>
    with SingleTickerProviderStateMixin {
  static const double HEIGHT = 400;

  late AnimationController animCtrl;
  late Animation<double> moveUpAnim;
  late Animation<double> rotateAnim;
  late Animation<double> opacityAnim;
  bool expanded = false;

  Future<void> show() async {
    await Future.delayed(Duration(milliseconds: 30));

    setState(() => expanded = true);
    await animCtrl.forward();
  }

  Future<void> hide() async {
    await animCtrl.reverse();
    setState(() => expanded = false);
  }

  @override
  void initState() {
    super.initState();

    animCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 260));

    moveUpAnim = Tween<double>(begin: 0, end: HEIGHT)
        .chain(CurveTween(curve: Curves.easeInOutQuart))
        .animate(animCtrl);

    rotateAnim = Tween<double>(begin: 0, end: 0.5)
        .chain(CurveTween(curve: Curves.easeInOutQuart))
        .animate(animCtrl);

    opacityAnim = Tween<double>(begin: 0, end: 0.3)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(animCtrl);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));

    return WillPopScope(
      onWillPop: () async {
        if (expanded) {
          await hide();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        top: 0,
        // width: double.infinity,
        child: Stack(
          fit: StackFit.loose,
          alignment: Alignment.bottomCenter,
          children: [
            expanded
                ? GestureDetector(
                    behavior: expanded
                        ? HitTestBehavior.opaque
                        : HitTestBehavior.translucent,
                    onTap: () {
                      if (expanded) hide();
                    },
                    child: AnimatedBuilder(
                      animation: animCtrl,
                      builder: (ctx, child) => Container(
                        constraints: BoxConstraints.expand(),
                        color: Colors.black.withOpacity(opacityAnim.value),
                      ),
                    ),
                  )
                : SizedBox(),
            AnimatedBuilder(
              animation: animCtrl,
              builder: (ctx, child) => SizedOverflowBox(
                alignment: Alignment.topCenter,
                size: Size(double.infinity,
                    BottomSheet._CONT_HEIGHT + moveUpAnim.value),
                child: child,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height,
                // height: HEIGHT,
                // padding: EdgeInsets.only(top: 12),
                // height: double.infinity,
                // constraints: BoxConstraints.expand(),
                // color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.all(6),
                      // margin: EdgeInsets.only(left: 6, top: 6, right: 6, bottom: 6),
                      // padding: EdgeInsets.only(top: 5),
                      height: BottomSheet._CONT_HEIGHT - 12,
                      // constraints:
                      //     BoxConstraints.tightFor(height: BottomSheet._CONT_HEIGHT),
                      child: Container(
                        // margin: EdgeInsets.only(top: 6),
                        constraints: BoxConstraints.expand(),
                        // padding: EdgeInsets.only(left: 24, right: 24),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 5,
                              color: Colors.black12,
                            )
                          ],
                          borderRadius: BorderRadius.all(
                              // topLeft: Radius.circular(24),
                              Radius.circular(24)),
                          color: Colors.white,
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          // color: Colors.red,
                          child: InkResponse(
                            containedInkWell: true,
                            highlightShape: BoxShape.rectangle,
                            // customBorder: RoundedRectangleBorder(
                            //   borderRadius:
                            //       BorderRadius.all(Radius.circular(24)),
                            // ),
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                            onTap: () {
                              if (expanded)
                                hide();
                              else
                                show();
                            },
                            splashColor: Colors.purple[300]!.withOpacity(0.5),
                            // focusColor: Colors.blue,
                            highlightColor:
                                Colors.purple[100]!.withOpacity(0.5),
                            // hoverColor: Colors.green,
                            child: Padding(
                              padding: EdgeInsets.only(left: 24, right: 24),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Me',
                                      style: TextStyle(
                                          fontFamily: 'RobotoSlab',
                                          color: Colors.grey[900],
                                          fontSize: 18)),
                                  RotationTransition(
                                    turns: rotateAnim,
                                    child: Icon(
                                      Icons.arrow_drop_up,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: 24),
                    Container(
                      height: HEIGHT,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 5,
                            color: Colors.black12.withOpacity(0.06),
                          )
                        ],
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        color: Colors.white,
                      ),
                      // height: MediaQuery.of(context).size.height / 8,
                      margin: EdgeInsets.symmetric(vertical: 12),
                      // child: InkWell(
                      // When the user taps the button, show a snackbar.
                      child: ListView(
                        // padding: EdgeInsets.zero,
                        padding: EdgeInsets.only(top: 24, bottom: 32),
                        children: [
                          // Center(
                          //     child: Text('These don\'t work yet.',
                          //         style: TextStyle(fontSize: 18))),
                          Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              onTap: () {
                                print('object');
                              },
                              // leading: Icon(Icons.sentiment_satisfied),
                              title: Text(widget.userInfo.username!),
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
                              title: Text(widget.userInfo.user?.email ??
                                  "Set email (soon)"),
                              subtitle: Text(widget.userInfo.user?.email == null
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
                                widget.userInfo.logOut();
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
                            subtitle: Text(
                                'Sword icon made by Freepik @ flaticon.com'),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 24),
                          ),
                        ],
                        // ),
                      ),
                    ),
                    // Expanded(child: Container()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FriendListDisplay extends StatelessWidget {
  FriendListDisplay(this.friend, this.battleRequest, {Key? key})
      : super(key: key);

  final PublicUser friend;
  final void Function(String) battleRequest;

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
      // ],
      // ),
      // ),
    );
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
  Map<int, PublicUser>? searchResults;
  bool searching = false;
  int? addingFriend;
  String? searchText;
  List<int> successfullyAdded = new List.empty();

  void setSearchText(String text) {
    this.searchText = text;
  }

  void search() async {
    setState(() {
      searching = true;
    });
    String url = "${constants.URL}/api/users?search=$searchText";
    var response = await http.get(url);

    if (response.statusCode == 200) {
      searchResults = (jsonDecode(response.body) as List<dynamic>)
          .asMap()
          .map<int, PublicUser?>((i, dyn) {
        PublicUser? user = PublicUser.fromMap(dyn as Map<String, dynamic>);
        if (user == null) return MapEntry(i, null);
        return MapEntry(i, user);
      }).filterNotNull();

      searchResults!.removeWhere((index, publicUser) =>
          publicUser == null || publicUser.id == widget.myId);

      searchResults!.forEach((index, publicUser) {
        if (widget.userInfo.user?.friends.any((f) => f.id == publicUser.id) ==
            true) {
          publicUser.isFriend = true;
        }
      });
    }
    setState(() {
      searching = false;
    });
    // }

    // onError: () => setState(() {
    //   searching = false;
    // }),
  }

  void addFriend(String id, int index) async {
    setState(() => addingFriend = index);
    // if (
    await widget.userInfo.addFriend(id);
    searchResults?.forEach((index, publicUser) {
      if (widget.userInfo.user?.friends.any((f) => f.id == publicUser.id) ==
          true) {
        publicUser.isFriend = true;
      }
    });
    // ) {
    //   .add(index);
    // }
    if (mounted) {
      setState(() {
        addingFriend = null;
      });
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
    return OverlayDialog(
      widget.visible,
      hide: () {
        widget.searchbarFocusNode.unfocus();
        widget.hide();
      },
      child: Container(
        height: 170.0 + (searchResults != null ? 200 : 0),
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

  Widget buildSearchresults(Map<int, PublicUser> searchResults) {
    Map<int, Widget> results = searchResults.map((index, publicUser) {
      return MapEntry(
          index,
          ListTile(
            title: Text(publicUser.name),
            subtitle: Text("SR: ${publicUser.gameInfo.skillRating}"),
            trailing: IconButton(
              splashColor: Colors.red[700]!.withOpacity(0.5),
              highlightColor: Colors.red[700]!.withOpacity(0.5),
              icon: publicUser.isFriend
                  ? Icon(Icons.check)
                  : addingFriend == index
                      ? CircularProgressIndicator()
                      : Icon(Icons.person_add),
              onPressed: publicUser.isFriend
                  ? () {}
                  : () => addFriend(publicUser.id, index),
            ),
          ));
    });
    return Expanded(
      child: results.isEmpty
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
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: results.values.toList(),
              ),
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
