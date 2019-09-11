import 'dart:async';
import 'dart:core';
import 'dart:math';
//import 'dart:js';

import 'package:color/color.dart';
import 'package:meta/meta.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:quiver/core.dart' as quiver;
import 'package:quiver/iterables.dart' hide max;
import 'package:scadnano/src/json_serializable.dart';

import 'util.dart' as util;
import 'strand.dart';
import 'model_ui.dart';
import 'app.dart';
import 'constants.dart' as constants;

//TODO: support editing an existing DNADesign so that user can modify strands, etc.

//TODO: add a mixin that lets me specify for each class that when it is created using from_json,
//  it should store all the fields that are not used by scadnano,
//  and write them back out on serialization using to_json

//TODO: import cadnano files

class Mismatch {
  final int dna_idx;
  final int offset;
  final int within_insertion;

  Mismatch(this.dna_idx, this.offset, {this.within_insertion = -1});

  String toString() =>
      'Mismatch(dna_idx=${this.dna_idx}, offset=${this.offset}' +
      (this.within_insertion < 0 ? ')' : ', within_insertion=${this.within_insertion})');
}

/// Represents parts of the Model to serialize
class DNADesign extends JSONSerializable {
  String version = constants.CURRENT_VERSION;

  Grid grid;

  int major_tick_distance;

  /// all helices in model
  List<Helix> helices = [];

  /// all strands in model
  List<Strand> strands = [];

  List<PotentialHelix> potential_helices = [];

  Map<BoundSubstrand, List<Mismatch>> _substrand_mismatches_map = {};

  DNADesign();

  //"private" constructor; meta package will warn if it is used outside testing
  @visibleForTesting
  DNADesign.internal();

  DNADesign.default_design({int num_helices_x = 10, int num_helices_y = 10}) {
    this.grid = Grid.square;
    this.major_tick_distance = 8;
    this.build_default_potential_helices(num_helices_x, num_helices_y);
    this.strands = [];
    this.helices = [];
  }

  build_default_potential_helices(int num_helices_x, int num_helices_y) {
    this.potential_helices = [];
    for (int gx = 0; gx < num_helices_x; gx++) {
      for (int gy = 0; gy < num_helices_y; gy++) {
        var grid_pos = GridPosition(gx, gy);
        this.potential_helices.add(PotentialHelix(grid_pos));
      }
    }
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
  Map<String, dynamic> to_json_serializable() {
    Map<String, dynamic> json_map = {constants.version_key: this.version};
    if (this.grid != constants.default_grid) {
      json_map[constants.grid_key] = grid_to_json(this.grid);
    }
    if (this.major_tick_distance != default_major_tick_distance(this.grid)) {
      json_map[constants.major_tick_distance_key] = this.major_tick_distance;
    }

    json_map[constants.helices_key] = [for (var helix in this.helices) helix.to_json_serializable()];

    if (this.potential_helices.isNotEmpty) {
      json_map[constants.potential_helices_key] = [
        for (var ph in this.potential_helices) ph.to_json_serializable()
      ];
    }
    json_map[constants.strands_key] = [for (var strand in this.strands) strand.to_json_serializable()];

    return json_map;
  }

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
    int idx = 0;
    for (var helix_json in deserialized_helices_list) {
      Helix helix = Helix.from_json(helix_json);
      helix.idx = idx;
      idx++;
      this.helices.add(helix);
    }

    this.strands = [];
    List<dynamic> deserialized_strand_list = json_map[constants.strands_key];
    for (var strand_json in deserialized_strand_list) {
      Strand strand = Strand.from_json(strand_json);
      this.strands.add(strand);
    }

    //XXX: order of these is important because each uses the data calculated from the previous
    this._set_helices_idxs();
    this._set_helices_grid_and_svg_positions();
    this._build_helix_idx_substrands_map();
    this._set_helices_max_bases(update: false);
    this._build_substrand_mismatches_map();
    this._check_legal_design();
  }

  static int default_major_tick_distance(Grid grid) {
    return grid == Grid.hex || grid == Grid.honeycomb ? 7 : 8;
  }

  _set_helices_idxs() {
    for (int idx = 0; idx < this.helices.length; idx++) {
      var helix = this.helices[idx];
      helix._idx = idx;
    }
  }

  _set_helices_grid_and_svg_positions() {
    for (int idx = 0; idx < this.helices.length; idx++) {
      var helix = this.helices[idx];
      if (helix.grid_position == null) {
        helix._grid_position = helix.default_grid_position();
      }
      if (helix.svg_position == null) {
        helix._svg_position = helix.default_svg_position();
      }
    }
  }

  _set_helices_max_bases({bool update = true}) {
    for (var helix in this.helices) {
      if (update || helix.max_bases < 0) {
        var max_bases = -1;
        for (var substrand in helix._substrands) {
          max_bases = max(max_bases, substrand.end);
        }
        helix._max_bases = max_bases;
      }
    }
  }

  _check_legal_design() {
    //TODO: implement this and give reasonable error messages
  }

  String toString() => """DNADesign(grid=$grid, major_tick_distance=$major_tick_distance, 
  helices=$helices, 
  strands=$strands)""";

  _build_helix_idx_substrands_map() {
    for (Strand strand in this.strands) {
      for (Substrand substrand in strand.substrands) {
        if (substrand.is_bound_substrand()) {
          var bound_ss = substrand as BoundSubstrand;
          this.helices[bound_ss.helix]._substrands.add(bound_ss);
        }
      }
    }
  }

  _build_substrand_mismatches_map() {
    this._substrand_mismatches_map = {};
    for (Strand strand in this.strands) {
      if (strand.dna_sequence != null) {
        for (Substrand substrand in strand.substrands) {
          if (substrand.is_bound_substrand()) {
            var bound_ss = substrand as BoundSubstrand;
            this._substrand_mismatches_map[bound_ss] = this._find_mismatches_on_substrand(bound_ss);
          }
        }
      }
    }
  }

  List<Mismatch> _find_mismatches_on_substrand(BoundSubstrand substrand) {
    List<Mismatch> mismatches = [];

    for (int offset = substrand.start; offset < substrand.end; offset++) {
      if (substrand.deletions.contains(offset)) {
        continue;
      }

      var other_ss = this.other_substrand_at_offset(substrand, offset);
      if (other_ss == null || other_ss.dna_sequence() == null) {
        continue;
      }

      this._ensure_other_substrand_same_deletion_or_insertion(substrand, other_ss, offset);

      var seq = substrand.dna_sequence_in(offset, offset);
      var other_seq = other_ss.dna_sequence_in(offset, offset);
      assert(other_seq.length == seq.length);

      for (int idx = 0, idx_other = seq.length - 1; idx < seq.length; idx++, idx_other--) {
        if (seq.codeUnitAt(idx) != _wc(other_seq.codeUnitAt(idx_other))) {
          int dna_idx = substrand.offset_to_strand_dna_idx(offset, substrand.forward) + idx;
          int within_insertion = seq.length == 1 ? -1 : idx;
          var mismatch = Mismatch(dna_idx, offset, within_insertion: within_insertion);
          mismatches.add(mismatch);
        }
      }
    }
    return mismatches;
  }

  /// Return other substrand at `offset` on `substrand.helix_idx`, or null if there isn't one.
  BoundSubstrand other_substrand_at_offset(BoundSubstrand substrand, int offset) {
    List<BoundSubstrand> other_substrands = this._other_substrands_overlapping(substrand);
    for (var other_ss in other_substrands) {
      if (other_ss.contains_offset(offset)) {
        assert(substrand.forward != other_ss.forward);
        return other_ss;
      }
    }
    return null;
  }

  void _ensure_other_substrand_same_deletion_or_insertion(
      BoundSubstrand substrand, BoundSubstrand other_ss, int offset) {
    if (substrand.deletions.contains(offset) && !other_ss.deletions.contains(offset)) {
      throw UnsupportedError('cannot yet handle one strand having deletion at an offset but the overlapping '
          'strand does not\nThis was found between the substrands on helix ${substrand.helix} '
          'occupying offset intervals\n'
          '(${substrand.start}, ${substrand.end}) and\n'
          '(${other_ss.start}, ${other_ss.end})');
    }
    if (substrand.contains_insertion_at(offset) && !other_ss.contains_insertion_at(offset)) {
      throw UnsupportedError('cannot yet handle one strand having insertion at an offset but the overlapping '
          'strand does not\nThis was found between the substrands on helix ${substrand.helix} '
          'occupying offset intervals\n'
          '(${substrand.start}, ${substrand.end}) and\n'
          '(${other_ss.start}, ${other_ss.end})');
    }
  }

  /// Return list of mismatches in substrand where the base is mismatched with the overlapping substrand.
  /// If a mismatch occurs outside an insertion, within_insertion = -1).
  /// If a mismatch occurs in an insertion, within_insertion = relative position within insertion (0,1,...)).
  List<Mismatch> mismatches_on_substrand(BoundSubstrand substrand) {
    var ret = this._substrand_mismatches_map[substrand];
    assert(ret != null);
    return ret;
  }

  /// Return list of substrands on the Helix with the given index.
  substrands_on_helix(int helix_idx) {
    return this.helices[helix_idx]._substrands;
  }

  /// Return list of Substrands overlapping `substrand`.
  List<BoundSubstrand> _other_substrands_overlapping(BoundSubstrand substrand) {
    List<BoundSubstrand> ret = [];
    var helix = this.helices[substrand.helix];
    for (var other_ss in helix._substrands) {
      if (substrand.overlaps(other_ss)) {
        ret.add(other_ss);
      }
    }
    return ret;
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

final Map<int, int> _wc_table = {
  'A'.codeUnitAt(0): 'T'.codeUnitAt(0),
  'T'.codeUnitAt(0): 'A'.codeUnitAt(0),
  'G'.codeUnitAt(0): 'C'.codeUnitAt(0),
  'C'.codeUnitAt(0): 'G'.codeUnitAt(0),
  'a'.codeUnitAt(0): 't'.codeUnitAt(0),
  't'.codeUnitAt(0): 'a'.codeUnitAt(0),
  'g'.codeUnitAt(0): 'c'.codeUnitAt(0),
  'c'.codeUnitAt(0): 'g'.codeUnitAt(0),
};

int _wc(int code_unit) {
  if (_wc_table.containsKey(code_unit)) {
    return _wc_table[code_unit];
  } else {
    return code_unit;
  }
}

class Model with ChangeNotifier<Model> {
  DNADesign _dna_design;

  String _editor_content = "";

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

  bool get show_mismatches => this.main_view_ui_model.show_mismatches;

  set show_mismatches(bool show) {
    this.main_view_ui_model.show_mismatches = show;
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
    return this._dna_design.to_json_serializable();
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
//    context[constants.editor_content_js_key] = new_content;
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

/// Represents a potential position for a Helix (the circles drawn in the side
/// view initially, which are unused helices). It has a grid position but nothing else.
class PotentialHelix extends JSONSerializable {
  /// position within square/hex/honeycomb integer grid (side view)
  GridPosition _grid_position;

  PotentialHelix(this._grid_position);

  PotentialHelix.from_json(Map<String, dynamic> json_map) {
    if (json_map.containsKey(constants.grid_position_key)) {
      List<dynamic> gp_list = json_map[constants.grid_position_key];
      if (!(gp_list.length == 2 || gp_list.length == 3)) {
        throw ArgumentError(
            "list of grid_position coordinates must be length 2 or 3 but this is the list: ${gp_list}");
      }
      this._grid_position = GridPosition.from_list(gp_list);
    }
  }

  Map<String, dynamic> to_json_serializable() {
    Map<String, dynamic> json_map = {constants.grid_position_key: this._grid_position};
    return json_map;
  }
}

/// Represents a helix (as opposed to the circles drawn in the side
/// view initially, which are unused helices). However, a helix doesn't
/// have to have any strands on it.
class Helix extends JSONSerializable with ChangeNotifier<Helix> {
  /// unique identifier of used helix; also index indicating order to show
  /// in main view from top to bottom (unused helices not shown in main view)
  /// by default. This default positioning can be overridden by setting the position field.
  int _idx = -1;

  /// position within square/hex/honeycomb integer grid (side view)
  GridPosition _grid_position = null;

  /// SVG position of upper-left corner (main view). This is only 2D.
  /// There is a position object that can be stored in the JSON, but this is used only for 3D visualization,
  /// which is currently unsupported in scadnano. If we want to support it in the future, we can store that
  /// position in Helix as well, but svg_position will always be 2D.
  Point<num> _svg_position = null;

  /// Maximum length (in bases) of Substrand that can be drawn on this Helix.
  int _max_bases = -1;

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

  List<BoundSubstrand> _substrands = [];

  Helix({grid_position, max_bases}) {
    this._grid_position = grid_position;
    this._max_bases = max_bases;
    _set_change_notifier();
  }

  dynamic to_json_serializable() {
    Map<String, dynamic> json_map = {};

    if (this.has_grid_position()) {
      json_map[constants.grid_position_key] = this.grid_position;
    }

    if (this.has_nondefault_svg_position()) {
      json_map[constants.svg_position_key] = [this.svg_position.x, this.svg_position.y];
    }

    if (this.has_nondefault_max_bases()) {
      json_map[constants.max_bases_key] = this.max_bases;
    }

    return NoIndent(json_map);
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

  bool has_max_bases() => this._max_bases != null;

  bool has_nondefault_max_bases() {
    int max_ss_offset = -1;
    for (var ss in this._substrands) {
      if (max_ss_offset < ss.end) {
        max_ss_offset = ss.end;
      }
    }
    return this.max_bases != max_ss_offset;
  }

  Helix.from_json(Map<String, dynamic> json_map) {
    this._set_change_notifier();

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

    if (json_map.containsKey(constants.max_bases_key)) {
      this._max_bases = json_map[constants.max_bases_key];
    }
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

class IllegalDNADesignError implements Exception {
  String cause;

  IllegalDNADesignError(String the_cause) {
    this.cause = '**********************\n'
            '* illegal DNA design *\n'
            '**********************\n\n' +
        the_cause;
  }
}

class StrandError extends IllegalDNADesignError {
  StrandError(Strand strand, String the_cause) : super(the_cause) {
    var first_substrand = strand.first_bound_substrand();
    var last_substrand = strand.last_bound_substrand();

    var msg = '\n'
        'strand length        =  ${strand.dna_length}\n'
        'DNA length           =  ${strand.dna_sequence.length}\n'
        'DNA sequence         =  ${strand.dna_sequence}'
        "strand 5' helix      =  ${first_substrand.helix}\n"
        "strand 5' end offset =  ${first_substrand.offset_5p}\n"
        "strand 3' helix      =  ${last_substrand.helix}\n"
        "strand 3' end offset =  ${last_substrand.offset_3p}\n";

    this.cause += msg;
  }
}

Color parse_json_color(Map json_map) {
  int r = json_map['r'];
  int g = json_map['g'];
  int b = json_map['b'];
  return RgbColor(r, g, b);
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
    if (this.notifier != null) {
      this.notifier.add(this as T);
    }
  }
}
