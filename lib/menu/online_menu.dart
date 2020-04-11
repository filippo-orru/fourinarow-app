import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/play_online.dart';

import 'common/menu_common.dart';

class OnlineMenuRange extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Menu(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Text(
            //   "Who do you want to play with?",
            //   style: TextStyle(fontSize: 24),
            // ),
            ArmsButton(
              "Worldwide (coming soon)",
              // icon: Icons.wifi_tethering,
              callback: () => {},

              // borderColor: Colors.black,
            ),
            ArmsButton(
              "Play with a friend",
              callback: () =>
                  Navigator.of(context).pushNamed("/online/selectHost"),
            ),
          ],
        ),
      ),
    );
  }
}

class OnlineMenuHost extends StatefulWidget {
  @override
  _OnlineMenuHostState createState() => _OnlineMenuHostState();
}

class _OnlineMenuHostState extends State<OnlineMenuHost> {
  String lobbyCode;

  @override
  Widget build(BuildContext context) {
    return Menu(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Text(
            //   "Do you host or do you join?",
            //   style: TextStyle(fontSize: 24),
            // ),
            ArmsButton(
              "Create new game",
              // icon: Icons.wifi_tethering,
              callback: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => PlayingOnline())),

              // borderColor: Colors.black,
            ),
            TextField(
                autocorrect: false,
                enableSuggestions: false,
                maxLength: 4,
                textCapitalization: TextCapitalization.characters,
                enableInteractiveSelection: false,
                onChanged: (s) => lobbyCode = s),
            ArmsButton(
              "Join a game",
              callback: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PlayingOnline(lobbyCode: lobbyCode))),
            ),
          ],
        ),
      ),
    );
  }
}
