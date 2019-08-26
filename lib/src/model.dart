import 'dart:async';
import 'dart:core';
import 'dart:math';
import 'dart:js';

import 'package:color/color.dart';
import 'package:tuple/tuple.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart' as quiver;

import 'model_ui.dart';
import 'app.dart';
import 'constants.dart' as constants;

//TODO: support editing an existing DNADesign so that user can modify strands, etc.

//TODO: add a mixin that lets me specify for each class that when it is created using fromJson, it should store all the
// fields that are not used by scadnano, and write them back out on serialization using toJson

//TODO: import cadnano files


/// Represents parts of the Model to serialize
class DNADesign {
  String version = constants.CURRENT_VERSION;

  Grid grid;

  int major_tick_distance;

  /// all helices in model
  List<Helix> helices = [];

  /// all strands in model
  List<Strand> strands = [];

  // optimized implementation detail; not serialized
  // optimization so we can quickly look up a helix given its index. It is
  // maintained in sorted order, so that used_helices[helix.idx] == helix.
  List<Helix> used_helices = [];

  Map<int,List<Substrand>> helix_idx_substrands_map = {};

  DNADesign();

  //"private" constructor; meta package will warn if it is used outside testing
  @visibleForTesting
  DNADesign.internal();

  DNADesign.default_design({int num_helices_x = 10, int num_helices_y = 10}) {
    this.grid = Grid.square;
    this.major_tick_distance = 8;
    this.build_default_unused_helices(num_helices_x, num_helices_y);
    this.strands = [];
  }

  build_default_unused_helices(int num_helices_x, int num_helices_y) {
    this.helices = [];
    for (int gx = 0; gx < num_helices_x; gx++) {
      for (int gy = 0; gy < num_helices_y; gy++) {
        var grid_pos = GridPosition(gx, gy);
        this.helices.add(Helix(idx: -1, grid_position: grid_pos));
      }
    }
    // should be unnecessary if model.helices is empty
    this.build_used_helices();
  }

  /// Build the list used_helices.
  build_used_helices() {
    this.used_helices = [];
    for (Helix helix in this.helices) {
      if (helix.used) {
        this.used_helices.add(helix);
      }
    }
    this.used_helices.sort((h1, h2) => h1._idx - h2._idx);
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
    Map<String, dynamic> json_map = {constants.version_key: this.version};
    if (this.grid != constants.default_grid) {
      json_map[constants.grid_key] = grid_to_json(this.grid);
    }
    if (this.major_tick_distance != default_major_tick_distance(this.grid)) {
      json_map[constants.major_tick_distance_key] = this.major_tick_distance;
    }
    json_map[constants.helices_key] = this.helices;
    json_map[constants.strands_key] = this.strands;
    return json_map;
  }

  static int default_major_tick_distance(Grid grid) {
    return grid == Grid.hex || grid == Grid.honeycomb ? 7 : 8;
  }

//  DNADesign.from_js_object(JsObject js_obj) {
//    if (js_obj.hasProperty(constants.version_key)) {
//      this.version = js_obj[constants.version_key];
//    } else {
//      this.version = constants.INITIAL_VERSION;
//    }
////    this.version =
////        js_obj.hasProperty(constants.version_key) ? js_obj[constants.version_key] : constants.INITIAL_VERSION;
//
//    this.grid =
//        js_obj.hasProperty(constants.grid_key) ? grid_from_string(js_obj[constants.grid_key]) : Grid.none;
//
//    if (js_obj.hasProperty(constants.major_tick_distance_key)) {
//      this.major_tick_distance = js_obj[constants.major_tick_distance_key];
//    } else if (js_obj.hasProperty(constants.grid_key)) {
//      if (this.grid == Grid.hex || this.grid == Grid.honeycomb) {
//        this.major_tick_distance = 7;
//      } else {
//        this.major_tick_distance = 8;
//      }
//    }
//
//    this.helices = [];
//    List<dynamic> deserialized_helices_list = js_obj[constants.helices_key];
//    for (var helix_json in deserialized_helices_list) {
//      Helix helix = Helix.from_js_object(helix_json);
//      this.helices.add(helix);
//    }
//    this.build_used_helices();
//
//    this.strands = [];
//    List<dynamic> deserialized_strand_list = js_obj[constants.strands_key];
//    for (var strand_json in deserialized_strand_list) {
//      Strand strand = Strand.from_js_object(strand_json);
//      this.strands.add(strand);
//    }
//  }

  DNADesign.from_json(Map<String, dynamic> json_map) {
//    this.menu_view_ui_model.loaded_filename = filename;

    //TODO: add test for illegally overlapping substrands on Helix (copy algorithm from Python repo)

    this.version = json_map.containsKey(constants.version_key)
        ? json_map[constants.version_key]
        : constants.INITIAL_VERSION;

    this.grid =
        json_map.containsKey(constants.grid_key) ? grid_from_string(json_map[constants.grid_key]) : Grid.none;

    if (json_map.containsKey(constants.major_tick_distance_key)) {
      this.major_tick_distance = json_map[constants.major_tick_distance_key];
    } else if (json_map.containsKey(constants.grid_key)) {
      if (this.grid == Grid.hex || this.grid == Grid.honeycomb) {
        this.major_tick_distance = 7;
      } else {
        this.major_tick_distance = 8;
      }
    }

    this.helices = [];
    List<dynamic> deserialized_helices_list = json_map[constants.helices_key];
    for (var helix_json in deserialized_helices_list) {
      Helix helix = Helix.from_json(helix_json);
      this.helices.add(helix);
    }
    this.build_used_helices();

    this.strands = [];
    List<dynamic> deserialized_strand_list = json_map[constants.strands_key];
    for (var strand_json in deserialized_strand_list) {
      Strand strand = Strand.from_json(strand_json);
      this.strands.add(strand);
    }

    this.build_helix_idx_substrands_map();
  }

  String toString() => """DNADesign(grid=$grid, major_tick_distance=$major_tick_distance, 
  helices=$helices, 
  strands=$strands)""";

  build_helix_idx_substrands_map() {
    this.helix_idx_substrands_map = {};
    for (Helix helix in this.used_helices) {
      this.helix_idx_substrands_map[helix.idx] = [];
    }
    for (Strand strand in this.strands) {
      for (Substrand substrand in strand.substrands) {
        this.helix_idx_substrands_map[substrand.helix_idx].add(substrand);
      }
    }
  }

//  /// Add new Helix.
//  /// If idx > 0, idx must be < current number of helices.
//  /// Inserted into middle of used helices if idx is intermediate, and other helces idx's are incremented.
//  add_helix(Helix helix) {
//    if (helix.idx >= 0) {
//      var new_idx = this.idx;
//      this.helix.idx = new_idx;
//      design.used_helices.insert(new_idx, this.helix);
//      for (var helix_after_idx_used in design.used_helices.sublist(new_idx + 1)) {
//        helix_after_idx_used.idx++;
//        app.controller.notifier_helix_change_used.add(helix_after_idx_used);
//      }
//    } else {
//      design.used_helices.removeAt(old_idx);
//      this.helix.idx = -1;
//      app.controller.notifier_helix_change_used.add(this.helix);
//      for (var helix_after_idx_unused in design.used_helices.sublist(old_idx)) {
//        helix_after_idx_unused.idx--;
//        app.controller.notifier_helix_change_used.add(helix_after_idx_unused);
//      }
//    }
//  }

//  /// Set helix used status to true. idx is new idx to use.
//  set_helix_used(Helix helix, int new_idx) {
//    helix.idx = new_idx;
//    this.used_helices.insert(new_idx, helix);
//    for (var helix_after_idx_used in this.used_helices.sublist(new_idx + 1)) {
//      helix_after_idx_used.idx++;
//      app.controller.notifier_helix_change_used.add(helix_after_idx_used);
//    }
//  }
//
//  /// Set helix used status to false.
//  set_helix_unused(Helix helix) {
//    int old_idx = helix.idx;
//    this.used_helices.removeAt(old_idx);
//    helix.idx = -1;
//    app.controller.notifier_helix_change_used.add(helix);
//    for (var helix_after_idx_unused in this.used_helices.sublist(old_idx)) {
//      helix_after_idx_unused.idx--;
//      app.controller.notifier_helix_change_used.add(helix_after_idx_unused);
//    }
//  }
}

class Model with ChangeNotifier<Model> {
  DNADesign _dna_design;

  String _editor_content = constants.initial_editor_content;

  MenuViewUIModel menu_view_ui_model = MenuViewUIModel();
  EditorViewUIModel editor_view_ui_model = EditorViewUIModel();
  MainViewUIModel main_view_ui_model = MainViewUIModel();
  SideViewUIModel side_view_ui_model = SideViewUIModel();

  /// Save button is enabled iff this is true
  bool changed_since_last_save = false;

  //It's handy to have convenience getters and setters for Model, but for things delegated to contained
  // model parts like MainViewUIModel, we don't fire a changed notification, but let the sub-part do it.
  bool get show_dna => this.main_view_ui_model.show_dna;

  set show_dna(bool show) {
    this.main_view_ui_model.show_dna = show;
  }

  bool get show_editor => this.main_view_ui_model.show_editor;

  set show_editor(bool show) {
    this.main_view_ui_model.show_editor = show;
  }

  String _error_message = null;

  //"private" constructor; meta package will warn if it is used outside testing
  @visibleForTesting
  Model.internal() {
    this._set_change_notifier();
  }

  Model.default_model({int num_helices_x = 10, int num_helices_y = 10}) {
    this._dna_design = DNADesign.default_design(num_helices_x: num_helices_x, num_helices_y: num_helices_y);
    this._set_change_notifier();
  }

  Model.empty() {
    this._set_change_notifier();
  }

  _set_change_notifier() {
    this.notifier = app.controller.notifier_model_change;
  }

  //TODO: this is crashing when we save; debug it
  /// This exact method name is required for Dart to know how to encode as JSON.
  Map<String, dynamic> toJson() {
    return this._dna_design.toJson();
  }

  DNADesign get dna_design => this._dna_design;

  String get error_message => this._error_message;

  String get editor_content => this._editor_content;

  set dna_design(DNADesign new_dna_design) {
    this._dna_design = new_dna_design;
    this.notify_changed();
  }

  set error_message(String new_msg) {
    this._error_message = new_msg;
    this.notify_changed();
  }

  set editor_content(String new_content) {
    this._editor_content = new_content;
    context[constants.editor_content_js_key] = new_content;
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
  int get hashCode => quiver.hash3(this.h, this.v, this.b);

  @override
  bool operator ==(other) {
    return this.h == other.h && this.v == other.v && this.b == other.b;
  }
}


/// Represents a used helix (as opposed to the circles drawn in the side
/// view initially, which are unused helices). However, a "used" helix doesn't
/// have to have any strands on it.
class Helix with ChangeNotifier<Helix> {
  /// unique identifier of used helix; also index indicating order to show
  /// in main view from top to bottom (unused helices not shown in main view)
  /// by default. This default positioning can be overridden by setting the position field.
  int _idx = -1;

  /// position within square/hex/honeycomb integer grid (side view)
  GridPosition _grid_position;

  /// SVG position of upper-left corner (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position in Helix as well, but svg_position will always be 2D.
  Point<num> _svg_position;

  /// Maximum length (in bases) of Substrand that can be drawn on this Helix.
  int _max_bases;

  int _major_tick_distance = -1;

  List<int> _major_ticks = null;

  int get major_tick_distance => this._major_tick_distance;

  List<int> get major_ticks => this._major_ticks;

  bool has_major_tick_distance() => this._major_tick_distance >= 0;

  bool has_major_ticks() => this._major_ticks != null;

  set major_tick_distance(int new_dist) {
    this._major_tick_distance = new_dist;
    this.notify_changed();
  }

  set major_ticks(List<int> new_ticks) {
    this._major_ticks = new_ticks;
    this.notify_changed();
  }

  num get gh => this._grid_position.h;

  num get gv => this._grid_position.v;

  num get gb => this._grid_position.b;

  GridPosition get grid_position => this._grid_position;

  Point<num> get svg_position => this._svg_position;

  int get max_bases => this._max_bases;

  bool get used => this._idx >= 0;

  List<Substrand> _substrands = [];

  Helix({int idx, grid_position, max_bases}) {
    this._idx = idx;
    this._grid_position = grid_position;
    this._max_bases = max_bases;
    this._svg_position = this.default_svg_position();
    _set_change_notifier();
  }

  /// Gets "center of base" (middle of square representing base) given helix idx and offset,
  /// depending on whether strand is going right or not.
  Point<num> svg_base_pos(int offset, bool right) {
    num x = constants.BASE_WIDTH_SVG / 2 + offset * constants.BASE_WIDTH_SVG + this._svg_position.x;
    num y = constants.BASE_HEIGHT_SVG / 2 + this._svg_position.y;
    if (!right) {
      y += 10;
    }
    return Point<num>(x, y);
  }

  int svg_x_to_offset(num x) {
    return ((x - this._svg_position.x) / constants.BASE_WIDTH_SVG).floor();
  }

  bool svg_y_to_right(num y) {
    return (y - this._svg_position.y) < 10;
  }

  Point<num> default_svg_position() {
    return Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * this._idx);
  }

  int get idx => this._idx;

  set idx(int new_idx) {
    this._idx = new_idx;
    this._svg_position = this.default_svg_position();
    this.notify_changed();
  }

  int get hashCode =>
      quiver.hash4(this._idx, this.grid_position.h, this.grid_position.v, this.grid_position.b);

  operator ==(other) {
    if (other is Helix) {
      var other_helix = other;
      return this._idx == other_helix._idx && this.grid_position == other_helix.grid_position;
    } else {
      return false;
    }
  }

  String toString() => "Helix(idx=$_idx, gh=$gh, gv=$gv, gb=$gb, max_bases=$max_bases})";

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json_map = {constants.idx_key: this._idx};

    if (this.has_grid_position()) {
      json_map[constants.grid_position_key] = this.grid_position;
    }

    if (this.has_svg_position()) {
      json_map[constants.svg_position_key] = [this.svg_position.x, this.svg_position.y];
    }

    if (this.has_max_bases()) {
      json_map[constants.max_bases_key] = this.max_bases;
    }

    return json_map;
  }

  bool has_substrands() => this._substrands.isNotEmpty;

  bool has_grid_position() => this._grid_position != null;

  bool has_svg_position() => this._svg_position != null;

  bool has_max_bases() => this._max_bases != null;

  Helix.from_json(Map<String, dynamic> json_map) {
    this._set_change_notifier();

    this._idx = get_value(json_map, constants.idx_key);

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
      this._svg_position = Point<int>(svg_position_list[0], svg_position_list[1]);
    } else {
      this._svg_position = this.default_svg_position();
    }

    this._max_bases = get_value(json_map, constants.max_bases_key);
  }

  void _set_change_notifier() {
    this.notifier = app.controller.notifier_helix_change;
  }

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

class Strand {
  static Color DEFAULT_STRAND_COLOR = RgbColor.name('black');

  /// Is "id" instead of "idx" because they may not be indices 0...len-1 in
  /// case some strands are deleted.
  Color color = null;
  String dna_sequence = null;
  List<Substrand> substrands = [];

  Strand();

  String toString() => 'Strand(helix=${substrands[0].helix_idx}, start=${substrands[0].offset_5p})';

  int get length {
    int num = 0;
    for (var substrand in substrands) {
      num += substrand.dna_length;
    }
    return num;
  }

  Map<String, dynamic> toJson() {
    var json_map = Map<String, dynamic>();

    // need to use List.from because List.map returns Iterable, not List
    json_map[constants.substrands_key] =
        List<dynamic>.from(this.substrands.map((substrand) => substrand.toJson()));
    if (this.color != null) {
      json_map[constants.color_key] = this.color.toRgbColor().toMap();
    }
    if (this.dna_sequence != null) {
      json_map[constants.dna_sequence_key] = this.dna_sequence;
    }

    return json_map;
  }

  Strand.from_json(Map<String, dynamic> json_map) {
    // need to use List.from because List.map returns Iterable, not List
    this.substrands = List<Substrand>.from(get_value(json_map, constants.substrands_key)
        .map((substrandJson) => Substrand.from_json(substrandJson)));
    for (var substrand in this.substrands) {
      substrand._strand = this;
    }

    if (json_map.containsKey(constants.color_key)) {
      this.color = parse_json_color(json_map[constants.color_key]);
    } else {
      this.color = DEFAULT_STRAND_COLOR;
    }

    this.dna_sequence =
        json_map.containsKey(constants.dna_sequence_key) ? json_map[constants.dna_sequence_key] : null;
    if (this.dna_sequence != null) {
      if (this.dna_sequence.length != this.length) {
        var first_substrand = this.substrands.first;
        var last_substrand = this.substrands.last;
        throw IllegalDNADesignError('Strand length does not match DNA sequence length:\n'
            'strand length        =  ${this.length}\n'
            'DNA length           =  ${this.dna_sequence.length}\n'
            "strand 5' helix      =  ${first_substrand.helix_idx}\n"
            "strand 5' end offset =  ${first_substrand.offset_5p}\n"
            "strand 3' helix      =  ${last_substrand.helix_idx}\n"
            "strand 3' end offset =  ${last_substrand.offset_3p}\n"
            'DNA sequence         =  ${this.dna_sequence}');
      }
    }
  }

//  Strand.from_js_object(JsObject js_obj) {
//    // need to use List.from because List.map returns Iterable, not List
//    this.substrands = List<Substrand>.from(js_obj[constants.substrands_key]
//        .map((substrand_js_obj) => Substrand.from_js_object(substrand_js_obj)));
//    for (var substrand in this.substrands) {
//      substrand._strand = this;
//    }
//
//    if (js_obj.hasProperty(constants.color_key)) {
//      this.color = parse_json_color(js_obj[constants.color_key]);
//    } else {
//      this.color = DEFAULT_STRAND_COLOR;
//    }
//
//    this.dna_sequence =
//        js_obj.hasProperty(constants.dna_sequence_key) ? js_obj[constants.dna_sequence_key] : null;
//  }
}

class IllegalDNADesignError implements Exception {
  String cause;
  IllegalDNADesignError(String the_cause) {
    this.cause =
        '**********************\n'
        '* illegal DNA design *\n'
        '**********************\n\n' + the_cause;
  }
}

Color parse_json_color(Map json_map) {
  int r = json_map['r'];
  int g = json_map['g'];
  int b = json_map['b'];
  return RgbColor(r, g, b);
}

class Substrand {
  int helix_idx = -1;
  bool right = true;
  int start = null;
  int end = null;
  List<int> deletions = [];
  List<Tuple2<int, int>> insertions = []; // elt: Pair(offset, num insertions)

  /// 5' end, INCLUSIVE
  int get offset_5p => right ? start : end - 1;

  /// 3' end, INCLUSIVE
  int get offset_3p => right ? end - 1 : start;

  int get dna_length => (this.end - this.start) - this.deletions.length + this.num_insertions();

  int get visual_length => (this.end - this.start);

  /// Indicates if `offset` is the offset of a base on this substrand.
  /// Note that offsets refer to visual portions of the displayed grid for the Helix.
  /// If for example, this Substrand starts at position 0 and ends at 10, and it has 5 deletions,
  /// then it contains the offset 7 even though there is no base 7 positions from the start.
  bool contains_offset(int offset) {
    return this.start <= offset && offset < this.end;
  }

  /// List of offsets (inclusive at each end) in 5' - 3' order, from 5' to `offset_stop`.
  List<int> offsets_from_5p_to(int offset_stop) {
    List<int> offsets = [];
    if (this.right) {
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
    if (this.right) {
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

  String dna_sequence() {
    if (this._strand.dna_sequence == null) {
      return null;
    } else {
//      for debugging
//      if (this.start >= 384 && this.helix_idx == 15) {
//        print(this._strand.dna_sequence);
//        var x=0;
//      }
      return this.dna_sequence_in(this.start, this.end - 1);
    }
  }

  /// Return DNA sequence of this Substrand in the interval of offsets given by
  //  [`left`, `right`], INCLUSIVE.
  //
  //  WARNING: This is inclusive on both ends,
  //  unlike other parts of this API where the right endpoint is exclusive.
  //  This is to make the notion well-defined when one of the endpoints is on an offset with a
  //  deletion or insertion.
  String dna_sequence_in(int offset_left, int offset_right) {
    String strand_seq = this._strand.dna_sequence;
    if (strand_seq == null) {
      return null;
    }
    // if on a deletion, move inward until we are off of it
    while (this.deletions.contains(offset_left)) {
      offset_left += 1;
    }
    while (this.deletions.contains(offset_right)) {
      offset_right -= 1;
    }

    if (offset_left > offset_right) {
      return '';
    }
    if (offset_left >= this.end) {
      return '';
    }
    if (offset_right < 0) {
      return '';
    }

    bool five_p_on_left = this.right;
    int str_idx_left = this.offset_to_strand_dna_idx(offset_left, five_p_on_left);
    int str_idx_right = this.offset_to_strand_dna_idx(offset_right, !five_p_on_left);
    if (!this.right) {
      // these will be out of order if strand is left
      int swap = str_idx_left;
      str_idx_left = str_idx_right;
      str_idx_right = swap;
    }

    String subseq = this._strand.dna_sequence.substring(str_idx_left, str_idx_right + 1);
    return subseq;
  }

  /// This is suitable for rendering along the helix lines.
  /// For deletions, spaces are added where a base would be.
  /// For insertions, all bases corresponding to the insertion
  /// (including the first one that would be represented even if there were no insertion)
  /// are replaced with a single space.
  String dna_sequence_deletions_insertions_to_spaces() {
    String seq = this.dna_sequence();
    List<int> codeunits = [];

    var deletions_set = this.deletions.toSet();
    var insertions_map = Map<int, int>.fromIterable(
      this.insertions,
      key: (insertion) => insertion.item1,
      value: (insertion) => insertion.item2,
    );

    int seq_idx = 0;
    int offset = this.offset_5p;
    int space_codeunit = ' '.codeUnitAt(0);
    int forward = this.right ? 1 : -1;
    bool offset_out_of_bounds(offset) =>
        this.right ? offset >= this.offset_3p + forward : offset <= this.offset_3p + forward;
    while (!offset_out_of_bounds(offset)) {
      if (deletions_set.contains(offset)) {
        codeunits.add(space_codeunit);
        offset += forward;
      } else if (insertions_map.containsKey(offset)) {
        codeunits.add(space_codeunit);
        int insertion_length = insertions_map[offset];
        int forward_insertion = insertion_length + 1;
        seq_idx += forward_insertion;
        offset += forward;
      } else {
        int base_codeunit = seq.codeUnitAt(seq_idx);
        codeunits.add(base_codeunit);
        seq_idx++;
        offset += forward;
      }
    }

    var seq_modified = String.fromCharCodes(codeunits);
    return seq_modified;
  }

  /// Convert from offset on Substrand's Helix to string index on the parent Strand's DNA sequence.
  int offset_to_strand_dna_idx(int offset, bool offset_closer_to_5p) {
    if (this.deletions.contains(offset)) {
      throw ArgumentError('offset {offset} illegally contains a deletion from {self.deletions}');
    }

    // length adjustment for insertions depends on whether this is a left or right offset
    int len_adjust = this._net_ins_del_length_increase_from_5p_to(offset, offset_closer_to_5p);

    // get string index assuming this Substrand is first on Strand
    int ss_str_idx = null;
    if (this.right) {
      //account for insertions and deletions
      offset += len_adjust;
      ss_str_idx = offset - this.start;
    } else {
      // account for insertions and deletions
      offset -= len_adjust;
      ss_str_idx = this.end - 1 - offset;
    }

    // correct for existence of previous Substrands on this Strand
    return ss_str_idx + this.get_seq_start_idx();
  }

  /// Net number of insertions from 5' end to offset_edge.
  /// Check is inclusive on the left and exclusive on the right (which is 5' depends on direction).
  int _net_ins_del_length_increase_from_5p_to(int offset_edge, bool offset_closer_to_5p) {
    int length_increase = 0;
    for (int deletion in this.deletions) {
      if (this._between_5p_and_offset(deletion, offset_edge)) {
        length_increase -= 1;
      }
    }
    for (Tuple2<int, int> insertion in this.insertions) {
      int insertion_offset = insertion.item1;
      int insertion_length = insertion.item2;
      if (this._between_5p_and_offset(insertion_offset, offset_edge)) {
        length_increase += insertion_length;
      }
    }

    // special case for when offset_edge is an endpoint closer to the 3' end,
    // we add its extra insertions also in this case
    if (!offset_closer_to_5p) {
      var insertion_map = Map<int, int>.fromIterable(
        this.insertions,
        key: (insertion) => insertion.item1,
        value: (insertion) => insertion.item2,
      );
      if (insertion_map.containsKey(offset_edge)) {
        int insertion_length = insertion_map[offset_edge];
        length_increase += insertion_length;
      }
    }

    return length_increase;
  }

  bool _between_5p_and_offset(int offset_to_test, int offset_edge) {
    return (this.right && this.start <= offset_to_test && offset_to_test < offset_edge) ||
        (!this.right && offset_edge < offset_to_test && offset_to_test < this.end);
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
      self_seq_idx_start += prev_substrand.dna_length;
    }
    return self_seq_idx_start;
  }

  // for efficiency but not serialized since it would introduce a JSON cycle
  Strand _strand;

  Strand get strand => this._strand;

  void set strand(Strand new_strand) {
    this._strand = new_strand;
  }

  int num_insertions() {
    int num = 0;
    for (Tuple2<int, int> insertion in insertions) {
      num += insertion.item2;
    }
    return num;
  }

  Substrand();

  Map<String, dynamic> toJson() {
    var json_map = {
      constants.helix_idx_key: this.helix_idx,
      constants.right_key: this.right,
      constants.start_key: this.start,
      constants.end_key: this.end,
    };
    if (this.deletions.isNotEmpty) {
      json_map[constants.deletions_key] = this.deletions;
    }
    if (this.insertions.isNotEmpty) {
      // need to use List.from because List.map returns Iterable, not List
      json_map[constants.insertions_key] =
          List<dynamic>.from(this.insertions.map((insertion) => insertion.toList()));
    }
    return json_map;
  }

  Substrand.from_json(Map<String, dynamic> json_map) {
    this.helix_idx = get_value(json_map, constants.helix_idx_key);
    this.right = get_value(json_map, constants.right_key);
    this.start = get_value(json_map, constants.start_key);
    this.end = get_value(json_map, constants.end_key);
    if (json_map.containsKey(constants.deletions_key)) {
      this.deletions = List<int>.from(json_map[constants.deletions_key]);
    } else {
      this.deletions = [];
    }
    if (json_map.containsKey(constants.insertions_key)) {
      this.insertions = parse_json_insertions(json_map[constants.insertions_key]);
    } else {
      this.insertions = [];
    }
  }


//  Substrand.from_js_object(JsObject js_obj) {
//    this.helix_idx = js_obj[constants.helix_idx_key];
//    this.right = js_obj[constants.right_key];
//    this.start = js_obj[constants.start_key];
//    this.end = js_obj[constants.end_key];
//    if (js_obj.hasProperty(constants.deletions_key)) {
//      this.deletions = List<int>.from(js_obj[constants.deletions_key]);
//    } else {
//      this.deletions = [];
//    }
//    if (js_obj.hasProperty(constants.insertions_key)) {
//      this.insertions = parse_json_insertions(js_obj[constants.insertions_key]);
//    } else {
//      this.insertions = [];
//    }
//  }

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



/// Use this mixin to get listener functionality for when an object changes and listeners need to be notified.
/// Must pass an existing instance of a notifier (should be stored in central location like Controller).
/// This avoids the issues of Model and View objects being created and destroyed and the notifiers/listeners
/// not updating properly.
class ChangeNotifier<T> {
//  final StreamController<T> notifier = StreamController<T>.broadcast();
  StreamController<T> notifier;

  listen_for_change(void Function(T) listener) {
    this.notifier.stream.listen(listener);
  }

  notify_changed() {
    if (this.notifier != null){
      this.notifier.add(this as T);
    }
  }
}