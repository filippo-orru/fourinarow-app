import 'package:flutter/widgets.dart';

import 'all.dart';

// class ConnStateError extends ConnState {
//   final ConnError error;
//   ConnStateError(this.error, {Key key}) : super(key: key);

//   @override
//   createState() => ConnStateErrorState();
// }

// class ConnStateErrorState extends State<ConnStateError> {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: widget.error,
//     );

// return Text("Dev: You forgot to add the ConnError");
//   }
// }

// abstract class ConnError extends StatelessWidget {}

// class ConnErrorTimeout extends ConnError {
//   Widget build(BuildContext context) {
//     return Text("Connection timed out! Couldn't reach server.");
//   }
// }

// class ConnErrorInternal extends ConnError {
//   final String message;
//   ConnErrorInternal(this.message);

//   Widget build(BuildContext context) {
//     return Text("ConnState: Error ($message)");
//   }
// }
