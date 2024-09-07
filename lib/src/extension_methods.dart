import 'package:built_collection/built_collection.dart';

extension BuiltMapValues<K, Vin> on BuiltMap<K, Vin> {
  /// Maps f onto all values in given BuiltMap, without changing keys.
  BuiltMap<K, Vout> map_values<Vout>(Vout f(K k, Vin v)) =>
      this.map((K key, Vin value) => MapEntry<K, Vout>(key, f(key, value)));
}

extension MapValues<K, Vin> on Map<K, Vin> {
  /// Maps f onto all values in given Map, without changing keys.
  Map<K, Vout> map_values<Vout>(Vout f(K k, Vin v)) =>
      this.map((K key, Vin value) => MapEntry<K, Vout>(key, f(key, value)));
}

extension MinMaxOfIterable<C extends Comparable> on Iterable<C> {
  C get min {
    if (isEmpty) {
      throw ArgumentError('cannot call min on an empty iterable');
    }
    C? min_val = null;
    for (C val in this) {
      if (min_val == null || min_val.compareTo(val) > 0) {
        min_val = val;
      }
    }
    return min_val!;
  }

  C get max {
    if (isEmpty) {
      throw ArgumentError('cannot call max on an empty iterable');
    }
    C? max_val = null;
    for (C val in this) {
      if (max_val == null || max_val.compareTo(val) < 0) {
        max_val = val;
      }
    }
    return max_val!;
  }
}
