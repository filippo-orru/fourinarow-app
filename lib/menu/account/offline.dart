import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/inherit/connection/server_conn.dart';
import 'package:four_in_a_row/inherit/user.dart';

enum OfflineCaller {
  Friends,
  OnlineMatch,
}

class OfflineScreen extends StatefulWidget {
  final OfflineCaller caller;

  OfflineScreen(this.caller);

  @override
  _OfflineScreenState createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool hasRetried = false;
  bool loading = false;

  Future<bool> action() async {
    switch (widget.caller) {
      case OfflineCaller.OnlineMatch:
        return await ServerConnProvider.of(context).refresh();

      case OfflineCaller.Friends:
        var userInfo = await UserinfoProvider.of(context).refresh();
        return !userInfo.offline;
        break;
      default:
        return false;
    }
  }

  void retry() async {
    setState(() => loading = true);

    if (await action() == true) {
      Navigator.of(context).pop();
    } else {
      setState(() => hasRetried = true);
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    String description;

    switch (widget.caller) {
      case OfflineCaller.OnlineMatch:
        description =
            'Please connect to the internet to access the friends tab.';
        break;
      case OfflineCaller.Friends:
        description =
            'Please connect to the internet to access the friends tab.';
        break;
    }

    return Scaffold(
      body: Container(
        margin: EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'It appears that you are offline.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 24),
            Text(description),
            SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                // mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  loading
                      ? CircularProgressIndicator()
                      : (hasRetried
                          ? TweenAnimationBuilder(
                              duration: Duration(milliseconds: 2000),
                              builder: (ctx, anim, child) =>
                                  Opacity(opacity: anim, child: child),
                              tween: Tween<double>(begin: 1, end: 0),
                              child: Text('No connection'),
                              onEnd: () => setState(() => hasRetried = false),
                            )
                          : SizedBox()),
                  SizedBox(width: 24),
                  RaisedButton(
                    onPressed: retry,
                    color: Colors.blue[300],
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    elevation: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
