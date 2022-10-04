import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:react/react.dart';
import 'package:scadnano/src/state/extension.dart';

import '../serializers.dart';

part 'potential_extension.g.dart';

abstract class PotentialExtension
    with BuiltJsonSerializable
    implements Built<PotentialExtension, PotentialExtensionBuilder> {
  factory PotentialExtension.from([void Function(PotentialExtensionBuilder) updates]) = _$PotentialExtension;

  PotentialExtension._();

  static Serializer<PotentialExtension> get serializer => _$potentialExtensionSerializer;

  factory PotentialExtension({
    Point<num> start_point,
    Point<num> current_point,
    Extension extension
  }) {
    return PotentialExtension.from((b) => b
      ..start_point = start_point
      ..current_point = current_point
      ..extension = extension.toBuilder()
    );
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  Point<num> get start_point;

  Point<num> get current_point;

  Extension get extension;
}
