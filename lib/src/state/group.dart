import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:collection/collection.dart';

import '../json_serializable.dart';
import '../serializers.dart';
import 'design.dart';
import 'geometry.dart';
import 'grid.dart';
import 'position3d.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'group.g.dart';

final DEFAULT_HelixGroupBuilder = HelixGroupBuilder();
final DEFAULT_HelixGroup = DEFAULT_HelixGroupBuilder.build();

abstract class HelixGroup with BuiltJsonSerializable implements Built<HelixGroup, HelixGroupBuilder> {
  Grid get grid;

  BuiltList<int> get helices_view_order;

  Position3D get position;

  double get pitch;

  double get yaw;

  double get roll;

  static void _initializeBuilder(HelixGroupBuilder b) {
    b.grid = Grid.none;
    b.position = Position3D.origin.toBuilder();
    b.pitch = 0;
    b.yaw = 0;
    b.roll = 0;
    b.helices_view_order = null;
  }

  factory HelixGroup({
    Grid grid = Grid.none,
    Iterable<int> helices_view_order = null,
    Position3D position = null,
    double pitch = 0,
    double yaw = 0,
    double roll = 0,
  }) {
    if (position == null) {
      position = Position3D.origin;
    }
    if (helices_view_order == null) {
      throw new IllegalDesignError('must specify helices_view_order explicitly');
    }
    return HelixGroup.from((b) => b
      ..grid = grid
      ..helices_view_order.replace(helices_view_order)
      ..position.replace(position)
      ..pitch = pitch
      ..yaw = yaw
      ..roll = roll);
  }

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false, Iterable<int> helix_idxs}) {
    Map<String, dynamic> json_map = {};

    var pos = position.to_json_serializable(suppress_indent: suppress_indent);
    json_map[constants.position_key] = suppress_indent ? NoIndent(pos) : pos;

    if (!util.are_close(pitch, constants.default_pitch)) {
      json_map[constants.pitch_key] = pitch;
    }
    if (!util.are_close(roll, constants.default_roll)) {
      json_map[constants.roll_key] = roll;
    }
    if (!util.are_close(yaw, constants.default_yaw)) {
      json_map[constants.yaw_key] = yaw;
    }

    json_map[constants.grid_key] = grid.name;

    var default_helices_view_order = List<int>.of(helix_idxs);
    default_helices_view_order.sort();
    var helices_view_order_to_write = helices_view_order.toList();
    var eq = const ListEquality().equals;
    if (!eq(helices_view_order_to_write, default_helices_view_order)) {
      json_map[constants.helices_view_order_key] =
          suppress_indent ? NoIndent(helices_view_order_to_write) : helices_view_order_to_write;
    }

    return json_map;
  }

  static HelixGroup from_json(Map<String, dynamic> json_map, {Iterable<int> helix_idxs}) {
    var grid_name = util.optional_field(json_map, constants.grid_key, Grid.none.name);
    var grid = Grid.valueOf(grid_name);

    List<int> helices_view_order;
    if (json_map.containsKey(constants.helices_view_order_key)) {
      helices_view_order = List<int>.from(json_map[constants.helices_view_order_key]);
      if (helices_view_order.length != helix_idxs.length) {
        throw IllegalDesignError('number of helices (${helix_idxs.length}) does not match '
            'length of helices_view_order (${helices_view_order.length})\n'
            'helix idxs:         ${helix_idxs.join(", ")}\n'
            'helices_view_order: ${helices_view_order.join(", ")}');
      }
      if (!util.lists_contain_same_elts(helices_view_order, helix_idxs)) {
        throw IllegalDesignError('helices_view_order ${helices_view_order} must have same indexes as '
            'helix_idxs ${helix_idxs}\n'
            'helix idxs:         ${helix_idxs.join(", ")}\n'
            'helices_view_order: ${helices_view_order.join(", ")}');
      }
    } else {
      helices_view_order = List<int>.of(helix_idxs);
      helices_view_order.sort();
    }

    var position_map = util.mandatory_field(json_map, constants.position_key, 'HelixGroup',
        legacy_keys: constants.legacy_position_keys);
    var position = Position3D.from_json(position_map);

    num pitch = util.optional_field(json_map, constants.pitch_key, constants.default_pitch);
    num roll = util.optional_field(json_map, constants.roll_key, constants.default_roll);
    num yaw = util.optional_field(json_map, constants.yaw_key, constants.default_yaw);

    return HelixGroup(
        position: position,
        pitch: pitch,
        yaw: yaw,
        roll: roll,
        helices_view_order: helices_view_order,
        grid: grid);
  }

  /// Returns a map mapping helix indices to their view order.
  @memoized
  BuiltMap<int, int> get helices_view_order_inverse {
    Map<int, int> view_order_inverse = Map<int, int>();
    int order = 0;
    for (var idx in helices_view_order) {
      view_order_inverse[idx] = order++;
    }
    return view_order_inverse.build();
  }

  String transform_str(Geometry geometry) {
    var translate_svg = position * geometry.nm_to_main_svg_pixels;
    return 'translate(${translate_svg.x}, ${translate_svg.y}) rotate(${pitch})';
//    return 'rotate(${pitch}) translate($x_translate_svg, $y_translate_svg)';
  }

  /// Transform point in main view according to this group's position and pitch.
  /// First we rotate about the origin by pitch, then we translated by
  /// (position.x, position.y), converted to SVG scale.
  Point<num> transform_point_main_view(Point<num> point, Geometry geometry, {bool inverse = false}) {
    Point<num> translation = Point<num>(position.x, position.y) * geometry.nm_to_main_svg_pixels;
    if (!inverse) {
      Point<num> rotated = util.rotate(point, pitch);
      Point<num> translated_and_rotated = rotated + translation;
      return translated_and_rotated;
    } else {
      Point<num> untranslated = point - translation;
      Point<num> unrotated_and_untranslated = util.rotate(untranslated, -pitch);
      return unrotated_and_untranslated;
    }
  }

  /************************ end BuiltValue boilerplate ************************/

  factory HelixGroup.from([void Function(HelixGroupBuilder) updates]) = _$HelixGroup;

  HelixGroup._();

  static Serializer<HelixGroup> get serializer => _$helixGroupSerializer;

  @memoized
  int get hashCode;
}
