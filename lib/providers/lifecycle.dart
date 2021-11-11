import 'package:flutter/material.dart';

class _LifecycleInherit extends InheritedWidget {
  _LifecycleInherit({Key? key, required Widget child, required this.state})
      : super(key: key, child: child);

  final LifecycleProviderState state;

  @override
  bool updateShouldNotify(_LifecycleInherit oldWidget) {
    return false;
  }
}

class LifecycleProvider extends StatefulWidget {
  LifecycleProvider({required this.child});

  final Widget child;

  @override
  LifecycleProviderState createState() => LifecycleProviderState();

  static LifecycleProviderState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_LifecycleInherit>()?.state;
  }
}

class LifecycleProviderState extends State<LifecycleProvider>
    with WidgetsBindingObserver, ChangeNotifier {
  AppLifecycleState state = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    this.state = state;
    print("Appstate: $state");
    if (mounted) setState(() {}); //state != AppLifecycleState.defunct
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return _LifecycleInherit(child: widget.child, state: this);
  }
}
