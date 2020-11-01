import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:four_in_a_row/inherit/connection/server_conn.dart';
import 'package:four_in_a_row/inherit/user.dart';

class PlayOnline extends StatefulWidget {
  PlayOnline();

  @override
  _PlayOnlineState createState() => _PlayOnlineState();
}

class _PlayOnlineState extends State<PlayOnline> {
  UserinfoProviderState userInfo;

  // @override
  // initState() {
  //   super.initState();
  // }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    // userInfo = userInfo ?? UserinfoProvider.of(context);
    // UserinfoProvider.of(context)?.refresh(shouldSetState: false);
  }

  @override
  Widget build(BuildContext context) {
    ServerConnState serverConn = ServerConnProvider.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Flexible(
        //   flex: MediaQuery.of(context).devicePixelRatio < 2 ? 1 : 7,
        //   child:
        // FittedBox(
        //     child:
        MediaQuery.of(context).devicePixelRatio < 2
            ? SizedBox()
            : UserRankDisplay(),
        // ),
        // LimitedBox(
        //     maxHeight: 48,
        //     child:
        Container(
          height: 24,
        ),
        // Flexible(
        //     flex: 5,
        //     child:
        Transform.scale(
          scale: MediaQuery.of(context).devicePixelRatio < 2 ? 0.5 : 1,
          // child:
          // FittedBox(
          child: Container(
            // height: 150,
            width: 250,
            child: JoinLobbyButtons(),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 24),
            Text(
                serverConn.connected
                    ? (serverConn.currentServerInfo == null
                        ? "..."
                        : "Currently online: " +
                            serverConn
                                .currentServerInfo.currentlyConnectedPlayers
                                .toString() +
                            (serverConn.currentServerInfo.playerWaitingInLobby
                                ? ". Players in queue"
                                : ""))
                    : "No connection",
                style: TextStyle(color: Colors.white70))
          ],
        )
      ],
    );
  }
}

class UserRankDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var userInfo = UserinfoProvider.of(context);

    return userInfo?.loggedIn == true
        ? Container(
            width: 180,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Text(
                      "${userInfo.user.gameInfo.skillRating}",
                      style: TextStyle(
                        fontSize: 48,
                        color: Colors.grey[100],
                        shadows: [
                          Shadow(
                            blurRadius: 1,
                            color: Colors.black12,
                            offset: Offset(0, 2),
                          ),
                        ],
                        fontFamily: 'RobotoSlab',
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'SR',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[100],
                        shadows: [
                          Shadow(
                            blurRadius: 1,
                            color: Colors.black.withOpacity(0.08),
                            offset: Offset(0, 2),
                          ),
                        ],
                        fontFamily: 'RobotoSlab',
                      ),
                    ),
                  ],
                ),
                // Text(
                //   "#${userInfo.gameInfo.playerRank} World Wide".toUpperCase(),
                //   style: TextStyle(
                //     fontSize: 15,
                //     letterSpacing: 0.6,
                //     color: Colors.white.withOpacity(0.6),
                //     fontStyle: FontStyle.italic,
                //     // fontFamily: 'RobotoSlab',
                //   ),
                // ),
              ],
            ),
          )
        : SizedBox();
  }
}

class JoinLobbyButtons extends StatefulWidget {
  JoinLobbyButtons();

  // final bool showMore;

  @override
  _JoinLobbyButtonsState createState() => _JoinLobbyButtonsState();
}

class _JoinLobbyButtonsState extends State<JoinLobbyButtons>
    with SingleTickerProviderStateMixin {
  final TextEditingController lobbyCodeController = TextEditingController();
  bool expandedLobbyCode = false;
  bool showMore = false;

  AnimationController moveUpAnimCtrl;
  Animation<Offset> moveUpAnim;

  void createLobby() {
    ServerConnProvider.of(context).startGame(ORqLobby(null));
    // Navigator.of(context).push(fadeRoute(child: PlayingOnline()));
  }

  void joinLobby(userInfo) {
    ServerConnProvider.of(context)
        .startGame(ORqLobby(this.lobbyCodeController.text));
    // route: fadeRoute(child: PlayingOnline()));
    // Navigator.of(context).push(fadeRoute(child: PlayingOnline()));
  }

  @override
  void initState() {
    super.initState();

    KeyboardVisibilityNotification().addNewListener(onChange: (bool visible) {
      visible ? moveUpAnimCtrl.forward() : moveUpAnimCtrl.reverse();
      // print("keyboard vis: $visible");
    });

    moveUpAnimCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    moveUpAnim =
        moveUpAnimCtrl.drive(Tween(begin: Offset.zero, end: Offset(0, -60)));
  }

  @override
  void dispose() {
    lobbyCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        children: <Widget>[
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
        alignment: Alignment.topCenter,
      ),
      child: !showMore
          ? buildMoreButton()
          : Column(children: [
              FlatIconButton(
                icon: Icons.close,
                onPressed: () => setState(() => showMore = false),
              ),
              SizedBox(height: 12),
              Container(
                height: (48 * 2 + 16).toDouble(),
                // width: 290,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    buildCreateLobby(),
                    buildJoinLobby(context),
                  ],
                ),
              ),
            ]),
    );
  }

  Container buildMoreButton() {
    return Container(
      height: 48,
      child: FlatButton(
        color: Colors.white24,
        splashColor: Colors.white54,
        // padding: EdgeInsets.symmetric(
        //     horizontal: 18, vertical: 12),
        onPressed: () => setState(() => showMore = true),
        child: Text(
          'MORE',
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ),
    );
  }

  Container buildCreateLobby() {
    return Container(
      // constraints:
      //     BoxConstraints.tightFor(
      height: 48,
      child: FlatButton(
        color: Colors.white24,
        splashColor: Colors.white54,
        onPressed: createLobby,
        // setState(() => expandedLobbyCode = true),
        child: Text(
          'CREATE LOBBY',
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ),
    );
  }

  AnimatedSwitcher buildJoinLobby(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 200),
      child: expandedLobbyCode
          ? AnimatedBuilder(
              animation: moveUpAnim,
              builder: (BuildContext context, Widget child) {
                return Transform.translate(
                  offset: moveUpAnim.value,
                  child: child,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FlatIconButton(
                    icon: Icons.close,
                    onPressed: () => setState(() => expandedLobbyCode = false),
                  ),
                  SizedBox(width: 12),
                  Container(
                    height: 48,
                    width: 96,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        border: Border.all(color: Colors.white38, width: 1.5)),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Transform.translate(
                      offset: Offset(0, 0),
                      child: Material(
                        type: MaterialType.transparency,
                        child: TextField(
                          // focusNode: inputFocusNode,
                          cursorColor: Colors.white,
                          // cursorRadius: Radius.circular(2),
                          cursorWidth: 2,
                          keyboardType: TextInputType.visiblePassword,
                          style: TextStyle(
                            color: Colors.white,

                            letterSpacing: 5,
                            // decorationStyle: null,
                            // decorationThickness: 0,
                            decorationColor: Colors.transparent,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            // border: InputBorder.none,
                            // fillColor: Colors.red,
                            hintStyle: TextStyle(
                              color: Colors.white54,
                            ),
                            counterStyle: TextStyle(
                              color: Colors.white54,
                            ),
                            hintText: "CODE",
                            counter: SizedBox(),
                            counterText: null,
                            contentPadding: EdgeInsets.all(0),
                          ),
                          controller: lobbyCodeController,
                          autofocus: false,
                          autocorrect: false,
                          enableSuggestions: false,
                          maxLength: 4,
                          textCapitalization: TextCapitalization.characters,
                          enableInteractiveSelection: false,
                          onSubmitted: (_) =>
                              joinLobby(UserinfoProvider.of(context)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  FlatIconButton(
                    onPressed: () => joinLobby(UserinfoProvider.of(context)),
                    icon: Icons.check,
                  ),
                ],
              ),
            )
          : Container(
              // width: double.infinity,
              height: 48,
              child: FlatButton(
                color: Colors.white24,
                splashColor: Colors.white54,
                onPressed: () => setState(() => expandedLobbyCode = true),
                child: Text(
                  'JOIN LOBBY',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ),
            ),
    );
  }
}

class FlatIconButton extends StatelessWidget {
  const FlatIconButton({
    Key key,
    this.enabled = true,
    @required this.onPressed,
    this.icon = Icons.check,
    this.bgColor = Colors.white12,
  }) : super(key: key);

  final bool enabled;
  final VoidCallback onPressed;
  final IconData icon;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final colorRemovalFactor = enabled ? 1 : 0.5;
    Color color = this
        .bgColor
        .withBlue((this.bgColor.blue * colorRemovalFactor).floor())
        .withGreen((this.bgColor.green * colorRemovalFactor).floor())
        .withRed((this.bgColor.red * colorRemovalFactor).floor());
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        width: 48,
        height: 48,
        child: FlatButton(
          padding: EdgeInsets.all(0),
          color: color,
          splashColor: Colors.white70,
          focusColor: Colors.white,
          hoverColor: Colors.transparent,
          // padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          onPressed: () {
            if (enabled) onPressed();
          },
          child: Opacity(opacity: 0.88, child: Icon(icon, color: Colors.white)),
        ),
      ),
    );
  }
}