import 'dart:async';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/logger.dart';

class LifecycleProvider extends StatefulWidget {
  final Widget child;

  const LifecycleProvider({Key? key, required this.child}) : super(key: key);

  @override
  State<LifecycleProvider> createState() => _LifecycleProviderState();
}

class _LifecycleProviderState extends State<LifecycleProvider> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    Lifecycle.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Lifecycle.instance.add(state);
  }
}

class Lifecycle with WidgetsBindingObserver {
  static final Lifecycle instance = Lifecycle._();

  final StreamController<AppLifecycleState> _streamController = StreamController.broadcast();
  Stream<AppLifecycleState> get stream => _streamController.stream;
  AppLifecycleState currentState = AppLifecycleState.resumed;

  Lifecycle._();

  void add(AppLifecycleState state) {
    Logger.d("AppLifecycleState = ${state.name}");
    _streamController.add(state);
    currentState = state;
  }

  void close() {
    _streamController.close();
  }
}
