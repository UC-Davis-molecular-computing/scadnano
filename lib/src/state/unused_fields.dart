import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

mixin UnusedFields {
  @BuiltValueField(serialize: false)
  BuiltMap<String, dynamic> get unused_fields;
}
