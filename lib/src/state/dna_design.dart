import 'dart:math';

import 'package:collection/collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'crossover.dart';
import 'dna_end.dart';
import 'grid_position.dart';
import '../json_serializable.dart';
import 'strand.dart';
import 'bound_substrand.dart';
import 'helix.dart';
import 'grid.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'substrand.dart';

part 'dna_design.g.dart';

//TODO: create mismatches field in DNADesign that can be accessed directly by DesignMainMismatches instead of
// going through list of all Strands

abstract class DNADesign implements Built<DNADesign, DNADesignBuilder>, JSONSerializable {
  DNADesign._();

  factory DNADesign([void Function(DNADesignBuilder) updates]) => _$DNADesign((d) => d
    ..version = constants.CURRENT_VERSION
    ..grid = Grid.square
    ..is_origami = false
    ..helices.replace([])
    ..strands.replace([]));

  /****************************** end built_value boilerplate ******************************/

  String get version;

  Grid get grid;

  @nullable
  int get major_tick_distance;

  BuiltList<Helix> get helices;

  BuiltList<Strand> get strands;

//  BuiltList<int> get helices_view_order;

  @nullable
  bool get is_origami;

  @memoized
  BuiltMap<String, Strand> get strands_by_id {
    var builder = MapBuilder<String, Strand>();
    for (var strand in strands) {
      builder[strand.id()] = strand;
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, BoundSubstrand> get bound_substrands_by_id {
    var builder = MapBuilder<String, BoundSubstrand>();
    for (var strand in strands) {
      for (var bound_substrand in strand.bound_substrands()) {
        builder[bound_substrand.id()] = bound_substrand;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, Loopout> get loopouts_by_id {
    var builder = MapBuilder<String, Loopout>();
    for (var strand in strands) {
      for (var loopout in strand.loopouts()) {
        builder[loopout.id()] = loopout;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, Crossover> get crossovers_by_id {
    var builder = MapBuilder<String, Crossover>();
    for (var strand in strands) {
      for (var crossover in strand.crossovers) {
        builder[crossover.id()] = crossover;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      for (var bound_substrand in strand.bound_substrands()) {
        builder[bound_substrand.dnaend_start.id()] = bound_substrand.dnaend_start;
        builder[bound_substrand.dnaend_end.id()] = bound_substrand.dnaend_end;
      }
    }
    return builder.build();
  }

  Selectable selectable_by_id(String id) {
    Selectable selectable;

    selectable = strands_by_id[id];
    if (selectable != null) {
      return selectable;
    }

    selectable = loopouts_by_id[id];
    if (selectable != null) {
      return selectable;
    }

    selectable = crossovers_by_id[id];
    if (selectable != null) {
      return selectable;
    }

    selectable = ends_by_id[id];
    if (selectable != null) {
      return selectable;
    }

    return selectable;
  }

  @memoized
  BuiltMap<BoundSubstrand, BuiltList<Mismatch>> get substrand_mismatches_map {
    var substrand_mismatches_map_builder = MapBuilder<BoundSubstrand, ListBuilder<Mismatch>>();
    for (Strand strand in this.strands) {
      if (strand.dna_sequence != null) {
        for (BoundSubstrand bound_ss in strand.bound_substrands()) {
          substrand_mismatches_map_builder[bound_ss] = this._find_mismatches_on_substrand(bound_ss);
        }
      }
    }
    var substrand_mismatches_builtmap_builder = MapBuilder<BoundSubstrand, BuiltList<Mismatch>>();
    substrand_mismatches_map_builder.build().forEach((bound_ss, mismatches) {
      substrand_mismatches_builtmap_builder[bound_ss] = mismatches.build();
    });
    return substrand_mismatches_builtmap_builder.build();
  }

  @memoized
  BuiltMap<DNAEnd, BoundSubstrand> get end_to_substrand {
    var end_to_substrand_builder = MapBuilder<DNAEnd, BoundSubstrand>();
    for (var strand in strands) {
      for (var substrand in strand.bound_substrands()) {
        end_to_substrand_builder[substrand.dnaend_3p] = substrand;
        end_to_substrand_builder[substrand.dnaend_5p] = substrand;
      }
    }
    return end_to_substrand_builder.build();
  }

  @memoized
  BuiltMap<Substrand, Strand> get substrand_to_strand {
    var substrand_to_strand_builder = MapBuilder<Substrand, Strand>();
    for (var strand in strands) {
      for (var substrand in strand.substrands) {
        substrand_to_strand_builder[substrand] = strand;
      }
    }
    return substrand_to_strand_builder.build();
  }

  @memoized
  BuiltMap<Crossover, Strand> get crossover_to_strand {
    var crossover_to_strand_builder = MapBuilder<Crossover, Strand>();
    for (var strand in strands) {
      for (var crossover in strand.crossovers) {
        crossover_to_strand_builder[crossover] = strand;
      }
    }
    return crossover_to_strand_builder.build();
  }

  Strand loopout_to_strand(Loopout loopout) => substrand_to_strand[loopout];

  Strand end_to_strand(DNAEnd end) => substrand_to_strand[end_to_substrand[end]];

  @memoized
  BuiltList<BuiltSet<BoundSubstrand>> get helix_idx_to_substrands {
    return _construct_helix_idx_to_substrands_map(helices.length, strands);
  }

  @memoized
  bool get helices_view_order_is_identity {
    for (var helix in helices) {
      if (helix.idx != helix.view_order) {
        return false;
      }
    }
    return true;
  }

  static _default_svg_position(int idx) => Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * idx);

  static _default_grid_position(int idx) => GridPosition(0, idx);

  @memoized
  BuiltMap<GridPosition, dynamic> get gp_to_helix {
    var map_builder = MapBuilder<GridPosition, Helix>();
    for (var helix in helices) {
      map_builder[helix.grid_position] = helix;
    }
    return map_builder.build();
  }

//  _add_helix(HelixUseActionParameters params) {
////    Helix helix = Helix(
////        grid_position: params.grid_position,
////        max_offset: params.max_offset,
////        min_offset: params.min_offset,
////        major_tick_distance: params.major_tick_distance,
////        major_ticks: params.major_ticks);
////    helix.set_idx(params.idx);
//
//    Helix helix = Helix((h) => h
//      ..grid_position = params.grid_position.toBuilder()
//      ..max_offset = params.max_offset
//      ..min_offset = params.min_offset
//      ..major_tick_distance = params.major_tick_distance
//      ..major_ticks = params.major_ticks
//      ..idx = params.idx
//      ..svg_position = _default_svg_position(params.idx));
//
//    this.helices.insert(params.idx, helix);
//    this.gp_to_helix[params.grid_position] = helix;
////    this.helices_store.gp_to_helix[params.grid_position] = helix;
//
//    for (int idx = params.idx + 1; idx < this.helices.length; idx++) {
//      helices[idx] = helices[idx].rebuild((h) => h
//        ..idx = idx
//        ..svg_position = _default_svg_position(idx));
//    }
//
////    for (Helix helix_after_idx_used in this.helices.sublist(params.idx + 1)) {
////      int prev_idx = helix_after_idx_used.idx();
////      helix_after_idx_used.set_idx(prev_idx + 1);
////    }
//  }
//
//  _remove_helix(HelixUseActionParameters params) {
////    Helix old_helix = this.helices_store.gp_to_helix[params.grid_position];
//    Helix old_helix = this.gp_to_helix[params.grid_position];
////    int old_idx = old_helix.idx;
////    assert(old_idx == params.idx);
//
//    this.helices.removeAt(old_helix.idx);
//    for (int idx = old_helix.idx; idx < this.helices.length; idx++) {
//      helices[idx] = helices[idx].rebuild((h) => h
//        ..idx = idx
//        ..svg_position = _default_svg_position(idx));
//    }
//
////    for (Helix helix_after_idx_unused in this.helices.sublist(old_idx)) {
////      int prev_idx = helix_after_idx_unused.idx();
////      helix_after_idx_unused.set_idx(prev_idx - 1);
////    }
//  }

  //TODO: profile to see if it would help to optimize rebuilding of memoized data; currently it is
  // rebuilt from scratch even if we only add a single Strand
  DNADesign add_strand(Strand strand) => rebuild((d) => d..strands.add(strand));

  DNADesign add_strands(Iterable<Strand> new_strands) => rebuild((d) => d..strands.addAll(new_strands));

  DNADesign remove_strand(Strand strand) => rebuild((d) => d..strands.remove(strand));

  DNADesign remove_strands(Iterable<Strand> strands_to_remove) {
    Set<Strand> strands_to_remove_set = strands_to_remove.toSet();
    return rebuild((d) => d..strands.removeWhere((strand) => strands_to_remove_set.contains(strand)));
  }

  /// max offset allowed on any Helix in the Model
  @memoized
  int get max_offset => helices.map((helix) => helix.max_offset).reduce(max);

  /// min offset allowed on any Helix in the Model
  @memoized
  int get min_offset => helices.map((helix) => helix.min_offset).reduce(min);

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {constants.version_key: this.version};

    if (this.grid != constants.default_grid) {
//      json_map[constants.grid_key] = grid_to_json(this.grid);
      json_map[constants.grid_key] = this.grid.to_json();
    }
    if (this.major_tick_distance != grid.default_major_tick_distance()) {
      json_map[constants.major_tick_distance_key] = this.major_tick_distance;
    }

    List<dynamic> helix_jsons = json_map[constants.helices_key] = [
      for (var helix in this.helices) helix.to_json_serializable(suppress_indent: suppress_indent)
    ];
    json_map[constants.strands_key] = [
      for (var strand in this.strands) strand.to_json_serializable(suppress_indent: suppress_indent)
    ];

    for (int i = 0; i < helices.length; i++) {
      var helix = helices[i];
      var helix_json = helix_jsons[i];
      if (helix.has_max_offset() && has_nondefault_max_offset(helix)) {
        helix_json[constants.max_offset_key] = helix.max_offset;
      }
      if (helix.has_min_offset() && has_nondefault_min_offset(helix)) {
        helix_json[constants.min_offset_key] = helix.min_offset;
      }
    }

    return json_map;
  }

  bool has_nondefault_max_offset(Helix helix) {
    var ends = substrands_on_helix(helix.idx).map((ss) => ss.end);
    int max_end = ends.isEmpty ? 0 : ends.reduce(max);
    return helix.max_offset != max_end;
  }

  bool has_nondefault_min_offset(Helix helix) {
    var starts = substrands_on_helix(helix.idx).map((ss) => ss.start);
    int min_start = starts.isEmpty ? null : starts.reduce(min);
    // if all offsets are nonnegative (or there are no substrands, i.e., min_start == null),
    // then default min_offset is 0; otherwise it is minimum offset
    if (min_start == null || min_start >= 0) {
      return helix.min_offset != 0;
    } else {
      return helix.min_offset != min_start;
    }
  }

  static DNADesign from_json(Map<String, dynamic> json_map) {
    var dna_design_builder = DNADesignBuilder();

    dna_design_builder.version =
        util.get_value_with_default(json_map, constants.version_key, constants.INITIAL_VERSION);
    dna_design_builder.grid =
        util.get_value_with_default(json_map, constants.grid_key, Grid.square, transformer: Grid.valueOf);

    if (json_map.containsKey(constants.major_tick_distance_key)) {
      dna_design_builder.major_tick_distance = json_map[constants.major_tick_distance_key];
    } else if (!dna_design_builder.grid.is_none()) {
      if (dna_design_builder.grid == Grid.hex || dna_design_builder.grid == Grid.honeycomb) {
        dna_design_builder.major_tick_distance = 7;
      } else {
        dna_design_builder.major_tick_distance = 8;
      }
    }

    List<HelixBuilder> helix_builders = [];
    List<dynamic> deserialized_helices_list = json_map[constants.helices_key];
    int num_helices = deserialized_helices_list.length;

    // create HelixBuilders
    int idx = 0;
    for (var helix_json in deserialized_helices_list) {
      HelixBuilder helix_builder = Helix.from_json(helix_json);
      helix_builder.idx = idx;
      helix_builder.grid = dna_design_builder.grid;
      helix_builders.add(helix_builder);
      idx++;
    }

    // view order of helices
    var identity_permutation = util.identity_permutation(num_helices);
    List<int> helices_view_order = List<int>.from(util.get_value_with_default(
        json_map, constants.helices_view_order_key, identity_permutation));
    if (helices_view_order.length != num_helices) {
      throw IllegalDNADesignError('length of helices (${num_helices}) does not match '
          'length of helices_view_order (${helices_view_order.length})');
    }
    var helices_view_order_sorted = List<int>.from(helices_view_order);
    helices_view_order_sorted.sort();
    if (!ListEquality().equals(helices_view_order_sorted, identity_permutation)) {
      throw IllegalDNADesignError('helices_view_order = ${helices_view_order} is not a permutation');
    }
    for (int i = 0; i < helices_view_order.length; i++) {
      int i_unsorted = helices_view_order[i];
      var helix_builder = helix_builders[i_unsorted];
      int view_order = i;
      helix_builder.view_order = view_order;
//      if (helix_builder.svg_position == null) {
//        helix_builder.svg_position = DNADesign._default_svg_position(display_order);
//      }
      if (helix_builder.grid_position == null) {
        helix_builder.grid_position = DNADesign._default_grid_position(view_order);
      }
    }

    // strands
    bool is_origami = false;
    List<Strand> strands = [];
    List<dynamic> deserialized_strand_list = json_map[constants.strands_key];
    for (var strand_json in deserialized_strand_list) {
      Strand strand = Strand.from_json(strand_json);
      strands.add(strand);
      if (strand.is_scaffold == true) {
        is_origami = true;
      }
    }
    if (is_origami == true) {
      dna_design_builder.is_origami = true;
    }
    dna_design_builder.strands.replace(strands);

    _set_helices_min_max_offsets(helix_builders, dna_design_builder.strands.build());

    // build Helices
    List<Helix> helices = [for (var helix_builder in helix_builders) helix_builder.build()];
    dna_design_builder.helices.replace(helices);

    var dna_design = dna_design_builder.build();
    dna_design._check_legal_design();

    return dna_design;
  }

  _check_legal_design() {
//    TODO: implement this and give reasonable error messages
  }

  String toString() => """DNADesign(is_origami=$is_origami, grid=$grid, major_tick_distance=$major_tick_distance, 
  helices=$helices, 
  strands=$strands)""";

  ListBuilder<Mismatch> _find_mismatches_on_substrand(BoundSubstrand substrand) {
    var mismatches = ListBuilder<Mismatch>();

    for (int offset = substrand.start; offset < substrand.end; offset++) {
      if (substrand.deletions.contains(offset)) {
        continue;
      }

      var other_ss = this.other_substrand_at_offset(substrand, offset);
      if (other_ss == null || other_ss.dna_sequence == null) {
        continue;
      }

      this._ensure_other_substrand_same_deletion_or_insertion(substrand, other_ss, offset);

      var seq = substrand.dna_sequence_in(offset, offset);
      var other_seq = other_ss.dna_sequence_in(offset, offset);
      assert(other_seq.length == seq.length);

      for (int idx = 0, idx_other = seq.length - 1; idx < seq.length; idx++, idx_other--) {
        if (seq.codeUnitAt(idx) != _wc(other_seq.codeUnitAt(idx_other))) {
          int dna_idx = substrand.offset_to_substrand_dna_idx(offset, substrand.forward) + idx;
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
  BuiltList<Mismatch> mismatches_on_substrand(BoundSubstrand substrand) {
    var ret = this.substrand_mismatches_map[substrand];
    if (ret == null) {
      ret = BuiltList<Mismatch>();
    }
    return ret;
  }

  /// Return set of substrands on the Helix with the given index.
  BuiltSet<BoundSubstrand> substrands_on_helix(int helix_idx) => helix_idx_to_substrands[helix_idx];

//  Set<BoundSubstrand> substrands_on_helix_at(int helix_idx, int offset) => helix_idx_to_substrands[helix_idx];

  /// Return [Substrand]s at [offset], INCLUSIVE on left and EXCLUSIVE on right.
  BuiltSet<BoundSubstrand> substrands_on_helix_at(int helix_idx, int offset) {
    var substrands_at_offset = SetBuilder<BoundSubstrand>({
      for (var substrand in this.helix_idx_to_substrands[helix_idx]) if (substrand.contains_offset(offset)) substrand
    });
    return substrands_at_offset.build();
  }

  /// Return list of Substrands overlapping `substrand`.
  List<BoundSubstrand> _other_substrands_overlapping(BoundSubstrand substrand) {
    List<BoundSubstrand> ret = [];
    var helix = this.helices[substrand.helix];
    for (var other_ss in helix_idx_to_substrands[helix.idx]) {
      if (substrand.overlaps(other_ss)) {
        ret.add(other_ss);
      }
    }
    return ret;
  }

  /// Number of bases between start and end offsets, inclusive, on the given [Helix].
  /// Accounts for substrands with insertions and deletions on [BoundSubstrand]s on this Helix, but not if they
  /// are inconsistent (on one [BoundSubstrand] but not the other).
  int helix_num_bases_between(Helix helix, int start, int end) {
    if (start > end) {
      int swap = start;
      start = end;
      end = swap;
    }

    List<BoundSubstrand> substrands_intersecting = [];
    for (var ss in this.helix_idx_to_substrands[helix.idx]) {
      if (start < ss.end && ss.start <= end) {
        substrands_intersecting.add(ss);
      }
    }

    Set<int> deletions_intersecting = {};
    Set<Insertion> insertions_intersecting = {};
    for (var ss in substrands_intersecting) {
      for (var deletion in ss.deletions) {
        if (start <= deletion && deletion <= end) {
          deletions_intersecting.add(deletion);
        }
      }
      for (var insertion in ss.insertions) {
        if (start <= insertion.offset && insertion.offset <= end) {
          insertions_intersecting.add(insertion);
        }
      }
    }

    int total_insertion_length = 0;
    for (var insertion in insertions_intersecting) {
      total_insertion_length += insertion.length;
    }

    int dna_length = end - start + 1 - deletions_intersecting.length + total_insertion_length;

    return dna_length;
  }

  /// in radians
  double helix_rotation_3p(Helix helix, int offset) {
    int num_bases;
    if (helix.rotation_anchor < offset) {
      num_bases = this.helix_num_bases_between(helix, helix.rotation_anchor, offset - 1);
    } else if (helix.rotation_anchor > offset) {
      num_bases = -this.helix_num_bases_between(helix, offset + 1, helix.rotation_anchor);
    } else {
      num_bases = 0;
    }
//    num rad = (helix.rotation + (2 * pi * num_bases / 10.5)) % (2 * pi);
//    return rad;
//    num rad = (util.to_radians(helix.rotation) + (2 * pi * num_bases / 10.5)) % (2 * pi);
//    return util.to_degrees(rad);
    num rot = (helix.rotation + (360 * num_bases / 10.5)) % (360);
    return rot;
  }

  /// in radians;  3' rotation + 150 degrees
  double helix_rotation_5p(Helix helix, int offset) =>
//      this.helix_rotation_3p(helix, offset) + (2 * pi * 150.0 / 360.0);
      this.helix_rotation_3p(helix, offset) + 150;

  bool helix_has_nondefault_max_offset(Helix helix) {
    int max_ss_offset = -1;
    for (var ss in this.helix_idx_to_substrands[helix.idx]) {
      if (max_ss_offset < ss.end) {
        max_ss_offset = ss.end;
      }
    }
    return helix.max_offset != max_ss_offset;
  }

  bool helix_has_nondefault_min_offset(Helix helix) {
    int min_ss_offset = -1;
    for (var ss in this.helix_idx_to_substrands[helix.idx]) {
      if (min_ss_offset > ss.start) {
        min_ss_offset = ss.start;
      }
    }
    return helix.min_offset != min_ss_offset;
  }

  bool helix_has_substrands(Helix helix) => this.helix_idx_to_substrands[helix.idx].isNotEmpty;

  @memoized
  BuiltList<int> get helices_view_order_inverse {
    List<int> helices_view_order_inverse = List<int>(helices.length);
    for (int i = 0; i < helices.length; i++) {
      int i_unsorted = helices[i].view_order;
      helices_view_order_inverse[i_unsorted] = i;
    }
    return helices_view_order_inverse.toBuiltList();
  }
}

BuiltList<BuiltSet<BoundSubstrand>> _construct_helix_idx_to_substrands_map(int num_helices, Iterable<Strand> strands) {
  var helix_idx_to_substrands_builder = ListBuilder<SetBuilder<BoundSubstrand>>();
  for (int _ = 0; _ < num_helices; _++) {
    helix_idx_to_substrands_builder.add(SetBuilder<BoundSubstrand>());
  }
  for (Strand strand in strands) {
    for (Substrand substrand in strand.substrands) {
      if (substrand.is_bound_substrand()) {
        var bound_ss = substrand as BoundSubstrand;
        helix_idx_to_substrands_builder[bound_ss.helix].add(bound_ss);
      }
    }
  }
  var helix_idx_to_substrands_builtset_builder = ListBuilder<BuiltSet<BoundSubstrand>>();
  for (var set in helix_idx_to_substrands_builder.build()) {
    helix_idx_to_substrands_builtset_builder.add(set.build());
  }
  return helix_idx_to_substrands_builtset_builder.build();
}

_set_helices_min_max_offsets(List<HelixBuilder> helix_builders, Iterable<Strand> strands) {
  var helix_idx_to_substrands = _construct_helix_idx_to_substrands_map(helix_builders.length, strands);

  for (int idx = 0; idx < helix_builders.length; idx++) {
    HelixBuilder helix_builder = helix_builders[idx];

    if (helix_builder.max_offset == null) {
      var substrands = helix_idx_to_substrands[helix_builder.idx];
      var max_offset = substrands.isEmpty ? 0 : substrands.first.end; // in case of no substrands, max offset is 0
      for (var substrand in substrands) {
        max_offset = max(max_offset, substrand.end);
      }
      helix_builder.max_offset = max_offset;
    }

    if (helix_builder.min_offset == null) {
      var substrands = helix_idx_to_substrands[helix_builder.idx];
      var min_offset = substrands.isEmpty ? 0 : substrands.first.start; // in case of no substrands, min offset is 0
      for (var substrand in substrands) {
        min_offset = min(min_offset, substrand.start);
      }
      if (min_offset > 0) {
        min_offset = 0;
      }
      helix_builder.min_offset = min_offset;
    }
  }

//  _build_end_to_substrand_map() {
//    var end_to_substrand_builder = MapBuilder<DNAEnd, BoundSubstrand>();
//    for (var strand in strands) {
//      for (var substrand in strand.bound_substrands()) {
//        end_to_substrand_builder[substrand.dnaend_3p] = substrand;
//        end_to_substrand_builder[substrand.dnaend_5p] = substrand;
//      }
//    }
//    end_to_substrand = end_to_substrand_builder.build();
//  }

//  _build_substrand_to_strand_map() {
//    var substrand_to_strand_builder = MapBuilder<Substrand, Strand>();
//    for (var strand in strands) {
//      for (var substrand in strand.substrands) {
//        substrand_to_strand_builder[substrand] = strand;
//      }
//    }
//    substrand_to_strand = substrand_to_strand_builder.build();
//  }

//  _build_helix_idx_to_substrands_list(int num_helices) {
//    var helix_idx_to_substrands_builder = ListBuilder<SetBuilder<BoundSubstrand>>();
//    for (int _ = 0; _ < num_helices; _++) {
//      helix_idx_to_substrands_builder.add(SetBuilder<BoundSubstrand>());
//    }
//    for (Strand strand in this.strands) {
//      for (Substrand substrand in strand.substrands) {
//        if (substrand.is_bound_substrand()) {
//          var bound_ss = substrand as BoundSubstrand;
//          helix_idx_to_substrands_builder[bound_ss.helix].add(bound_ss);
//        }
//      }
//    }
//    var helix_idx_to_substrands_builtset_builder = ListBuilder<BuiltSet<BoundSubstrand>>();
//    for (var set in helix_idx_to_substrands_builder.build()) {
//      helix_idx_to_substrands_builtset_builder.add(set.build());
//    }
//    helix_idx_to_substrands = helix_idx_to_substrands_builtset_builder.build();
//  }

//  _build_substrand_mismatches_map() {
//    var substrand_mismatches_map_builder = MapBuilder<BoundSubstrand, ListBuilder<Mismatch>>();
////    this._substrand_mismatches_map = {};
//    for (Strand strand in this.strands) {
//      if (strand.dna_sequence != null) {
//        for (BoundSubstrand bound_ss in strand.bound_substrands()) {
//          substrand_mismatches_map_builder[bound_ss] = this._find_mismatches_on_substrand(bound_ss);
//        }
//      }
//    }
//    var substrand_mismatches_builtmap_builder = MapBuilder<BoundSubstrand, BuiltList<Mismatch>>();
//    substrand_mismatches_map_builder.build().forEach ((bound_ss, mismatches) {
//      substrand_mismatches_builtmap_builder[bound_ss] = mismatches.build();
//    });
//    _substrand_mismatches_map = substrand_mismatches_builtmap_builder.build();
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

  IllegalDNADesignError(this.cause);
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
