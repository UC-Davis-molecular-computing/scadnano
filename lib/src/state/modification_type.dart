import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
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

  static Serializer<ModificationType> get serializer => _$modificationTypeSerializer;
}
