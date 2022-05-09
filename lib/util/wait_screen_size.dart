import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';

Future<void> waitScreenSizeAvailable() async {
  if (!_hasScreenSize) {
    WidgetsFlutterBinding.ensureInitialized();
    var observer = _Observer();
    WidgetsBinding.instance!.addObserver(observer);
    await observer.hasScreenSize;
    WidgetsBinding.instance!.removeObserver(observer);
  }
}

bool get _hasScreenSize => !window.physicalSize.isEmpty;

class _Observer extends WidgetsBindingObserver {
  final _screenSizeCompleter = Completer<void>();

  Future<void> get hasScreenSize => _screenSizeCompleter.future;

  @override
  void didChangeMetrics() {
    if (!_screenSizeCompleter.isCompleted && _hasScreenSize) {
      _screenSizeCompleter.complete();
    }
  }
}
