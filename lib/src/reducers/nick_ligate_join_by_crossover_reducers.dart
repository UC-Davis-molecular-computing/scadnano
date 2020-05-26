import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

BuiltList<Strand> nick_reducer(BuiltList<Strand> strands, AppState state, actions.Nick action) {
  // remove Domain where nick will be, and remember where it was attached
  Domain domain_to_remove = action.domain;
  var strand = state.dna_design.substrand_to_strand[domain_to_remove];

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
      deletions: domain_to_remove.deletions.where((d) => d < nick_offset),
      insertions: domain_to_remove.insertions.where((i) => i.offset < nick_offset));
  Domain domain_right = Domain(
      helix: helix,
      forward: forward,
      start: nick_offset,
      end: end,
      deletions: domain_to_remove.deletions.where((d) => d >= nick_offset),
      insertions: domain_to_remove.insertions.where((i) => i.offset >= nick_offset));

  // join new Domains to existing strands
  int index_removed = strand.substrands.indexOf(domain_to_remove);
  List<Substrand> substrands_5p = strand.substrands.sublist(0, index_removed).toList();
  List<Substrand> substrands_3p = strand.substrands.sublist(index_removed + 1).toList();
  Domain domain_5p = domain_left;
  Domain domain_3p = domain_right;
  if (!forward) {
    domain_5p = domain_right;
    domain_3p = domain_left;
  }
  domain_5p = domain_5p.rebuild((b) => b
    ..is_last = true
    ..is_first = substrands_5p.isEmpty);
  domain_3p = domain_3p.rebuild((b) => b
    ..is_first = true
    ..is_last = substrands_3p.isEmpty);
  substrands_5p.add(domain_5p);
  substrands_3p.insert(0, domain_3p);

  String dna_5p = null;
  String dna_3p = null;
  if (strand.dna_sequence != null) {
    int dna_length_5p = [for (var ss in substrands_5p) ss.dna_length()].reduce((l1, l2) => l1 + l2);
    dna_5p = strand.dna_sequence.substring(0, dna_length_5p);
    dna_3p = strand.dna_sequence.substring(dna_length_5p);
  }

  int dna_length_strand_5p = [for (var ss in substrands_5p) ss.dna_length()].reduce((a, b) => a + b);

  // move modifications onto strand_5p from strand
  Map<int, ModificationInternal> modifications_int_strand_5p = {};
  for (int i = 0; i < substrands_5p.length; i++) {
    var mods_on_ss = strand.internal_modifications_on_substrand_absolute_idx[i];
    mods_on_ss.forEach((idx, mod) {
      if (i < substrands_5p.length - 1 || idx < dna_length_strand_5p) {
        modifications_int_strand_5p[idx] = mod;
      }
    });
  }

  Strand strand_5p = Strand(substrands_5p,
      color: strand.color,
      dna_sequence: dna_5p,
      idt: strand.idt,
      is_scaffold: strand.is_scaffold,
      modification_5p: strand.modification_5p,
      modification_3p: null,
      modifications_int: modifications_int_strand_5p);

  // move modifications onto strand_3p from strand
  Map<int, ModificationInternal> modifications_int_strand_3p = {};
  for (int i = substrands_5p.length - 1; i < strand.substrands.length; i++) {
    var mods_on_ss = strand.internal_modifications_on_substrand_absolute_idx[i];
    mods_on_ss.forEach((idx, mod) {
      if (i > substrands_5p.length || idx >= dna_length_strand_5p) {
        int new_idx = idx - dna_length_strand_5p;
        modifications_int_strand_3p[new_idx] = mod;
      }
    });
  }

  Strand strand_3p = Strand(substrands_3p,
      color: strand.is_scaffold == true ? strand.color : null,
      dna_sequence: dna_3p,
      is_scaffold: strand.is_scaffold,
      modification_5p: null,
      modification_3p: strand.modification_3p,
      modifications_int: modifications_int_strand_3p);

  return swap_old_strands_for_new(strands, [strand], [strand_5p, strand_3p]);
}

BuiltList<Strand> ligate_reducer(BuiltList<Strand> strands, AppState state, actions.Ligate action) {
  DNAEnd dna_end_clicked = action.dna_end;
  Domain substrand = state.dna_design.end_to_substrand[dna_end_clicked];
  Strand strand = state.dna_design.substrand_to_strand[substrand];
  int helix = substrand.helix;
  bool forward = substrand.forward;
  int offset = dna_end_clicked.offset;

  // Look at adjacent locations for a substrand not equal to current substrand,
  // Need strange logic with offset because Domain.end is exclusive.
  Domain other_substrand;
  BuiltSet<Domain> substrands_adjacent;
  DNAEnd strand_end;
  if (dna_end_clicked.is_start)
    substrands_adjacent = state.dna_design.substrands_on_helix_at(helix, offset - 1);
  else
    substrands_adjacent = state.dna_design.substrands_on_helix_at(helix, offset);
  for (var substrand_adj in substrands_adjacent) {
    Strand strand_adj = state.dna_design.substrand_to_strand[substrand_adj];
    var ends = strand.ligatable_ends_with(strand_adj);
    if (ends != null) {
      strand_end = ends.item1;
      other_substrand = substrand_adj;
      break;
    }
  }
  // if no substrands are adjacent, then action has no effect
  if (other_substrand == null) {
    return strands;
  }

  // normalize left/right distinction
  bool other_is_right = !strand_end.is_start;
  Domain ss_left, ss_right;
  if (other_is_right) {
    ss_left = substrand;
    ss_right = other_substrand;
  } else {
    ss_left = other_substrand;
    ss_right = substrand;
  }
  Strand strand_left = state.dna_design.substrand_to_strand[ss_left];
  Strand strand_right = state.dna_design.substrand_to_strand[ss_right];

  // normalize 5'/3' distinction; below refers to which Strand has the 5'/3' end that will be ligated
  // So strand_5p is the one whose 3' end will be the 3' end of the whole new Strand
  Domain ss_5p, ss_3p;
  Strand strand_5p, strand_3p;
  if (!forward) {
    ss_5p = ss_left;
    ss_3p = ss_right;
    strand_5p = strand_left;
    strand_3p = strand_right;
  } else {
    ss_5p = ss_right;
    ss_3p = ss_left;
    strand_5p = strand_right;
    strand_3p = strand_left;
  }

  Domain new_substrand = Domain(
      helix: helix,
      forward: forward,
      start: ss_left.start,
      end: ss_right.end,
      deletions: ss_left.deletions + ss_right.deletions,
      insertions: ss_left.insertions + ss_right.insertions,
      is_first: ss_3p.is_first,
      is_last: ss_5p.is_last);
  var substrands_5p_new = strand_5p.substrands.toList()..removeAt(0);
  var substrands_3p_new = strand_3p.substrands.toList()..removeLast();

  // take properties from existing strands
  var substrands_new = substrands_3p_new + [new_substrand] + substrands_5p_new;
  Strand new_strand = join_two_strands_with_substrands(strand_3p, strand_5p, substrands_new);

  return swap_old_strands_for_new(strands, [strand_left, strand_right], [new_strand]);
}

BuiltList<Strand> join_strands_by_crossover_reducer(
    BuiltList<Strand> strands, AppState state, actions.JoinStrandsByCrossover action) {
  // gather substrand data
  DNAEnd dna_end_first_click = action.dna_end_first_click;
  DNAEnd dna_end_second_click = action.dna_end_second_click;

  bool first_clicked_is_from = !dna_end_first_click.is_5p;
  DNAEnd dna_end_from = first_clicked_is_from ? dna_end_first_click : dna_end_second_click;
  DNAEnd dna_end_to = first_clicked_is_from ? dna_end_second_click : dna_end_first_click;
  Strand strand_from = state.dna_design.end_to_strand(dna_end_from);
  Strand strand_to = state.dna_design.end_to_strand(dna_end_to);
  if (strand_from == strand_to) {
    // circular Strands not supported
    print('WARNING: circular strands not supported, so I cannot connect strand ${strand_to.id()} to itself.');
    return strands;
  }
  Strand strand_first_clicked = first_clicked_is_from ? strand_from : strand_to;
  Strand strand_second_clicked = first_clicked_is_from ? strand_to : strand_from;
  ListBuilder<Substrand> substrands_from = strand_from.substrands.toBuilder();
  ListBuilder<Substrand> substrands_to = strand_to.substrands.toBuilder();

  // change substrand data
  int last_idx_from = substrands_from.length - 1;
  Domain last_domain_from = substrands_from[last_idx_from];
  Domain first_domain_to = substrands_to[0];
  last_domain_from = last_domain_from.rebuild((b) => b..is_last = false);
  first_domain_to = first_domain_to.rebuild((b) => b
    ..is_first = false
    ..strand_id = strand_to.id());

  // put back into Substrand lists
  substrands_from[last_idx_from] = last_domain_from;
  substrands_to[0] = first_domain_to;

  List<Substrand> substrands_new = substrands_from.build().toList() + substrands_to.build().toList();

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

  // include 5'p' mod from 5' strand and 3' mod from 3' strand.
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
