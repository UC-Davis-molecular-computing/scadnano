import 'dart:math';

import 'package:platform_detect/platform_detect.dart';
import 'package:quiver/core.dart' as quiver;
import 'package:scadnano/src/json_serializable.dart';
import 'package:tuple/tuple.dart';
import 'package:w_flux/w_flux.dart';

import 'strand.dart';
import '../dispatcher/actions.dart';
import '../constants.dart' as constants;

class HelicesStore extends Store {
  List<Helix> _helices;

  List<Helix> get helices => this._helices;

  set helices(List<Helix> new_helices) {
    this._helices = new_helices;
    this.build_helices_map();
  }

  Map<GridPosition, dynamic> _gp_to_helix;

  Map<GridPosition, dynamic> get gp_to_helix => this._gp_to_helix;

  HelicesStore() {
    this._helices = [];
    this.build_helices_map();
  }

  build_helices_map() {
    this._gp_to_helix = {};
    for (var h in this.helices) {
      this._gp_to_helix[h.grid_position()] = h;
    }
  }

}

enum Grid { square, hex, honeycomb, none }

String grid_to_json(Grid grid) {
  switch (grid) {
    case Grid.square:
      return 'square';
    case Grid.hex:
      return 'hex';
    case Grid.honeycomb:
      return 'honeycomb';
    case Grid.none:
      return 'none';
    default:
      throw UnimplementedError('unrecognized grid: $grid');
  }
}

Grid grid_from_string(String string) {
  switch (string) {
    case 'square':
      return Grid.square;
    case 'hex':
      return Grid.hex;
    case 'honeycomb':
      return Grid.honeycomb;
    case 'none':
      return Grid.none;
    default:
      throw new UnimplementedError('unrecognized grid: $string');
  }
}

/// TODO: document GridPosition class
class GridPosition {
  final int h;
  final int v;
  final int b;

  const GridPosition(this.h, this.v, [this.b]);

  const GridPosition.origin() : this(0, 0, 0);

  const GridPosition.none() : this(-1, -1, -1);

  static const ORIGIN = GridPosition.origin(); //Point<int>(0, 0);
  static const NONE = GridPosition.origin(); //Point<int>(0, 0);

  GridPosition.from_list(List<dynamic> json_list)
      : this(json_list[0], json_list[1], json_list.length == 3 ? json_list[2] : 0);

  List<int> toJson() {
    var list = [
      this.h,
      this.v,
    ];
    if (this.b != 0) {
      list.add(this.b);
    }
    return list;
  }

  @override
//  int get hashCode => quiver.hash3(this.h, this.v, this.b);
  int get hashCode {
    int h = quiver.hash3(this.h, this.v, this.b);
    return h;
  }

  @override
  bool operator ==(other) {
    return this.h == other.h && this.v == other.v && this.b == other.b;
  }

  @override
  String toString() => '(${this.h}, ${this.v}, ${this.b})';
}

//TODO: rename Helix.max_bases to max_offset, add Helix.min_offset, and allow offsets to be negative

/// Represents a double helix. However, a [Helix] doesn't have to have any [Strand]s on it.
class Helix extends Store implements JSONSerializable {
  /// unique identifier of used helix; also index indicating order to show
  /// in main view from top to bottom (unused helices not shown in main view)
  /// by default.
  int _idx = -1;

  /// position within square/hex/honeycomb integer grid (side view)
  GridPosition _grid_position = null;

  /// SVG position of upper-left corner (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position in Helix as well, but svg_position will always be 2D.
  Point<num> _svg_position = null;

  double _rotation = constants.default_helix_rotation;
  int _rotation_anchor = constants.default_helix_rotation_anchor;

  /// 1 plus the maximum allowed offset of Substrand that can be drawn on this Helix.
  int _max_offset = null;

  /// Minimum allowed offset of Substrand that can be drawn on this Helix.
  int _min_offset = null;

  int _major_tick_distance = -1;

  List<int> _major_ticks = null;

  int get major_tick_distance => this._major_tick_distance;

  List<int> get major_ticks => this._major_ticks;

  bool has_major_tick_distance() => this._major_tick_distance >= 0;

  bool has_major_ticks() => this._major_ticks != null;

  get rotation => this._rotation;

  set rotation(double new_rotation) {
    this._rotation = new_rotation;
  }

  bool has_nondefault_rotation() => (this._rotation - constants.default_helix_rotation).abs() > 0.0001;

  get rotation_anchor => this._rotation_anchor;

  set rotation_anchor(int new_rotation_anchor) {
    this._rotation_anchor = new_rotation_anchor;
  }

  bool has_nondefault_rotation_anchor() => this._rotation_anchor != constants.default_helix_rotation_anchor;

  set major_tick_distance(int new_dist) {
    this._major_tick_distance = new_dist;
  }

  set major_ticks(List<int> new_ticks) {
    this._major_ticks = new_ticks;
  }

  num get gh => this._grid_position.h;

  num get gv => this._grid_position.v;

  num get gb => this._grid_position.b;

  GridPosition grid_position() => this._grid_position;

  Point<num> svg_position() => this._svg_position;

  int get max_offset => this._max_offset;

  int get min_offset => this._min_offset == null? 0: this._min_offset;

  List<BoundSubstrand> _substrands = [];

  List<BoundSubstrand> bound_substrands() => this._substrands;

  Helix({grid_position, max_offset=null, min_offset=null}) {
    this._grid_position = grid_position;
    this._max_offset = max_offset;
    this._min_offset = min_offset;

    this._handle_actions();
  }

  _handle_actions() {
    this.triggerOnActionV2<SetHelixRotationActionParameters>(Actions.set_helix_rotation, (params) {
      if (this.idx() == params.idx) {
        this.rotation = params.rotation;
        this.rotation_anchor = params.anchor;
      }
    });
  }


  dynamic to_json_serializable() {
    Map<String, dynamic> json_map = {};

    if (this.has_grid_position()) {
      json_map[constants.grid_position_key] = this._grid_position;
    }

    if (this.has_nondefault_svg_position()) {
      json_map[constants.svg_position_key] = [this._svg_position.x, this._svg_position.y];
    }

    if (this.has_max_offset() && this.has_nondefault_max_offset()) {
      json_map[constants.max_offset_key] = this.max_offset;
    }

    if (this.has_min_offset() && this.has_nondefault_min_offset()) {
      json_map[constants.min_offset_key] = this.min_offset;
    }

    if (this.has_nondefault_rotation()) {
      json_map[constants.rotation_key] = this._rotation;
    }

    return NoIndent(json_map);
  }

  /// Return [Substrand]s at [offset].
  List<BoundSubstrand> substrands_at(int offset) {
    List<BoundSubstrand> substrands_at_offset = [
      for (var substrand in this._substrands) if (substrand.contains_offset(offset)) substrand
    ];
    return substrands_at_offset;
  }

  /// Gets "center of base" (middle of square representing base) given helix idx and offset,
  /// depending on whether strand is going forward or not.
  Point<num> svg_base_pos(int offset, bool forward) {
    num x = constants.BASE_WIDTH_SVG / 2 + offset * constants.BASE_WIDTH_SVG + this._svg_position.x;
    num y = constants.BASE_HEIGHT_SVG / 2 + this._svg_position.y;
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
      offset = ((x - this._svg_position.x) / constants.BASE_WIDTH_SVG).floor();
    }
    return offset;
  }

  // Don't know why but Firefox knows about the SVG translation already so no need to correct for it.
  bool svg_y_is_forward(num y) {
    var relative_y;
    if (browser.isFirefox) {
      relative_y = y;
    } else {
      relative_y = (y - this._svg_position.y);
    }
    return relative_y < 10;
  }

  GridPosition default_grid_position() {
    return GridPosition(0, this._idx);
  }

  Point<num> default_svg_position() {
    return Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * this._idx);
  }

  int idx() => this._idx;

  set_idx(int new_idx) {
    this._idx = new_idx;
    this._svg_position = this.default_svg_position();
  }

  int get hashCode =>
      quiver.hash4(this._idx, this._grid_position.h, this._grid_position.v, this._grid_position.b);

  operator ==(other) {
    if (other is Helix) {
      var other_helix = other;
      return this._idx == other_helix._idx && this._grid_position == other_helix._grid_position;
    } else {
      return false;
    }
  }

  String toString() => "Helix(idx=$_idx, gh=$gh, gv=$gv, gb=$gb, max_offset=$max_offset})";

  bool has_substrands() => this._substrands.isNotEmpty;

  bool has_grid_position() => this._grid_position != null;

  bool has_svg_position() => this._svg_position != null;

  bool has_nondefault_svg_position() {
    num eps = 0.00000001;
    num default_x = this.default_svg_position().x;
    num default_y = this.default_svg_position().y;
    num this_x = this._svg_position.x;
    num this_y = this._svg_position.y;
    num diff_x = (this_x - default_x).abs();
    num diff_y = (this_y - default_y).abs();
    return diff_x > eps && diff_y > eps;
  }

  bool has_max_offset() => this._max_offset != null;

  bool has_min_offset() => this._min_offset != null;

  bool has_nondefault_max_offset() {
    int max_ss_offset = -1;
    for (var ss in this._substrands) {
      if (max_ss_offset < ss.end) {
        max_ss_offset = ss.end;
      }
    }
    return this.max_offset != max_ss_offset;
  }

  bool has_nondefault_min_offset() {
    int min_ss_offset = -1;
    for (var ss in this._substrands) {
      if (min_ss_offset > ss.start) {
        min_ss_offset = ss.start;
      }
    }
    return this.min_offset != min_ss_offset;
  }


  //TODO: if Helix.max_offset key is missing in JSON, it causes an exception when drawing Helix lines
  //  in main view

  Helix.from_json(Map<String, dynamic> json_map) {
    if (json_map.containsKey(constants.major_tick_distance_key)) {
      this._major_tick_distance = json_map[constants.major_tick_distance_key];
    }

    if (json_map.containsKey(constants.major_ticks_key)) {
      this._major_ticks = List<int>.from(json_map[constants.major_ticks_key]);
    }

    if (json_map.containsKey(constants.grid_position_key)) {
      List<dynamic> gp_list = json_map[constants.grid_position_key];
      if (!(gp_list.length == 2 || gp_list.length == 3)) {
        throw ArgumentError(
            "list of grid_position coordinates must be length 2 or 3 but this is the list: ${gp_list}");
      }
      this._grid_position = GridPosition.from_list(gp_list);
    }

    if (json_map.containsKey(constants.svg_position_key)) {
      List<dynamic> svg_position_list = json_map[constants.svg_position_key];
      if (svg_position_list.length != 2) {
        throw ArgumentError(
            "svg_position must have exactly two integers but instead it has ${svg_position_list.length}: ${svg_position_list}");
      }
      this._svg_position = Point<num>(svg_position_list[0], svg_position_list[1]);
    }

    if (json_map.containsKey(constants.max_offset_key)) {
      this._max_offset = json_map[constants.max_offset_key];
    }

    this._handle_actions();
  }

  set_default_grid_position() {
    this._grid_position = this.default_grid_position();
  }

  set_default_svg_position() {
    this._svg_position = this.default_svg_position();
  }

  set_max_bases_directly(int max_bases) {
    this._max_offset = max_bases;
  }

  /// Transform to apply to an SVG element so that it will appear in the correct position relative to this
  /// Helix.
  translate() => 'translate(${this.svg_position().x} ${this.svg_position().y})';

  num svg_width() => constants.BASE_WIDTH_SVG * this.num_bases();

  num svg_height() => 2 * constants.BASE_HEIGHT_SVG;

  /// Number of bases between start and end offsets, inclusive, on this [Helix].
  /// Accounts for substrands with insertions and deletions on [BoundSubstrand]s on this Helix, but not if they
  /// are inconsistent (on one [BoundSubstrand] but not the other).
  int num_bases_between(int start, int end) {
    if (start > end) {
      int swap = start;
      start = end;
      end = swap;
    }

    List<BoundSubstrand> substrands_intersecting = [];
    for (var ss in this._substrands) {
      if (start < ss.end && ss.start <= end) {
        substrands_intersecting.add(ss);
      }
    }

    Set<int> deletions_intersecting = {};
    Set<Tuple2<int, int>> insertions_intersecting = {};
    for (var ss in substrands_intersecting) {
      for (var deletion in ss.deletions) {
        if (start <= deletion && deletion <= end) {
          deletions_intersecting.add(deletion);
        }
      }
      for (var insertion in ss.insertions) {
        if (start <= insertion.item1 && insertion.item1 <= end) {
          insertions_intersecting.add(insertion);
        }
      }
    }

    int total_insertion_length = 0;
    for (var insertion in insertions_intersecting) {
      total_insertion_length += insertion.item2;
    }

    int dna_length = end - start + 1 - deletions_intersecting.length + total_insertion_length;

    return dna_length;
  }

  /// in radians
  double rotation_3p(int offset) {
    int num_bases;
    if (this._rotation_anchor < offset) {
      num_bases = this.num_bases_between(this._rotation_anchor, offset - 1);
    } else if (this._rotation_anchor > offset) {
      num_bases = -this.num_bases_between(offset + 1, this._rotation_anchor);
    } else {
      num_bases = 0;
    }
    return (this._rotation + (2 * pi * num_bases / 10.5)) % (2 * pi);
  }

  /// in radians;  3' rotation + 150 degrees
  double rotation_5p(int offset) => this.rotation_3p(offset) + (150.0 / 360.0 * 2 * pi);

  int num_bases() => this.max_offset - this.min_offset;

//  Helix.from_js_object(JsObject js_obj) {
//    this._idx = js_obj[constants.idx_key];
//
//    if (js_obj.hasProperty(constants.grid_position_key)) {
//      List<dynamic> gp_list = js_obj[constants.grid_position_key];
//      if (!(gp_list.length == 2 || gp_list.length == 3)) {
//        throw ArgumentError(
//            "list of grid_position coordinates must be length 2 or 3 but this is the list: ${gp_list}");
//      }
//      this._grid_position = GridPosition.from_list(gp_list);
//    }
//
//    if (js_obj.hasProperty(constants.svg_position_key)) {
//      List<dynamic> svg_position_list = js_obj[constants.svg_position_key];
//      if (svg_position_list.length != 2) {
//        throw ArgumentError(
//            "svg_position must have exactly two integers but instead it has ${svg_position_list.length}: ${svg_position_list}");
//      }
//      this._svg_position = Point<int>(svg_position_list[0], svg_position_list[1]);
//    } else {
//      this._svg_position = this.default_svg_position();
//    }
//
//    this._max_bases = js_obj[constants.max_bases_key];
//  }
}
