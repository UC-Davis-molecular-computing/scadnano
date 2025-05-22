import 'package:web/web.dart';

import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart';
import 'package:scadnano/src/reducers/change_loopout_ext_properties.dart';
import 'package:scadnano/src/state/linker.dart';
import 'package:scadnano/src/state/potential_crossover.dart';
import 'package:tuple/tuple.dart';

import '../state/crossover.dart';
import '../state/design.dart';
import '../state/address.dart';
import '../state/app_state.dart';
import '../state/domain.dart';
import '../state/dna_end.dart';
import '../state/modification.dart';
import '../state/strand.dart';
import '../state/substrand.dart';
import '../state/loopout.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import 'delete_reducer.dart' as delete_reducer;

// moves a linker (crossover or loopout, stored as action.potential_crossover.linker)
// so that one end stays fixed (stored in action.potential_crossover.dna_end_first_clicked)
// while the other end moves to action.dna_end_second_click, editing two strands
BuiltList<Strand> move_linker_reducer(BuiltList<Strand> strands, AppState state, actions.MoveLinker action) {
  /*
    # If end_fixed is 5'
    before:

     strand_from                      strand_to

     domain_fixed
    <------------+  <-- end_fixed
                 |
                 |
                 |
    [------------+  <-- end_from    [------------->  <-- end_to
     domain_from                       domain_to

    after:
     domain_fixed
    <------------+
                  \
                   ------------------------------
                                                 \
    [------------>                  [-------------+
     domain_from                       domain_to

     new_strand_disconnected         new_strand_connected

    # If end_fixed is 3'
    before:

     strand_from                     strand_to

     domain_fixed
    [------------+  <-- end_fixed
                 |
                 |
                 |
    <------------+  <-- end_from    <-------------] <-- end_to
     domain_from                       domain_to

    after:
     domain_fixed
    [------------+
                  \
                   ------------------------------
                                                 \
    <------------]                  <-------------+
     domain_from                       domain_to

     new_strand_disconnected         new_strand_connected
     */
  Design design = state.design;
  PotentialCrossover potential_crossover = action.potential_crossover;
  Linker linker = potential_crossover.linker!;
  // assert(linker != null); // since MoveLinker action was dispatched
  DNAEnd end_fixed = potential_crossover.dna_end_first_click;
  DNAEnd end_to = action.dna_end_second_click;
  Strand strand_from = design.linker_to_strand[linker]!;
  Strand strand_to = design.end_to_strand(end_to);

  //TODO: support moving crossover from a strand to itself to make it circular
  if (strand_from == strand_to) {
    window.alert('creating circular strand by moving existing crossover/loopout not supported yet');
    return strands;
  }

  // list of all strands to mutate and return
  List<Strand> new_all_strands = strands.toList();
  // two strands we get by splitting strand_from
  List<Strand> new_strands = delete_reducer.remove_linkers_from_strand(strand_from, [linker]);
  if (new_strands.length == 2) {
    // strand_from was not circular
    Strand new_strand_disconnected = end_fixed.is_5p ? new_strands[0] : new_strands[1];
    Strand new_strand_connected_intermediate = end_fixed.is_5p ? new_strands[1] : new_strands[0];
    List<Strand> strands_to_join = [new_strand_connected_intermediate, strand_to];
    if (end_fixed.is_5p) {
      strands_to_join = strands_to_join.reversed.toList();
    }

    // join_strands_by_crossover_reducer is awkward to use since it looks up strands by ends
    // but we've modified the design already, so we bypass it and call _join_strands_with_crossover directly
    bool first_clicked_is_3p = end_fixed.is_3p;
    BuiltList<Strand> new_strands_connected;
    if (first_clicked_is_3p) {
      new_strands_connected = _join_strands_with_crossover(new_strand_connected_intermediate, strand_to,
          [new_strand_connected_intermediate, strand_to].build(), first_clicked_is_3p);
    } else {
      new_strands_connected = _join_strands_with_crossover(strand_to, new_strand_connected_intermediate,
          [strand_to, new_strand_connected_intermediate].build(), first_clicked_is_3p);
    }
    assert(new_strands_connected.length == 1);
    Strand new_strand_connected = new_strands_connected.first;

    // if linker is a Loopout, we need to convert the Crossover we just made in
    // _join_strands_with_crossover to a Loopout
    if (linker is Loopout) {
      int crossover_idx = end_fixed.is_5p
          ? strand_to.domains.length - 1
          : new_strand_connected_intermediate.domains.length - 1;
      var crossover = new_strand_connected.linkers[crossover_idx] as Crossover;
      var convert_crossover_to_loopout_action =
          actions.ConvertCrossoverToLoopout(crossover, linker.loopout_num_bases, linker.dna_sequence);
      new_strand_connected =
          convert_crossover_to_loopout_reducer(new_strand_connected, convert_crossover_to_loopout_action);
    }

    // assign DNA
    String linker_seq = "";
    if (linker is Loopout) {
      // assign wildcards to loopouts with no DNA sequence
      linker_seq = linker.dna_sequence ?? constants.DNA_BASE_WILDCARD * linker.dna_length();
    }
    // add wildcards to strands with no DNA sequences
    String strand_to_dna_sequence =
        strand_to.dna_sequence ?? constants.DNA_BASE_WILDCARD * strand_to.dna_length;
    String new_strand_connected_dna_sequence = new_strand_connected_intermediate.dna_sequence ??
        constants.DNA_BASE_WILDCARD * new_strand_connected_intermediate.dna_length;
    String new_strand_connected_seq;
    if (end_fixed.is_5p) {
      new_strand_connected_seq = strand_to_dna_sequence + linker_seq + new_strand_connected_dna_sequence;
    } else {
      new_strand_connected_seq = new_strand_connected_dna_sequence + linker_seq + strand_to_dna_sequence;
    }
    new_strand_connected = new_strand_connected.set_dna_sequence(new_strand_connected_seq);
    // not necessary to assign DNA to new_strand_disconnected since that strand was created by
    // delete_reducer.remove_linkers_from_strand, which already handles the DNA sequence

    // assign new strands into new list of all strands
    int strand_from_orig_idx = strands.indexOf(strand_from);
    int strand_to_orig_idx = strands.indexOf(strand_to);
    new_all_strands[strand_from_orig_idx] = new_strand_connected;
    new_all_strands[strand_to_orig_idx] = new_strand_disconnected;
  } else if (new_strands.length == 1) {
    // strand_from was circular
    //TODO: implement this
    window.alert('moving crossover/loopout from a circular strand not yet supported');
    return strands;
  } else {
    throw AssertionError('should be unreachable');
  }

  return new_all_strands.build();
}

BuiltList<Strand> nick_reducer(BuiltList<Strand> strands, AppState state, actions.Nick action) {
  // remove Domain where nick will be, and remember where it was attached
  Domain domain_to_remove = action.domain;
  var strand = state.design.substrand_to_strand[domain_to_remove]!;

  // create new Domains
  int nick_offset = action.offset;
  int helix = domain_to_remove.helix;
  var forward = domain_to_remove.forward;
  var start = domain_to_remove.start;
  var end = domain_to_remove.end;
  Domain domain_left = Domain(
      helix: helix,
      forward: forward,
      start: start,
      end: nick_offset,
      is_scaffold: domain_to_remove.is_scaffold,
      deletions: domain_to_remove.deletions.where((d) => d < nick_offset),
      insertions: domain_to_remove.insertions.where((i) => i.offset < nick_offset));
  Domain domain_right = Domain(
      helix: helix,
      forward: forward,
      start: nick_offset,
      end: end,
      is_scaffold: domain_to_remove.is_scaffold,
      deletions: domain_to_remove.deletions.where((d) => d >= nick_offset),
      insertions: domain_to_remove.insertions.where((i) => i.offset >= nick_offset));

  // join new Domains to existing strands
  int index_removed = strand.substrands.indexOf(domain_to_remove);
  List<Substrand> substrands_before = strand.substrands.sublist(0, index_removed).toList();
  List<Substrand> substrands_after = strand.substrands.sublist(index_removed + 1).toList();
  Domain domain_before = domain_left;
  Domain domain_after = domain_right;
  if (!forward) {
    domain_before = domain_right;
    domain_after = domain_left;
  }
  domain_before = domain_before.rebuild((b) => b
    ..is_last = true
    ..is_first = substrands_before.isEmpty);
  domain_after = domain_after.rebuild((b) => b
    ..is_first = true
    ..is_last = substrands_after.isEmpty);
  substrands_before.add(domain_before);
  substrands_after.insert(0, domain_after);

  String? dna_before = null;
  String? dna_after = null;
  if (strand.dna_sequence != null) {
    int dna_length_before = [for (var ss in substrands_before) ss.dna_length()].reduce((l1, l2) => l1 + l2);
    dna_before = strand.dna_sequence!.substring(0, dna_length_before);
    dna_after = strand.dna_sequence!.substring(dna_length_before);
  }

  int dna_length_strand_5p = [for (var ss in substrands_before) ss.dna_length()].reduce((a, b) => a + b);

  // move modifications onto strand_5p from strand
  Map<int, ModificationInternal> modifications_int_strand_5p = {};
  for (int i = 0; i < substrands_before.length; i++) {
    var mods_on_ss = strand.internal_modifications_on_substrand_absolute_idx[i];
    mods_on_ss.forEach((idx, mod) {
      if (i < substrands_before.length - 1 || idx < dna_length_strand_5p) {
        modifications_int_strand_5p[idx] = mod;
      }
    });
  }

  if (strand.circular) {
    var substrands = substrands_after + substrands_before;
    var strand_new = strand.rebuild((b) => b
      ..substrands.replace(substrands)
      ..circular = false);
    strand_new = strand_new.initialize();

    int strand_idx = strands.indexOf(strand);
    var strands_mutable = strands.toBuilder();
    strands_mutable[strand_idx] = strand_new;
    return strands_mutable.build();
  } else {
    Strand strand_5p = Strand(substrands_before,
        name: strand.name,
        color: strand.color,
        dna_sequence: dna_before,
        vendor_fields: strand.vendor_fields,
        is_scaffold: strand.is_scaffold,
        modification_5p: strand.modification_5p,
        modification_3p: null,
        modifications_int: modifications_int_strand_5p);

    // move modifications onto strand_3p from strand
    Map<int, ModificationInternal> modifications_int_strand_3p = {};
    for (int i = substrands_before.length - 1; i < strand.substrands.length; i++) {
      var mods_on_ss = strand.internal_modifications_on_substrand_absolute_idx[i];
      mods_on_ss.forEach((idx, mod) {
        if (i > substrands_before.length || idx >= dna_length_strand_5p) {
          int new_idx = idx - dna_length_strand_5p;
          modifications_int_strand_3p[new_idx] = mod;
        }
      });
    }

    Strand strand_3p = Strand(substrands_after,
        name: strand.name,
        color: strand.is_scaffold == true ? strand.color : null,
        dna_sequence: dna_after,
        is_scaffold: strand.is_scaffold,
        modification_5p: null,
        modification_3p: strand.modification_3p,
        modifications_int: modifications_int_strand_3p);

    return swap_old_strands_for_new(strands, [strand], [strand_5p, strand_3p]);
  }
}

BuiltList<Strand> ligate_reducer(BuiltList<Strand> strands, AppState state, actions.Ligate action) {
  DNAEnd dna_end_clicked = action.dna_end;
  Domain domain = state.design.end_to_domain[dna_end_clicked]!;
  Strand strand = state.design.substrand_to_strand[domain]!;
  int helix = domain.helix;
  bool forward = domain.forward;
  int offset = dna_end_clicked.offset!;

  // Look at adjacent locations for a domain not equal to current domain,
  // Need strange logic with offset because Domain.end is exclusive.
  Domain? other_domain = null;
  BuiltSet<Domain> domains_adjacent;
  if (dna_end_clicked.is_start)
    domains_adjacent = state.design.domains_on_helix_at(helix, offset - 1);
  else
    domains_adjacent = state.design.domains_on_helix_at(helix, offset);
  for (var domain_adj in domains_adjacent) {
    Strand strand_adj = state.design.substrand_to_strand[domain_adj]!;
    var ends = strand.ligatable_ends_with(strand_adj);
    if (ends != null) {
      other_domain = domain_adj;
      break;
    }
  }
  // if no substrands are adjacent, then action has no effect
  if (other_domain == null) {
    return strands;
  }

  // normalize left/right distinction
  bool other_is_right = !dna_end_clicked.is_start;
  Domain dom_left, dom_right;
  if (other_is_right) {
    dom_left = domain;
    dom_right = other_domain;
  } else {
    dom_left = other_domain;
    dom_right = domain;
  }
  Strand strand_left = state.design.substrand_to_strand[dom_left]!;
  Strand strand_right = state.design.substrand_to_strand[dom_right]!;

  // normalize 5'/3' distinction; below refers to which Strand has the 5'/3' end that will be ligated
  // So strand_5p is the one whose 3' end will be the 3' end of the whole new Strand
  // strand_5p and dom_5p are the ones on the 5' side of the nick,
  // e.g.,
  //
  //  strand_3p  strand_5p
  // [--------->[--------->
  //    dom_3p     dom_5p
  //
  // or
  //
  //  strand_5p  strand_3p
  // <---------]<---------]
  //    dom_5p     dom_3p
  Domain dom_5p, dom_3p;
  Strand strand_5p, strand_3p;
  if (!forward) {
    dom_5p = dom_left;
    dom_3p = dom_right;
    strand_5p = strand_left;
    strand_3p = strand_right;
  } else {
    dom_5p = dom_right;
    dom_3p = dom_left;
    strand_5p = strand_right;
    strand_3p = strand_left;
  }

  Domain dom_new = Domain(
      helix: helix,
      forward: forward,
      start: dom_left.start,
      end: dom_right.end,
      is_scaffold: strand_5p.is_scaffold || strand_3p.is_scaffold,
      deletions: dom_left.deletions + dom_right.deletions,
      insertions: dom_left.insertions + dom_right.insertions,
      is_first: dom_3p.is_first,
      is_last: dom_5p.is_last);

  if (strand_left == strand_right) {
    // join domains and make strand circular
    var strand = strand_left;
    assert(!strand.circular);
    assert(strand.first_domain == dom_5p);
    assert(strand.last_domain == dom_3p);
    var substrands = strand.substrands.toList();
    substrands.removeAt(0);
    substrands.removeLast();
    substrands.insert(0, dom_new);

    // If this linear strand had no crossovers, only loopouts, this is illegal so we do nothing
    // (and forbid_create_circular_strand_no_crossovers_middleware middleware should warn user)
    // If there is a crossover, we need to find it to make those domains the "first" and "last"
    // in the circular strand.
    // let's look for two consecutive domains connected by a crossover and make the latter of them
    // the "first" domain, and rotate the substrand list to start there.
    // If we can't find one, we do nothing.
    // (Should have already reported error to user though, in middleware,
    // if they tried to convert the last crossover in a circular strand to be a Loopout.)
    if (strand.crossovers.isEmpty) {
      return strands;
    }
    if (substrands.last is Loopout) {
      int first_dom = -1;
      for (int i = 0; i < substrands.length - 1; i++) {
        if (substrands[i] is Domain && substrands[i + 1] is Domain) {
          first_dom = i + 1;
        }
      }
      assert(first_dom >= 0); // we would have returned above since this means no crossovers
      substrands = substrands.sublist(first_dom) + substrands.sublist(0, first_dom);
    }

    var new_strand = strand.rebuild((b) => b
      ..substrands.replace(substrands)
      ..circular = true);
    new_strand = new_strand.initialize();

    int strand_idx = strands.indexOf(strand);
    var strands_mutable = strands.toBuilder();
    strands_mutable[strand_idx] = new_strand;
    return strands_mutable.build();
  } else {
    var substrands_5p_new = strand_5p.substrands.toList()..removeAt(0);
    var substrands_3p_new = strand_3p.substrands.toList()..removeLast();
    // take properties from existing strands
    var substrands_new = substrands_3p_new + [dom_new] + substrands_5p_new;

    //TODO: figure out if strand_3p was the one clicked
    bool first_clicked_is_3p = dna_end_clicked.is_3p;
    Strand new_strand =
        join_two_strands_with_substrands(strand_3p, strand_5p, substrands_new, first_clicked_is_3p);

    return swap_old_strands_for_new(strands, [strand_left, strand_right], [new_strand]);
  }
}

//////////////////////////////////////////////////////////////////////////
// actions.JoinStrandsByMultipleCrossovers

BuiltList<Strand> join_strands_by_multiple_crossovers_reducer(
    BuiltList<Strand> strands, AppState state, actions.JoinStrandsByMultipleCrossovers action) {
  List<Tuple2<DNAEnd, DNAEnd>> end_pairs =
      find_end_pairs_to_connect(state.design, state.ui_state.selectables_store.selected_dna_ends.toList());

  // build up list of addresses; these will stay the same even as the strands change as we add Crossovers
  List<Address> addresses_from = [];
  List<Address> addresses_to = [];
  for (var end_pair in end_pairs) {
    var end1 = end_pair.item1;
    var end2 = end_pair.item2;
    var end_from = end1.is_3p ? end1 : end2;
    var end_to = end1.is_3p ? end2 : end1;
    addresses_from.add(state.design.end_to_address[end_from]!);
    addresses_to.add(state.design.end_to_address[end_to]!);
  }

  // add one crossover at a time, looking up strands to connect by Address
  // (since we are invalidating the Design's lookup as we modify the list [strands])
  for (int i = 0; i < addresses_from.length; i++) {
    var address_from = addresses_from[i];
    var address_to = addresses_to[i];
    var strand_from = _strand_with_end_address(strands, address_from, true)!;
    var strand_to = _strand_with_end_address(strands, address_to, false)!;
    strands = _join_strands_with_crossover(strand_from, strand_to, strands, true);
  }

  return strands;
}

Strand? _strand_with_end_address(Iterable<Strand> strands, Address address, bool end_is_3p) {
  for (var strand in strands) {
    if (end_is_3p && strand.address_3p == address) {
      return strand;
    }
    if (!end_is_3p && strand.address_5p == address) {
      return strand;
    }
  }
  return null;
}

/// find which pairs of ends among [selected_ends] to connect by Crossovers, and dispatch BatchAction
/// to connect them
List<Tuple2<DNAEnd, DNAEnd>> find_end_pairs_to_connect(Design design, List<DNAEnd> selected_ends) {
  Map<DNAEnd, Domain> all_domains = {for (var end in selected_ends) end: design.end_to_domain[end]!};

  // group according to HelixGroups
  Map<String, List<DNAEnd>> ends_by_group = {};
  for (var end in selected_ends) {
    var domain = all_domains[end]!;
    int helix_idx = domain.helix;
    var helix = design.helices[helix_idx]!;
    var group_name = helix.group;
    if (!ends_by_group.containsKey(group_name)) {
      ends_by_group[group_name] = [];
    }
    ends_by_group[group_name]!.add(end);
  }

  // find pairs of ends to connect
  List<Tuple2<DNAEnd, DNAEnd>> end_pairs_to_connect = [];
  for (var group_name in design.groups.keys) {
    // BuiltList<int> helices_view_order = design.groups[group_name].helices_view_order;
    BuiltMap<int, int> helices_view_order_inverse = design.groups[group_name]!.helices_view_order_inverse;
    var ends_in_group = ends_by_group[group_name]!;
    Map<DNAEnd, Domain> domains_by_end_in_group = {
      for (var end in ends_in_group) end: design.end_to_domain[end]!
    };
    var end_pairs_to_connect_in_group = find_end_pairs_to_connect_in_group(
        ends_in_group, domains_by_end_in_group, helices_view_order_inverse);
    end_pairs_to_connect.addAll(end_pairs_to_connect_in_group);
  }

  return end_pairs_to_connect;
}

/// find end pairs to connect according to algorithm described here:
/// https://github.com/UC-Davis-molecular-computing/scadnano/issues/581
List<Tuple2<DNAEnd, DNAEnd>> find_end_pairs_to_connect_in_group(
    List<DNAEnd> ends, Map<DNAEnd, Domain> domains_by_end, BuiltMap<int, int> helices_view_order_inverse) {
  /// sort by helix, then by forward/reverse, then by offset
  ends.sort((DNAEnd end1, DNAEnd end2) {
    var domain1 = domains_by_end[end1]!;
    var domain2 = domains_by_end[end2]!;
    int helix1 = domain1.helix;
    int helix2 = domain2.helix;
    int helix1_order = helices_view_order_inverse[helix1]!;
    int helix2_order = helices_view_order_inverse[helix2]!;
    if (helix1_order != helix2_order) {
      return helix1_order - helix2_order;
    }
    if (domain1.forward != domain2.forward) {
      return domain1.forward ? -1 : 1;
    }
    assert(end1.offset_inclusive != end2.offset_inclusive);
    return end1.offset_inclusive - end2.offset_inclusive;
  });

  // group ends by common offsets to reduce search time
  Map<int, List<DNAEnd>> ends_by_offset = {};
  for (var end in ends) {
    if (!ends_by_offset.containsKey(end.offset_inclusive)) {
      ends_by_offset[end.offset_inclusive] = [];
    }
    ends_by_offset[end.offset_inclusive]!.add(end);
  }

  List<Tuple2<DNAEnd, DNAEnd>> end_pairs = [];

  for (int offset in ends_by_offset.keys) {
    // remember which ends have been paired with this offset, so we don't pick any twice
    Set<DNAEnd> already_chosen_ends = {};
    var ends_with_offset = ends_by_offset[offset]!;
    for (int i = 0; i < ends_with_offset.length; i++) {
      var end1 = ends_with_offset[i];
      if (already_chosen_ends.contains(end1)) {
        continue;
      }
      var end2 = find_paired_end(end1, i + 1, ends_with_offset, already_chosen_ends, domains_by_end);
      if (end2 != null) {
        var end_pair = Tuple2<DNAEnd, DNAEnd>(end1, end2);
        end_pairs.add(end_pair);
        already_chosen_ends.add(end1);
        already_chosen_ends.add(end2);
      }
    }
  }

  return end_pairs;
}

/// find DNAEnd in list [ends_with_offset], but not in set [already_chosen_ends], to pair with [end1],
/// starting at index [starting_index] in [ends_with_offset].
/// Assume [end1] has same offset as all DNAEnds in [ends_with_offset].
DNAEnd? find_paired_end(DNAEnd end1, int starting_index, List<DNAEnd> ends_with_offset,
    Set<DNAEnd> already_chosen_ends, Map<DNAEnd, Domain> domains_by_end) {
  var domain1 = domains_by_end[end1]!;
  for (int i = starting_index; i < ends_with_offset.length; i++) {
    DNAEnd end2 = ends_with_offset[i];
    if (!already_chosen_ends.contains(end2)) {
      var domain2 = domains_by_end[end2]!;
      if (end1.is_5p != end2.is_5p && domain1.forward != domain2.forward && domain1.helix != domain2.helix) {
        // assert(end1.is_5p != end2.is_5p);
        return end2;
      }
    }
  }
  return null;
}

//////////////////////////////////////////////////////////////////////////
// actions.JoinStrandsByCrossover

BuiltList<Strand> join_strands_by_crossover_reducer(
    BuiltList<Strand> strands, AppState state, actions.JoinStrandsByCrossover action) {
  // gather substrand data
  DNAEnd end_first_click = action.dna_end_first_click;
  DNAEnd end_second_click = action.dna_end_second_click;

  // "from" strand is the one with the 3' end adjacent to the new crossover
  // (in 5' to 3' direction, this crossover goes from one strand to another)
  bool first_clicked_is_3p = end_first_click.is_3p;
  DNAEnd end_3p = first_clicked_is_3p ? end_first_click : end_second_click;
  DNAEnd end_5p = first_clicked_is_3p ? end_second_click : end_first_click;
  Strand strand_3p = state.design.end_to_strand(end_3p);
  Strand strand_5p = state.design.end_to_strand(end_5p);

  // if joining strand to itself by crossover, just make it circular
  return _join_strands_with_crossover(strand_3p, strand_5p, strands, first_clicked_is_3p);
}

// This is a common function used by actions JoinStrandsByCrossover and JoinStrandsByMultipleCrossovers
BuiltList<Strand> _join_strands_with_crossover(
    Strand strand_3p, Strand strand_5p, BuiltList<Strand> strands, bool first_clicked_is_3p) {
  // if joining strand to itself by crossover, just make it circular
  if (strand_3p == strand_5p) {
    var strand = strand_3p;
    int strand_idx = strands.indexOf(strand);
    var strands_mutable = strands.toList();
    var new_strand = strand.rebuild((b) => b..circular = true);
    new_strand = new_strand.initialize();
    strands_mutable[strand_idx] = new_strand;
    return strands_mutable.toBuiltList();
  }

  List<Substrand> substrands_3p = strand_3p.substrands.toList();
  List<Substrand> substrands_5p = strand_5p.substrands.toList();

  // change substrand data
  int last_idx_3p = substrands_3p.length - 1;
  Domain last_domain_3p = substrands_3p[last_idx_3p] as Domain;
  Domain first_domain_5p = substrands_5p[0] as Domain;
  last_domain_3p = last_domain_3p.rebuild((b) => b..is_last = false);
  first_domain_5p = first_domain_5p.rebuild((b) => b
    ..is_first = false
    ..strand_id = strand_5p.id);

  // put back into Substrand lists
  substrands_3p[last_idx_3p] = last_domain_3p;
  substrands_5p[0] = first_domain_5p;

  List<Substrand> substrands_new = substrands_3p + substrands_5p;

  // create new Strand
  Strand new_strand =
      join_two_strands_with_substrands(strand_3p, strand_5p, substrands_new, first_clicked_is_3p);

  return swap_old_strands_for_new(strands, [strand_3p, strand_5p], [new_strand]);
}

/// Joins two Strands using specified list of Substrands. Used to merge properties in a consistent way.
/// properties_from_strand_3p indicates whether to use strand_3p for properties,
/// but lets is_scaffold property override this.
/// Note that it *ignores* the substrands in strand1 and strand2.
/// Set properties_from_strand_3p
Strand join_two_strands_with_substrands(
    Strand strand_3p, Strand strand_5p, List<Substrand> substrands_new, bool properties_from_strand_3p) {
  // if one is scaffold and the other isn't, take properties from scaffold
  if (strand_3p.is_scaffold && !strand_5p.is_scaffold) {
    properties_from_strand_3p = true;
  } else if (!strand_3p.is_scaffold && strand_5p.is_scaffold) {
    properties_from_strand_3p = false;
  }

  //TODO: use properties_from_strand_3p to determine where to get properties
  var color = properties_from_strand_3p ? strand_3p.color : strand_5p.color;
  var idt = properties_from_strand_3p ? strand_3p.vendor_fields : strand_5p.vendor_fields;

  // strand_3p is strand whose 3' end is being joined to the other strand's 5' end
  var dna = null;
  if (strand_3p.dna_sequence == null && strand_5p.dna_sequence == null) {
    dna = null;
  } else if (strand_3p.dna_sequence != null && strand_5p.dna_sequence != null) {
    dna = strand_3p.dna_sequence! + strand_5p.dna_sequence!;
  } else if (strand_3p.dna_sequence == null) {
    dna = constants.DNA_BASE_WILDCARD * strand_3p.dna_length + strand_5p.dna_sequence!;
  } else if (strand_5p.dna_sequence == null) {
    dna = strand_3p.dna_sequence! + constants.DNA_BASE_WILDCARD * strand_5p.dna_length;
  }

  // include 5' mod from 5' strand and 3' mod from 3' strand.
  var mod_5p = strand_3p.modification_5p;
  var mod_3p = strand_5p.modification_3p;

  // put internal mods from both on new strand
  var mods_int = strand_3p.modifications_int.toMap();
  for (int idx in strand_5p.modifications_int.keys) {
    var mod_3p = strand_5p.modifications_int[idx]!;
    int new_idx = strand_3p.dna_length + idx;
    mods_int[new_idx] = mod_3p;
  }

  String? strand_name = null;

  if (strand_3p.name != null && strand_5p.name == null) {
    strand_name = strand_3p.name;
  } else if (strand_3p.name == null && strand_5p.name != null) {
    strand_name = strand_5p.name;
  } else if (strand_3p.name != null && strand_5p.name != null) {
    strand_name = properties_from_strand_3p ? strand_3p.name : strand_5p.name;
  }

  Strand new_strand = Strand(substrands_new,
      name: strand_name,
      color: color,
      dna_sequence: dna,
      vendor_fields: idt,
      is_scaffold: strand_3p.is_scaffold || strand_5p.is_scaffold,
      modification_5p: mod_5p,
      modification_3p: mod_3p,
      modifications_int: mods_int);
  return new_strand;
}

// Take strands_to_remove out of strands and put strands_to_add in
BuiltList<Strand> swap_old_strands_for_new(
    BuiltList<Strand> strands, Iterable<Strand> strands_to_remove, Iterable<Strand> strands_to_add) {
  List<Strand> new_strands = strands.toList();
  for (var strand in strands_to_remove) {
    new_strands.remove(strand);
  }
  for (var strand in strands_to_add) {
    new_strands.add(strand);
  }
  return new_strands.build();
}
