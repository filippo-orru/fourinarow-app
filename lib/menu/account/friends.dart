import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:four_in_a_row/util/constants.dart' as constants;
import 'package:flutter/material.dart';
import 'package:four_in_a_row/models/user.dart';

import '../main_menu.dart';
import 'onboarding/onboarding.dart';

class FriendsList extends StatefulWidget {
  FriendsList(this.userInfo);

  final UserinfoProviderState userInfo;

  @override
  _FriendsListState createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList>
    with SingleTickerProviderStateMixin {
  AnimationController expandMore;
  Animation<Offset> offsetTween;

  bool showAddFriend = false;

  @override
  void initState() {
    super.initState();
    expandMore =
        AnimationController(vsync: this, duration: Duration(milliseconds: 130));
    offsetTween =
        Tween(begin: Offset(0, 0.5), end: Offset.zero).animate(expandMore);
    widget.userInfo.refresh()..then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    // var onTap = () {
    //   widget.userInfo.logOut();
    //   Navigator.of(context).pushReplacement(slideUpRoute(AccountOnboarding()));
    // };
    return Scaffold(
        resizeToAvoidBottomInset: false,
        // appBar: AppBar(title: Text("Friends")),
        body: widget.userInfo.loggedIn
            ? Container(
                // padding: EdgeInsets.only(top: 64, bottom: 32),

                child: Stack(
                  children: [
                    SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomAppBar(
                              title: 'Friends',
                              refreshing: widget.userInfo.refreshing),
                          Expanded(
                              child:
                                  _FriendsListInner(userInfo: widget.userInfo)),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 24,
                      bottom: BottomSheet.HEIGHT,
                      child: FloatingActionButton(
                        backgroundColor: Colors.purple[300],
                        child: Icon(Icons.add),
                        onPressed: () => setState(() => showAddFriend = true),
                      ),
                    ),
                    BottomSheet(widget.userInfo),
                    AddFriendDialog(
                      showAddFriend,
                      hide: () => setState(
                        () => showAddFriend = false,
                      ),
                      myId: widget.userInfo.id,
                      userInfo: widget.userInfo,
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'An error has occurred. Please log out and try again.'),
                    SizedBox(height: 18),
                    RaisedButton(
                        color: Colors.grey[100],
                        elevation: 2,
                        onPressed: () {
                          widget.userInfo.logOut();
                          Navigator.of(context).pop();
                        },
                        child: Text('Log out'))
                  ],
                ),
              ));
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    @required this.title,
    this.refreshing = false,
    Key key,
  }) : super(key: key);

  final String title;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      // margin: EdgeInsets.only(
      //     bottom: 4, left: 4, right: 4, top: 4),
      // alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        // color: Colors.purple[300],
        // color: Colors.grey[300],
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            color: Colors.black12,
          )
        ],
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const BackButtonIcon(),
                splashColor: Colors.grey[400],
                color: Colors.black,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
              ),
              SizedBox(width: 24),
              Text(title,
                  style: TextStyle(
                    fontFamily: "RobotoSlab",
                    // color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    child: refreshing
                        ? Transform.scale(
                            scale: 0.7, child: CircularProgressIndicator())
                        // Container(
                        //     constraints: BoxConstraints.expand(),
                        //     color: Colors.black26,
                        //     child: Center(child: C),
                        //   )
                        : SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsListInner extends StatefulWidget {
  _FriendsListInner({
    Key key,
    @required this.userInfo,
  }) : super(key: key);

  final UserinfoProviderState userInfo;
  final GlobalKey<RefreshIndicatorState> refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  __FriendsListInnerState createState() => __FriendsListInnerState();
}

class __FriendsListInnerState extends State<_FriendsListInner> {
  List<int> expanded = new List();

  @override
  Widget build(BuildContext context) {
    var elements = widget.userInfo.friends
        .asMap()
        .map((i, PublicUser f) {
          Widget cont = FriendListDisplay(f);
          if (i != widget.userInfo.friends.length - 1) {
            cont = Column(
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                cont,
                Divider(
                  indent: 12,
                  endIndent: 12,
                  color: Colors.black.withOpacity(0.3),
                ),
                // Container(
                //     width: MediaQuery.of(context).size.width - 30,
                //     height: 1,
                //     color: Colors.black12)
              ],
            );
          }
          return MapEntry(i, cont);
        })
        .values
        .toList();
    return RefreshIndicator(
      onRefresh: widget.userInfo.refresh,
      // () {
      // refreshKey.currentState?.show(atTop: false);
      //   return userInfo.refresh();
      // },
      key: widget.refreshKey,
      child: ListView(
        padding: EdgeInsets.only(bottom: BottomSheet.HEIGHT),
        children: elements == null || elements.isEmpty
            ? [
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.only(top: 24),
                  child: Text("No friends yet. Add some to get started!"),
                )
              ]
            : elements,
      ),
    );
  }
}

class MoreButton extends StatelessWidget {
  const MoreButton({
    Key key,
    @required this.label,
    @required this.onTap,
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

  final UserinfoProviderState userInfo;

  const BottomSheet(
    this.userInfo, {
    Key key,
  }) : super(key: key);

  @override
  _BottomSheetState createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheet>
    with SingleTickerProviderStateMixin {
  static const double HEIGHT = 400;

  AnimationController moveUpAnimCtrl;
  Animation<double> moveUpAnim;
  Animation<double> rotateAnim;
  bool expanded = false;

  void toggle() {
    Future.delayed(Duration(milliseconds: 30), () {
      if (expanded) {
        moveUpAnimCtrl.reverse();
      } else {
        moveUpAnimCtrl.forward();
      }
      expanded = !expanded;
    });
  }

  @override
  void initState() {
    super.initState();
    moveUpAnimCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 260));

    moveUpAnim = Tween<double>(begin: 0, end: HEIGHT)
        .chain(CurveTween(curve: Curves.easeInOutQuart))
        .animate(moveUpAnimCtrl);

    rotateAnim = Tween<double>(begin: 0, end: 0.5)
        .chain(CurveTween(curve: Curves.easeInOutQuart))
        .animate(moveUpAnimCtrl);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));

    return WillPopScope(
      onWillPop: () {
        if (expanded) {
          toggle();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        // width: double.infinity,
        child: AnimatedBuilder(
          animation: moveUpAnim,
          builder: (ctx, child) => SizedOverflowBox(
            alignment: Alignment.topCenter,
            size: Size(
                double.infinity, BottomSheet._CONT_HEIGHT + moveUpAnim.value),
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
                        onTap: toggle,
                        splashColor: Colors.purple[300].withOpacity(0.5),
                        // focusColor: Colors.blue,
                        highlightColor: Colors.purple[100].withOpacity(0.5),
                        // hoverColor: Colors.green,
                        child: Padding(
                          padding: EdgeInsets.only(left: 24, right: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          title: Text(widget.userInfo.username),
                          subtitle: Text('Change username (soon)'),
                          contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          onTap: () {
                            print('object');
                          },
                          title:
                              Text(widget.userInfo.email ?? "Set email (soon)"),
                          subtitle: Text(widget.userInfo.email == null
                              ? 'You haven\'t set an email yet'
                              : 'Change email (soon)'),
                          contentPadding: EdgeInsets.symmetric(horizontal: 24),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 24),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 24),
                        ),
                      ),
                      ListTile(
                        title: Text('Credits'),
                        subtitle:
                            Text('Sword icon made by Freepik @ flaticon.com'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 24),
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
      ),
    );
  }
}

class FriendListDisplay extends StatelessWidget {
  FriendListDisplay(this.friend);

  final PublicUser friend;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: true,
      // trailing: Icon(Icons.),
      // child:
      // Container(
      // color: Colors.black26,
      // margin: EdgeInsets.symmetric(vertical: 8),
      // padding: EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      // width: double.infinity,
      // height: 45,
      // child: Row(
      // mainAxisSize: MainAxisSize.max,
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // crossAxisAlignment: CrossAxisAlignment.center,
      // children: [
      title: Text(
        friend.name,
        style: TextStyle(fontSize: 17),
      ),
      subtitle: Text("SR: ${friend.gameInfo.skillRating}"),
      // ],
      // ),
      // ),
    );
  }
}

class AddFriendDialog extends StatefulWidget {
  AddFriendDialog(
    this.show, {
    @required this.hide,
    @required this.userInfo,
    @required this.myId,
    Key key,
  }) : super(key: key);

  final bool show;
  final VoidCallback hide;
  final String myId;
  final UserinfoProviderState userInfo;

  @override
  _AddFriendDialogState createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog>
    with SingleTickerProviderStateMixin {
  static const Duration DURATION = Duration(milliseconds: 150);
  final FocusNode searchbarFocusNode = FocusNode();
  AnimationController animCtrl;
  Animation<double> opacityAnim;
  Animation<Offset> offsetAnim;
  String searchText = "";
  bool searching = false;
  Map<int, PublicUser> searchResults;
  int addingFriend;
  List<int> successfullyAdded = new List();

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
      searchResults =
          (jsonDecode(response.body) as List<dynamic>).asMap().map((i, dyn) {
        return MapEntry(i, PublicUser.fromMap(dyn as Map<String, dynamic>));
      });

      searchResults
          .removeWhere((index, publicUser) => publicUser.id == widget.myId);

      searchResults.forEach((index, publicUser) {
        if (widget.userInfo.friends.any((f) => f.id == publicUser.id)) {
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

  void _hide() {
    animCtrl.reverse().then((_) => widget.hide());
  }

  void addFriend(String id, int index) async {
    setState(() => addingFriend = index);
    // if (
    await widget.userInfo.addFriend(id);
    searchResults.forEach((index, publicUser) {
      if (widget.userInfo.friends.any((f) => f.id == publicUser.id)) {
        publicUser.isFriend = true;
      }
    });
    // ) {
    //   .add(index);
    // }
    setState(() {
      addingFriend = null;
    });
  }

  @override
  void initState() {
    super.initState();
    animCtrl = AnimationController(
      vsync: this,
      duration: DURATION,
    );
    opacityAnim = CurveTween(curve: Curves.easeIn).animate(animCtrl);
    offsetAnim = Tween(begin: Offset(0, 30), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(animCtrl);
  }

  @override
  void didUpdateWidget(AddFriendDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    searching = false;
    if (oldWidget.show && !widget.show) {
      animCtrl.reverse();
    } else if (!oldWidget.show && widget.show) {
      animCtrl.forward();
      this.searchbarFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    this.animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.show) {
          _hide();
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: TweenAnimationBuilder(
        tween: Tween<Offset>(
            begin: Offset.zero,
            end: Offset(0, -MediaQuery.of(context).viewInsets.bottom * 0.37)),
        duration: Duration(milliseconds: 100),
        builder: (ctx, Offset value, child) =>
            Transform.translate(offset: value, child: child),
        child: AnimatedBuilder(
          animation: animCtrl,
          builder: (ctx, child) =>
              Opacity(opacity: opacityAnim.value, child: child),
          child: widget.show
              ? GestureDetector(
                  onTap: _hide,
                  child: Container(
                    constraints: BoxConstraints.expand(),
                    color: Colors.black26,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AnimatedBuilder(
                        animation: animCtrl,
                        builder: (ctx, child) => Transform.translate(
                          offset: offsetAnim.value,
                          child: child,
                        ),
                        child: Container(
                          height:
                              170.0 + (this.searchResults != null ? 200 : 0),
                          width: min(
                              450, MediaQuery.of(context).size.width * 0.85),
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
                                  onTap: () =>
                                      searchbarFocusNode.requestFocus(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      color: Colors.grey[100],
                                    ),
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(18, 8, 8, 8),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: TextField(
                                                autofocus: true,
                                                onChanged: setSearchText,
                                                onSubmitted: (_) => search(),
                                                focusNode: searchbarFocusNode,
                                                decoration: InputDecoration(
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
                                              splashColor: Colors.purple[300]
                                                  .withOpacity(0.5),
                                              highlightColor: Colors.purple[200]
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
                                searchResults != null
                                    ? Expanded(
                                        child: SearchResults(
                                          searchResults,
                                          addingFriend,
                                          searchTerm: searchText,
                                          friends: widget.userInfo.friends,
                                          // successfullyAdded: successfullyAdded,
                                          addFriend: addFriend,
                                        ),
                                      )
                                    : SizedBox(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox(),
        ),
      ),
    );
  }
}

class SearchResults extends StatelessWidget {
  const SearchResults(
    this.searchResults,
    this.addingFriend, {
    Key key,
    @required this.searchTerm,
    @required this.friends,
    @required this.addFriend,
  }) : super(key: key);

  final String searchTerm;
  final Map<int, PublicUser> searchResults;
  final List<PublicUser> friends;
  // final List<int> successfullyAdded;
  final int addingFriend;
  final void Function(String, int) addFriend;

  @override
  Widget build(BuildContext context) {
    Map<int, Widget> results = searchResults.map((index, publicUser) {
      return MapEntry(
          index,
          ListTile(
            title: Text(publicUser.name),
            subtitle: Text("SR: ${publicUser.gameInfo.skillRating}"),
            trailing: IconButton(
              splashColor: Colors.red[700].withOpacity(0.5),
              highlightColor: Colors.red[700].withOpacity(0.5),
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
    return results == null || results.length == 0
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Text("No users found for \"$searchTerm\"",
                    style: TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ))),
          )
        : Scrollbar(
            child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: results.values.toList()),
          );
  }
}
