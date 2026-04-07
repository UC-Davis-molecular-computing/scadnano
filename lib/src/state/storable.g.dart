// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storable.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Storable _$design = const Storable._('design');
const Storable _$app_ui_state_storables = const Storable._(
  'app_ui_state_storables',
);

Storable _$valueOf(String name) {
  switch (name) {
    case 'design':
      return _$design;
    case 'app_ui_state_storables':
      return _$app_ui_state_storables;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<Storable> _$values = BuiltSet<Storable>(const <Storable>[
  _$design,
  _$app_ui_state_storables,
]);

Serializer<Storable> _$storableSerializer = _$StorableSerializer();

class _$StorableSerializer implements PrimitiveSerializer<Storable> {
  @override
  final Iterable<Type> types = const <Type>[Storable];
  @override
  final String wireName = 'Storable';

  @override
  Object serialize(
    Serializers serializers,
    Storable object, {
    FullType specifiedType = FullType.unspecified,
  }) => object.name;

  @override
  Storable deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Storable.valueOf(serialized as String);
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
