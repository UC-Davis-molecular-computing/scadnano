import 'dart:math';

import 'package:w_flux/w_flux.dart';
import 'package:color/color.dart';
import 'package:meta/meta.dart';

import '../json_serializable.dart';
import '../dispatcher/actions.dart';
import '../app.dart';
import 'strand.dart';
import 'bound_substrand.dart';
import 'helix.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;

//TODO: support editing an existing DNADesign so that user can modify strands, etc.

//TODO: add a mixin that lets me specify for each class that when it is created using from_json,
//  it should store all the fields that are not used by scadnano,
//  and write them back out on serialization using to_json

//TODO: import/export cadnano files

//TODO: export SVG

/// Represents parts of the Model to serialize
class DNADesign extends Store implements JSONSerializable {
  Action<Null> get save_dna_file => Actions.save_dna_file;

  String version = constants.CURRENT_VERSION;

  Grid grid;

  int major_tick_distance;

  /// helices
  HelicesStore helices_store = HelicesStore();

  List<Helix> get helices => this.helices_store.helices;

  /// strands
  StrandsStore strands_store = StrandsStore();

  List<Strand> get strands => this.strands_store.strands;

  Map<BoundSubstrand, List<Mismatch>> _substrand_mismatches_map = {};

  _handle_actions() {
    this.triggerOnActionV2<Null>(this.save_dna_file, (_) {
      String content = json_encode(this);
      String default_filename = app.model.menu_view_ui_model.loaded_filename;
      util.save_file(default_filename, content);
    });

    this.strands_store.triggerOnActionV2<Strand>(Actions.strand_remove, remove_strand);
    this.strands_store.triggerOnActionV2<Strand>(Actions.strand_add, add_strand);
    this.strands_store.triggerOnActionV2<Iterable<Strand>>(Actions.strands_remove, remove_strands);
    this.strands_store.triggerOnActionV2<Iterable<Strand>>(Actions.strands_add, add_strands);

    this.helices_store.triggerOnActionV2<HelixUseActionParameters>(Actions.helix_use, (params) {
      params.create ? this._add_helix(params) : this._remove_helix(params);
    });

    this.helices_store.triggerOnActionV2<List<Helix>>(Actions.set_helices, (new_helices) {
      this.helices_store.helices = new_helices;
    });
  }

  _add_helix(HelixUseActionParameters params) {
    Helix helix = Helix(
        grid_position: params.grid_position,
        max_offset: params.max_offset,
        min_offset: params.min_offset,
        major_tick_distance: params.major_tick_distance,
        major_ticks: params.major_ticks);
    helix.set_idx(params.idx);

    this.helices.insert(params.idx, helix);
    this.helices_store.gp_to_helix[params.grid_position] = helix;

    for (Helix helix_after_idx_used in this.helices.sublist(params.idx + 1)) {
      int prev_idx = helix_after_idx_used.idx();
      helix_after_idx_used.set_idx(prev_idx + 1);
    }
  }

  _remove_helix(HelixUseActionParameters params) {
    Helix old_helix = this.helices_store.gp_to_helix[params.grid_position];
    int old_idx = old_helix.idx();
    assert(old_idx == params.idx);

    this.helices.removeAt(old_idx);

    for (Helix helix_after_idx_unused in this.helices.sublist(old_idx)) {
      int prev_idx = helix_after_idx_unused.idx();
      helix_after_idx_unused.set_idx(prev_idx - 1);
    }
  }

  add_strand(Strand strand) {
    this.strands.add(strand);
    for (BoundSubstrand ss in strand.bound_substrands()) {
      this.helices[ss.helix].bound_substrands().add(ss);
    }
  }

  remove_strand(Strand strand) {
    this.strands.remove(strand);
    for (BoundSubstrand ss in strand.bound_substrands()) {
      this.helices[ss.helix].bound_substrands().remove(ss);
    }
  }

  add_strands(Iterable<Strand> strands) {
    for (Strand strand in strands) {
      add_strand(strand);
    }
  }

  remove_strands(Iterable<Strand> strands) {
    for (Strand strand in strands) {
      remove_strand(strand);
    }
  }

  DNADesign() {
    this._handle_actions();
  }

  //"private" constructor; meta package will warn if it is used outside testing
  @visibleForTesting
  DNADesign.internal() {
    this._handle_actions();
  }

  DNADesign.default_design({int num_helices_x = 10, int num_helices_y = 10}) {
    this._handle_actions();
    this.grid = Grid.square;
    this.major_tick_distance = 8;
  }

  /// max offset allowed on any Helix in the Model
  int max_offset() {
    int ret = 0;
    for (var helix in this.helices) {
      if (ret < helix.max_offset) {
        ret = helix.max_offset;
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
    json_map[constants.strands_key] = [for (var strand in this.strands) strand.to_json_serializable()];

    return json_map;
  }

  /// Replace this DNADesign with the one described in json_map.
  read_from_json(Map<String, dynamic> json_map) {
//  DNADesign.from_json(Map<String, dynamic> json_map) {
    //TODO: add test for illegally overlapping substrands on Helix (copy algorithm from Python repo)

    this.version =
        json_map.containsKey(constants.version_key) ? json_map[constants.version_key] : constants.INITIAL_VERSION;

    this.grid = json_map.containsKey(constants.grid_key) ? grid_from_string(json_map[constants.grid_key]) : Grid.none;

    if (json_map.containsKey(constants.major_tick_distance_key)) {
      this.major_tick_distance = json_map[constants.major_tick_distance_key];
    } else if (json_map.containsKey(constants.grid_key)) {
      if (this.grid == Grid.hex || this.grid == Grid.honeycomb) {
        this.major_tick_distance = 7;
      } else {
        this.major_tick_distance = 8;
      }
    }

    List<Helix> helices = [];
    List<dynamic> deserialized_helices_list = json_map[constants.helices_key];
    int idx = 0;
    for (var helix_json in deserialized_helices_list) {
      Helix helix = Helix.from_json(helix_json);
      helix.set_idx(idx++);
      helices.add(helix);
    }

    //XXX: it's important that we keep the Store the same, so we don't assign to this.helices_store.
    // However, we can't send an Action to change it because we need the new data right away to build more
    // internal data (e.g., _build_helix_idx_substrands_map and _build_substrand_mismatches_map below).
    // Instead we directly mutate the Store (against the wishes of Flux) and then do a manual trigger at the end.
    this.helices_store.helices = helices;

    List<Strand> strands = [];
    List<dynamic> deserialized_strand_list = json_map[constants.strands_key];
    for (var strand_json in deserialized_strand_list) {
      Strand strand = Strand.from_json(strand_json);
      strands.add(strand);
    }
    this.strands_store.strands = strands;

    //XXX: order of these is important because each uses the data calculated from the previous
    this._set_helices_idxs();
    this._set_helices_grid_and_svg_positions();
    this._build_helix_idx_substrands_map();
    this._set_helices_max_offsets(update: false);

    //TODO: maybe move strand (and maybe helix) functionality into stores
    this._build_substrand_mismatches_map();
    this._check_legal_design();

    //FIXME: side view does not re-render on file load unless this is explicitly triggered
    this.helices_store.trigger();
  }

  static int default_major_tick_distance(Grid grid) {
    return grid == Grid.hex || grid == Grid.honeycomb ? 7 : 8;
  }

  _set_helices_idxs() {
    for (int idx = 0; idx < this.helices.length; idx++) {
      var helix = this.helices[idx];
      helix.set_idx(idx);
    }
  }

  _set_helices_grid_and_svg_positions() {
    for (int idx = 0; idx < this.helices.length; idx++) {
      var helix = this.helices[idx];
      if (helix.grid_position == null) {
        helix.set_default_grid_position();
      }
      if (helix.svg_position == null) {
        helix.set_default_svg_position();
      }
    }
  }

  _set_helices_max_offsets({bool update = true}) {
    for (var helix in this.helices) {
      if (update || !helix.has_max_offset()) {
        var max_bases = -1;
        for (var substrand in helix.bound_substrands()) {
          max_bases = max(max_bases, substrand.end);
        }
        helix.set_max_bases_directly(max_bases);
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
          this.helices[bound_ss.helix].bound_substrands().add(bound_ss);
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
    if (ret == null) {
      ret = List<Mismatch>();
    }
    return ret;
  }

  /// Return list of substrands on the Helix with the given index.
  substrands_on_helix(int helix_idx) {
    return this.helices[helix_idx].bound_substrands();
  }

  /// Return list of Substrands overlapping `substrand`.
  List<BoundSubstrand> _other_substrands_overlapping(BoundSubstrand substrand) {
    List<BoundSubstrand> ret = [];
    var helix = this.helices[substrand.helix];
    for (var other_ss in helix.bound_substrands()) {
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

class Mismatch {
  final int dna_idx;
  final int offset;
  final int within_insertion;

  Mismatch(this.dna_idx, this.offset, {this.within_insertion = -1});

  String toString() =>
      'Mismatch(dna_idx=${this.dna_idx}, offset=${this.offset}' +
      (this.within_insertion < 0 ? ')' : ', within_insertion=${this.within_insertion})');
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
        'strand length        =  ${strand.dna_length()}\n'
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
