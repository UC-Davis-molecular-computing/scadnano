// @dart=2.9
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../constants.dart' as constants;
import 'design.dart';

part 'modification_type.g.dart';

class ModificationType extends EnumClass {
  const ModificationType._(String name) : super(name);

  static const ModificationType five_prime = _$five_prime;
  static const ModificationType three_prime = _$three_prime;
  static const ModificationType internal = _$internal;

  static BuiltSet<ModificationType> get values => _$values;

  static ModificationType valueOf(String name) => _$valueOf(name);

  @memoized
  String get to_json => name;

  @memoized
  String get key {
    if (this == ModificationType.five_prime) {
      return constants.design_modifications_5p_key;
    } else if (this == ModificationType.three_prime) {
      return constants.design_modifications_3p_key;
    } else if (this == ModificationType.internal) {
      return constants.design_modifications_int_key;
    } else {
      throw IllegalDesignError('unknown ModificationType "${this}"');
    }
  }

  static Serializer<ModificationType> get serializer => _$modificationTypeSerializer;
}
