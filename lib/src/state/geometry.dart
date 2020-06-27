import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import 'unused_fields.dart';
import '../serializers.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'geometry.g.dart';

abstract class Geometry with BuiltJsonSerializable, UnusedFields implements Built<Geometry, GeometryBuilder> {
  factory Geometry(
          {num z_step = constants.default_z_step,
          num helix_radius = constants.default_helix_radius,
          num bases_per_turn = constants.default_bases_per_turn,
          num minor_groove_angle = constants.default_minor_groove_angle,
          num inter_helix_gap = constants.default_inter_helix_gap}) =>
      Geometry.from((b) => b
        ..z_step = z_step
        ..helix_radius = helix_radius
        ..bases_per_turn = bases_per_turn
        ..minor_groove_angle = minor_groove_angle
        ..inter_helix_gap = inter_helix_gap);

  factory Geometry.from([void Function(GeometryBuilder) updates]) = _$Geometry;

  Geometry._();

  static Serializer<Geometry> get serializer => _$geometrySerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  /// What is this?
  double get z_step;

  /// Radius of a DNA helix in nanometers.
  double get helix_radius;

  /// Number of DNA base pairs in in full turn of DNA.
  double get bases_per_turn;

  /// Minor groove angle in degrees.
  double get minor_groove_angle;

  /// Gap between helices in nanometers (due to electrostatic repulsion; needed to display to scale).
  double get inter_helix_gap;

  @memoized
  double get distance_between_helices_nm => 2 * helix_radius + inter_helix_gap;

  @memoized
  double get helix_diameter_nm => 2 * helix_radius;

  bool z_step_is_default() => util.are_close(z_step, constants.default_z_step);

  bool helix_radius_is_default() => util.are_close(helix_radius, constants.default_helix_radius);

  bool bases_per_turn_is_default() => util.are_close(bases_per_turn, constants.default_bases_per_turn);

  bool minor_groove_angle_is_default() =>
      util.are_close(minor_groove_angle, constants.default_minor_groove_angle);

  bool inter_helix_gap_is_default() => util.are_close(inter_helix_gap, constants.default_inter_helix_gap);

  static Geometry from_json(Map<String, dynamic> json_map) {
    double z_step = util.get_value_with_default(json_map, constants.z_step_key, constants.default_z_step);
    double helix_radius =
        util.get_value_with_default(json_map, constants.helix_radius_key, constants.default_helix_radius);
    double bases_per_turn =
        util.get_value_with_default(json_map, constants.bases_per_turn_key, constants.default_bases_per_turn);
    double minor_groove_angle = util.get_value_with_default(
        json_map, constants.minor_groove_angle_key, constants.default_minor_groove_angle,
        legacy_keys: constants.legacy_minor_groove_angle_keys,
        legacy_transformer: (num angle_radians) => util.to_degrees(angle_radians));
    double inter_helix_gap = util.get_value_with_default(
        json_map, constants.inter_helix_gap_key, constants.default_inter_helix_gap);

    var geometry = Geometry(
      z_step: z_step,
      helix_radius: helix_radius,
      bases_per_turn: bases_per_turn,
      minor_groove_angle: minor_groove_angle,
      inter_helix_gap: inter_helix_gap,
    );

    var unused_fields = util.unused_fields_map(json_map, constants.geometry_keys);
    geometry = geometry.rebuild((b) => b..unused_fields = unused_fields);

    return geometry;
  }

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    var json_map = Map<String, dynamic>();

    if (!z_step_is_default()) {
      json_map[constants.z_step_key] = z_step;
    }
    if (!helix_radius_is_default()) {
      json_map[constants.helix_radius_key] = helix_radius;
    }
    if (!bases_per_turn_is_default()) {
      json_map[constants.bases_per_turn_key] = bases_per_turn;
    }
    if (!minor_groove_angle_is_default()) {
      json_map[constants.minor_groove_angle_key] = minor_groove_angle;
    }
    if (!inter_helix_gap_is_default()) {
      json_map[constants.inter_helix_gap_key] = inter_helix_gap;
    }

    json_map.addAll(unused_fields.toMap());

    return json_map;
  }

  bool is_default() => util.are_all_close([
        z_step,
        helix_radius,
        bases_per_turn,
        minor_groove_angle,
        inter_helix_gap,
      ], [
        constants.default_z_step,
        constants.default_helix_radius,
        constants.default_bases_per_turn,
        constants.default_minor_groove_angle,
        constants.default_inter_helix_gap,
      ]);
}
