import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

Set<Built> _cache_built_value = {};
Set<BuiltList> _cache_built_list = {};
Set<BuiltSet> _cache_built_set = {};
Set<BuiltMap> _cache_built_map = {};

//abstract class BuiltInternable<V extends Built<V, B>, B extends Builder<V, B>> extends Built<V,B> {
//  B toBuilder() {
//
//  }
//}
//
//mixin BuilderInternable<V extends Built<V, B>, B extends Builder<V, B>> implements Builder<V,B> {
//  V build() {
//    V value = super.build();
//    return value.intern();
//  }
//}

extension BuiltExtendedWithIntern<V extends Built<V, B>, B extends Builder<V, B>> on Built<V, B> {
  V intern() {
    Set<Built> cache = _cache_built_value;
    Built<V, B> cached_value = cache.lookup(this);
    if (cached_value == null) {
      cache.add(this);
      return this;
    } else {
      return cached_value;
    }
  }
}

extension BuiltListExtendedWithIntern<E> on BuiltList<E> {
  BuiltList<E> intern() {
    Set<BuiltList> cache = _cache_built_list;
    BuiltList<E> cached_value = cache.lookup(this);
    if (cached_value == null) {
      cache.add(this);
      return this;
    } else {
      return cached_value;
    }
  }
}

extension BuiltSetExtendedWithIntern<E> on BuiltSet<E> {
  BuiltSet<E> intern() {
    Set<BuiltSet> cache = _cache_built_set;
    BuiltSet<E> cached_value = cache.lookup(this);
    if (cached_value == null) {
      cache.add(this);
      return this;
    } else {
      return cached_value;
    }
  }
}

extension BuiltMapExtendedWithIntern<K, V> on BuiltMap<K, V> {
  BuiltMap<K, V> intern() {
    Set<BuiltMap> cache = _cache_built_map;
    BuiltMap<K, V> cached_value = cache.lookup(this);
    if (cached_value == null) {
      cache.add(this);
      return this;
    } else {
      return cached_value;
    }
  }
}
