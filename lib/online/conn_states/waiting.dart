import 'all.dart';
import 'package:flutter/widgets.dart';

class ConnStateWaiting extends ConnState {
  ConnStateWaiting({Key key}) : super(key: key);

  @override
  createState() => ConnStateWaitingState();
}

class ConnStateWaitingState extends State<ConnStateWaiting> {
  @override
  Widget build(BuildContext context) {
    return Text("connecting");
  }
}
