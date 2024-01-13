import 'dart:async';

extension ListExtension<T> on List<T?> {
  List<T> filterNotNull() {
    return this.whereType<T>().toList();
  }
}

extension ListExtension2<T> on List<T> {
  List<T?> toNullable() {
    return this.map<T?>((e) => e).toList();
  }

  T? getOrNull(int index) {
    if (this.length > index) {
      return this[index];
    } else {
      return null;
    }
  }
}

extension StreamExtension<T> on Stream<T> {
  Stream<T?> toNullable() {
    return this.map<T?>((e) => e);
  }
}

extension FutureExtension<T> on Future<T> {
  Future<T?> toNullable() {
    return this.then<T?>((e) => e);
  }
}

extension MapExtension<K, V> on Map<K, V?> {
  V? getOrNull(K key) {
    if (this.containsKey(key)) {
      return this[key];
    } else {
      return null;
    }
  }

  Map<K, V> filterNotNull<K, V>() {
    this.removeWhere((_, v) => v == null);
    return this as Map<K, V>;
  }
}

extension RangeExtension on int {
  /// Excluding max
  List<int> to(int maxInclusive) => [for (int i = this; i <= maxInclusive; i++) i];
}

extension NumberStrings on int {
  String toNumberWord({useZero = false}) {
    switch (this) {
      case 0:
        return useZero ? "zero" : "no";
      case 1:
        return "one";
      case 2:
        return "two";
      case 3:
        return "three";
      case 4:
        return "four";
      case 5:
        return "five";
      case 6:
        return "six";
      default:
        return this.toString();
    }
  }
}

extension StringTransform on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}

Future<T> waitAny<T>(Iterable<Future<T>> futures) {
  var completer = new Completer<T>();
  for (var f in futures) {
    f.then((v) {
      if (!completer.isCompleted) completer.complete(v);
    }, onError: (e, s) {
      if (!completer.isCompleted) completer.completeError(e, s);
    });
  }
  return completer.future;
}

extension IterableExtension<T> on Iterable<T> {
  Map<K, V> associateBy<K, V>(K Function(T) keySelector, [V Function(T)? valueTransform]) {
    Map<K, V> destination = {};

    for (final element in this) {
      final key = keySelector(element);
      final V value = valueTransform == null ? element as V : valueTransform(element);
      destination[key] = value;
    }
    return destination;
  }

  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    Map<K, List<T>> destination = {};

    for (final element in this) {
      final K key = keySelector(element);

      final List<T> list;
      final value = destination[key];
      if (value != null) {
        list = value;
      } else {
        list = [];
        destination[key] = list;
      }

      list.add(element);
    }
    return destination;
  }
}

extension IntIterableExtension on Iterable<int> {
  int sum() {
    int sum = 0;
    for (final element in this) {
      sum += element;
    }
    return sum;
  }
}
