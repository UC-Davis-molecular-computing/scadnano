import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:color/color.dart';
import 'package:tuple/tuple.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' as quiver;

//TODO: allow deletions and insertions on only one strand, but default option for user is to put
// on both strands if both are bound, and to add to new strand when drawn bound to an existing
// strand with an insertion or deletion; alternately... change model to associate deletions
// and insertions to a helix position rather than to a substrand

const String CURRENT_VERSION = "0.0.1";

const int BASE_WIDTH_SVG = 10;
const int BASE_HEIGHT_SVG = 10;

/// DISTANCE_BETWEEN_HELICES_SVG is set to (BASE_WIDTH_SVG * 2.5/0.34) based on the following calculation,
/// to attempt to make the DNA appear to scale in 2D drawings:
/// The width of one base pair of double-stranded DNA bp is 0.34 nm.
/// In a DNA origami, AFM images estimate that the average distance between adjacent double helices is 2.5 nm.
/// (A DNA double-helix is only 2 nm wide, but the helices electrostatically repel each other so the spacing
/// in a DNA origami or an other DNA nanostructure with many parallel DNA helices---e.g., single-stranded tile
/// lattices---is larger than 2 nm.)
/// Thus the distance between the helices is 2.5/0.34 ~ 7.5 times the width of a single DNA base.
final double DISTANCE_BETWEEN_HELICES_SVG = (BASE_WIDTH_SVG * 2.5 / 0.34);

/// Represents parts of the Model to serialize
class DNADesign {
  //TODO: add version number (e.g., "0.0.2") to model and store in JSON

  String version = CURRENT_VERSION;

  Grid grid;

  int major_tick_distance;

  /// all helices in model
  List<Helix> helices;

  /// all strands in model
  List<Strand> strands;

  // optimized implementation detail; not serialized
  // optimization so we can quickly look up a helix given its index. It is
  // maintained in sorted order, so that used_helices[helix.idx] == helix.
  List<Helix> used_helices;

  //"private" constructor; meta package will warn if it is used outside testing
  @visibleForTesting
  DNADesign.internal();

  DNADesign.default_design({int num_helices_x = 10, int num_helices_y = 10}) {
    this.grid = Grid.square;
    this.major_tick_distance = 8;
    this.build_unused_helices(num_helices_x, num_helices_y);
    this.strands = [];
  }

  build_unused_helices(int num_helices_x, int num_helices_y) {
    this.helices = [];
    for (int gx = 0; gx < num_helices_x; gx++) {
      for (int gy = 0; gy < num_helices_y; gy++) {
        var grid_pos = Point<int>(gx, gy);
        this.helices.add(Helix(idx: -1, grid_position: grid_pos));
      }
    }
    // should be unnecessary if model.helices is empty
    this.build_used_helices();
  }

  factory DNADesign.dna_design_with_used_helices(int numX, int numY, int num_used, int bases_per_helix) {
    DNADesign design = DNADesign.internal();

    design.grid = Grid.square;
    design.major_tick_distance = 8;

    design.build_unused_helices(numX, numY);

    int idx_used = 0;
    for (int gx = 0; gx < numX; gx++) {
      for (int gy = 0; gy < numY; gy++) {
        var grid_pos = Point<int>(gx, gy);
        design.helices.add(Helix(idx: idx_used, grid_position: grid_pos, max_bases: bases_per_helix));
        idx_used++;
        if (idx_used == num_used) {
          design.build_used_helices();
          return design;
        }
      }
    }

    design.build_used_helices();
    return design;
  }

  /// max number of bases allowed on any Helix in the Model
  int max_bases() {
    int ret = 0;
    for (var helix in this.helices) {
      if (ret < helix.max_bases) {
        ret = helix.max_bases;
      }
    }
    return ret;
  }

  /// This exact method name is required for Dart to know how to encode as JSON.
  Map<String, dynamic> toJson() {
    return {
      'version': this.version,
      'grid': grid_to_json(this.grid),
      'major_tick_distance': this.major_tick_distance,
      'helices': this.helices,
      'strands': this.strands,
    };
  }

  DNADesign.from_json(Map<String, dynamic> parsed_json) {
//    this.menu_view_ui_model.loaded_filename = filename;
    if (parsed_json.containsKey('version')) {
      this.version = parsed_json[version];
    } else {
      this.version = "0.0.1";
    }
    this.grid = grid_from_string(parsed_json['grid']);
    this.major_tick_distance = parsed_json['major_tick_distance'];

    this.helices = [];
    List<dynamic> deserialized_helices_list = parsed_json['helices'];
    for (var helix_json in deserialized_helices_list) {
      Helix helix = Helix.fromJson(helix_json);
      this.helices.add(helix);
    }
    this.build_used_helices();

    this.strands = [];
    List<dynamic> deserialized_strand_list = parsed_json['strands'];
    for (var strand_json in deserialized_strand_list) {
      Strand strand = Strand.fromJson(strand_json);
      this.strands.add(strand);
    }
  }

  String toString() => """DNADesign(grid=$grid, major_tick_distance=$major_tick_distance, 
  helices=$helices, 
  strands=$strands)""";

  /// Build the list used_helices from helicesMap.
  build_used_helices() {
    this.used_helices = [];
    for (Helix helix in this.helices) {
      if (helix.used) {
        this.used_helices.add(helix);
      }
    }
    this.used_helices.sort((h1, h2) => h1._idx - h2._idx);
  }
}

class Model {
  DNADesign dna_design;

  MenuViewUIModel menu_view_ui_model = MenuViewUIModel();
  MainViewUIModel main_view_ui_model = MainViewUIModel();
  SideViewUIModel side_view_ui_model = SideViewUIModel();

  /// Save button is enabled iff this is true
  bool changed_since_last_save = false;

  /// disabling this will make it easier to navigate since less SVG needs be rendered
  bool show_dna = true;

  //"private" constructor; meta package will warn if it is used outside testing
  @visibleForTesting
  Model.internal();

  Model.default_model({int num_helices_x = 10, int num_helices_y = 10}) {
    this.dna_design = DNADesign.default_design(num_helices_x: num_helices_x, num_helices_y: num_helices_y);
  }

  /// Used with from_url
  Model.empty();

  static Future<Model> from_url(String url) async {
    Model model = Model.empty();
    var dna_design = await _dna_design_from_url(url);
    model.dna_design = dna_design;
    return model;
  }

  static Future<DNADesign> _dna_design_from_url(String url) async {
    return await HttpRequest.getString(url).then((content) {
      Map<String, dynamic> parsed_json = jsonDecode(content);
      var dna_design = DNADesign.from_json(parsed_json);
      return dna_design;
    });
  }

  /// This exact method name is required for Dart to know how to encode as JSON.
  Map<String, dynamic> toJson() {
    return this.dna_design.toJson();
  }
}

abstract class Action {
  /// Apply this action to model and return the resulting model.
  /// This can mutate the model in place or create a new one, but the resulting
  /// model should be returned in either case.
  /// WARNING: this should not be called directly.
  /// Instead, call app.send_action(the_action);, which maintains
  /// a stack of Actions for undo/redo and always applies to app.model.
  Model apply(Model model);

  /// Get the Action that, if applied to the model, undoes this Action.
  Action reverse();
}

enum Grid { square, hex }

String grid_to_json(Grid grid) {
  switch (grid) {
    case Grid.square:
      return 'square';
    case Grid.hex:
      return 'hex';
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
    default:
      throw new UnimplementedError('unrecognized grid: $string');
  }
}

enum Direction { left, right }

direction_to_json(Direction direction) {
  switch (direction) {
    case Direction.left:
      return 'left';
    case Direction.right:
      return 'right';
    default:
      throw UnimplementedError('unrecognized direction: $direction');
  }
}

Direction direction_from_string(String s) {
  switch (s) {
    case 'left':
      return Direction.left;
    case 'right':
      return Direction.right;
    default:
      throw new UnimplementedError('unrecognized direction: $s');
  }
}

enum ViewPanel { side_view, main_view }

/// Represents a used helix (as opposed to the circles drawn in the side
/// view initially, which are unused helices). However, a "used" helix doesn't
/// have to have any strands on it.
class Helix {
  /// unique identifier of used helix; also index indicating order to show
  /// in main view from top to bottom (unused helices not shown in main view)
  /// by default. This default positioning can be overridden by setting the position field.
  int _idx = null;

  /// If false, this helix has idx = null and appears only
  /// in the side view, not the main view. If true, it appears in the main
  /// view and has a positive integer value idx, though it may
  /// not actually have any Substrand's on it.
  bool used = false;

  /// position within square/hex integer grid (side view)
  final Point<int> grid_position;

  /// SVG position of upper-left corner (main view)
  /// This is only 2D. In the future we'll support an optional third z-coordinate
  /// (assumed by default to be 0) for drawing in a 3D view. In the 2D SVG view
  /// the z-coordinate will be ignored.
  Point<num> position;

  /// Maximum length (in bases) of Substrand that can be drawn on this Helix.
  int max_bases;

  Helix({int idx, this.grid_position, this.max_bases = 128}) {
    this._idx = idx;
    this.position = default_position();
    if (this._idx >= 0) {
      this.used = true;
    }
  }

  /// Gets "center of base" (middle of square representing base) given helix idx and offset.
  static Point<num> svg_base_pos(int helix_idx, int offset, Direction direction) {
    num x = 5 + offset * 10;
    num y = 5 + DISTANCE_BETWEEN_HELICES_SVG * helix_idx;
    if (direction == Direction.left) {
      y += 10;
    }
    return Point<num>(x, y);
  }

  Point<num> default_position() {
    return Point<num>(0, DISTANCE_BETWEEN_HELICES_SVG * _idx);
  }

  int get idx => this._idx;

  set idx(int new_idx) {
    this._idx = new_idx;
    this.position = default_position();
    this.used = true;
  }

  num get gx => grid_position.x;

  num get gy => grid_position.y;

  int get hashCode => quiver.hash3(this._idx, this.grid_position.x, this.grid_position.y);

  operator ==(other) {
    if (other is Helix) {
      var other_helix = other;
      return this._idx == other_helix._idx && this.grid_position == other_helix.grid_position;
    } else {
      return false;
    }
  }

  String toString() {
    return "Helix(idx=$_idx, gx=$gx, gy=$gy, used=$used, max_bases=$max_bases})";
  }

  Map<String, dynamic> toJson() => {
        'idx': this._idx,
        'grid_position': [this.grid_position.x, this.grid_position.y],
        'max_bases': this.max_bases,
      };

  Helix.fromJson(Map<String, dynamic> parsedJson)
      : this(
            idx: get_value(parsedJson, 'idx'),
            grid_position: Point<int>(
                get_value(parsedJson, 'grid_position')[0], get_value(parsedJson, 'grid_position')[1]),
            max_bases: get_value(parsedJson, 'max_bases'));
}

class Strand {
  /// Is "id" instead of "idx" because they may not be indices 0...len-1 in
  /// case some strands are deleted.
  Color color = RgbColor.name('blue');
  String dna_sequence = null;
  List<Substrand> substrands = [];

  Strand();

//  int get hashCode => quiver.hashObjects(this.substrands);
//
//  bool operator ==(other) =>
//      IterableEquality().equals(this.substrands, other.substrands);

  int get length {
    int num = 0;
    for (var substrand in substrands) {
      num += substrand.length;
    }
    return num;
  }

  Map<String, dynamic> toJson() => {
        // need to use List.from because List.map returns Iterable, not List
        'substrands': List<dynamic>.from(this.substrands.map((substrand) => substrand.toJson())),
        'color': this.color.toRgbColor().toMap(),
        'dna_sequence': this.dna_sequence
      };

  Strand.fromJson(Map<String, dynamic> parsed_json) {
    this.color = parseJsonColor(get_value(parsed_json, 'color'));
    // need to use List.from because List.map returns Iterable, not List
    this.substrands = List<Substrand>.from(
        get_value(parsed_json, 'substrands').map((substrandJson) => Substrand.fromJson(substrandJson)));
    for (var substrand in this.substrands) {
      substrand._strand = this;
    }
    if (parsed_json.containsKey('dna_sequence')) {
      this.dna_sequence = parsed_json['dna_sequence'];
    } else {
      this.dna_sequence = null;
    }
  }
}

Color parseJsonColor(Map parsedJsonMap) {
  int r = parsedJsonMap['r'];
  int g = parsedJsonMap['g'];
  int b = parsedJsonMap['b'];
  return RgbColor(r, g, b);
}

class Substrand {
  int helix_idx = -1;
  Direction direction = Direction.left;
  int start = null;
  int end = null;
  List<int> deletions = [];
  List<Tuple2<int, int>> insertions = []; // elt: Pair(offset, num insertions)

//  int get hashCode =>
//      quiver.hash4(this.helix_idx, this.direction, this.start, this.end);
//
//  bool operator ==(other) =>
//      (this.helix_idx == other.helix_idx
//          && this.direction == other.direction
//          && this.start == other.start
//          && this.end == other.end);

  /// 5' end, INCLUSIVE
  int get offset_5p => direction == Direction.left ? end - 1 : start;

  /// 3' end, INCLUSIVE
  int get offset_3p => direction == Direction.left ? start : end - 1;

  int get length => (this.end - this.start) - this.deletions.length + this.num_insertions();

  int get visual_length => (this.end - this.start);

  /// Total length increase (can be negative) from deletions and insertions between 5' end and `offset`.
  int net_ins_del_length_increase_from_5p_to(int offset_edge) {
    int length_increase = 0;
    for (int deletion in this.deletions) {
      if (this._between_5p_and_offset(deletion, offset_edge)) {
        length_increase--;
      }
    }
    for (Tuple2<int, int> insertion in this.insertions) {
      int insertion_offset = insertion.item1;
      int insertion_length = insertion.item2;
      if (this._between_5p_and_offset(insertion_offset, offset_edge)) {
        length_increase += insertion_length;
      }
    }
    return length_increase;
  }

  bool _between_5p_and_offset(int offset_to_test, int offset_edge) {
    return (this.direction == Direction.right && this.start <= offset_to_test && offset_to_test < offset_edge) ||
        (this.direction == Direction.left && offset_edge <= offset_to_test && offset_to_test < this.end);
  }

  /// List of offsets (inclusive at each end) in 5' - 3' order, from 5' to `offset_stop`.
  List<int> offsets_from_5p_to(int offset_stop) {
    List<int> offsets = [];
    if (this.direction == Direction.right) {
      for (int offset = this.start; offset <= offset_stop; offset++) {
        offsets.add(offset);
      }
    } else {
      for (int offset = this.end - 1; offset >= offset_stop; offset--) {
        offsets.add(offset);
      }
    }
    return offsets;
  }

  /// List of offsets (inclusive at each end) in 5' - 3' order.
  List<int> offsets_in_5p_3p_order() {
    List<int> offsets = [];
    if (this.direction == Direction.right) {
      for (int offset = this.start; offset < this.end; offset++) {
        offsets.add(offset);
      }
    } else {
      for (int offset = this.end - 1; offset >= this.start; offset--) {
        offsets.add(offset);
      }
    }
    return offsets;
  }

  String get dna_sequence {
    if (this._strand.dna_sequence == null) {
      return null;
    } else {
//      for debugging
//      if (this.start >= 384 && this.helix_idx == 15) {
//        print(this._strand.dna_sequence);
//        var x=0;
//      }
      int start_dna_index = this.offset_to_strand_dna_idx(this.offset_5p);
      int end_dna_index_inclusive = this.offset_to_strand_dna_idx(this.offset_3p);
      String subseq = this._strand.dna_sequence.substring(start_dna_index, end_dna_index_inclusive + 1);
      return subseq;
    }
  }

  /// Convert from offset on Substrand's Helix to string index
  /// on the parent Strand's DNA sequence.
  int offset_to_strand_dna_idx(int offset) {
    int ss_str_idx = null;
    if (this.direction == Direction.right) {
      //account for insertions and deletions
      offset += this._net_ins_del_length_increase_from_5p_to(offset);
      ss_str_idx = offset - this.start;
    } else {
      // account for insertions and deletions
      offset -= this._net_ins_del_length_increase_from_5p_to(offset);
      ss_str_idx = this.end - 1 - offset;
    }
    // correct for existence of previous Substrands on this Strand
    return ss_str_idx + this.get_seq_start_idx();
  }

  /// Net number of insertions from 5' end to offset_edge.
  /// Check is inclusive on the left and exclusive on the right (which is 5' depends on direction).
  int _net_ins_del_length_increase_from_5p_to(int offset_edge) {
    int length_increase = 0;
    for (int deletion in this.deletions) {
        if (this._between_5p_and_offset(deletion, offset_edge)) {
            length_increase -= 1;
        }
    }
    for (Tuple2<int,int> insertion in this.insertions) {
        int insertion_offset = insertion.item1;
        int insertion_length = insertion.item2;
        if (this._between_5p_and_offset(insertion_offset, offset_edge)) {
            length_increase += insertion_length;
        }
    }
    return length_increase;

  }

  /// Starting DNA subsequence index for first base of this Substrand on its
  /// parent Strand DNA sequence.
  int get_seq_start_idx() {
    var substrands = this._strand.substrands;
    // index of self in parent strand's list of substrands
    var self_substrand_idx = substrands.indexOf(this);
    // index of self's position within the DNA sequence of parent strand
    int self_seq_idx_start = 0;
    for (var prev_substrand in substrands.getRange(0, self_substrand_idx)) {
      self_seq_idx_start += prev_substrand.length;
    }
    return self_seq_idx_start;
  }

  // for efficiency but not serialized since it would introduce a JSON cycle
  Strand _strand;

  Strand get strand => this._strand;

  int num_insertions() {
    int num = 0;
    for (Tuple2<int, int> insertion in insertions) {
      num += insertion.item2;
    }
    return num;
  }

  Substrand();

  Map<String, dynamic> toJson() {
    var json_dict = {
      'helix_idx': this.helix_idx,
      'direction': direction_to_json(this.direction),
      'start': this.start,
      'end': this.end,
    };
    if (this.deletions.isNotEmpty) {
      json_dict['deletions'] = this.deletions;
    }
    if (this.insertions.isNotEmpty) {
      // need to use List.from because List.map returns Iterable, not List
      json_dict['insertions'] = List<dynamic>.from(this.insertions.map((insertion) => insertion.toList()));
    }
    return json_dict;
  }

  Substrand.fromJson(Map<String, dynamic> parsed_json) {
    this.helix_idx = get_value(parsed_json, 'helix_idx');
    this.direction = direction_from_string(get_value(parsed_json, 'direction'));
    this.start = get_value(parsed_json, 'start');
    this.end = get_value(parsed_json, 'end');
    if (parsed_json.containsKey('deletions')) {
      this.deletions = List<int>.from(parsed_json['deletions']);
    } else {
      this.deletions = [];
    }
    if (parsed_json.containsKey('insertions')) {
      this.insertions = parse_json_insertions(parsed_json['insertions']);
    } else {
      this.insertions = [];
    }
  }

  static List<Tuple2<int, int>> parse_json_insertions(json_encoded_insertions) {
    // need to use List.from because List.map returns Iterable, not List
    return List<Tuple2<int, int>>.from(
        json_encoded_insertions.map((insertion) => Tuple2<int, int>.fromList(insertion)));
  }


}

/// Tries to get value in map associated to key, but raises an exception if the key is not present.
dynamic get_value(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) {
    throw ArgumentError('key "${key}" is missing from map ${map}');
  } else {
    return map[key];
  }
}

////////////////////////////////////////////////
// MenuViewUIModel

const DEFAULT_FILENAME_NO_EXT = 'default_dna_filename';
const DEFAULT_EXT = 'dna';
const ALLOWED_EXTENSIONS = ['dna'];

default_filename() => DEFAULT_FILENAME_NO_EXT + "." + DEFAULT_EXT;

class MenuViewUIModel {
  String loaded_filename = default_filename();
}

////////////////////////////////////////////////
// MainViewUIModel

class MainViewUIModel {
  MainViewSelection selection = MainViewSelection();
}

class MainViewSelection {
  List<Substrand> starts = [];
  List<Substrand> ends = [];
  List<Crossover> crossovers = [];
  List<Substrand> substrands = [];
}

class Crossover {
  Substrand substrand_5p = null;
  Substrand substrand_3p = null;
}

////////////////////////////////////////////////
// SideViewUIModel

class SideViewSelection {
  List<Helix> helices = [];
}

class SideViewUIModel {
  SideViewSelection selection = SideViewSelection();
}
