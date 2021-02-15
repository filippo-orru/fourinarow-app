import 'package:flutter/widgets.dart';

class RouteObserverProvider extends InheritedWidget {
  RouteObserverProvider({Key? key, required this.child, required this.observer})
      : super(key: key, child: child);

  final Widget child;
  final RouteObserver observer;

  static RouteObserverProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RouteObserverProvider>()!;
  }

  @override
  bool updateShouldNotify(RouteObserverProvider oldWidget) {
    return false;
  }
}
