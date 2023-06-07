Set _cache = {};

V intern<V>(V value) {
  var cached_value = _cache.lookup(value);
  if (cached_value == null) {
    _cache.add(value);
    return value;
  } else {
    return cached_value;
  }
}

//extension Internable on Object {
//  V intern<V extends Object>() {
//    return intern_object(this);
//  }
//}

//Set<Built> _cache_built_value = {};
//Set<BuiltList> _cache_built_list = {};
//Set<BuiltSet> _cache_built_set = {};
//Set<BuiltMap> _cache_built_map = {};
//
//V intern_built<V extends Built<V, B>, B extends Builder<V, B>>(V value) {
//  Set<Built> cache = _cache_built_value;
//  Built<V, B> cached_value = cache.lookup(value);
//  if (cached_value == null) {
//    cache.add(value);
//    return value;
//  } else {
//    return cached_value;
//  }
//}
//
//V build_interned<V extends Built<V, B>, B extends Builder<V, B>>(B builder) {
//  V value = builder.build();
//  Set<Built> cache = _cache_built_value;
//  Built<V, B> cached_value = cache.lookup(value);
//  if (cached_value == null) {
//    cache.add(value);
//    return value;
//  } else {
//    return cached_value;
//  }
//}

//extension BuiltExtendedWithIntern<V extends Built<V, B>, B extends Builder<V, B>> on Built<V, B> {
//  V intern_this() {
//    return intern(this);
//  }
//}

//extension BuiltListExtendedWithIntern<E> on BuiltList<E> {
//  BuiltList<E> intern() {
//    Set<BuiltList> cache = _cache_built_list;
//    BuiltList<E> cached_value = cache.lookup(this);
//    if (cached_value == null) {
//      cache.add(this);
//      return this;
//    } else {
//      return cached_value;
//    }
//  }
//}
//
//extension BuiltSetExtendedWithIntern<E> on BuiltSet<E> {
//  BuiltSet<E> intern() {
//    Set<BuiltSet> cache = _cache_built_set;
//    BuiltSet<E> cached_value = cache.lookup(this);
//    if (cached_value == null) {
//      cache.add(this);
//      return this;
//    } else {
//      return cached_value;
//    }
//  }
//}
//
//extension BuiltMapExtendedWithIntern<K, V> on BuiltMap<K, V> {
//  BuiltMap<K, V> intern() {
//    Set<BuiltMap> cache = _cache_built_map;
//    BuiltMap<K, V> cached_value = cache.lookup(this);
//    if (cached_value == null) {
//      cache.add(this);
//      return this;
//    } else {
//      return cached_value;
//    }
//  }
//}
