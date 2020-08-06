import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

//import '../built_intern.dart';
import '../serializers.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

part 'position3d.g.dart';

abstract class Position3D with BuiltJsonSerializable implements Built<Position3D, Position3DBuilder> {
  num get x;

  num get y;

  num get z;

  factory Position3D.from_json(Map<String, dynamic> map) {
    if (map.containsKey('x') && map.containsKey('y') && map.containsKey('z')) {
      return Position3D(x: map['x'], y: map['y'], z: map['z']);
    } else if (map.containsKey('origin')) {
      var origin = map['origin'];
      return Position3D(x: origin['x'], y: origin['y'], z: origin['z']);
    }
  }

  // gets position from Helix map, first checking for "position" key,
  // then looking for "x", "y", "z", "pitch", "roll", "yaw" stored directly in map, and also allowing for
  // "x", "y", "z" to be under "origin" in either case.
  factory Position3D.get_position_from_helix_json_map(Map<String, dynamic> helix_map) {
    var map = helix_map;
    if (helix_map.containsKey(constants.position_key)) {
      map = helix_map[constants.position_key];
    }
    return Position3D.from_json(map);
  }

  to_json_serializable({bool suppress_indent = false}) => {'x': x, 'y': y, 'z': z};

  num distance_xy(Position3D other) => util.norm_l2(x - other.x, y - other.y);

  num distance_zy(Position3D other) => util.norm_l2(z - other.z, y - other.y);

  static Position3D origin = Position3D();

  @override
  Position3D operator *(num scalar) => Position3D(x: x * scalar, y: y * scalar, z: z * scalar);

  @override
  Position3D operator +(Position3D other) => Position3D(x: x + other.x, y: y + other.y, z: z + other.z);

  String xy([int digits_precision = 1]) =>
      '(${x.toStringAsFixed(digits_precision)}, ${y.toStringAsFixed(digits_precision)})';

  /************************ begin BuiltValue boilerplate ************************/
  factory Position3D({num x = 0, num y = 0, num z = 0}) => Position3D.from((b) => b
    ..x = x
    ..y = y
    ..z = z);

  factory Position3D.from([void Function(Position3DBuilder) updates]) = _$Position3D;

  Position3D._();

  static Serializer<Position3D> get serializer => _$position3DSerializer;

  @memoized
  int get hashCode;
}
