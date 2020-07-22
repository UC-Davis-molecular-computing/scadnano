import 'dart:math';

import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import '../state/design.dart';
import '../state/position3d.dart';
import '../state/unused_fields.dart';

import '../json_serializable.dart';
import '../serializers.dart';
import 'geometry.dart';
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
abstract class Helix with BuiltJsonSerializable, UnusedFields implements Built<Helix, HelixBuilder> {
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

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  factory Helix({
    int idx,
    Grid grid,
    Geometry geometry,
    int view_order = null,
    GridPosition grid_position = null,
    num roll = constants.default_helix_roll,
    num pitch = constants.default_helix_pitch,
    num yaw = constants.default_helix_yaw,
    int min_offset = 0,
    int major_tick_start = null,
    int max_offset = constants.default_max_offset,
    bool invert_yz = false,
    Position3D position = null,
    Point<num> svg_position = null,
  }) {
    if (view_order == null) {
      view_order = idx;
    }
    if (major_tick_start == null) {
      major_tick_start = min_offset;
    }
    return Helix.from((b) => b
      ..idx = idx
      ..view_order = view_order
      ..geometry = geometry?.toBuilder()
      ..grid = grid
      ..grid_position = grid_position?.toBuilder()
      ..position_ = position?.toBuilder()
      ..svg_position_ = svg_position
      ..roll = roll
      ..pitch = pitch
      ..yaw = yaw
      ..invert_yz = invert_yz
      ..min_offset = min_offset
      ..max_offset = max_offset
      ..major_tick_start = major_tick_start
      ..unused_fields.replace({}));
  }

  /// unique identifier of used helix; also index indicating order to show
  /// in main view from top to bottom (unused helices not shown in main view)
  /// by default.
  int get idx;

  // This is inferred from DNADesign.helices_view_order and is here for convenience, but isn't serialized.
  int get view_order;

  Grid get grid;

  Geometry get geometry;

  /// position within square/hex/honeycomb integer grid (side view)
  @nullable
  GridPosition get grid_position;

  /// SVG position of upper-left corner (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position in Helix as well, but svg_position will always be 2D.
  @nullable
  Point<num> get svg_position_;

  Point<num> get svg_position =>
      invert_yz ? (Point<num>(svg_position_.x, -svg_position_.y)) : svg_position_;

  @nullable
  Position3D get position_;

  Position3D get position => position_ ?? util.grid_to_position3d(grid_position, grid);

  /// Helix rotation of the backbone of the forward strand at the helix's minimum base offset. (y-z)
  double get roll;

  /// rotation in plane of main view (x-y)
  double get pitch;

  /// rotation in and out of main view screen (x-z)
  double get yaw;

  /// 1 plus the maximum allowed offset of Substrand that can be drawn on this Helix. i.e. EXCLUSIVE.
  int get max_offset;

  /// Minimum allowed offset of Substrand that can be drawn on this Helix.
  int get min_offset;

  bool get invert_yz;

  // If regular or periodic distances are used, this is the starting offset
  int get major_tick_start;

  // major_tick_distance
  BuiltList<int> get major_tick_periodic_distances;

  int get major_tick_distance =>
      major_tick_periodic_distances.length != 1 ? null : major_tick_periodic_distances.first;

  @nullable
  BuiltList<int> get major_ticks;

  GridPosition default_grid_position() => GridPosition(0, this.idx);

  @memoized
  Position3D get default_position {
    num x = min_offset * geometry.rise_per_base_pair;
    Point<num> svg_pos = util.side_view_grid_to_svg(grid_position, grid, invert_yz);
    Position3D position3d = util.svg_side_view_to_position3d(svg_pos, invert_yz).rebuild((b) => b..x = x);
    return position3d;
  }

  bool has_grid_position() => this.grid_position != null;

  bool has_position() => this.position_ != null;

  /// Gets 3D position (in "SVG coordinates" for the x,y,z) of Helix (offset 0).
  /// If [null], then [grid_position] must be non-[null], and it is auto-calculated from that.
  Position3D position3d() {
    if (position_ != null) {
      return position_;
    }
    return default_position;
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

  bool has_default_roll() => util.are_close(roll, constants.default_helix_roll);

  bool has_default_pitch() => util.are_close(pitch, constants.default_helix_pitch);

  bool has_default_yaw() => util.are_close(yaw, constants.default_helix_yaw);

  bool has_default_major_tick_distance() => major_tick_distance == null;

  bool has_default_major_tick_periodic_distances() => major_tick_periodic_distances.isEmpty;

  bool has_default_major_tick_start() => major_tick_start == min_offset;

  bool has_default_major_ticks() => major_ticks == null;

  bool has_major_tick_distance() => !has_default_major_tick_distance();

  bool has_major_ticks() => !has_default_major_ticks();

  bool has_major_tick_periodic_distances() =>
      major_tick_periodic_distances != null && major_tick_periodic_distances.length >= 2;

  dynamic to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {};

    // if we have major ticks or position, it's harder to read Helix on one line,
    // so don't wrap it in NoIndent, but still wrap longer sub-objects in them
    bool use_no_indent = has_default_major_ticks() && !has_position();

    if (!has_default_roll()) {
      json_map[constants.roll_key] = util.to_int_if_close(roll);
    }

    if (!has_default_pitch()) {
      json_map[constants.pitch_key] = util.to_int_if_close(pitch);
    }

    if (!has_default_yaw()) {
      json_map[constants.yaw_key] = util.to_int_if_close(yaw);
    }

    if (has_grid_position()) {
      var gp = this.grid_position.to_json_serializable(suppress_indent: suppress_indent);
      json_map[constants.grid_position_key] = suppress_indent && !use_no_indent ? NoIndent(gp) : gp;
    }

    if (has_position()) {
      var pos = this.position.to_json_serializable(suppress_indent: suppress_indent);
      json_map[constants.position_key] = suppress_indent && !use_no_indent ? NoIndent(pos) : pos;
    }

    if (!has_default_major_tick_distance()) {
      json_map[constants.major_tick_distance_key] = major_tick_distance;
    }

    if (!has_default_major_tick_start()) {
      json_map[constants.major_tick_start_key] = major_tick_start;
    }

    if (has_major_tick_periodic_distances()) {
      var distances = major_tick_periodic_distances.toList();
      json_map[constants.major_tick_periodic_distances_key] =
          suppress_indent && !use_no_indent ? NoIndent(distances) : distances;
    }

    json_map.addAll(unused_fields.toMap());

    if (!has_default_major_ticks()) {
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
    num x = constants.BASE_WIDTH_SVG / 2.0 + offset * constants.BASE_WIDTH_SVG; // + this.svg_position.x;
    // svg_height is height of whole helix, including both forward and reverse strand
    // must divide by 2 to get height of one strand, then divide by 2 again to go halfway into square
    num y = svg_height() / 4.0 + this.svg_position.y;
    if (!forward) {
      y += 10;
    }
    return Point<num>(x, y);
  }

  int svg_x_to_offset(num x) {
    var offset = ((x - svg_position.x) / constants.BASE_WIDTH_SVG).floor();
    return offset;
  }

  // Don't know why but Firefox knows about the SVG translation already so no need to correct for it.
  bool svg_y_is_forward(num y) {
    var relative_y = (y - svg_position.y).abs();
    return relative_y < 10;
  }

  static HelixBuilder from_json(Map<String, dynamic> json_map) {
    var helix_builder = HelixBuilder();

    helix_builder.unused_fields = util.unused_fields_map(json_map, constants.helix_keys);

    if (json_map.containsKey(constants.major_tick_distance_key)) {
      int major_tick_distance = json_map[constants.major_tick_distance_key];
      helix_builder.major_tick_periodic_distances = ListBuilder<int>([major_tick_distance]);
    }

    if (json_map.containsKey(constants.major_ticks_key)) {
      var major_ticks_json = json_map[constants.major_ticks_key];
      if (major_ticks_json != null) {
        helix_builder.major_ticks = ListBuilder<int>(List<int>.from(major_ticks_json));
      }
    }

    if (json_map.containsKey(constants.major_tick_periodic_distances_key)) {
      var major_tick_periodic_distances_json = json_map[constants.major_tick_periodic_distances_key];
      helix_builder.major_tick_periodic_distances =
          ListBuilder<int>(List<int>.from(major_tick_periodic_distances_json));
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
      var max_offset_json = json_map[constants.max_offset_key];
      if (max_offset_json != null) {
        helix_builder.max_offset = json_map[constants.max_offset_key];
      }
    }

    // XXX: many of these fields are not nullable. But they are allowed to be null in the builder,
    // before we call build(). We communicate to the DNADesign that they need to be populated with
    // defaults by allowing them to be null here. These are for fields where the default requires
    // knowledge of the whole design (e.g., min and max offset are based on offsets of Domains on
    // the helix).
    helix_builder.min_offset = util.get_value_with_null_default(json_map, constants.min_offset_key);
    helix_builder.major_tick_start =
        util.get_value_with_null_default(json_map, constants.major_tick_start_key);
    helix_builder.idx = util.get_value_with_null_default(json_map, constants.idx_on_helix_key);
    helix_builder.roll =
        util.get_value_with_default(json_map, constants.roll_key, constants.default_helix_roll);
    helix_builder.pitch =
        util.get_value_with_default(json_map, constants.pitch_key, constants.default_helix_pitch);
    helix_builder.yaw = util.get_value_with_default(json_map, constants.yaw_key, constants.default_helix_yaw);

    if (json_map.containsKey(constants.major_tick_distance_key) &&
        json_map.containsKey(constants.major_tick_periodic_distances_key)) {
      throw IllegalDNADesignError('helix ${helix_builder.idx ?? ""} has both keys '
          '${constants.major_tick_distance_key} and '
          '${constants.major_tick_periodic_distances_key}. At most one is allow to be specified.');
    }

    Position3D position = Position3D.get_position_from_helix_json_map(json_map);
    helix_builder.position_ = position?.toBuilder();

    return helix_builder;
  }

  num svg_width() => constants.BASE_WIDTH_SVG * this.num_bases();

  num svg_height() => constants.BASE_HEIGHT_SVG * 2; //(invert_yz ? -2 : 2);

  int num_bases() => this.max_offset - this.min_offset;

  /// Calculates full list of major tick marks, in sorted order,
  /// whether using [Design.default_major_tick_distance],
  /// [Helix.major_tick_distance], or [Helix.major_ticks].
  /// They are used in reverse order to determine precedence. (e.g., [Helix.major_ticks]
  /// overrides [Helix.major_tick_distance], which overrides
  /// [Design.default_major_tick_distance].
  List<int> calculate_major_ticks(int default_major_tick_distance) {
    List<int> ticks = [];
    if (has_major_ticks()) {
      var sorted_ticks = major_ticks.toList();
      sorted_ticks.sort();
      ticks = sorted_ticks;
    } else if (has_major_tick_periodic_distances()) {
      int distance_idx = -1;
      int distance = null;
      for (int tick = major_tick_start; tick <= max_offset; tick += distance) {
        distance_idx = (distance_idx + 1) % major_tick_periodic_distances.length;
        distance = major_tick_periodic_distances[distance_idx];
        ticks.add(tick);
      }
    } else {
      int distance = major_tick_distance != null && major_tick_distance > 0
          ? major_tick_distance
          : default_major_tick_distance;
      if (distance > 0) {
        ticks = [for (int tick = major_tick_start; tick <= max_offset; tick += distance) tick];
      }
    }
    return ticks;
  }
}
