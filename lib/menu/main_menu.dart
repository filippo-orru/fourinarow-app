import 'package:flutter/material.dart';

import 'common/menu_common.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    playLocal() => Navigator.of(context).pushNamed("/local/play");
    playOnline() => Navigator.of(context).pushNamed("/online/selectRange");
    return Menu(
      child: Container(
        // height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text("Four in a Row",
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic)),
            ),
            Expanded(
              child: Container(
                // padding: EdgeInsets.symmetric(horizontal: 64),
                width: 312,
                child: Column(
                  children: <Widget>[
                    ArmsButton("Play!", callback: playLocal),
                    SizedBox(height: 24),
                    ArmsButton("Play Online!", callback: playOnline),
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
