import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/helix.dart';

import '../state/app_state.dart';
import '../state/domain.dart';
import '../state/dna_end.dart';
import '../state/modification.dart';
import '../state/strand.dart';
import '../state/substrand.dart';
import '../state/loopout.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

BuiltList<Strand> nick_reducer(BuiltList<Strand> strands, AppState state, actions.Nick action) {
  // remove Domain where nick will be, and remember where it was attached
  Domain domain_to_remove = action.domain;
  var strand = state.design.substrand_to_strand[domain_to_remove];

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

  String dna_before = null;
  String dna_after = null;
  if (strand.dna_sequence != null) {
    int dna_length_before = [for (var ss in substrands_before) ss.dna_length()].reduce((l1, l2) => l1 + l2);
    dna_before = strand.dna_sequence.substring(0, dna_length_before);
    dna_after = strand.dna_sequence.substring(dna_length_before);
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
    String dna_sequence = null;
    if (strand.dna_sequence != null) {
      dna_sequence = dna_before + dna_after;
    }
    var strand_new = strand.rebuild((b) => b
      ..substrands.replace(substrands)
      ..dna_sequence = dna_sequence
      ..circular = false);
    strand_new = strand_new.initialize();

    int strand_idx = strands.indexOf(strand);
    var strands_mutable = strands.toBuilder();
    strands_mutable[strand_idx] = strand_new;
    return strands_mutable.build();
  } else {
    Strand strand_5p = Strand(substrands_before,
        color: strand.color,
        dna_sequence: dna_before,
        idt: strand.idt,
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
  Domain domain = state.design.end_to_domain[dna_end_clicked];
  Strand strand = state.design.substrand_to_strand[domain];
  int helix = domain.helix;
  bool forward = domain.forward;
  int offset = dna_end_clicked.offset;

  // Look at adjacent locations for a domain not equal to current domain,
  // Need strange logic with offset because Domain.end is exclusive.
  Domain other_domain;
  BuiltSet<Domain> domains_adjacent;
  DNAEnd other_strand_end;
  if (dna_end_clicked.is_start)
    domains_adjacent = state.design.domains_on_helix_at(helix, offset - 1);
  else
    domains_adjacent = state.design.domains_on_helix_at(helix, offset);
  for (var domain_adj in domains_adjacent) {
    Strand strand_adj = state.design.substrand_to_strand[domain_adj];
    var ends = strand.ligatable_ends_with(strand_adj);
    if (ends != null) {
      other_strand_end = ends.item1;
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
  Strand strand_left = state.design.substrand_to_strand[dom_left];
  Strand strand_right = state.design.substrand_to_strand[dom_right];

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
    Strand new_strand = join_two_strands_with_substrands(strand_3p, strand_5p, substrands_new);

    return swap_old_strands_for_new(strands, [strand_left, strand_right], [new_strand]);
  }
}

BuiltList<Strand> join_strands_by_multiple_crossovers_reducer(
    BuiltList<Strand> strands, AppState state, actions.JoinStrandsByMultipleCrossovers action) {
  // build up list of addresses; these will stay the same even as the strands change as we add Crossovers
  List<Address> addresses_from = [];
  List<Address> addresses_to = [];
  for (var end_pair in action.end_pairs) {
    var end1 = end_pair.item1;
    var end2 = end_pair.item2;
    var end_from = end1.is_3p? end1: end2;
    var end_to = end1.is_3p? end2: end1;
    addresses_from.add(state.design.end_to_address[end_from]);
    addresses_to.add(state.design.end_to_address[end_to]);
  }

  // add one crossover at a time, looking up strands to connect by Address
  // (since we are invalidating the Design's lookup as we modify the list [strands])
  for (int i=0; i<addresses_from.length; i++) {
    var address_from = addresses_from[i];
    var address_to = addresses_to[i];
    var strand_from = _strand_with_end_address(strands, address_from, true);
    var strand_to = _strand_with_end_address(strands, address_to, false);
    assert(strand_from != null);
    assert(strand_to != null);
    strands = _join_strands_with_crossover(strand_from, strand_to, strands, true);
  }

  return strands;
}

Strand _strand_with_end_address(Iterable<Strand> strands, Address address, bool end_is_3p) {
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

BuiltList<Strand> join_strands_by_crossover_reducer(
    BuiltList<Strand> strands, AppState state, actions.JoinStrandsByCrossover action) {
  // gather substrand data
  DNAEnd end_first_click = action.dna_end_first_click;
  DNAEnd end_second_click = action.dna_end_second_click;

  // "from" strand is the one with the 3' end adjacent to the new crossover
  // (in 5' to 3' direction, this crossover goes from one strand to another)
  bool first_clicked_is_from = end_first_click.is_3p;
  DNAEnd end_from = first_clicked_is_from ? end_first_click : end_second_click;
  DNAEnd end_to = first_clicked_is_from ? end_second_click : end_first_click;
  Strand strand_from = state.design.end_to_strand(end_from);
  Strand strand_to = state.design.end_to_strand(end_to);

  // if joining strand to itself by crossover, just make it circular
  return _join_strands_with_crossover(strand_from, strand_to, strands, first_clicked_is_from);
}

// This is a common function used by actions JoinStrandsByCrossover and JoinStrandsByMultipleCrossovers
BuiltList<Strand> _join_strands_with_crossover(
    Strand strand_from, Strand strand_to, BuiltList<Strand> strands, bool first_clicked_is_from) {
  // if joining strand to itself by crossover, just make it circular
  if (strand_from == strand_to) {
    var strand = strand_from;
    int strand_idx = strands.indexOf(strand);
    var strands_mutable = strands.toList();
    var new_strand = strand.rebuild((b) => b..circular = true);
    new_strand = new_strand.initialize();
    strands_mutable[strand_idx] = new_strand;
    return strands_mutable.toBuiltList();
  }

  Strand strand_first_clicked = first_clicked_is_from ? strand_from : strand_to;
  Strand strand_second_clicked = first_clicked_is_from ? strand_to : strand_from;
  List<Substrand> substrands_from = strand_from.substrands.toList();
  List<Substrand> substrands_to = strand_to.substrands.toList();

  // change substrand data
  int last_idx_from = substrands_from.length - 1;
  Domain last_domain_from = substrands_from[last_idx_from];
  Domain first_domain_to = substrands_to[0];
  last_domain_from = last_domain_from.rebuild((b) => b..is_last = false);
  first_domain_to = first_domain_to.rebuild((b) => b
    ..is_first = false
    ..strand_id = strand_to.id);

  // put back into Substrand lists
  substrands_from[last_idx_from] = last_domain_from;
  substrands_to[0] = first_domain_to;

  List<Substrand> substrands_new = substrands_from + substrands_to;

  // create new Strand
  Strand new_strand = join_two_strands_with_substrands(
      strand_first_clicked, strand_second_clicked, substrands_new,
      dna_in_order_1_2: first_clicked_is_from);

  return swap_old_strands_for_new(strands, [strand_from, strand_to], [new_strand]);
}

/// Joins two Strands using specified list of Substrands. Used to merge properties in a consistent way.
/// Defaults to using strand1 for properties, but lets is_scaffold property override.
/// Note that it *ignores* the substrands in strand1 and strand2.
/// Set dna_in_order_1_2=false to reverse the order of DNA concatenation.
Strand join_two_strands_with_substrands(Strand strand1, Strand strand2, List<Substrand> substrands_new,
    {bool dna_in_order_1_2 = true}) {
  var color = strand1.color;
  var idt = strand1.idt;
  if (strand2.is_scaffold == true) {
    color = strand2.color;
    idt = strand2.idt;
  }

  var dna = null;
  var strand_5p = strand1;
  var strand_3p = strand2;
  if (!dna_in_order_1_2) {
    strand_5p = strand2;
    strand_3p = strand1;
  }
  if (strand_5p.dna_sequence == null && strand_3p.dna_sequence == null) {
    dna = null;
  } else if (strand_5p.dna_sequence != null && strand_3p.dna_sequence != null) {
    dna = strand_5p.dna_sequence + strand_3p.dna_sequence;
  } else if (strand_5p.dna_sequence == null) {
    dna = constants.DNA_BASE_WILDCARD * strand_5p.dna_length() + strand_3p.dna_sequence;
  } else if (strand_3p.dna_sequence == null) {
    dna = strand_5p.dna_sequence + constants.DNA_BASE_WILDCARD * strand_3p.dna_length();
  }

  // include 5' mod from 5' strand and 3' mod from 3' strand.
  var mod_5p = strand_5p.modification_5p;
  var mod_3p = strand_3p.modification_3p;

  // put internal mods from both on new strand
  var mods_int = strand_5p.modifications_int.toMap();
  for (int idx in strand_3p.modifications_int.keys) {
    var mod_3p = strand_3p.modifications_int[idx];
    int new_idx = strand_5p.dna_length() + idx;
    mods_int[new_idx] = mod_3p;
  }

  Strand new_strand = Strand(substrands_new,
      color: color,
      dna_sequence: dna,
      idt: idt,
      is_scaffold: strand1.is_scaffold || strand2.is_scaffold,
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
