import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/serializers.dart';

part 'test.g.dart';

abstract class Value
    with BuiltJsonSerializable
    implements Built<Value, ValueBuilder> {

  factory Value({List<int> numbers}) = _$Value._;

  factory Value.from([void Function(ValueBuilder) updates]) = _$Value;

  Value._();

  static Serializer<Value> get serializer => _$valueSerializer;
  /************************ end BuiltValue boilerplate ************************/

  List<int> get numbers;

}