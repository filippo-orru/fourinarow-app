extension ListExtension<T> on List<T?> {
  List<T> filterNotNull() {
    return this.where((e) => e != null).toList() as List<T>;
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
  Map<K, V> filterNotNull<K, V>() {
    this.removeWhere((_, v) => v == null);
    return this as Map<K, V>;
  }
}
