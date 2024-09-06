// @dart=2.9
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import 'unused_fields.dart';
import '../serializers.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

part 'geometry.g.dart';

/// DISTANCE_BETWEEN_HELICES_SVG is set to (BASE_WIDTH_SVG * 2.5/0.332) based on the following calculation,
/// to attempt to make the DNA appear to scale in 2D drawings:
/// The width of one base pair of double-stranded DNA bp is 0.332 nm. (DNA_BASE_WIDTH_NM)
/// In a DNA origami, AFM images estimate that the average distance between adjacent double helices is 2.5 nm.
/// (HELIX_DISTANCE_NM)
/// (A DNA double-helix is only 2 nm wide, but the helices electrostatically repel each other so the spacing
/// in a DNA origami or an other DNA nanostructure with many parallel DNA helices---e.g., single-stranded tile
/// lattices---is larger than 2 nm.)
/// Thus the distance between the helices is 2.5/0.332 ~ 7.5 times the width of a single DNA base.
abstract class Geometry with BuiltJsonSerializable, UnusedFields implements Built<Geometry, GeometryBuilder> {
  factory Geometry.from([void Function(GeometryBuilder) updates]) = _$Geometry;

  Geometry._();

  static Serializer<Geometry> get serializer => _$geometrySerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/
  factory Geometry({
    num rise_per_base_pair = constants.default_rise_per_base_pair,
    num helix_radius = constants.default_helix_radius,
    num inter_helix_gap = constants.default_inter_helix_gap,
    num bases_per_turn = constants.default_bases_per_turn,
    num minor_groove_angle = constants.default_minor_groove_angle,
  }) =>
      Geometry.from((b) => b
        ..rise_per_base_pair = rise_per_base_pair
        ..helix_radius = helix_radius
        ..inter_helix_gap = inter_helix_gap
        ..bases_per_turn = bases_per_turn
        ..minor_groove_angle = minor_groove_angle);

  /// Distance in nanometers between two adjacent base pairs along the length of a DNA double helix.
  double get rise_per_base_pair;

  /// Radius in nanometers of a DNA double helix.
  double get helix_radius;

  /// Gap between helices in nanometers (due to electrostatic repulsion; needed to display to scale).
  double get inter_helix_gap;

  /// Number of DNA base pairs in in full turn of DNA.
  double get bases_per_turn;

  /// Minor groove angle in degrees.
  double get minor_groove_angle;

  @memoized
  double get distance_between_helices_nm => 2 * helix_radius + inter_helix_gap;

  @memoized
  double get distance_between_helices_svg => distance_between_helices_nm * nm_to_svg_pixels;

  @memoized
  double get helix_diameter_nm => 2 * helix_radius;

  @memoized
  double get helix_radius_svg => helix_radius * nm_to_svg_pixels;

  @memoized
  double get helix_diameter_svg => helix_diameter_nm * nm_to_svg_pixels;

  @memoized
  double get base_width_svg => rise_per_base_pair * 30.12;

  @memoized
  double get base_height_svg => rise_per_base_pair * 30.12;

  @memoized
  double get distance_between_helices => 2 * helix_radius + inter_helix_gap;

  @memoized
  double get nm_to_svg_pixels => base_width_svg / rise_per_base_pair;

  @memoized
  double get svg_pixels_to_nm => 1.0 / nm_to_svg_pixels;

  bool rise_per_base_pair_is_default() =>
      util.are_close(rise_per_base_pair, constants.default_rise_per_base_pair);

  bool helix_radius_is_default() => util.are_close(helix_radius, constants.default_helix_radius);

  bool bases_per_turn_is_default() => util.are_close(bases_per_turn, constants.default_bases_per_turn);

  bool minor_groove_angle_is_default() =>
      util.are_close(minor_groove_angle, constants.default_minor_groove_angle);

  bool inter_helix_gap_is_default() => util.are_close(inter_helix_gap, constants.default_inter_helix_gap);

  static Geometry from_json(Map<String, dynamic> json_map) {
    double rise_per_base_pair = util.optional_field(
        json_map, constants.rise_per_base_pair_key, constants.default_rise_per_base_pair,
        legacy_keys: constants.legacy_rise_per_base_pair_keys);
    double helix_radius =
        util.optional_field(json_map, constants.helix_radius_key, constants.default_helix_radius);
    double inter_helix_gap =
        util.optional_field(json_map, constants.inter_helix_gap_key, constants.default_inter_helix_gap);
    double bases_per_turn =
        util.optional_field(json_map, constants.bases_per_turn_key, constants.default_bases_per_turn);
    double minor_groove_angle = util.optional_field(
        json_map, constants.minor_groove_angle_key, constants.default_minor_groove_angle,
        legacy_keys: constants.legacy_minor_groove_angle_keys,
        legacy_transformer: (num angle_radians) => util.to_degrees(angle_radians));

    var geometry = Geometry(
      rise_per_base_pair: rise_per_base_pair,
      helix_radius: helix_radius,
      inter_helix_gap: inter_helix_gap,
      bases_per_turn: bases_per_turn,
      minor_groove_angle: minor_groove_angle,
    );

    var unused_fields = util.unused_fields_map(json_map, constants.geometry_keys);
    geometry = geometry.rebuild((b) => b..unused_fields = unused_fields);

    return geometry;
  }

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    var json_map = Map<String, dynamic>();

    if (!rise_per_base_pair_is_default()) {
      json_map[constants.rise_per_base_pair_key] = rise_per_base_pair;
    }
    if (!helix_radius_is_default()) {
      json_map[constants.helix_radius_key] = helix_radius;
    }
    if (!inter_helix_gap_is_default()) {
      json_map[constants.inter_helix_gap_key] = inter_helix_gap;
    }
    if (!bases_per_turn_is_default()) {
      json_map[constants.bases_per_turn_key] = bases_per_turn;
    }
    if (!minor_groove_angle_is_default()) {
      json_map[constants.minor_groove_angle_key] = minor_groove_angle;
    }

    json_map.addAll(unused_fields.toMap());

    return json_map;
  }

  bool is_default() => util.are_all_close([
        rise_per_base_pair,
        helix_radius,
        inter_helix_gap,
        bases_per_turn,
        minor_groove_angle,
      ], [
        constants.default_rise_per_base_pair,
        constants.default_helix_radius,
        constants.default_inter_helix_gap,
        constants.default_bases_per_turn,
        constants.default_minor_groove_angle,
      ]);
}
