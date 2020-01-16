import 'dart:math';

import 'package:built_value/serializer.dart';
import 'package:platform_detect/platform_detect.dart';
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
  Helix._();

  static Serializer<Helix> get serializer => _$helixSerializer;

  factory Helix.from([void Function(HelixBuilder) updates]) = _$Helix;

//  factory Helix([void Function(HelixBuilder) updates]) = _$Helix;

  factory Helix({
    int idx,
    Grid grid,
    int view_order = null,
    GridPosition grid_position = null,
    num rotation = constants.default_helix_rotation,
    int rotation_anchor = constants.default_helix_rotation_anchor,
    int min_offset = 0,
    int max_offset = constants.default_max_offset,
    Position3D position = null,
    Point<num> svg_position = null,
  }) {
    if (view_order == null) {
      view_order = idx;
    }
//    if (grid_position == null) {
//      if (position == null) {
//        grid_position = GridPosition(0, idx);
//      } else if (!grid.is_none()) {
//        grid_position = util.position3d_to_grid(position, grid);
//      }
//    }
    return Helix.from((b) => b
      ..idx = idx
      ..view_order = view_order
      ..grid = grid
      ..grid_position = grid_position?.toBuilder()
      ..position_ = position?.toBuilder()
      ..svg_position_ = svg_position
      ..rotation = rotation
      ..rotation_anchor = rotation_anchor
      ..min_offset = min_offset
      ..max_offset = max_offset);
  }

  /************************ end BuiltValue boilerplate ************************/

  static void _finalizeBuilder(HelixBuilder builder) {
    if (builder._grid_position == null && builder._position_ == null) {
      throw ArgumentError('exactly one of Helix.grid_position and Helix.position can be null, '
          'but both are null.');
    }
    if (builder._grid_position != null && builder._position_ != null) {
      throw ArgumentError('exactly one of Helix.grid_position and Helix.position can be null, '
          'but both are non-null.');
    }
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

  /// SVG position of upper-left corner (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position in Helix as well, but svg_position will always be 2D.
  @nullable
  Point<num> get svg_position_;

  @nullable
  Position3D get position_;

  Position3D get position => position_ != null ? position_ : util.grid_to_position3d(grid_position, grid);

  double get rotation;

  int get rotation_anchor;

  /// 1 plus the maximum allowed offset of Substrand that can be drawn on this Helix. i.e. EXCLUSIVE.
  int get max_offset;

  /// Minimum allowed offset of Substrand that can be drawn on this Helix.
  int get min_offset;

  @nullable
  int get major_tick_distance;

  @nullable
  BuiltList<int> get major_ticks;

  GridPosition default_grid_position() => GridPosition(0, this.idx);

  Point<num> default_svg_position() {
    if (grid != Grid.none) {
      //FIXME: need to know positions of helices above this one in view order to know vertical offset
//      return Point<num>(grid_position.b * constants.BASE_WIDTH_SVG,
//          grid_position.v * constants.DISTANCE_BETWEEN_HELICES_SVG);
      return Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * this.view_order);
    } else if (position != null) {
      var pos3d = position3d();
      // position z is main view x
      // SVG pixels in x direction = p.z in nm * (1/0.34 bp/nm) * (BASE_WIDTH_SVG pixels/bp)
      // SVG pixels in y direction =
      //   p.y in nm * (1/2.5 helix/nm)
      //   * (GridPosition.distance grid_point/helix)
      //   * (DISTANCE_BETWEEN_HELICES_SVG pixels/grid_point)
      //FIXME: need to know positions of helices above this one in view order to know vertical offset
      return util.position3d_to_main_view_svg(pos3d);
    } else {
//      throw AssertionError('cannot have grid_position, position both null and call default_svg_position');
      return Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * this.view_order);
    }
  }

  Position3D default_position() {
    num z = grid_position.b * constants.BASE_WIDTH_SVG;
    Point<num> svg_pos = util.side_view_grid_to_svg(grid_position, grid);
    Position3D position3d = util.svg_side_view_to_position3d(svg_pos).rebuild((b) => b..z = z);
    return position3d;
  }

  bool has_grid_position() => this.grid_position != null;

  /// More like "has *assigned* SVG position"; if not one is calculated from grid_position or position
  bool has_svg_position() => this.svg_position_ != null;

  bool has_position() => this.position_ != null;

//  @override
//  String toString() =>
//      super.toString().replaceFirst(r'helix=[+-]?\d+(\.\d+)?', 'helix=${util.to_degrees(rotation)}');

  /// Gets 3D position (in "SVG coordinates" for the x,y,z) of Helix (offset 0).
  /// If [null], then [grid_position] must be non-[null], and it is auto-calculated from that.
  @memoized
  Point<num> get svg_position {
    if (svg_position_ != null) {
      return svg_position_;
    }
    return default_svg_position();
  }

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

  bool has_major_tick_distance() => this.major_tick_distance != null;

  bool has_major_ticks() => this.major_ticks != null;

  bool has_nondefault_rotation() => (this.rotation - constants.default_helix_rotation).abs() > 0.0001;

  bool has_nondefault_rotation_anchor() => this.rotation_anchor != constants.default_helix_rotation_anchor;

  dynamic to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {};

    if (this.has_grid_position()) {
      json_map[constants.grid_position_key] =
          this.grid_position.to_json_serializable(suppress_indent: suppress_indent);
    }

    if (this.has_position()) {
      json_map[constants.position3d_key] =
          this.position.to_json_serializable(suppress_indent: suppress_indent);
    }

    if (this.has_nondefault_svg_position()) {
      json_map[constants.svg_position_key] = [this.svg_position.x, this.svg_position.y];
    }

    if (this.has_nondefault_rotation()) {
      json_map[constants.rotation_key] = this.rotation;
    }

    if (this.has_nondefault_rotation_anchor()) {
      json_map[constants.rotation_anchor_key] = this.rotation_anchor;
    }

    return suppress_indent ? NoIndent(json_map) : json_map;
  }

  /// Gets "center of base" (middle of square representing base) given helix idx and offset,
  /// depending on whether strand is going forward or not. This is relative to the starting point of
  /// the Helix.
  Point<num> svg_base_pos(int offset, bool forward) {
    num x = constants.BASE_WIDTH_SVG / 2 + offset * constants.BASE_WIDTH_SVG + this.svg_position.x;
    num y = constants.BASE_HEIGHT_SVG / 2 + this.svg_position.y;
    if (!forward) {
      y += 10;
    }
    return Point<num>(x, y);
  }

  // Don't know why but Firefox knows about the SVG translation already so no need to correct for it.
  int svg_x_to_offset(num x) {
    var offset;
//    if (browser.isFirefox) {
//      offset = (x / constants.BASE_WIDTH_SVG).floor();
//    } else {
    offset = ((x - svg_position.x) / constants.BASE_WIDTH_SVG).floor();
//    }
    return offset;
  }

  // Don't know why but Firefox knows about the SVG translation already so no need to correct for it.
  bool svg_y_is_forward(num y) {
    var relative_y = (y - svg_position.y);
    return relative_y < 10;
  }

  bool has_nondefault_svg_position() {
    num eps = 0.00000001;
    num default_x = this.default_svg_position().x;
    num default_y = this.default_svg_position().y;
    num this_x = this.svg_position.x;
    num this_y = this.svg_position.y;
    num diff_x = (this_x - default_x).abs();
    num diff_y = (this_y - default_y).abs();
    return diff_x > eps && diff_y > eps;
  }

  bool has_max_offset() => this.max_offset != null;

  bool has_min_offset() => this.min_offset != null;

  //TODO: if Helix.max_offset key is missing in JSON, it causes an exception when drawing Helix lines in main view

  static HelixBuilder from_json(Map<String, dynamic> json_map) {
    var helix_builder = HelixBuilder();

    if (json_map.containsKey(constants.major_tick_distance_key)) {
      helix_builder.major_tick_distance = json_map[constants.major_tick_distance_key];
    }

    if (json_map.containsKey(constants.major_ticks_key)) {
      helix_builder.major_ticks = ListBuilder<int>(List<int>.from(json_map[constants.major_ticks_key]));
//      helix_builder.major_ticks = List<int>.from(json_map[constants.major_ticks_key]);
    }

    if (json_map.containsKey(constants.grid_position_key)) {
      List<dynamic> gp_list = json_map[constants.grid_position_key];
      if (!(gp_list.length == 2 || gp_list.length == 3)) {
        throw ArgumentError(
            "list of grid_position coordinates must be length 2 or 3 but this is the list: ${gp_list}");
      }
      helix_builder.grid_position = GridPosition.from_list(gp_list).toBuilder();
    }

    if (json_map.containsKey(constants.svg_position_key)) {
      List<dynamic> svg_position_list = json_map[constants.svg_position_key];
      if (svg_position_list.length != 2) {
        throw ArgumentError(
            "svg_position must have exactly two integers but instead it has ${svg_position_list.length}: ${svg_position_list}");
      }
      helix_builder.svg_position_ = Point<num>(svg_position_list[0], svg_position_list[1]);
    }

    if (json_map.containsKey(constants.max_offset_key)) {
      helix_builder.max_offset = json_map[constants.max_offset_key];
    }

    helix_builder.rotation =
        util.get_value_with_default(json_map, constants.rotation_key, constants.default_helix_rotation);
    helix_builder.rotation_anchor = util.get_value_with_default(
        json_map, constants.rotation_anchor_key, constants.default_helix_rotation_anchor);

    Position3D position = util.get_value_with_default(json_map, constants.position3d_key, null,
        transformer: (map) => Position3D.from_json(map));
    helix_builder.position_ = position?.toBuilder();

    return helix_builder;
  }

  /// Transform to apply to an SVG element so that it will appear in the correct position relative to this
  /// Helix.
//  translate() => 'translate(${this.svg_position.x} ${this.svg_position.y})';

  num svg_width() => constants.BASE_WIDTH_SVG * this.num_bases();

  num svg_height() => 2 * constants.BASE_HEIGHT_SVG;

  int num_bases() => this.max_offset - this.min_offset;

//  /// Number of bases between start and end offsets, inclusive, on this [Helix].
//  /// Accounts for substrands with insertions and deletions on [BoundSubstrand]s on this Helix, but not if they
//  /// are inconsistent (on one [BoundSubstrand] but not the other).
//  int num_bases_between(int start, int end) {
//    if (start > end) {
//      int swap = start;
//      start = end;
//      end = swap;
//    }
//
//    List<BoundSubstrand> substrands_intersecting = [];
//    for (var ss in this._substrands) {
//      if (start < ss.end && ss.start <= end) {
//        substrands_intersecting.add(ss);
//      }
//    }
//
//    Set<int> deletions_intersecting = {};
//    Set<Tuple2<int, int>> insertions_intersecting = {};
//    for (var ss in substrands_intersecting) {
//      for (var deletion in ss.deletions) {
//        if (start <= deletion && deletion <= end) {
//          deletions_intersecting.add(deletion);
//        }
//      }
//      for (var insertion in ss.insertions) {
//        if (start <= insertion.item1 && insertion.item1 <= end) {
//          insertions_intersecting.add(insertion);
//        }
//      }
//    }
//
//    int total_insertion_length = 0;
//    for (var insertion in insertions_intersecting) {
//      total_insertion_length += insertion.item2;
//    }
//
//    int dna_length = end - start + 1 - deletions_intersecting.length + total_insertion_length;
//
//    return dna_length;
//  }
//
//  /// in radians
//  double rotation_3p(int offset) {
//    int num_bases;
//    if (this._rotation_anchor < offset) {
//      num_bases = this.num_bases_between(this._rotation_anchor, offset - 1);
//    } else if (this._rotation_anchor > offset) {
//      num_bases = -this.num_bases_between(offset + 1, this._rotation_anchor);
//    } else {
//      num_bases = 0;
//    }
//    num rad = (this._rotation + (2 * pi * num_bases / 10.5)) % (2 * pi);
//    return rad;
//  }
//
//  /// in radians;  3' rotation + 150 degrees
//  double rotation_5p(int offset) => this.rotation_3p(offset) + (2 * pi * 150.0 / 360.0);

}

//class HelicesStore extends Store {
//  List<Helix> _helices;
//
//  List<Helix> get helices => this._helices;
//
//  set helices(List<Helix> new_helices) {
//    this._helices = new_helices;
//    this.build_helices_map();
//  }
//
//  Map<GridPosition, dynamic> _gp_to_helix;
//
//  Map<GridPosition, dynamic> get gp_to_helix => this._gp_to_helix;
//
//  HelicesStore() {
//    this._helices = [];
//    this.build_helices_map();
//    this._handle_actions();
//  }
//
//  build_helices_map() {
//    this._gp_to_helix = {};
//    for (var h in this.helices) {
//      this._gp_to_helix[h.grid_position] = h;
//    }
//  }
//
//  _handle_actions() {
//    this.triggerOnActionV2<SetHelixRotationActionParameters>(Actions.set_helix_rotation, (params) {
//      Helix helix = this.helices[params.idx];
////      helix.rotation = params.rotation;
////      helix.rotation_anchor = params.anchor;
//    });
//  }
//}
