// @dart=2.9
import 'dart:html';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'base_pair_display_type.g.dart';

class BasePairDisplayType extends EnumClass {
  const BasePairDisplayType._(String name) : super(name);

  @memoized
  int get hashCode;

  static Serializer<BasePairDisplayType> get serializer => _$basePairDisplayTypeSerializer;

  /******************** end BuiltValue boilerplate *********************/

  static const BasePairDisplayType none = _$none;
  static const BasePairDisplayType lines = _$lines;
  static const BasePairDisplayType rectangle = _$rectangle; // used to join two Domains with Crossover
  static BuiltList<BasePairDisplayType> types = const [none, lines, rectangle].toBuiltList();

  static BuiltSet<BasePairDisplayType> get values => _$values;

  static BasePairDisplayType valueOf(String name) => _$valueOf(name);

  String to_json() => name;

  int toIndex() {
    switch (this) {
      case none:
        return 0;
      case lines:
        return 1;
      case rectangle:
        return 2;
    }
    return 0;
  }

  String display_name() {
    // edit this to display a different string than the identifier name above
    switch (this) {
      case none:
        return 'none';
      case lines:
        return 'lines';
      case rectangle:
        return 'rectangle';
    }
    return super.toString();
  }

  @override
  String toString() => display_name();

  static BasePairDisplayType from_json(String the_name) {
    for (var val in values) {
      if (val.name == the_name) {
        return val;
      }
    }
    throw ArgumentError('there is no base pair display type with name "${the_name}"');
  }
}
