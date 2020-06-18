import 'dart:math';

import 'package:collection/collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/potential_vertical_crossover.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:tuple/tuple.dart';
import 'crossover.dart';
import 'dna_end.dart';
import 'grid_position.dart';
import '../json_serializable.dart';
import 'modification.dart';
import 'strand.dart';
import 'domain.dart';
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
    ..helices.replace({})
    ..strands.replace([])
    ..unused_fields = MapBuilder<String, Object>({}));

  /****************************** end built_value boilerplate ******************************/
  @memoized
  int get hashCode;

  String get version;

  Grid get grid;

  @nullable
  int get major_tick_distance;

  BuiltMap<int, Helix> get helices;

  BuiltList<Strand> get strands;

  BuiltMap<String, Object> get unused_fields;

  @memoized
  bool get is_origami {
    for (var strand in strands) {
      if (strand.is_scaffold) {
        return true;
      }
    }
    return false;
  }

  // like crossovers_by_helix_idx, but maps to sets instead of lists
  @memoized
  BuiltMap<int, BuiltSet<Crossover>> get crossovers_by_helix_idx_as_sets =>
      {for (int idx in crossovers_by_helix_idx.keys) idx: crossovers_by_helix_idx[idx].toBuiltSet()}.build();

  // all crossovers incident on helix with given idx, sorted by offset on that helix
  @memoized
  BuiltMap<int, BuiltList<Crossover>> get crossovers_by_helix_idx {
    // convert to proper return type by dropping the offset
    Map<int, BuiltList<Crossover>> builder = {
      for (int idx in address_crossover_pairs_by_helix_idx.keys)
        idx: address_crossover_pairs_by_helix_idx[idx]
            .map((address_crossover_pair) => address_crossover_pair.item2)
            .toBuiltList()
    };

    return builder.build();
  }

  // all (offset,crossover) pairs incident on helix with given idx, sorted by offset on that helix
  // offset is inclusive on either end. This ensures that each half of a double crossover actual
  // has different offsets, and the leftmost one is considered smaller.
  @memoized
  BuiltMap<int, BuiltList<Tuple2<Address, Crossover>>> get address_crossover_pairs_by_helix_idx {
    // this is essentially what we return, but each crossover also carries with it the start offset of
    // the helix earlier in the ordering, which helps to sort the lists of crossovers before returning
    Map<int, List<Tuple2<Address, Crossover>>> address_crossover_pairs = {};

    // initialize internal map to have empty lists
    for (int helix_idx in helices.keys) {
      address_crossover_pairs[helix_idx] = [];
    }

    // populate internal map with offsets along with lists
    for (var strand in strands) {
      for (var crossover in strand.crossovers) {
        var prev_dom = strand.substrands[crossover.prev_domain_idx] as Domain;
        var next_dom = strand.substrands[crossover.next_domain_idx] as Domain;
        bool is_prev = true;
        for (var dom in [prev_dom, next_dom]) {
          List<Tuple2<Address, Crossover>> address_crossover_pair_list = address_crossover_pairs[dom.helix];
          int offset;
          // ugg, this logic is ugly. Here's the various possibilities
          /*
          !is_prev           is_prev            is_prev            !is_prev
          !dom.forward       dom.forward        !dom.forward       dom.forward
          <----+             [----+             |                  |
               |                  |             +----]             +---->
          */
          if ((is_prev && dom.forward) || (!is_prev && !dom.forward)) {
            offset = dom.end - 1;
          } else {
            offset = dom.start;
          }
          var address = Address(helix_idx: dom.helix, offset: offset, forward: dom.forward);
          var pair = Tuple2<Address, Crossover>(address, crossover);
          address_crossover_pair_list.add(pair);
          is_prev = false;
        }
      }
    }

    // sort by offset where it intersects the helix
    for (var pair_idxs in address_crossover_pairs.keys) {
      List<Tuple2<Address, Crossover>> start_crossover_pair_list = address_crossover_pairs[pair_idxs];
      start_crossover_pair_list.sort((address_crossover_pair1, address_crossover_pair2) {
        Address add1 = address_crossover_pair1.item1;
        Address add2 = address_crossover_pair2.item1;
        return add1.offset - add2.offset;
      });
    }

    // convert to proper return type by dropping the offset
    Map<int, BuiltList<Tuple2<Address, Crossover>>> builder = {
      for (int idx in address_crossover_pairs.keys) idx: address_crossover_pairs[idx].toBuiltList()
    };

    return builder.build();
  }

  @memoized
  BuiltMap<String, Strand> get strands_by_id {
    var builder = MapBuilder<String, Strand>();
    for (var strand in strands) {
      builder[strand.id()] = strand;
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, Domain> get bound_substrands_by_id {
    var builder = MapBuilder<String, Domain>();
    for (var strand in strands) {
      for (var bound_substrand in strand.domains()) {
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
      for (var bound_substrand in strand.domains()) {
        builder[bound_substrand.dnaend_start.id()] = bound_substrand.dnaend_start;
        builder[bound_substrand.dnaend_end.id()] = bound_substrand.dnaend_end;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_5p_strand_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      var end = strand.dnaend_5p;
      builder[end.id()] = end;
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_3p_strand_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      var end = strand.dnaend_3p;
      builder[end.id()] = end;
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_5p_other_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      for (var bound_substrand in strand.domains()) {
        var end = bound_substrand.dnaend_5p;
        if (!bound_substrand.is_first) {
          builder[end.id()] = end;
        }
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_3p_other_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      for (var bound_substrand in strand.domains()) {
        var end = bound_substrand.dnaend_3p;
        if (!bound_substrand.is_last) {
          builder[end.id()] = end;
        }
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, Selectable> get selectable_by_id {
    Map<String, Selectable> map = {};
    for (var map_small in [strands_by_id, loopouts_by_id, crossovers_by_id, ends_by_id]) {
      for (var key in map_small.keys) {
        var obj = map_small[key];
        map[key] = obj;
      }
    }
    return map.build();
  }

  @memoized
  BuiltMap<Domain, BuiltList<Mismatch>> get substrand_mismatches_map {
    var substrand_mismatches_map_builder = MapBuilder<Domain, ListBuilder<Mismatch>>();
    for (Strand strand in this.strands) {
      if (strand.dna_sequence != null) {
        for (Domain bound_ss in strand.domains()) {
          substrand_mismatches_map_builder[bound_ss] = this._find_mismatches_on_substrand(bound_ss);
        }
      }
    }
    var substrand_mismatches_builtmap_builder = MapBuilder<Domain, BuiltList<Mismatch>>();
    substrand_mismatches_map_builder.build().forEach((bound_ss, mismatches) {
      substrand_mismatches_builtmap_builder[bound_ss] = mismatches.build();
    });
    return substrand_mismatches_builtmap_builder.build();
  }

  @memoized
  BuiltMap<DNAEnd, Domain> get end_to_substrand {
    var end_to_substrand_builder = MapBuilder<DNAEnd, Domain>();
    for (var strand in strands) {
      for (var substrand in strand.domains()) {
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
  BuiltMap<Strand, int> get strand_to_index {
    var strand_to_index = Map<Strand, int>();
    int idx = 0;
    for (var strand in strands) {
      strand_to_index[strand] = idx++;
    }
    return strand_to_index.build();
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
  BuiltList<int> get helix_idxs => helices.keys.toBuiltList();

  @memoized
  BuiltMap<int, BuiltList<Domain>> get helix_idx_to_substrands {
    return construct_helix_idx_to_substrands_map(strands, helix_idxs);
  }

//  @memoized
//  bool get helices_view_order_is_identity {
//    for (var helix in helices.values) {
//      if (helix.idx != helix.view_order) {
//        return false;
//      }
//    }
//    return true;
//  }

//  static _default_svg_position(int idx) => Point<num>(0, constants.DISTANCE_BETWEEN_HELICES_SVG * idx);
//  static _default_grid_position(int idx) => GridPosition(0, idx);

  @memoized
  BuiltMap<GridPosition, dynamic> get gp_to_helix {
    var map_builder = MapBuilder<GridPosition, Helix>();
    for (var helix in helices.values) {
      map_builder[helix.grid_position] = helix;
    }
    return map_builder.build();
  }

  /// Gets DNAEnd at given address (helix,offset,forward)
  /// Offset is inclusive, i.e., dna_end.offset_inclusive
  @memoized
  BuiltMap<Address, DNAEnd> get address_to_end {
    var map = Map<Address, DNAEnd>();
    for (var strand in strands) {
      for (var ss in strand.domains()) {
        for (var end in [ss.dnaend_start, ss.dnaend_end]) {
          var key = Address(helix_idx: ss.helix, offset: end.offset_inclusive, forward: ss.forward);
          map[key] = end;
        }
      }
    }
    return map.build();
  }

  /// Gets Strand with 5p end at given address (helix,offset,forward)
  /// Offset is inclusive, i.e., dna_end.offset_inclusive
  @memoized
  BuiltMap<Address, Strand> get address_5p_to_strand {
    var map = Map<Address, Strand>();
    for (var strand in strands) {
      var ss = strand.first_domain();
      var key = Address(helix_idx: ss.helix, offset: ss.dnaend_5p.offset_inclusive, forward: ss.forward);
      map[key] = strand;
    }
    return map.build();
  }

  /// Gets Strand with 5p end at given address (helix,offset,forward)
  /// Offset is inclusive, i.e., dna_end.offset_inclusive
  @memoized
  BuiltMap<Address, Strand> get address_3p_to_strand {
    var map = Map<Address, Strand>();
    for (var strand in strands) {
      var ss = strand.last_bound_substrand();
      var key = Address(helix_idx: ss.helix, offset: ss.dnaend_3p.offset_inclusive, forward: ss.forward);
      map[key] = strand;
    }
    return map.build();
  }

  /// Maps Addresses to PotentialVerticalCrossovers.
  /// The end on TOP (i.e., lower helix idx) has the address with the key in the map.
  @memoized
  BuiltList<PotentialVerticalCrossover> get potential_vertical_crossovers {
    List<PotentialVerticalCrossover> crossovers = [];
    for (var strand_5p in strands) {
      var ss = strand_5p.first_domain();
      int helix_idx = ss.helix;
      int offset = ss.dnaend_5p.offset_inclusive;
      bool forward = ss.forward;
      var address_5p = Address(helix_idx: helix_idx, offset: offset, forward: forward);
      for (var address_3p in [
        Address(helix_idx: helix_idx - 1, offset: offset, forward: !forward),
        Address(helix_idx: helix_idx + 1, offset: offset, forward: !forward)
      ]) {
        int helix_idx_top;
        int helix_idx_bot;
        var address_top;
        bool forward_top;
        Domain substrand_top;
        Domain substrand_bot;
        DNAEnd dna_end_top;
        DNAEnd dna_end_bot;
        if (address_3p_to_strand.keys.contains(address_3p)) {
          Strand strand_3p = address_3p_to_strand[address_3p];
          if (strand_5p != strand_3p) {
            if (helix_idx + 1 == address_3p.helix_idx) {
              // 5' end is on top, 3' is on bottom
              helix_idx_top = address_5p.helix_idx;
              address_top = address_5p;
              forward_top = forward;
              substrand_top = ss;
              dna_end_top = substrand_top.dnaend_5p;

              helix_idx_bot = address_3p.helix_idx;
              substrand_bot = strand_3p.last_bound_substrand();
              dna_end_bot = substrand_bot.dnaend_3p;
            } else {
              // 3' end is on top, 5' is on bottom
              helix_idx_top = address_3p.helix_idx;
              address_top = address_3p;
              forward_top = !forward;
              substrand_top = strand_3p.last_bound_substrand();
              dna_end_top = substrand_top.dnaend_3p;

              helix_idx_bot = address_5p.helix_idx;
              substrand_bot = ss;
              dna_end_bot = substrand_bot.dnaend_5p;
            }
          }
        }
        if (helix_idx_top != null) {
          crossovers.add(PotentialVerticalCrossover(
            helix_idx_top: helix_idx_top,
            helix_idx_bot: helix_idx_bot,
            offset: offset,
            forward_top: forward_top,
            color: strand_5p.color.toHexColor().toCssString(),
            substrand_top: substrand_top,
            substrand_bot: substrand_bot,
            dna_end_top: dna_end_top,
            dna_end_bot: dna_end_bot,
          ));
        }
      }
    }
    return crossovers.build();
  }

  /// max offset allowed on any Helix in the Model
  @memoized
  int get max_offset => helices.values.map((helix) => helix.max_offset).reduce(max);

  /// min offset allowed on any Helix in the Model
  @memoized
  int get min_offset => helices.values.map((helix) => helix.min_offset).reduce(min);

  DNADesign add_strand(Strand strand) => rebuild((d) => d..strands.add(strand));

  DNADesign add_strands(Iterable<Strand> new_strands) => rebuild((d) => d..strands.addAll(new_strands));

  DNADesign remove_strand(Strand strand) => rebuild((d) => d..strands.remove(strand));

  DNADesign remove_strands(Iterable<Strand> strands_to_remove) {
    Set<Strand> strands_to_remove_set = strands_to_remove.toSet();
    return rebuild((d) => d..strands.removeWhere((strand) => strands_to_remove_set.contains(strand)));
  }

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {constants.version_key: constants.CURRENT_VERSION};

    json_map.addAll(unused_fields.toMap());

    json_map[constants.grid_key] = this.grid.to_json();

    if (this.major_tick_distance != null && this.major_tick_distance != grid.default_major_tick_distance()) {
      json_map[constants.major_tick_distance_key] = this.major_tick_distance;
    }

    var helix_jsons_map = {
      for (var helix in helices.values)
        helix.idx: helix.to_json_serializable(suppress_indent: suppress_indent)
    };

    // unwrap from NoIndent if necessary
    var helix_jsons_unwrapped =
        List<Map<String, dynamic>>.from(helix_jsons_map.values.map(util.unwrap_from_noindent));
    _remove_helix_idxs_if_default(helix_jsons_unwrapped);

    //
    for (var helix in helices.values) {
      var helix_json = util.unwrap_from_noindent(helix_jsons_map[helix.idx]);
      if (has_nondefault_max_offset(helix)) {
        helix_json[constants.max_offset_key] = helix.max_offset;
      }
      if (has_nondefault_min_offset(helix)) {
        helix_json[constants.min_offset_key] = helix.min_offset;
      }
    }

    json_map[constants.helices_key] = helix_jsons_map.values.toList();

    if (!util.is_increasing(helices_view_order)) {
      var order = helices_view_order.toList();
      json_map[constants.helices_view_order_key] = suppress_indent ? NoIndent(order) : order;
    }

    // modifications
    var mods = this._all_modifications();
    if (mods.length > 0) {
      Map<String, dynamic> mods_map = {};
      for (var mod in mods) {
        if (!mods_map.containsKey(mod.id)) {
          mods_map[mod.id] = mod.to_json_serializable(suppress_indent: suppress_indent);
        }
      }
      json_map[constants.design_modifications_key] = mods_map;
    }

    json_map[constants.strands_key] = [
      for (var strand in strands) strand.to_json_serializable(suppress_indent: suppress_indent)
    ];

    return json_map;
  }

  // set of all modifications in this design
  BuiltSet<Modification> _all_modifications() {
    var mods_5p = BuiltSet<Modification>(
        {for (var strand in strands) if (strand.modification_5p != null) strand.modification_5p});
    var mods_3p = BuiltSet<Modification>(
        {for (var strand in strands) if (strand.modification_3p != null) strand.modification_3p});
    var mods_int = BuiltSet<Modification>(
        {for (var strand in strands) for (var mod in strand.modifications_int.values) mod});
    return mods_5p.union(mods_3p).union(mods_int);
  }

  bool has_nondefault_max_offset(Helix helix) {
    var ends = domains_on_helix(helix.idx).map((ss) => ss.end);
    int max_end = ends.isEmpty ? constants.default_max_offset : ends.reduce(max);
    return helix.max_offset != max_end;
  }

  bool has_nondefault_min_offset(Helix helix) {
    var starts = domains_on_helix(helix.idx).map((ss) => ss.start);
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
    if (json_map == null) return null;

    var dna_design_builder = DNADesignBuilder();

    dna_design_builder.version =
        util.get_value_with_default(json_map, constants.version_key, constants.CURRENT_VERSION);
    bool position_x_z_should_swap = util.version_precedes(dna_design_builder.version, '0.9.0');

    dna_design_builder.grid = util.get_value_with_default(
        json_map, constants.grid_key, constants.default_grid,
        transformer: Grid.valueOf);

    bool grid_is_none = dna_design_builder.grid == Grid.none;

    dna_design_builder.unused_fields = util.unused_fields_map(json_map, constants.dna_design_keys);

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
    for (Map<String, dynamic> helix_json in deserialized_helices_list) {
      HelixBuilder helix_builder = Helix.from_json(helix_json);
      if (helix_builder.idx == null) {
        helix_builder.idx = idx;
      }
      helix_builder.grid = dna_design_builder.grid;
      if (grid_is_none && helix_json.containsKey(constants.grid_position_key)) {
        throw IllegalDNADesignError(
            'grid is none, but Helix $idx has grid_position = ${helix_json[constants.grid_position_key]}');
      } else if (!grid_is_none && helix_json.containsKey(constants.position_key)) {
        throw IllegalDNADesignError(
            'grid is not none, but Helix $idx has position = ${helix_json[constants.position_key]}');
      }
      // don't want to do this while codenano has different version numbers
//      if (position_x_z_should_swap && grid_is_none) {
//        // prior to version 0.10.0, x and z had the opposite role
//        num swap = helix_builder.position_.x;
//        helix_builder.position_.x = helix_builder.position_.z;
//        helix_builder.position_.z = swap;
//      }
      helix_builders.add(helix_builder);
      idx++;
    }

    // view order of helices
    var helix_indices = [for (var helix_builder in helix_builders) helix_builder.idx];
    // ensure no two helices have same idx
    Tuple2<int,int> repeated_idxs = util.repeated_element_indices(helix_indices);
    if (repeated_idxs != null) {
      int i1 = repeated_idxs.item1;
      int i2 = repeated_idxs.item2;
      int helix_idx = helix_builders[i1].idx;
      throw IllegalDNADesignError('helix idx values must be unique, '
          'but two helices share idx = ${helix_idx}; they appear at positions ${i1} and ${i2} in the '
          'list of helices.');
    }
    List<int> helices_view_order = List<int>.from(
        util.get_value_with_default(json_map, constants.helices_view_order_key, helix_indices));
    if (helices_view_order.length != num_helices) {
      throw IllegalDNADesignError('length of helices (${num_helices}) does not match '
          'length of helices_view_order (${helices_view_order.length})');
    }
    var helices_view_order_sorted = List<int>.from(helices_view_order);
    helix_indices.sort();
    helices_view_order_sorted.sort();
    if (!ListEquality().equals(helices_view_order_sorted, helix_indices)) {
      throw IllegalDNADesignError('helices_view_order = ${helices_view_order} is not a permutation of '
          'the indices of the helices, which are ${helix_indices}');
    }

    for (int view_order = 0; view_order < helices_view_order.length; view_order++) {
      int idx = helices_view_order[view_order];
      var helix_builder = helix_builders.firstWhere((h) => h.idx == idx);
      helix_builder.view_order = view_order;
    }

    // strands
    List<Strand> strands = [];
    List strand_jsons = json_map[constants.strands_key];
    for (var strand_json in strand_jsons) {
      Strand strand = Strand.from_json(strand_json);
      strands.add(strand);
    }
    dna_design_builder.strands.replace(strands);

    _set_helices_min_max_offsets(helix_builders, dna_design_builder.strands.build());

    // build Helices
    Map<int, Helix> helices = {
      for (var helix_builder in helix_builders) helix_builder.idx: helix_builder.build()
    };
    helices = util.helices_assign_svg(helices, dna_design_builder.grid);
    dna_design_builder.helices.replace(helices);

    // modifications in whole design
    if (json_map.containsKey(constants.design_modifications_key)) {
      Map<String, dynamic> all_mods_json = json_map[constants.design_modifications_key];
      Map<String, Modification> all_mods = {};
      for (var mod_key in all_mods_json.keys) {
        var mod_json = all_mods_json[mod_key];
        var mod = Modification.from_json(mod_json);
        mod = mod.set_id(mod_key);
        all_mods[mod_key] = mod;
      }
      DNADesign.assign_modifications_to_strands(strands, strand_jsons, all_mods);
      dna_design_builder.strands.replace(strands);
    }

    var dna_design = dna_design_builder.build();
    dna_design._check_legal_design();

    return dna_design;
  }

  static assign_modifications_to_strands(
      List<Strand> strands, List strand_jsons, Map<String, Modification> all_mods) {
    for (int i = 0; i < strands.length; i++) {
      var strand = strands[i];
      var strand_json = strand_jsons[i];
      if (strand_json.containsKey(constants.modification_5p_key)) {
        var mod_name = strand_json[constants.modification_5p_key];
        Modification5Prime mod = all_mods[mod_name];
        strand = strand.rebuild((b) => b..modification_5p.replace(mod));
      }
      if (strand_json.containsKey(constants.modification_3p_key)) {
        var mod_name = strand_json[constants.modification_3p_key];
        Modification3Prime mod = all_mods[mod_name];
        strand = strand.rebuild((b) => b..modification_3p.replace(mod));
      }
      if (strand_json.containsKey(constants.modifications_int_key)) {
        Map<int, ModificationInternal> mods_by_idx = {};
        var mod_names_by_idx_json = strand_json[constants.modifications_int_key];
        for (var idx_str in mod_names_by_idx_json.keys) {
          int offset = int.parse(idx_str);
          String mod_name = mod_names_by_idx_json[idx_str];
          ModificationInternal mod = all_mods[mod_name];
          mods_by_idx[offset] = mod;
        }
        strand = strand.rebuild((b) => b..modifications_int.replace(mods_by_idx));
      }
      strands[i] = strand;
    }
  }

  _check_legal_design() {
    _check_helix_offsets();
    _check_strands_reference_helices_legally();
    _check_loopouts_not_consecutive_or_singletons_or_zero_length();
    _check_strands_overlap_legally();
    _check_grid_positions_disjoint();
  }

  _check_helix_offsets() {
    for (var helix in helices.values) {
      if (helix.min_offset != null && helix.max_offset != null && helix.min_offset >= helix.max_offset) {
        var err_msg = 'for helix ${helix.idx}, '
            'helix.min_offset = ${helix.min_offset} must be strictly less than '
            'helix.max_offset = ${helix.max_offset}';
        throw IllegalDNADesignError(err_msg);
      }
    }
  }

  _check_strands_reference_helices_legally() {
    // ensure each strand refers to an existing helix
    for (var strand in strands) {
      _check_strand_references_legal_helices(strand);
      _check_strand_has_legal_offsets_in_helices(strand);
    }
  }

  _check_strand_references_legal_helices(Strand strand) {
    for (var domain in strand.domains()) {
      if (!helices.containsKey(domain.helix)) {
        var err_msg = "domain ${domain} refers to nonexistent Helix index ${domain.helix}; "
            "here is the list of valid helices: ${helices.keys.join(', ')}";
        throw StrandError(strand, err_msg);
      }
    }
  }

  _check_strand_has_legal_offsets_in_helices(Strand strand) {
    for (var domain in strand.domains()) {
      var helix = helices[domain.helix];
      if (domain.start < helix.min_offset) {
        var err_msg = "domain ${domain} has start offset ${domain.start}, "
            "beyond the beginning of "
            "Helix ${domain.helix} that has min_offset = ${helix.min_offset}";
        throw StrandError(strand, err_msg);
      }
      if (domain.end > helix.max_offset) {
        var err_msg = "domain ${domain} has end offset ${domain.end}, "
            "beyond the end of "
            "Helix ${domain.helix} that has max_offset = ${helix.max_offset}";
        throw StrandError(strand, err_msg);
      }
    }
  }

  _check_loopouts_not_consecutive_or_singletons_or_zero_length() {
    for (var strand in strands) {
      DNADesign._check_loopout_not_singleton(strand);
      DNADesign._check_two_consecutive_loopouts(strand);
      DNADesign._check_loopouts_length(strand);
    }
  }

  static _check_loopout_not_singleton(Strand strand) {
    if (strand.substrands.length == 1 && strand.first_domain().is_loopout()) {
      throw StrandError(strand, 'strand cannot have a single Loopout as its only domain');
    }
  }

  static _check_two_consecutive_loopouts(Strand strand) {
    for (int i = 0; i < strand.substrands.length - 1; i++) {
      var domain1 = strand.substrands[i];
      var domain2 = strand.substrands[i + 1];
      if (domain1.is_loopout() && domain2.is_loopout()) {
        throw StrandError(strand, 'cannot have two consecutive Loopouts in a strand');
      }
    }
  }

  static _check_loopouts_length(Strand strand) {
    for (var loopout in strand.loopouts()) {
      if (loopout.loopout_length <= 0) {
        throw StrandError(strand, 'loopout length must be positive but is ${loopout.loopout_length}');
      }
    }
  }

  _check_strands_overlap_legally() {
    String err_msg(Domain domain1, Domain domain2, int h_idx) {
      return "two domains overlap on helix ${h_idx}: "
          "\n${domain1}\n  and\n${domain2}\n  but have the same direction";
    }

    // ensure that if two strands overlap on the same helix, they point in opposite directions
    for (int helix_idx in helices.keys) {
      var domains = this.domains_on_helix(helix_idx);
      if (domains.length == 0) continue;

      // check all consecutive domains on the same helix, sorted by start/end indices
      List<Tuple3<int, bool, Domain>> offsets_data = [];
      for (var domain in domains) {
        offsets_data.add(Tuple3<int, bool, Domain>(domain.start, true, domain));
        offsets_data.add(Tuple3<int, bool, Domain>(domain.end, false, domain));
      }
      offsets_data.sort((d1, d2) => d1.item1 - d2.item1);

      List<Domain> current_domains = [];
      for (var data in offsets_data) {
        var offset = data.item1;
        var is_start = data.item2;
        var domain = data.item3;
        if (is_start) {
          if (current_domains.length >= 2) {
            if (offset >= current_domains[1].end) {
              current_domains.removeAt(1);
            }
          }
          if (current_domains.length >= 1) {
            if (offset >= current_domains[0].end) {
              current_domains.removeAt(0);
            }
          }
          current_domains.add(domain);

          if (current_domains.length < 2) {
            continue;
          }

          var domain0 = current_domains[0];
          var domain1 = current_domains[1];
          if (current_domains.length > 2) {
            var domain2 = current_domains[2];
            if (domain0.forward == domain1.forward) {
              throw IllegalDNADesignError(err_msg(domain0, domain1, helix_idx));
            }
            if (domain0.forward == domain2.forward) {
              throw IllegalDNADesignError(err_msg(domain0, domain2, helix_idx));
            }
            if (domain1.forward == domain2.forward) {
              throw IllegalDNADesignError(err_msg(domain1, domain2, helix_idx));
            }
            throw AssertionError("since current_domains = ${current_domains} has at least three domains, "
                "I expected to find a pair of illegally overlapping domains");
          } else if (current_domains.length == 2) {
            if (domain0.forward == domain1.forward) {
              throw IllegalDNADesignError(err_msg(domain0, domain1, helix_idx));
            }
          }
        }
      }
    }
  }

  _check_grid_positions_disjoint() {
    if (!grid.is_none()) {
      var idxs = helices.keys.toList();
      var gps = {for (var idx in idxs) idx: helices[idx].grid_position};
      for (int i=0; i<gps.length-1; i++) {
        int idx1 = idxs[i];
        var gp1 = gps[idx1];
        for (int j=i+1; j<idxs.length; j++) {
          int idx2 = idxs[j];
          var gp2 = gps[idx2];
          if (gp1 == gp2) {
            throw IllegalDNADesignError('cannot use the same grid_position twice, but helices '
                '${idx1} and ${idx2} both have grid_position ${gp1}');
          }
        }
      }
    }
  }

  String toString() =>
      """DNADesign(is_origami=$is_origami, grid=$grid, major_tick_distance=$major_tick_distance, 
  helices=$helices, 
  strands=$strands)""";

  ListBuilder<Mismatch> _find_mismatches_on_substrand(Domain substrand) {
    var mismatches = ListBuilder<Mismatch>();

    for (int offset = substrand.start; offset < substrand.end; offset++) {
      if (substrand.deletions.contains(offset)) {
        continue;
      }

      var other_ss = this.other_substrand_at_offset(substrand, offset);
      if (other_ss == null || other_ss.dna_sequence == null) {
        continue;
      }

      // most of the time, the sequence is length 1, but we have to handle insertions
      var seq = substrand.dna_sequence_in(offset, offset);
      var other_seq = other_ss.dna_sequence_in(offset, offset);

//      this._ensure_other_substrand_same_deletion_or_insertion(substrand, other_ss, offset);
      // rather than banning single deletions/insertions outright, we'll simply declare it a mismatch
      // if they are not the same on both strands

      // other_ss has a deletion (and substrand implicitly doesn't since we would have continue'd),
      if (other_ss.deletions.contains(offset)) {
        // This throws an error if substrand has a deletion at offset.
        int dna_idx = substrand.substrand_offset_to_substrand_dna_idx(offset, substrand.forward);
        int within_insertion = seq.length == 1 ? -1 : 0;
        var mismatch = Mismatch(dna_idx, offset, within_insertion: within_insertion);
        mismatches.add(mismatch);
        continue;
      }

      int length_insertion_substrand = substrand.insertion_offset_to_length[offset];
      int length_insertion_other_ss = other_ss.insertion_offset_to_length[offset];
      if (length_insertion_substrand != length_insertion_other_ss) {
        // one has an insertion and the other doesn't, or they both have insertions of different lengths
        int dna_idx = substrand.substrand_offset_to_substrand_dna_idx(offset, substrand.forward);
        int within_insertion = seq.length == 1 ? -1 : 0;
        var mismatch = Mismatch(dna_idx, offset, within_insertion: within_insertion);
        mismatches.add(mismatch);
        continue;
      }

      // at this point, they both have an insertion here, or the both don't,
      // and if they both do, they're the same length
      assert(other_seq.length == seq.length);

      for (int idx = 0, idx_other = seq.length - 1; idx < seq.length; idx++, idx_other--) {
        if (seq.codeUnitAt(idx) != _wc(other_seq.codeUnitAt(idx_other))) {
          int dna_idx = substrand.substrand_offset_to_substrand_dna_idx(offset, substrand.forward) + idx;
          int within_insertion = seq.length == 1 ? -1 : idx;
          var mismatch = Mismatch(dna_idx, offset, within_insertion: within_insertion);
          mismatches.add(mismatch);
        }
      }
    }
    return mismatches;
  }

  /// Return other substrand at `offset` on `substrand.helix_idx`, or null if there isn't one.
  Domain other_substrand_at_offset(Domain substrand, int offset) {
    List<Domain> other_substrands = this._other_substrands_overlapping(substrand);
    for (var other_ss in other_substrands) {
      if (other_ss.contains_offset(offset)) {
        assert(substrand.forward != other_ss.forward);
        return other_ss;
      }
    }
    return null;
  }

//  void _ensure_other_substrand_same_deletion_or_insertion(
//      Domain substrand, Domain other_ss, int offset) {
//    if (substrand.deletions.contains(offset) && !other_ss.deletions.contains(offset)) {
//      throw UnsupportedError('cannot yet handle one strand having deletion at an offset but the overlapping '
//          'strand does not\nThis was found between the substrands on helix ${substrand.helix} '
//          'occupying offset intervals\n'
//          '(${substrand.start}, ${substrand.end}) and\n'
//          '(${other_ss.start}, ${other_ss.end})');
//    }
//    if (substrand.contains_insertion_at(offset) && !other_ss.contains_insertion_at(offset)) {
//      throw UnsupportedError('cannot yet handle one strand having insertion at an offset but the overlapping '
//          'strand does not\nThis was found between the substrands on helix ${substrand.helix} '
//          'occupying offset intervals\n'
//          '(${substrand.start}, ${substrand.end}) and\n'
//          '(${other_ss.start}, ${other_ss.end})');
//    }
//  }

  /// Return list of mismatches in substrand where the base is mismatched with the overlapping substrand.
  /// If a mismatch occurs outside an insertion, within_insertion = -1).
  /// If a mismatch occurs in an insertion, within_insertion = relative position within insertion (0,1,...)).
  BuiltList<Mismatch> mismatches_on_substrand(Domain substrand) {
    var ret = this.substrand_mismatches_map[substrand];
    if (ret == null) {
      ret = BuiltList<Mismatch>();
    }
    return ret;
  }

  /// Return set of substrands on the Helix with the given index.
  BuiltList<Domain> domains_on_helix(int helix_idx) => helix_idx_to_substrands[helix_idx];

  /// Return set of substrands on the helices with the given helix_idxs.
  BuiltList<Domain> domains_on_helices(Iterable<int> helix_idxs) {
    ListBuilder<Domain> list_builder = ListBuilder<Domain>();
    for (var helix_idx in helix_idxs) {
      list_builder.addAll(domains_on_helix(helix_idx));
    }
    return list_builder.build();
  }

//  Set<Domain> substrands_on_helix_at(int helix_idx, int offset) => helix_idx_to_substrands[helix_idx];

  /// Return [Substrand]s at [offset], INCLUSIVE on left and EXCLUSIVE on right.
  BuiltSet<Domain> substrands_on_helix_at(int helix_idx, int offset) {
    var substrands_at_offset = SetBuilder<Domain>({
      for (var substrand in this.helix_idx_to_substrands[helix_idx])
        if (substrand.contains_offset(offset)) substrand
    });
    return substrands_at_offset.build();
  }

  /// Return [Substrand] at [address], INCLUSIVE, or null if there is none.
  Domain substrand_on_helix_at(Address address) {
    for (var substrand in this.helix_idx_to_substrands[address.helix_idx]) {
      if (substrand.contains_offset(address.offset) && substrand.forward == address.forward) {
        return substrand;
      }
    }
    return null;
  }

  /// Return list of Substrands overlapping `substrand`.
  List<Domain> _other_substrands_overlapping(Domain substrand) {
    List<Domain> ret = [];
    var helix = this.helices[substrand.helix];
    for (var other_ss in helix_idx_to_substrands[helix.idx]) {
      if (substrand.overlaps(other_ss)) {
        ret.add(other_ss);
      }
    }
    return ret;
  }

  /// Number of bases between start and end offsets, inclusive, on the given [Helix].
  /// Accounts for substrands with insertions and deletions on [Domain]s on this Helix, but not if they
  /// are inconsistent (on one [Domain] but not the other).
  int helix_num_bases_between(Helix helix, int start, int end) {
    if (start > end) {
      int swap = start;
      start = end;
      end = swap;
    }

    List<Domain> substrands_intersecting = [];
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

  /// rotation angle of the backbone at the given address, assuming the given roll.
  /// It is assumed that the helix has roll [roll]; if parameter [roll] is not specified,
  /// the current value of the helix's roll is used
  double helix_rotation_at(Address address, [double roll = null]) {
    var helix = helices[address.helix_idx];
    int offset = address.offset;
    double rotation = helix_rotation_forward(helix, offset, roll);
    if (!address.forward) {
      rotation = (rotation + 150) % 360;
    }
    return rotation;
  }

  /// rotation angle of the backbone of the forward strand on [helix] at [offset]
  /// in degrees; gives rotation of backbone of strand in the forward direction, as viewed in the side view
  double helix_rotation_forward(Helix helix, int offset, [double roll = null]) {
    if (roll == null) {
      roll = helix.roll;
    }
    int num_bases;
    if (helix.min_offset < offset) {
      num_bases = this.helix_num_bases_between(helix, helix.min_offset, offset - 1);
    } else if (helix.min_offset > offset) {
      num_bases = -this.helix_num_bases_between(helix, offset + 1, helix.min_offset);
    } else {
      num_bases = 0;
    }
    num rot = (roll + (360 * num_bases / 10.5)) % (360);
    return rot;
  }

  /// in degrees; rotation of forward strand  + 150 degrees
  double helix_rotation_reverse(Helix helix, int offset) => this.helix_rotation_forward(helix, offset) + 150;

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

  /// Returns a map mapping helix indices to their view order.
  @memoized
  BuiltMap<int, int> get helices_view_order_inverse {
    Map<int, int> view_order_inverse = Map<int, int>();
    for (var idx in helices.keys) {
      int view_order = helices[idx].view_order;
      view_order_inverse[idx] = view_order;
    }
    return view_order_inverse.build();
  }

  /// Returns a map mapping view_order to helix_idx.
  @memoized
  BuiltList<int> get helices_view_order {
    List<int> view_orders = List<int>(helices.length);
    for (var idx in helices.keys) {
      int view_order = helices[idx].view_order;
      view_orders[view_order] = idx;
    }
    return view_orders.toBuiltList();
  }

  bool is_occupied(Address address) => substrand_on_helix_at(address) != null;

  @memoized
  int max_offset_of_strands_at(int helix_idx) {
    var substrands = helix_idx_to_substrands[helix_idx];
    int max_offset =
        substrands.isEmpty ? 0 : substrands.first.end; // in case of no substrands, max offset is 0
    for (var substrand in substrands) {
      max_offset = max(max_offset, substrand.end);
    }
    return max_offset;
  }

  @memoized
  int min_offset_of_strands_at(int helix_idx) {
    var substrands = helix_idx_to_substrands[helix_idx];
    int min_offset =
        substrands.isEmpty ? 0 : substrands.first.start; // in case of no substrands, min offset is 0
    for (var substrand in substrands) {
      min_offset = min(min_offset, substrand.start);
    }
    return min_offset;
  }

  @memoized
  bool get has_insertions_or_deletions {
    for (var strand in strands) {
      for (var substrand in strand.domains()) {
        if (substrand.deletions.isNotEmpty || substrand.insertions.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  _remove_helix_idxs_if_default(List<Map<String, dynamic>> helix_jsons) {
    bool use_default = true;
    for (int expected_idx = 0; expected_idx < helix_jsons.length; expected_idx++) {
      Map<String, dynamic> helix_json = helix_jsons[expected_idx];
      int idx = helix_json[constants.idx_on_helix_key];
      if (idx != expected_idx) {
        use_default = false;
        break;
      }
    }
    if (use_default) {
      for (Map helix_json in helix_jsons) {
        helix_json.remove(constants.idx_on_helix_key);
      }
    }
  }
}

BuiltMap<int, BuiltList<Domain>> construct_helix_idx_to_substrands_map(Iterable<Strand> strands,
    [Iterable<int> helix_idxs = null]) {
  var helix_idx_to_substrands = Map<int, List<Domain>>();

  if (helix_idxs != null) {
    for (int helix_idx in helix_idxs) {
      helix_idx_to_substrands[helix_idx] = [];
    }
  }

  for (Strand strand in strands) {
    for (Substrand substrand in strand.substrands) {
      if (substrand.is_domain()) {
        var bound_ss = substrand as Domain;
        if (helix_idx_to_substrands.containsKey(bound_ss.helix)) {
          helix_idx_to_substrands[bound_ss.helix].add(bound_ss);
        } else {
          helix_idx_to_substrands[bound_ss.helix] = [bound_ss];
        }
      }
    }
  }

  var helix_idx_to_substrands_builtset_builder = Map<int, BuiltList<Domain>>();
  for (var helix_idx in helix_idx_to_substrands.keys) {
    // sort by start offset; since the intervals are disjoint, this sorts them by end as well
    var substrands = helix_idx_to_substrands[helix_idx];
    substrands.sort((ss1, ss2) => ss1.start - ss2.start);
    helix_idx_to_substrands_builtset_builder[helix_idx] = substrands.build();
  }
  return helix_idx_to_substrands_builtset_builder.build();
}

_set_helices_min_max_offsets(List<HelixBuilder> helix_builders, Iterable<Strand> strands) {
  var helix_idx_to_substrands =
      construct_helix_idx_to_substrands_map(strands, helix_builders.map((h) => h.idx));

  for (int idx = 0; idx < helix_builders.length; idx++) {
    HelixBuilder helix_builder = helix_builders[idx];

    if (helix_builder.max_offset == null) {
      var substrands = helix_idx_to_substrands[helix_builder.idx];
      var max_offset =
          substrands.isEmpty ? constants.default_max_offset : substrands.first.end;
      for (var substrand in substrands) {
        max_offset = max(max_offset, substrand.end);
      }
      helix_builder.max_offset = max_offset;
    }

    if (helix_builder.min_offset == null) {
      var substrands = helix_idx_to_substrands[helix_builder.idx];
      var min_offset =
          substrands.isEmpty ? constants.default_min_offset : substrands.first.start;
      for (var substrand in substrands) {
        min_offset = min(min_offset, substrand.start);
      }
      // if there are strands with no offsets less than 1, we still want Helix.min_offset to be 0
      // i.e., it can only be positive if the JSON explicitly declares that
      if (min_offset > 0) {
        min_offset = 0;
      }
      helix_builder.min_offset = min_offset;
    }
  }
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
    var first_substrand = strand.first_domain();
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
