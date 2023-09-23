import 'package:flutter/material.dart';
import 'package:four_in_a_row/app.dart';
import 'package:four_in_a_row/app_startup.dart';
import 'package:four_in_a_row/providers/lifecycle.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/util/wait_screen_size.dart';
import 'package:provider/provider.dart';

void main() {
  waitScreenSizeAvailable();
  runApp(FiarAppWrapper());
}

class FiarAppWrapper extends StatefulWidget {
  @override
  _FiarAppWrapperState createState() => _FiarAppWrapperState();
}

enum StartupState { Running, Preloading, Done }

class _FiarAppWrapperState extends State<FiarAppWrapper> {
  StartupState state = StartupState.Running;

  @override
  Widget build(BuildContext context) {
    return LifecycleProvider(
      child: ChangeNotifierProvider<ThemesProvider>(
        create: (_) => ThemesProvider(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            state == StartupState.Preloading || state == StartupState.Done
                ? FiarProviderApp()
                : SizedBox(),
            AppStartup(
              onCompleted: () {
                setState(() => state = StartupState.Done);
              },
              onStartPreloading: () {
                setState(() => state = StartupState.Preloading);
              },
            ),
          ],
        ),
      ),
    );
  }
}
