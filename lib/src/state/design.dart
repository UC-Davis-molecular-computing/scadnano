import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';

import 'package:scadnano/src/state/position3d.dart';
import 'package:scadnano/src/state/strand_maker.dart';
import '../state/loopout.dart';
import '../state/potential_vertical_crossover.dart';
import '../state/selectable.dart';
import 'package:tuple/tuple.dart';
import 'geometry.dart';
import 'crossover.dart';
import 'dna_end.dart';
import 'grid_position.dart';
import '../json_serializable.dart';
import 'group.dart';
import 'modification.dart';
import 'strand.dart';
import 'domain.dart';
import 'helix.dart';
import 'grid.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'substrand.dart';
import 'unused_fields.dart';
import 'domain_name_mismatch.dart';
import 'address.dart';
import '../extension_methods.dart';

part 'design.g.dart';

Position3D default_position(Geometry geometry, int idx) =>
    Position3D(x: 0, y: idx * geometry.distance_between_helices_nm);

GridPosition default_grid_position(int idx) => GridPosition(0, idx);

abstract class Design with UnusedFields implements Built<Design, DesignBuilder>, JSONSerializable {
  Design._();

  /// If [num_helices] is specified, helices are automatically populated with reasonable defaults based
  /// on the grid.
  factory Design(
      {Iterable<Helix> helices,
      Grid grid = Grid.none,
      int num_helices,
      Geometry geometry,
      Map<String, HelixGroup> groups = null}) {
    if (helices != null && num_helices != null) {
      throw IllegalDesignError('cannot specify both helices and num_helices:\n'
          'num_helices = ${num_helices}\n'
          'helices = ${helices}');
    }
    geometry ??= constants.default_geometry;
    if (helices == null) {
      if (num_helices == null) {
        helices = List<Helix>();
      } else {
        helices = [
          for (int idx in Iterable<int>.generate(num_helices))
            Helix(
              idx: idx,
              grid: grid,
              geometry: geometry,
              grid_position: grid == Grid.none ? null : default_grid_position(idx),
              position: grid != Grid.none ? null : default_position(geometry, idx),
            )
        ];
      }
    }
    var helices_map = {for (var helix in helices) helix.idx: helix};
    if (_uses_default_group(helices)) {
      if (groups != null) {
        throw ArgumentError('groups must be null if all helices use default group');
      }
      return Design.from((b) => b
        ..geometry.replace(geometry)
        ..groups[constants.default_group_name] = b.groups[constants.default_group_name].rebuild((g) => g
          ..grid = grid
          ..helices_view_order.replace(helices_map.keys))
        ..helices.replace(helices_map));
    } else {
      if (groups == null) {
        groups = _calculate_groups_from_helices(helices, grid);
      }
      return Design.from(
          (b) => b..geometry.replace(geometry)..groups.replace(groups)..helices.replace(helices_map));
    }
  }

  factory Design.from([void Function(DesignBuilder) updates]) = _$Design;

  static void _initializeBuilder(DesignBuilder b) {
    b.version = constants.CURRENT_VERSION;
    b.geometry = constants.default_geometry.toBuilder();
    b.helices = MapBuilder<int, Helix>();
    b.strands = ListBuilder<Strand>();
    b.unused_fields = MapBuilder<String, Object>({});
    b.groups = MapBuilder<String, HelixGroup>({constants.default_group_name: DEFAULT_HelixGroup});
    b.groups[constants.default_group_name] =
        b.groups[constants.default_group_name].rebuild((g) => g.grid = Grid.none);
  }

  @memoized
  int get hashCode;

  /****************************** end built_value boilerplate ******************************/

  String get version;

  Geometry get geometry;

  BuiltMap<int, Helix> get helices;

  BuiltList<Strand> get strands;

  BuiltMap<String, HelixGroup> get groups;

  BuiltMap<int, Helix> helices_in_group(String group_name) =>
      BuiltMap<int, Helix>.from(helices.toMap()..removeWhere((idx, helix) => helix.group != group_name));

  StrandMaker strand(int current_helix, int current_offset) {
    return StrandMaker(this, current_helix, current_offset);
  }

  @memoized
  bool get is_origami {
    for (var strand in strands) {
      if (strand.is_scaffold) {
        return true;
      }
    }
    return false;
  }

  // returns null if any Strand has a helix not in this Design
  BuiltSet<String> group_names_of_strands(Iterable<Strand> selected_strands) {
    var helix_idxs_of_selected_strands = {
      for (var strand in selected_strands)
        for (var domain in strand.domains()) domain.helix
    };

    Set<String> groups_of_selected_strands = {};
    for (int helix_idx in helix_idxs_of_selected_strands) {
      if (helices[helix_idx] == null) {
        return null;
      }
      var name = helices[helix_idx].group;
      groups_of_selected_strands.add(name);
    }

    return groups_of_selected_strands.build();
  }

  @memoized
  BuiltMap<Domain, Color> get color_of_domain {
    Map<Domain, Color> map = {};
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        map[domain] = strand.color;
      }
    }
    return map.build();
  }

  HelixGroup group_of_helix_idx(int helix_idx) {
    Helix helix = helices[helix_idx];
    HelixGroup group = groups[helix.group];
    return group;
  }

  String group_name_of_helix_idx(int helix_idx) {
    Helix helix = helices[helix_idx];
    return helix.group;
  }

  HelixGroup group_of_domain(Domain domain) => group_of_helix_idx(domain.helix);

  HelixGroup group_of_strand(Strand strand) => group_of_domain(strand.first_domain);

  String group_name_of_domain(Domain domain) => group_name_of_helix_idx(domain.helix);

  String group_name_of_strand(Strand strand) => group_name_of_domain(strand.first_domain);

  BuiltSet<String> group_names_of_domains(Iterable<Domain> domains) {
    var helix_idxs_of_domains = {for (var domain in domains) domain.helix};
    var groups_of_domains = {for (int helix_idx in helix_idxs_of_domains) helices[helix_idx].group};
    return groups_of_domains.build();
  }

  BuiltSet<String> group_names_of_ends(Iterable<DNAEnd> ends) {
    Set<String> names = {};
    for (var end in ends) {
      int helix_idx = end_to_domain[end].helix;
      var helix = helices[helix_idx];
      var name = helix.group;
      names.add(name);
    }
    return names.build();
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

  // all (offset,crossover) pairs incident on helix with given idx, sorted by offset on that helix.
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
      builder[strand.id] = strand;
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, Domain> get domains_by_id {
    var builder = MapBuilder<String, Domain>();
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        builder[domain.id] = domain;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, Loopout> get loopouts_by_id {
    var builder = MapBuilder<String, Loopout>();
    for (var strand in strands) {
      for (var loopout in strand.loopouts()) {
        builder[loopout.id] = loopout;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, Crossover> get crossovers_by_id {
    var builder = MapBuilder<String, Crossover>();
    for (var strand in strands) {
      for (var crossover in strand.crossovers) {
        builder[crossover.id] = crossover;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, SelectableDeletion> get deletions_by_id {
    var builder = MapBuilder<String, SelectableDeletion>();
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        for (var deletion in domain.selectable_deletions) {
          builder[deletion.id] = deletion;
        }
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, SelectableInsertion> get insertions_by_id {
    var builder = MapBuilder<String, SelectableInsertion>();
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        for (var insertion in domain.selectable_insertions) {
          builder[insertion.id] = insertion;
        }
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, SelectableModification> get modifications_by_id {
    var builder = MapBuilder<String, SelectableModification>();
    for (var strand in strands) {
      for (var mod in strand.selectable_modifications) {
        builder[mod.id] = mod;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        builder[domain.dnaend_start.id] = domain.dnaend_start;
        builder[domain.dnaend_end.id] = domain.dnaend_end;
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_5p_strand_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      var end = strand.dnaend_5p;
      builder[end.id] = end;
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_3p_strand_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      var end = strand.dnaend_3p;
      builder[end.id] = end;
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_5p_other_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        var end = domain.dnaend_5p;
        if (!domain.is_first) {
          builder[end.id] = end;
        }
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, DNAEnd> get ends_3p_other_by_id {
    var builder = MapBuilder<String, DNAEnd>();
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        var end = domain.dnaend_3p;
        if (!domain.is_last) {
          builder[end.id] = end;
        }
      }
    }
    return builder.build();
  }

  @memoized
  BuiltMap<String, Selectable> get selectable_by_id {
    Map<String, Selectable> map = {};
    for (var map_small in [
      strands_by_id,
      loopouts_by_id,
      crossovers_by_id,
      ends_by_id,
      domains_by_id,
      deletions_by_id,
      insertions_by_id,
      modifications_by_id,
    ]) {
      for (var key in map_small.keys) {
        var obj = map_small[key];
        map[key] = obj;
      }
    }
    return map.build();
  }

  /// design.strands_overlapping[strand] is a list of all strands that overlap strand.
  @memoized
  BuiltMap<Strand, BuiltList<Strand>> get strands_overlapping {
    Map<Strand, List<Strand>> map = {};
    Map<Strand, BuiltList<Strand>> map_builtlist = {};
    for (int i = 0; i < strands.length; i++) {
      var strand1 = strands[i];
      map[strand1] = [];
      for (int j = 0; j < strands.length; j++) {
        if (i == j) {
          continue;
        }
        var strand2 = strands[j];
        if (strand1.overlaps(strand2)) {
          map[strand1].add(strand2);
        }
      }
      map_builtlist[strand1] = map[strand1].toBuiltList();
    }
    return map_builtlist.build();
  }

  @memoized
  BuiltMap<Domain, BuiltList<Mismatch>> get domain_mismatches_map {
    var domain_mismatches_map_builder = MapBuilder<Domain, ListBuilder<Mismatch>>();
    for (Strand strand in this.strands) {
      if (strand.dna_sequence != null) {
        for (Domain domain in strand.domains()) {
          domain_mismatches_map_builder[domain] = this._find_mismatches_on_substrand(domain);
        }
      }
    }
    var domain_mismatches_builtmap_builder = MapBuilder<Domain, BuiltList<Mismatch>>();
    domain_mismatches_map_builder.build().forEach((domain, mismatches) {
      domain_mismatches_builtmap_builder[domain] = mismatches.build();
    });
    return domain_mismatches_builtmap_builder.build();
  }

  @memoized
  BuiltMap<DNAEnd, Domain> get end_to_domain {
    var end_to_substrand_builder = MapBuilder<DNAEnd, Domain>();
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        end_to_substrand_builder[domain.dnaend_3p] = domain;
        end_to_substrand_builder[domain.dnaend_5p] = domain;
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

  Strand end_to_strand(DNAEnd end) => substrand_to_strand[end_to_domain[end]];

  @memoized
  BuiltList<int> get helix_idxs => helices.keys.toBuiltList();

  @memoized
  BuiltMap<int, BuiltList<Domain>> get helix_idx_to_domains =>
      construct_helix_idx_to_domains_map(strands, helix_idxs);

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
          var address = Address(helix_idx: ss.helix, offset: end.offset_inclusive, forward: ss.forward);
          map[address] = end;
        }
      }
    }
    return map.build();
  }

  /// Gets Address (helix,offset,forward) of given DNAEnd
  /// Offset is inclusive, i.e., dna_end.offset_inclusive
  @memoized
  BuiltMap<DNAEnd, Address> get end_to_address {
    var map = Map<DNAEnd, Address>();
    for (var strand in strands) {
      for (var ss in strand.domains()) {
        for (var end in [ss.dnaend_start, ss.dnaend_end]) {
          var address = Address(helix_idx: ss.helix, offset: end.offset_inclusive, forward: ss.forward);
          map[end] = address;
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
      var ss = strand.first_domain;
      var key = Address(helix_idx: ss.helix, offset: ss.dnaend_5p.offset_inclusive, forward: ss.forward);
      map[key] = strand;
    }
    return map.build();
  }

  /// Gets Strand with 3p end at given address (helix,offset,forward)
  /// Offset is inclusive, i.e., dna_end.offset_inclusive
  @memoized
  BuiltMap<Address, Strand> get address_3p_to_strand {
    var map = Map<Address, Strand>();
    for (var strand in strands) {
      var ss = strand.last_domain;
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
      var ss = strand_5p.first_domain;
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
              forward_top = forward;
              substrand_top = ss;
              dna_end_top = substrand_top.dnaend_5p;

              helix_idx_bot = address_3p.helix_idx;
              substrand_bot = strand_3p.last_domain;
              dna_end_bot = substrand_bot.dnaend_3p;
            } else {
              // 3' end is on top, 5' is on bottom
              helix_idx_top = address_3p.helix_idx;
              forward_top = !forward;
              substrand_top = strand_3p.last_domain;
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
            domain_top: substrand_top,
            domain_bot: substrand_bot,
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
  int get max_offset => helices.values.map((helix) => helix.max_offset).max;

  /// min offset allowed on any Helix in the Model
  @memoized
  int get min_offset => helices.values.map((helix) => helix.min_offset).min;

  Design add_strand(Strand strand) => rebuild((d) => d..strands.add(strand));

  Design add_strands(Iterable<Strand> new_strands) => rebuild((d) => d..strands.addAll(new_strands));

  Design remove_strand(Strand strand) => rebuild((d) => d..strands.remove(strand));

  Design remove_strands(Iterable<Strand> strands_to_remove) {
    Set<Strand> strands_to_remove_set = strands_to_remove.toSet();
    return rebuild((d) => d..strands.removeWhere((strand) => strands_to_remove_set.contains(strand)));
  }

  bool has_default_groups() => groups.length == 1 && groups.containsKey(constants.default_group_name);

  /// Throw exception if group is not default; otherwise return the default group
  HelixGroup default_group() {
    // Gets default group and raise exception if default group is not being used
    if (!has_default_groups()) {
      throw ArgumentError('cannot access Design.helices_view_order when groups are used. '
          'Access group.helices_view_order for each group instead.');
    }
    if (groups == null) {
      throw AssertionError('Design.groups should not be None by this point');
    }
    var all_groups = List<HelixGroup>.from(groups.values);
    var group = all_groups.first;
    return group;
  }

  /// Throw exception if default group is not being used; otherwise set the grid of the default group.
  set_grid(Grid grid) {
    var group = default_group();
    group = group.rebuild((b) => b..grid = grid);
    var design = rebuild((b) {
      b.groups[constants.default_group_name] = group;
    });
    return design;
  }

  /// Throw exception if default group is not being used; otherwise set the grid of the default group.
  set_helices_view_order(Iterable<int> helices_view_order) {
    var group = default_group();
    group = group.rebuild((b) => b..helices_view_order.replace(helices_view_order));
    var design = rebuild((b) {
      b.groups[constants.default_group_name] = group;
    });
    return design;
  }

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {constants.version_key: constants.CURRENT_VERSION};

    json_map.addAll(unused_fields.toMap());

    if (has_default_groups()) {
      json_map[constants.grid_key] = default_group().grid.to_json();
    }

    if (!this.geometry.is_default()) {
      json_map[constants.geometry_key] = geometry.to_json_serializable(suppress_indent: suppress_indent);
    }

    if (!has_default_groups()) {
      Map<String, dynamic> group_map = {};
      for (var name in groups.keys) {
        var group = groups[name];
        group_map[name] = group.to_json_serializable(
            suppress_indent: suppress_indent, helix_idxs: helix_idxs_in_group[name]);
      }
      json_map[constants.groups_key] = group_map;
    }

    var helix_jsons_map = {
      for (var helix in helices.values)
        helix.idx: helix.to_json_serializable(suppress_indent: suppress_indent)
    };

    // unwrap from NoIndent if necessary
    var helix_jsons_unwrapped =
        List<Map<String, dynamic>>.from(helix_jsons_map.values.map(util.unwrap_from_noindent));
    _remove_helix_idxs_if_default(helix_jsons_unwrapped);

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

    if (has_default_groups()) {
      var helices_view_order = default_group().helices_view_order;
      if (!util.is_increasing(helices_view_order)) {
        var order = helices_view_order.toList();
        json_map[constants.helices_view_order_key] = suppress_indent ? NoIndent(order) : order;
      }
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
    var mods_5p = BuiltSet<Modification>({
      for (var strand in strands)
        if (strand.modification_5p != null) strand.modification_5p
    });
    var mods_3p = BuiltSet<Modification>({
      for (var strand in strands)
        if (strand.modification_3p != null) strand.modification_3p
    });
    var mods_int = BuiltSet<Modification>({
      for (var strand in strands)
        for (var mod in strand.modifications_int.values) mod
    });
    return mods_5p.union(mods_3p).union(mods_int);
  }

  bool has_nondefault_max_offset(Helix helix) {
    int default_max_end = calculate_default_max_offset(strands);
    return helix.max_offset != default_max_end;
  }

  bool has_nondefault_min_offset(Helix helix) {
    var starts = domains_on_helix(helix.idx).map((ss) => ss.start);
    int min_start = starts.isEmpty ? null : starts.min;
    // if all offsets are nonnegative (or there are no substrands, i.e., min_start == null),
    // then default min_offset is 0; otherwise it is minimum offset
    if (min_start == null || min_start >= 0) {
      return helix.min_offset != 0;
    } else {
      return helix.min_offset != min_start;
    }
  }

  static _check_mutually_exclusive_fields(Map<String, dynamic> json_map) {
    var exclusive_pairs = [
      [constants.grid_key, constants.groups_key],
      [constants.helices_view_order_key, constants.groups_key],
    ];
    for (var pair in exclusive_pairs) {
      var key1 = pair[0];
      var key2 = pair[1];
      if (json_map.containsKey(key1) && json_map.containsKey(key2)) {
        throw IllegalDesignError('cannot specify both "${key1}" and "${key2}" in Design JSON');
      }
    }
  }

  static Tuple3<Map<int, HelixBuilder>, Map<String, HelixPitchYaw>, Map<HelixPitchYaw, List<HelixBuilder>>>
      _helices_from_json(Map<String, dynamic> json_map, bool invert_xy, Geometry geometry) {
    var grid =
        util.optional_field(json_map, constants.grid_key, constants.default_grid, transformer: Grid.valueOf);
    bool grid_is_none = grid == Grid.none;
    bool using_groups = json_map.containsKey(constants.groups_key);
    List<HelixBuilder> helix_builders_list = [];
    List<dynamic> deserialized_helices_list = json_map[constants.helices_key];
    // create HelixBuilders
    int idx = 0;
    for (Map<String, dynamic> helix_json in deserialized_helices_list) {
      HelixBuilder helix_builder = Helix.from_json(helix_json);
      if (helix_builder.idx == null) {
        helix_builder.idx = idx;
      }
      helix_builder.invert_xy = invert_xy;
      helix_builder.geometry = geometry.toBuilder();
      if (grid_is_none && !using_groups && helix_json.containsKey(constants.grid_position_key)) {
        throw IllegalDesignError(
            'grid is none, but Helix $idx has grid_position = ${helix_json[constants.grid_position_key]}');
      } else if (!grid_is_none && !using_groups && helix_json.containsKey(constants.position_key)) {
        throw IllegalDesignError(
            'grid is not none, but Helix $idx has position = ${helix_json[constants.position_key]}');
      }
      helix_builders_list.add(helix_builder);
      idx++;
    }
    // ensure no two helices have same idx
    var helix_indices = [for (var helix_builder in helix_builders_list) helix_builder.idx];
    _ensure_helix_idxs_unique(helix_indices, helix_builders_list);
    // now that we know idx's are unique, assign from list into map with idx keys
    Map<int, HelixBuilder> helix_builders_map = {
      for (var helix_builder in helix_builders_list) helix_builder.idx: helix_builder
    };

    return Tuple3(helix_builders_map, null, null);
  }

  static Map<String, HelixGroupBuilder> _group_from_json(
      Map<String, dynamic> json_map,
      Map<int, HelixBuilder> helix_builders_map,
      Map<String, HelixPitchYaw> group_to_pitch_yaw,
      Map<HelixPitchYaw, List<HelixBuilder>> pitch_yaw_to_helices) {
    var grid =
        util.optional_field(json_map, constants.grid_key, constants.default_grid, transformer: Grid.valueOf);
    // TODO: Delete this variable and replace with using multiple_groups_used and single_group_used
    bool using_groups = json_map.containsKey(constants.groups_key);

    // helix groups; populate with grids, but not helices_view_order yet
    Map<String, HelixGroupBuilder> group_builders_map = null;
    if (!using_groups) {
      group_builders_map = {constants.default_group_name: DEFAULT_HelixGroup.toBuilder()..grid = grid};
    } else {
      Map<String, dynamic> groups_json = json_map[constants.groups_key];
      group_builders_map = {};
      for (var name in groups_json.keys) {
        var group_json = groups_json[name];
        var helix_idxs_in_group =
            helix_builders_map.keys.where((idx) => helix_builders_map[idx].group == name);
        group_builders_map[name] =
            HelixGroup.from_json(group_json, helix_idxs: helix_idxs_in_group).toBuilder();
      }
    }
    ensure_helix_groups_in_groups_map(helix_builders_map, group_builders_map);

    // if helices_view_order not already specified in group or top-level of design, give each a default
    if (json_map.containsKey(constants.helices_view_order_key)) {
      var helices_view_order = List<int>.from(json_map[constants.helices_view_order_key]);
      group_builders_map[constants.default_group_name].helices_view_order.replace(helices_view_order);
    }
    assign_default_helices_view_orders_to_groups(group_builders_map, helix_builders_map);

    return group_builders_map;
  }

  static Tuple2<Map<int, HelixBuilder>, Map<String, HelixGroupBuilder>> _helices_and_groups_from_json(
      Map<String, dynamic> json_map, bool invert_xy, bool position_x_z_should_swap, Geometry geometry) {
    var grid =
        util.optional_field(json_map, constants.grid_key, constants.default_grid, transformer: Grid.valueOf);
    bool grid_is_none = grid == Grid.none;
    bool using_groups = json_map.containsKey(constants.groups_key);

    var r = _helices_from_json(json_map, invert_xy, geometry);
    Map<int, HelixBuilder> helix_builders_map = r.item1;
    Map<String, HelixPitchYaw> group_to_pitch_yaw = r.item2;
    Map<HelixPitchYaw, List<HelixBuilder>> pitch_yaw_to_helices = r.item3;

    Map<String, HelixGroupBuilder> group_builders_map =
        _group_from_json(json_map, helix_builders_map, group_to_pitch_yaw, pitch_yaw_to_helices);

    // Swap x and z coordinates if needed
    if (position_x_z_should_swap) {
      for (var helix_builder in helix_builders_map.values) {
        if (grid_is_none && !using_groups ||
            using_groups && group_builders_map[helix_builder.group].grid.is_none()) {
          // prior to version 0.13.0, x and z had the opposite role
          num swap = helix_builder.position_.x;
          helix_builder.position_.x = helix_builder.position_.z;
          helix_builder.position_.z = swap;
        }
      }
      for (var group_builder in group_builders_map.values) {
        num swap = group_builder.position.x;
        group_builder.position.x = group_builder.position.z;
        group_builder.position.z = swap;
      }
    }
    return Tuple2(helix_builders_map, group_builders_map);
  }

  static Design from_json_str(String json_str, [bool invert_xy = false]) {
    var json_map = jsonDecode(json_str);
    return Design.from_json(json_map, invert_xy);
  }

  static Design from_json(Map<String, dynamic> json_map, [bool invert_xy = false]) {
    if (json_map == null) return null;

    _check_mutually_exclusive_fields(json_map);

    var design_builder = DesignBuilder();

    design_builder.version = util.optional_field(json_map, constants.version_key, constants.CURRENT_VERSION);

    // prior to version 0.13.0, x and z had the opposite role
    bool position_x_z_should_swap = util.version_precedes(design_builder.version, '0.13.0');

    design_builder.unused_fields = util.unused_fields_map(json_map, constants.design_keys);

    Geometry geometry = util.optional_field(json_map, constants.geometry_key, Geometry(),
        transformer: (geometry_map) => Geometry.from_json(geometry_map),
        legacy_keys: constants.legacy_geometry_keys);
    design_builder.geometry.replace(geometry);

    var t = Design._helices_and_groups_from_json(json_map, invert_xy, position_x_z_should_swap, geometry);
    var helix_builders_map = t.item1;
    var group_builders_map = t.item2;

    // strands
    List<Strand> strands = [];
    List strand_jsons = json_map[constants.strands_key];
    for (var strand_json in strand_jsons) {
      Strand strand = Strand.from_json(strand_json);
      strands.add(strand);
    }
    design_builder.strands.replace(strands);

    set_helices_min_max_offsets(helix_builders_map, design_builder.strands.build());

    // build groups
    Map<String, HelixGroup> groups_map =
        group_builders_map.map((key, value) => MapEntry<String, HelixGroup>(key, value.build()));
    design_builder.groups.replace(groups_map);

    assign_grids_to_helix_builders_from_groups(groups_map, helix_builders_map);

    // build Helices
    Map<int, Helix> helices = {
      for (var helix_builder in helix_builders_map.values) helix_builder.idx: helix_builder.build()
    };
    helices = util.helices_assign_svg(geometry, invert_xy, helices, groups_map.build());
    design_builder.helices.replace(helices);

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
      Design.assign_modifications_to_strands(strands, strand_jsons, all_mods);
      design_builder.strands.replace(strands);
    }

    var design = design_builder.build();
    design._check_legal_design();

    return design;
  }

  static List<int> set_helices_view_order_default_group(
      Map<String, dynamic> json_map, List<int> helix_indices) {
    int num_helices = helix_indices.length;
    var helices_view_order =
        List<int>.from(util.optional_field(json_map, constants.helices_view_order_key, helix_indices));
    if (helices_view_order.length != num_helices) {
      throw IllegalDesignError('length of helices (${num_helices}) does not match '
          'length of helices_view_order (${helices_view_order.length})');
    }
    var helices_view_order_sorted = List<int>.of(helices_view_order);
    helix_indices.sort();
    helices_view_order_sorted.sort();
    if (!ListEquality().equals(helices_view_order_sorted, helix_indices)) {
      throw IllegalDesignError('helices_view_order = ${helices_view_order} is not a permutation of '
          'the indices of the helices, which are ${helix_indices}');
    }
    return helices_view_order;
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
    _ensure_helix_groups_exist();
    _check_helix_offsets();
    _check_strands_reference_helices_legally();
    _check_loopouts_not_consecutive_or_singletons_or_zero_length();
    check_strands_overlap_legally();
    _check_grid_positions_disjoint();
  }

  _check_helix_offsets() {
    for (var helix in helices.values) {
      if (helix.min_offset != null && helix.max_offset != null && helix.min_offset >= helix.max_offset) {
        var err_msg = 'for helix ${helix.idx}, '
            'helix.min_offset = ${helix.min_offset} must be strictly less than '
            'helix.max_offset = ${helix.max_offset}';
        throw IllegalDesignError(err_msg);
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
      strand.check_loopout_not_singleton();
      strand.check_two_consecutive_loopouts();
      strand.check_loopouts_length();
    }
  }

  check_strands_overlap_legally() {
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
              throw IllegalDesignError(err_msg(domain0, domain1, helix_idx));
            }
            if (domain0.forward == domain2.forward) {
              throw IllegalDesignError(err_msg(domain0, domain2, helix_idx));
            }
            if (domain1.forward == domain2.forward) {
              throw IllegalDesignError(err_msg(domain1, domain2, helix_idx));
            }
            throw AssertionError("since current_domains = ${current_domains} has at least three domains, "
                "I expected to find a pair of illegally overlapping domains");
          } else if (current_domains.length == 2) {
            if (domain0.forward == domain1.forward) {
              throw IllegalDesignError(err_msg(domain0, domain1, helix_idx));
            }
          }
        }
      }
    }
  }

  @memoized
  BuiltMap<String, BuiltList<int>> get helix_idxs_in_group {
    Map<String, List<int>> map = {for (var name in groups.keys) name: []};

    for (int idx in helices.keys) {
      var helix = helices[idx];
      var group_name = helix.group;
      map[group_name].add(idx);
    }

    return {for (var name in map.keys) name: map[name].build()}.build();
  }

  _check_grid_positions_disjoint() {
    for (var group_name in groups.keys) {
      var group = groups[group_name];
      if (group.grid == Grid.none) {
        continue;
      }
      BuiltList<int> idxs = helix_idxs_in_group[group_name];
      var gps = {for (var idx in idxs) idx: helices[idx].grid_position};
      for (int i = 0; i < gps.length - 1; i++) {
        int idx1 = idxs[i];
        var gp1 = gps[idx1];
        for (int j = i + 1; j < idxs.length; j++) {
          int idx2 = idxs[j];
          var gp2 = gps[idx2];
          if (gp1 == gp2) {
            throw IllegalDesignError('cannot use the same grid_position twice in the same group, but helices '
                '${idx1} and ${idx2} both have grid_position ${gp1} and are both in group ${group_name}');
          }
        }
      }
    }
  }

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

  /// Return list of DNA mismatches in substrand where the base is mismatched with the overlapping substrand.
  /// If a mismatch occurs outside an insertion, within_insertion = -1).
  /// If a mismatch occurs in an insertion, within_insertion = relative position within insertion (0,1,...)).
  BuiltList<Mismatch> dna_mismatches_on_domain(Domain domain) {
    var ret = this.domain_mismatches_map[domain];
    if (ret == null) {
      ret = BuiltList<Mismatch>();
    }
    return ret;
  }

  /// Return set of domains on the Helix with the given index.
  /// If [forward] is specified, then only domains in that direction are returned.
  List<Domain> domains_on_helix(int helix_idx, {bool forward = null}) {
    List<Domain> domains = helix_idx_to_domains[helix_idx].toList();
    if (forward != null) {
      domains = domains.where((Domain domain) => domain.forward == forward).toList();
    }
    return domains;
  }

  List<Domain> domains_on_helix_overlapping(Domain domain, {bool forward = null}) {
    var domains = domains_on_helix(domain.helix, forward: forward);
    domains.removeWhere((Domain other_domain) => !domain.overlaps(other_domain));
    return domains;
  }

  /// Return set of domains on the helices with the given helix_idxs.
  BuiltList<Domain> domains_on_helices(Iterable<int> helix_idxs) {
    ListBuilder<Domain> list_builder = ListBuilder<Domain>();
    for (var helix_idx in helix_idxs) {
      list_builder.addAll(domains_on_helix(helix_idx));
    }
    return list_builder.build();
  }

  /// Indicates whether domains mismatch, either because they overlap but not on exactly the same offsets,
  /// or they overlap perfectly but their domain names are not complementary.
  static bool domains_mismatch(Domain forward_domain, Domain reverse_domain) {
    if (!forward_domain.overlaps(reverse_domain)) {
      return false;
    }
    if (forward_domain.start != reverse_domain.start) {
      return true;
    }
    if (forward_domain.end != reverse_domain.end) {
      return true;
    }
    if (forward_domain.name == null || reverse_domain == null) {
      return false;
    }
    return !domain_names_complementary(forward_domain.name, reverse_domain.name);
  }

  static bool domain_names_complementary(String name1, String name2) {
    if (name1.length > name2.length) {
      String swap = name1;
      name1 = name2;
      name2 = swap;
    }
    return name1 + '*' == name2;
  }

  @memoized
  BuiltMap<int, BuiltList<DomainNameMismatch>> get domain_name_mismatches {
    Map<int, List<DomainNameMismatch>> mismatches = {for (int helix_idx in helices.keys) helix_idx: []};

    for (int helix_idx in helices.keys) {
      List<Domain> forward_domains = domains_on_helix(helix_idx, forward: true).toList();
      forward_domains.removeWhere((Domain domain) => domain.name == null);
      for (Domain forward_domain in forward_domains) {
        List<Domain> reverse_domains = domains_on_helix_overlapping(forward_domain, forward: false);
        for (var reverse_domain in reverse_domains) {
          if (reverse_domain != null && reverse_domain.name != null) {
            if (domains_mismatch(forward_domain, reverse_domain)) {
              var mismatch = DomainNameMismatch(
                helix_idx: helix_idx,
                forward_domain: forward_domain,
                reverse_domain: reverse_domain,
              );
              mismatches[helix_idx].add(mismatch);
            }
          }
        }
      }
    }

    Map<int, BuiltList<DomainNameMismatch>> mismatches_half_built = {
      for (int helix_idx in mismatches.keys) helix_idx: mismatches[helix_idx].build()
    };
    return mismatches_half_built.build();
  }

  @memoized
  BuiltList<Domain> get all_domains => [
        for (var strand in strands)
          for (var domain in strand.domains()) domain
      ].build();

//  Set<Domain> substrands_on_helix_at(int helix_idx, int offset) => helix_idx_to_substrands[helix_idx];

  /// Return [Domain]s at [offset], INCLUSIVE on left and EXCLUSIVE on right.
  BuiltSet<Domain> domains_on_helix_at(int helix_idx, int offset) {
    var substrands_at_offset = SetBuilder<Domain>({
      for (var substrand in this.helix_idx_to_domains[helix_idx])
        if (substrand.contains_offset(offset)) substrand
    });
    return substrands_at_offset.build();
  }

  /// Return [Domain]s at [offset], excluding the start and offset
  BuiltSet<Domain> domains_on_helix_at_offset_internal(int helix_idx, int offset) {
    var domains_at_offset = SetBuilder<Domain>({
      for (var domain in this.helix_idx_to_domains[helix_idx])
        if (domain.contains_offset(offset) && offset != domain.start && offset != domain.end - 1) domain
    });
    return domains_at_offset.build();
  }

  /// Return [Domain] at [address], INCLUSIVE, or null if there is none.
  Domain domain_on_helix_at(Address address) {
    for (var domain in this.helix_idx_to_domains[address.helix_idx]) {
      if (domain.contains_offset(address.offset) && domain.forward == address.forward) {
        return domain;
      }
    }
    return null;
  }

  /// Return list of Substrands overlapping `substrand`.
  List<Domain> _other_substrands_overlapping(Domain substrand) {
    List<Domain> ret = [];
    var helix = this.helices[substrand.helix];
    for (var other_ss in helix_idx_to_domains[helix.idx]) {
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
    for (var ss in this.helix_idx_to_domains[helix.idx]) {
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
    double rotation = helix_rotation_forward(helix.idx, offset, roll);
    if (!address.forward) {
      rotation = (rotation + 150) % 360;
    }
    return rotation;
  }

  /// rotation angle of the backbone of the forward strand on [helix] at [offset]
  /// in degrees; gives rotation of backbone of strand in the forward direction, as viewed in the side view
  double helix_rotation_forward(int helix_idx, int offset, [double roll = null]) {
    Helix helix = helices[helix_idx];
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
  double helix_rotation_reverse(int helix_idx, int offset) =>
      (helix_rotation_forward(helix_idx, offset) + 150) % 360;

  bool helix_has_nondefault_max_offset(Helix helix) {
    int max_ss_offset = -1;
    for (var ss in this.helix_idx_to_domains[helix.idx]) {
      if (max_ss_offset < ss.end) {
        max_ss_offset = ss.end;
      }
    }
    return helix.max_offset != max_ss_offset;
  }

  bool helix_has_nondefault_min_offset(Helix helix) {
    int min_ss_offset = -1;
    for (var ss in this.helix_idx_to_domains[helix.idx]) {
      if (min_ss_offset > ss.start) {
        min_ss_offset = ss.start;
      }
    }
    return helix.min_offset != min_ss_offset;
  }

  bool helix_has_substrands(Helix helix) => this.helix_idx_to_domains[helix.idx].isNotEmpty;

//  /// Returns a map mapping view_order to helix_idx.
//  @memoized
//  BuiltList<int> get helices_view_order {
//    List<int> view_orders = List<int>(helices.length);
//    for (var idx in helices.keys) {
//      int view_order = helices[idx].view_order;
//      view_orders[view_order] = idx;
//    }
//    return view_orders.toBuiltList();
//  }

  bool is_occupied(Address address) => domain_on_helix_at(address) != null;

  @memoized
  int max_offset_of_strands_at(int helix_idx) {
    var substrands = helix_idx_to_domains[helix_idx];
    int max_offset =
        substrands.isEmpty ? 0 : substrands.first.end; // in case of no substrands, max offset is 0
    for (var substrand in substrands) {
      max_offset = max(max_offset, substrand.end);
    }
    return max_offset;
  }

  @memoized
  int min_offset_of_strands_at(int helix_idx) {
    var substrands = helix_idx_to_domains[helix_idx];
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

  _ensure_helix_groups_exist() {
    for (var helix in helices.values) {
      if (!groups.containsKey(helix.group)) {
        throw IllegalDesignError('helix ${helix.idx} has group ${helix.group}, which does not '
            'exist in the design. The valid groups are '
            '${groups.keys.join(", ")}');
      }
    }
  }
}

Map<String, HelixGroup> _calculate_groups_from_helices(Iterable<Helix> helices, Grid grid) {
  // gather up helix-idxs in each group
  Map<String, List<int>> group_to_helix_idxs = {};
  for (var helix in helices) {
    var name = helix.group;
    if (!group_to_helix_idxs.containsKey(name)) {
      group_to_helix_idxs[name] = [];
    }
    group_to_helix_idxs[name].add(helix.idx);
  }

  // sort helix idxs within each group
  group_to_helix_idxs.values.map((idxs) => idxs.sort());

  Map<String, HelixGroup> groups = {
    for (var name in group_to_helix_idxs.keys)
      name: HelixGroup(grid: grid, helices_view_order: group_to_helix_idxs[name])
  };

  return groups;
}

bool _uses_default_group(Iterable<Helix> helices) {
  for (var helix in helices) {
    if (helix.group != constants.default_group_name) {
      return false;
    }
  }
  return true;
}

ensure_helix_groups_in_groups_map(
    Map<int, HelixBuilder> helix_builders_map, Map<String, HelixGroupBuilder> group_builders_map) {
  for (var helix_builder in helix_builders_map.values) {
    if (!group_builders_map.containsKey(helix_builder.group)) {
      throw IllegalDesignError('helix ${helix_builder.idx} has group ${helix_builder.group}, which does not '
          'exist in the design.\n'
          'The valid groups are: '
          '${group_builders_map.keys.join(", ")}');
    }
  }
}

assign_grids_to_helix_builders_from_groups(
    Map<String, HelixGroup> groups_map, Map<int, HelixBuilder> helix_builders) {
  for (HelixBuilder helix_builder in helix_builders.values) {
    HelixGroup group = groups_map[helix_builder.group];
    helix_builder.grid = group.grid;
  }
}

assign_default_helices_view_orders_to_groups(
    Map<String, HelixGroupBuilder> group_builders_map, Map<int, HelixBuilder> helix_builders) {
  Map<String, int> num_helices_in_group =
      group_builders_map.map((key, value) => MapEntry<String, int>(key, 0));
  for (var helix_builder in helix_builders.values) {
    num_helices_in_group[helix_builder.group]++;
  }

  for (var name in group_builders_map.keys) {
    var group_builder = group_builders_map[name];
    if (group_builder.helices_view_order?.length != num_helices_in_group[name]) {
      Map<int, HelixBuilder> helix_builders_in_group = {};
      for (int idx in helix_builders.keys) {
        var helix = helix_builders[idx];
        if (helix.group == name) {
          helix_builders_in_group[idx] = helix;
        }
      }
      assign_default_helices_view_order(group_builder, helix_builders_in_group);
    }
  }
}

assign_default_helices_view_order(
    HelixGroupBuilder group_builder, Map<int, HelixBuilder> helix_builders_in_group) {
  var helix_idxs = helix_builders_in_group.keys.toList();
  BuiltList<int> existing_helices_view_order = group_builder.helices_view_order.build();
  var new_helices_view_order = check_helices_view_order_and_return(existing_helices_view_order, helix_idxs);
  group_builder.helices_view_order.replace(new_helices_view_order);
}

List<int> check_helices_view_order_and_return(Iterable<int> helices_view_order, Iterable<int> helix_idxs) {
  if (helices_view_order?.length != helix_idxs.length) {
    var identity = List<int>.of(helix_idxs);
    identity.sort();
    helices_view_order = identity;
  } else {
    check_helices_view_order_is_bijection(helices_view_order, helix_idxs);
  }
  return helices_view_order.toList();
}

check_helices_view_order_is_bijection(Iterable<int> helices_view_order_, Iterable<int> helix_idxs_) {
  var sorted_helices_view_order = List<int>.of(helices_view_order_);
  var sorted_helix_idxs = List<int>.of(helix_idxs_);
  sorted_helices_view_order.sort();
  sorted_helix_idxs.sort();
  if (sorted_helices_view_order != sorted_helix_idxs) {
    throw IllegalDesignError("The specified helices view order: ${helices_view_order_}\n "
        "is not a bijection on helices indices: ${helix_idxs_}.");
  }
}

BuiltMap<int, BuiltList<Domain>> construct_helix_idx_to_domains_map(Iterable<Strand> strands,
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
        var domain = substrand as Domain;
        if (helix_idx_to_substrands.containsKey(domain.helix)) {
          helix_idx_to_substrands[domain.helix].add(domain);
        } else {
          helix_idx_to_substrands[domain.helix] = [domain];
        }
      }
    }
  }

  var helix_idx_to_substrands_builtset_builder = Map<int, BuiltList<Domain>>();
  for (var helix_idx in helix_idx_to_substrands.keys) {
    // sort by start offset; since the intervals are disjoint in a given direction,
    // this sorts them by end as well (within a direction)
    var substrands = helix_idx_to_substrands[helix_idx];
    substrands.sort((ss1, ss2) => ss1.start - ss2.start);
    helix_idx_to_substrands_builtset_builder[helix_idx] = substrands.build();
  }
  return helix_idx_to_substrands_builtset_builder.build();
}

_ensure_helix_idxs_unique(List<int> helix_indices, List<HelixBuilder> helix_builders_list) {
  Tuple2<int, int> repeated_idxs = util.repeated_element_indices(helix_indices);
  if (repeated_idxs != null) {
    int i1 = repeated_idxs.item1;
    int i2 = repeated_idxs.item2;
    int helix_idx = helix_builders_list[i1].idx;
    throw IllegalDesignError('helix idx values must be unique, '
        'but two helices share idx = ${helix_idx}; they appear at positions ${i1} and ${i2} in the '
        'list of helices.');
  }
}

set_helices_min_max_offsets(Map<int, HelixBuilder> helix_builders, Iterable<Strand> strands) {
  var helix_idx_to_substrands = construct_helix_idx_to_domains_map(strands, helix_builders.keys);

  for (int idx in helix_builders.keys) {
    HelixBuilder helix_builder = helix_builders[idx];

    if (helix_builder.max_offset == null) {
      helix_builder.max_offset = calculate_default_max_offset(strands);
    }

    if (helix_builder.min_offset == null) {
      var substrands = helix_idx_to_substrands[helix_builder.idx];
      var min_offset = substrands.isEmpty ? constants.default_min_offset : substrands.first.start;
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
    if (helix_builder.major_tick_start == null) {
      helix_builder.major_tick_start = helix_builder.min_offset;
    }
  }
}

int calculate_default_max_offset(Iterable<Strand> strands) {
  int greatest_max_offset;
  if (strands.isEmpty) {
    greatest_max_offset = constants.default_max_offset;
  } else {
    greatest_max_offset = strands.first.first_domain.end;
    for (var strand in strands) {
      for (var domain in strand.domains()) {
        if (domain.end > greatest_max_offset) {
          greatest_max_offset = domain.end;
        }
      }
    }
  }
  return greatest_max_offset;
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

class IllegalDesignError implements Exception {
  String cause;

  IllegalDesignError(this.cause);
}

class StrandError extends IllegalDesignError {
  StrandError(Strand strand, String the_cause) : super(the_cause) {
    var first_substrand = strand.first_domain;
    var last_substrand = strand.last_domain;

    var msg = '\n'
        '  number of domains    =  ${strand.substrands.length}\n'
        "  strand 5' end offset =  ${first_substrand.offset_5p}\n"
        "  strand 3' helix      =  ${last_substrand.helix}\n"
        "  strand 3' end offset =  ${last_substrand.offset_3p}\n"
        '  strand length        =  ${strand.dna_length()}\n'
        '  DNA sequence length  =  ${strand.dna_sequence?.length}\n'
        '  DNA sequence         =  ${strand.dna_sequence}\n'
        "  strand 5' helix      =  ${first_substrand.helix}\n";

    this.cause += msg;
  }
}

class HelixPitchYaw {
  double pitch;
  double yaw;
  // Helix idx of the first helix found with this pitch and yaw value
  int helix_idx;

  HelixPitchYaw(this.pitch, this.yaw, this.helix_idx);
}
