import 'package:built_collection/built_collection.dart';

extension BuiltMapValues<K, Vin> on BuiltMap<K, Vin> {
  /// Maps f onto all values in given BuiltMap, without changing keys.
  BuiltMap<K, Vout> map_values<Vout>(Vout f(Vin v)) =>
      this.map((K key, Vin value) => MapEntry<K, Vout>(key, f(value)));
}

extension MapValues<K, Vin> on Map<K, Vin> {
  /// Maps f onto all values in given Map, without changing keys.
  Map<K, Vout> map_values<Vout>(Vout f(Vin v)) =>
      this.map((K key, Vin value) => MapEntry<K, Vout>(key, f(value)));
}
