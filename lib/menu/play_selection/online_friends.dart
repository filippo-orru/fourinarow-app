import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:four_in_a_row/menu/common/menu_common.dart';
import 'package:four_in_a_row/menu/common/play_button.dart';
import 'package:four_in_a_row/play/play_online.dart';

class PlayOnlineFriends extends StatefulWidget {
  @override
  _PlayOnlineFriendsState createState() => _PlayOnlineFriendsState();
}

class _PlayOnlineFriendsState extends State<PlayOnlineFriends>
    with SingleTickerProviderStateMixin {
  final TextEditingController lobbyCodeController = TextEditingController();

  bool expandedLobbyCode = false;

  AnimationController moveUpAnimCtrl;
  Animation<Offset> moveUpAnim;

  void joinLobby() {
    Navigator.of(context).push(fadeRoute(
        child: PlayingOnline(req: ORqLobby(this.lobbyCodeController.text))));
  }

  @override
  void initState() {
    super.initState();
    KeyboardVisibilityNotification().addNewListener(onChange: (bool visible) {
      visible ? moveUpAnimCtrl.forward() : moveUpAnimCtrl.reverse();
      print("keyboard vis: $visible");
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 66,
              // width: 250,
              child: AnimatedSwitcher(
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
                              onPressed: () =>
                                  setState(() => expandedLobbyCode = false),
                            ),
                            SizedBox(width: 12),
                            Container(
                              height: 48,
                              width: 96,
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                  border: Border.all(
                                      color: Colors.white38, width: 1.5)),
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Transform.translate(
                                offset: Offset(0, 0),
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
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  enableInteractiveSelection: false,
                                  onSubmitted: (_) => joinLobby(),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Hero(
                              tag: "button",
                              child: FlatIconButton(
                                onPressed: joinLobby,
                                icon: Icons.check,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Hero(
                        tag: "button",
                        child: Container(
                          height: 48,
                          // width: 48,
                          child: FlatButton(
                            color: Colors.white24,
                            splashColor: Colors.white54,
                            // padding: EdgeInsets.symmetric(
                            //     horizontal: 18, vertical: 12),
                            onPressed: () =>
                                setState(() => expandedLobbyCode = true),
                            child: Text(
                              'JOIN LOBBY',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            // RaisedButton(
            //   child: Text("Join"),
            //   onPressed: () {},
            // ),
          ],
        ),
        SizedBox(height: 48),
        PlayButton(
          label: 'Host',
          color: Colors.white38,
          onTap: () => Navigator.of(context)
              .push(fadeRoute(child: PlayingOnline(req: ORqLobby(null)))),
        ),
      ],
    );
  }
}

class FlatIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const FlatIconButton({
    Key key,
    @required this.onPressed,
    this.icon = Icons.check,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      child: FlatButton(
        padding: EdgeInsets.all(0),
        color: Colors.white12,
        splashColor: Colors.white70,
        focusColor: Colors.white,
        hoverColor: Colors.transparent,
        // padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onPressed: onPressed,
        child: Opacity(opacity: 0.8, child: Icon(icon, color: Colors.white)),
      ),
    );
  }
}
