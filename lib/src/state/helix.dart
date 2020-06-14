import 'dart:math';

import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/position3d.dart';

import '../json_serializable.dart';
import '../serializers.dart';
import 'grid.dart';
import 'strand.dart';
import 'grid_position.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

import 'package:built_value/built_value.dart';

part 'helix.g.dart';

// "Address" of a base; (helix, offset, direction)
abstract class Address with BuiltJsonSerializable implements Built<Address, AddressBuilder> {
  factory Address({int helix_idx, int offset, bool forward}) = _$Address._;

  factory Address.from([void Function(AddressBuilder) updates]) = _$Address;

  Address._();

  static Serializer<Address> get serializer => _$addressSerializer;

  /************************ end BuiltValue boilerplate ************************/

  int get helix_idx;

  int get offset;

  bool get forward;
}

/// Represents a double helix. However, a [Helix] doesn't have to have any [Strand]s on it.
abstract class Helix with BuiltJsonSerializable implements Built<Helix, HelixBuilder> {
  Helix._() {
    if (grid_position == null && position_ == null) {
      throw ArgumentError('exactly one of Helix.grid_position and Helix.position should be null, '
          'but both are null.');
    }
    if (grid_position != null && position_ != null) {
      throw ArgumentError('exactly one of Helix.grid_position and Helix.position should be null, '
          'but both are non-null.');
    }
  }

  static Serializer<Helix> get serializer => _$helixSerializer;

  factory Helix.from([void Function(HelixBuilder) updates]) = _$Helix;

  /************************ end BuiltValue boilerplate ************************/

  factory Helix({
    int idx,
    Grid grid,
    int view_order = null,
    GridPosition grid_position = null,
    num roll = constants.default_helix_roll,
    int min_offset = 0,
    int max_offset = constants.default_max_offset,
    Position3D position = null,
    Point<num> svg_position = null,
  }) {
    if (view_order == null) {
      view_order = idx;
    }
    return Helix.from((b) => b
      ..idx = idx
      ..view_order = view_order
      ..grid = grid
      ..grid_position = grid_position?.toBuilder()
      ..position_ = position?.toBuilder()
      ..svg_position = svg_position
      ..roll = roll
      ..min_offset = min_offset
      ..max_offset = max_offset
      ..unused_fields = MapBuilder<String, Object>({}));
  }

  /// unique identifier of used helix; also index indicating order to show
  /// in main view from top to bottom (unused helices not shown in main view)
  /// by default.
  int get idx;

  // This is inferred from DNADesign.helices_view_order and is here for convenience, but isn't serialized.
  int get view_order;

  Grid get grid;

  /// position within square/hex/honeycomb integer grid (side view)
  @nullable
  GridPosition get grid_position;

  @memoized
  int get hashCode;

  /// SVG position of upper-left corner (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position in Helix as well, but svg_position will always be 2D.
  @nullable
  Point<num> get svg_position;

  @nullable
  Position3D get position_;

  Position3D get position => position_ ?? util.grid_to_position3d(grid_position, grid);

  /// Helix rotation of the backbone of the forward strand at the helix's minimum base offset.
  double get roll;

  /// 1 plus the maximum allowed offset of Substrand that can be drawn on this Helix. i.e. EXCLUSIVE.
  int get max_offset;

  /// Minimum allowed offset of Substrand that can be drawn on this Helix.
  int get min_offset;

  @nullable
  int get major_tick_distance;

  @nullable
  BuiltList<int> get major_ticks;

  BuiltMap<String, Object> get unused_fields;

  GridPosition default_grid_position() => GridPosition(0, this.idx);

//  Point<num> calculate_svg_position_from_position() {
//    if (grid != Grid.none) {
//      //FIXME: need to know positions of helices above this one in view order to know vertical offset
////      return Point<num>(grid_position.b * constants.BASE_WIDTH_SVG,
////          grid_position.v * constants.DISTANCE_BETWEEN_HELICES_SVG);
//      return Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * this.view_order);
//    } else if (position != null) {
//      var pos3d = position3d();
//      // position z is main view x
//      // SVG pixels in x direction = p.z in nm * (1/0.34 bp/nm) * (BASE_WIDTH_SVG pixels/bp)
//      // SVG pixels in y direction =
//      //   p.y in nm * (1/2.5 helix/nm)
//      //   * (GridPosition.distance grid_point/helix)
//      //   * (DISTANCE_BETWEEN_HELICES_SVG pixels/grid_point)
//      //FIXME: need to know positions of helices above this one in view order to know vertical offset
//      return util.position3d_to_main_view_svg(pos3d);
//    } else {
////      throw AssertionError('cannot have grid_position, position both null and call default_svg_position');
//      return Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * this.view_order);
//    }
//  }

  //TODO: should this be memoized?
  Position3D default_position() {
    num x = min_offset * constants.BASE_WIDTH_SVG;
    Point<num> svg_pos = util.side_view_grid_to_svg(grid_position, grid);
    Position3D position3d = util.svg_side_view_to_position3d(svg_pos).rebuild((b) => b..x = x);
    return position3d;
  }

  bool has_grid_position() => this.grid_position != null;

  /// More like "has *assigned* SVG position"; if not one is calculated from grid_position or position
//  bool has_svg_position() => this.svg_position_ != null;

  bool has_position() => this.position_ != null;

//  @override
//  String toString() =>
//      super.toString().replaceFirst(r'helix=[+-]?\d+(\.\d+)?', 'helix=${util.to_degrees(rotation)}');

//  @memoized
//  Point<num> get svg_position => svg_position_ ?? calculate_svg_position_from_position();

  /// Gets 3D position (in "SVG coordinates" for the x,y,z) of Helix (offset 0).
  /// If [null], then [grid_position] must be non-[null], and it is auto-calculated from that.
  Position3D position3d() {
    if (position_ != null) {
      return position_;
    }
    return default_position();
  }

  /// Calculates x-y angle in degrees, according to position3d(), from this [Helix] to [other].
  num angle_to(Helix other) {
    var pos1 = position3d();
    var pos2 = other.position3d();
    num x = pos2.x - pos1.x;
    num y = pos2.y - pos1.y;
    num angle_radians = (atan2(x, -y)) % (2 * pi); // using SVG "reverse y" coordinates
    return util.to_degrees(angle_radians);
  }

  bool has_major_tick_distance() => major_tick_distance != null;

  bool has_major_ticks() => major_ticks != null;

  bool has_nondefault_roll() => (roll - constants.default_helix_roll).abs() > 0.0001;

  bool has_nondefault_major_tick_distance() => major_tick_distance != null;

  bool has_nondefault_major_ticks() => major_ticks != null;

  dynamic to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {};

    // if we have major ticks or position, it's harder to read Helix on one line,
    // so don't wrap it in NoIndent, but still wrap longer sub-objects in them
    bool use_no_indent = !(has_nondefault_major_ticks() || has_position());

    if (has_nondefault_roll()) {
      // round if close to an integer
      num roll_rounded = (roll - roll.round()) < 0.0000001 ? roll.round() : roll;
      json_map[constants.roll_key] = roll_rounded;
    }

    if (has_grid_position()) {
      var gp = this.grid_position.to_json_serializable(suppress_indent: suppress_indent);
      json_map[constants.grid_position_key] = suppress_indent && !use_no_indent ? NoIndent(gp) : gp;
    }

    if (has_position()) {
      var pos = this.position.to_json_serializable(suppress_indent: suppress_indent);
      json_map[constants.position_key] = suppress_indent && !use_no_indent ? NoIndent(pos) : pos;
    }

    if (has_nondefault_major_tick_distance()) {
      json_map[constants.major_tick_distance_key] = major_tick_distance;
    }

    json_map.addAll(unused_fields.toMap());

    if (has_nondefault_major_ticks()) {
      var ticks = this.major_ticks.toList();
      json_map[constants.major_ticks_key] = suppress_indent && !use_no_indent ? NoIndent(ticks) : ticks;
    }

    json_map[constants.idx_on_helix_key] = idx;

    return suppress_indent && use_no_indent ? NoIndent(json_map) : json_map;
  }

  /// Gets main view SVG position of "center of base" (middle of square representing base)
  /// given helix idx and offset,  depending on whether strand is going forward or not.
  /// This is relative to the starting point of the Helix.
  Point<num> svg_base_pos(int offset, bool forward) {
    num x = constants.BASE_WIDTH_SVG / 2 + offset * constants.BASE_WIDTH_SVG;
    num y = constants.BASE_HEIGHT_SVG / 2 + this.svg_position.y;
    if (!forward) {
      y += 10;
    }
    return Point<num>(x, y);
  }

  int svg_x_to_offset(num x) {
    var offset = (x / constants.BASE_WIDTH_SVG).floor();
    return offset;
  }

  // Don't know why but Firefox knows about the SVG translation already so no need to correct for it.
  bool svg_y_is_forward(num y) {
    var relative_y = (y - svg_position.y);
    return relative_y < 10;
  }

  bool has_max_offset() => this.max_offset != null;

  bool has_min_offset() => this.min_offset != null;

  //TODO: if Helix.max_offset key is missing in JSON, it causes an exception when drawing Helix lines in main view

  static HelixBuilder from_json(Map<String, dynamic> json_map) {
    var helix_builder = HelixBuilder();

    helix_builder.unused_fields = util.unused_fields_map(json_map, constants.helix_keys);

    if (json_map.containsKey(constants.major_tick_distance_key)) {
      helix_builder.major_tick_distance = json_map[constants.major_tick_distance_key];
    }

    if (json_map.containsKey(constants.major_ticks_key)) {
      helix_builder.major_ticks = ListBuilder<int>(List<int>.from(json_map[constants.major_ticks_key]));
    }

    if (json_map.containsKey(constants.grid_position_key)) {
      List<dynamic> gp_list = json_map[constants.grid_position_key];
      if (!(gp_list.length == 2 || gp_list.length == 3)) {
        throw ArgumentError(
            "list of grid_position coordinates must be length 2 or 3 but this is the list: ${gp_list}");
      }
      helix_builder.grid_position = GridPosition.from_list(gp_list).toBuilder();
    }

    if (json_map.containsKey(constants.max_offset_key)) {
      helix_builder.max_offset = json_map[constants.max_offset_key];
    }

    if (json_map.containsKey(constants.min_offset_key)) {
      helix_builder.min_offset = json_map[constants.min_offset_key];
    }

    if (json_map.containsKey(constants.idx_on_helix_key)) {
      helix_builder.idx = json_map[constants.idx_on_helix_key];
    }

    helix_builder.roll =
        util.get_value_with_default(json_map, constants.roll_key, constants.default_helix_roll);

    Position3D position = Position3D.get_position_from_helix_json_map(json_map);
    helix_builder.position_ = position?.toBuilder();

    return helix_builder;
  }

  num svg_width() => constants.BASE_WIDTH_SVG * this.num_bases();

  num svg_height() => 2 * constants.BASE_HEIGHT_SVG;

  int num_bases() => this.max_offset - this.min_offset;

  /// Calculates full list of major tick marks, whether using [DNADesign.default_major_tick_distance],
  /// [Helix.major_tick_distance], or [Helix.major_ticks].
  /// They are used in reverse order to determine precedence. (e.g., [Helix.major_ticks]
  /// overrides [Helix.major_tick_distance], which overrides
  /// [DNADesign.default_major_tick_distance].
  List<int> calculate_major_ticks(int default_major_tick_distance) {
    if (major_ticks != null) {
      return major_ticks.toList();
    }
    int distance = major_tick_distance != null && major_tick_distance > 0
        ? major_tick_distance
        : default_major_tick_distance;
    return [for (int t = min_offset; t <= max_offset; t += distance) t];
  }

}

