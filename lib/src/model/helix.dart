import 'dart:math';

import 'package:built_value/serializer.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:quiver/core.dart' as quiver;
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/model/position3d.dart';

import '../json_serializable.dart';
import '../serializers.dart';
import 'grid.dart';
import 'selectable.dart';
import 'strand.dart';
import '../dispatcher/actions_OLD.dart';
import 'grid_position.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

import 'package:built_value/built_value.dart';

part 'helix.g.dart';

/// Represents a double helix. However, a [Helix] doesn't have to have any [Strand]s on it.
abstract class Helix with BuiltJsonSerializable implements Built<Helix, HelixBuilder> {
  Helix._();

  static Serializer<Helix> get serializer => _$helixSerializer;

  factory Helix([void Function(HelixBuilder) updates]) = _$Helix;

  /// unique identifier of used helix; also index indicating order to show
  /// in main view from top to bottom (unused helices not shown in main view)
  /// by default.
  int get idx;

  /// position within square/hex/honeycomb integer grid (side view)
  GridPosition get grid_position;

  Grid get grid;

  /// SVG position of upper-left corner (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position in Helix as well, but svg_position will always be 2D.
  Point<num> get svg_position;

  @nullable
  Position3D get position;

  double get rotation; //= constants.default_helix_rotation;
  int get rotation_anchor; // = constants.default_helix_rotation_anchor;

  /// 1 plus the maximum allowed offset of Substrand that can be drawn on this Helix.
  int get max_offset;

  /// Minimum allowed offset of Substrand that can be drawn on this Helix.
  int get min_offset;

  @nullable
  int get major_tick_distance;

  @nullable
  BuiltList<int> get major_ticks;

//  @override
//  String toString() =>
//      super.toString().replaceFirst(r'helix=[+-]?\d+(\.\d+)?', 'helix=${util.to_degrees(rotation)}');

  /// Gets 3D position (in "SVG coordinates" for the x,y,z) of Helix (offset 0).
  /// If [null], then [grid_position] must be non-[null], and it is auto-calculated from that.
  Position3D position3d() {
    if (position != null) {
      return position;
    }
    Point<num> svg_pos = util.side_view_grid_to_svg(grid_position, grid);
    num z = grid_position.b * constants.BASE_WIDTH_SVG;
    return Position3D(x: svg_pos.x, y: svg_pos.y, z: z, pitch: 0, roll: 0, yaw: 0);
  }

  /// Calculates x-y angle in degrees, according to position3d(), from this [Helix] to [other].
  num angle_to(Helix other) {
    var pos1 = position3d();
    var pos2 = other.position3d();
    num x = pos2.x - pos1.x;
    num y = pos2.y - pos1.y;
    // need to flip by 180 (by adding pi radians) since we are using SVG "reverse y" coordinates
    num angle_radians = (atan2(x, y) + pi) % (2 * pi);
    return util.to_degrees(angle_radians);
  }

  bool has_major_tick_distance() => this.major_tick_distance != null;

  bool has_major_ticks() => this.major_ticks != null;

  bool has_nondefault_rotation() => (this.rotation - constants.default_helix_rotation).abs() > 0.0001;

  bool has_nondefault_rotation_anchor() => this.rotation_anchor != constants.default_helix_rotation_anchor;

  num get gh => this.grid_position.h;

  num get gv => this.grid_position.v;

  num get gb => this.grid_position.b;

  dynamic to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {};

    if (this.has_grid_position()) {
      json_map[constants.grid_position_key] =
          this.grid_position.to_json_serializable(suppress_indent: suppress_indent);
    }

    if (this.has_nondefault_svg_position()) {
      json_map[constants.svg_position_key] = [this.svg_position.x, this.svg_position.y];
    }

//    if (this.has_max_offset() && this.has_nondefault_max_offset) {
//      json_map[constants.max_offset_key] = this.max_offset;
//    }
//
//    if (this.has_min_offset() && this.has_nondefault_min_offset) {
//      json_map[constants.min_offset_key] = this.min_offset;
//    }

    if (this.has_nondefault_rotation()) {
      json_map[constants.rotation_key] = this.rotation;
    }

    if (this.has_nondefault_rotation_anchor()) {
      json_map[constants.rotation_anchor_key] = this.rotation_anchor;
    }

    return suppress_indent ? NoIndent(json_map) : json_map;
  }

  /// Gets "center of base" (middle of square representing base) given helix idx and offset,
  /// depending on whether strand is going forward or not.
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
    if (browser.isFirefox) {
      offset = (x / constants.BASE_WIDTH_SVG).floor();
    } else {
      offset = ((x - this.svg_position.x) / constants.BASE_WIDTH_SVG).floor();
    }
    return offset;
  }

  // Don't know why but Firefox knows about the SVG translation already so no need to correct for it.
  bool svg_y_is_forward(num y) {
    var relative_y;
    if (browser.isFirefox) {
      relative_y = y;
    } else {
      relative_y = (y - this.svg_position.y);
    }
    return relative_y < 10;
  }

  GridPosition default_grid_position() => GridPosition((gp) => gp
    ..h = 0
    ..v = this.idx
    ..b = 0);

  Point<num> default_svg_position() => Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * this.idx);

  bool has_grid_position() => this.grid_position != null;

  bool has_svg_position() => this.svg_position != null;

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

//  bool has_nondefault_max_offset() {
//    int max_ss_offset = -1;
//    for (var ss in this._substrands) {
//      if (max_ss_offset < ss.end) {
//        max_ss_offset = ss.end;
//      }
//    }
//    return this.max_offset != max_ss_offset;
//  }
//
//  bool has_nondefault_min_offset() {
//    int min_ss_offset = -1;
//    for (var ss in this._substrands) {
//      if (min_ss_offset > ss.start) {
//        min_ss_offset = ss.start;
//      }
//    }
//    return this.min_offset != min_ss_offset;
//  }

  //TODO: if Helix.max_offset key is missing in JSON, it causes an exception when drawing Helix lines
  //  in main view

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
      helix_builder.svg_position = Point<num>(svg_position_list[0], svg_position_list[1]);
    }

    if (json_map.containsKey(constants.max_offset_key)) {
      helix_builder.max_offset = json_map[constants.max_offset_key];
    }

    helix_builder.rotation =
        util.get_value_with_default(json_map, constants.rotation_key, constants.default_helix_rotation);
    helix_builder.rotation_anchor = util.get_value_with_default(
        json_map, constants.rotation_anchor_key, constants.default_helix_rotation_anchor);

    helix_builder.position = util.get_value_with_default(json_map, 'position', null);

    return helix_builder;
  }

  /// Transform to apply to an SVG element so that it will appear in the correct position relative to this
  /// Helix.
  translate() => 'translate(${this.svg_position.x} ${this.svg_position.y})';

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
