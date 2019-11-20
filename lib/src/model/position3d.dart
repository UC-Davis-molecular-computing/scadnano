import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:codemirror/codemirror.dart';
import 'package:over_react/over_react.dart';

import '../built_intern.dart';
import '../serializers.dart';

part 'position3d.g.dart';

abstract class Position3D with BuiltJsonSerializable implements Built<Position3D, Position3DBuilder> {
  num get x;

  num get y;

  num get z;

  num get pitch;

  num get roll;

  num get yaw;

  /************************ begin BuiltValue boilerplate ************************/
  factory Position3D({num x = 0, num y = 0, num z = 0, num pitch = 0, num roll = 0, num yaw = 0}) =>
      Position3D.from((b) => b
        ..x = x
        ..y = y
        ..z = z
        ..pitch = pitch
        ..roll = roll
        ..yaw = yaw);

  factory Position3D.from([void Function(Position3DBuilder) updates]) = _$Position3D;

  Position3D._();

  static Serializer<Position3D> get serializer => _$position3DSerializer;
}
