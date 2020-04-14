export 'connected.dart';
export 'error.dart';
export 'waiting.dart';

import 'package:flutter/widgets.dart';

abstract class ConnState extends StatefulWidget {
  ConnState({Key key})
      // : _changeStateCallback = changeStateCallback,
      : super(key: key);
}
