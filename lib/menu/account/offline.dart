import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/connection/server_connection.dart';
import 'package:provider/provider.dart';

// enum OfflineCaller {
//   Friends,
//   OnlineMatch,
// }

class OfflineScreen extends StatefulWidget {
  final Future<bool> Function()? refreshCheckAction;

  OfflineScreen({Key? key, this.refreshCheckAction}) : super(key: key);

  @override
  _OfflineScreenState createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool hasRetried = false;
  bool loading = false;

  Future<bool> _defaultRefreshCheckAction() async {
    var serverConnection = context.read<ServerConnection>();
    await serverConnection.retryConnection();
    return serverConnection.connected;
  }

  void retry() async {
    setState(() => loading = true);

    await Future.delayed(Duration(milliseconds: 600)); // Better UX

    if (await (widget.refreshCheckAction ?? _defaultRefreshCheckAction)() == true) {
      Navigator.of(context).pop();
    } else {
      setState(() => hasRetried = true);
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    String description = 'Please connect to the internet to continue.';

    // TODO either delete or add in smarter way
    // switch (widget.caller) {
    //   case OfflineCaller.OnlineMatch:
    //     description =
    //     break;
    //   case OfflineCaller.Friends:
    //     description =
    //         'Please connect to the internet to access the friends tab.';
    //     break;
    // }

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
                              builder: (ctx, double anim, child) =>
                                  Opacity(opacity: anim, child: child),
                              tween: Tween<double>(begin: 1, end: 0),
                              child: Text('No connection'),
                              onEnd: () => setState(() => hasRetried = false),
                            )
                          : SizedBox()),
                  SizedBox(width: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue[300],
                    ),
                    onPressed: retry,
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
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
