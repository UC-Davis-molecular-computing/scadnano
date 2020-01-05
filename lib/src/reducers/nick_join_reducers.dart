import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

BuiltList<Strand> nick_reducer(BuiltList<Strand> strands, AppState state, actions.Nick action) {
  // remove BoundSubstrand where nick will be, and remember where it was attached
  BoundSubstrand substrand_to_remove = action.bound_substrand;
  var strand = state.dna_design.substrand_to_strand[substrand_to_remove];

  // create new BoundSubstrands
  int nick_offset = action.offset;
  int helix = substrand_to_remove.helix;
  var forward = substrand_to_remove.forward;
  var start = substrand_to_remove.start;
  var end = substrand_to_remove.end;
  BoundSubstrand substrand_left = BoundSubstrand(
      helix: helix,
      forward: forward,
      start: start,
      end: nick_offset,
      deletions: substrand_to_remove.deletions.where((d) => d < nick_offset),
      insertions: substrand_to_remove.insertions.where((i) => i.offset < nick_offset));
  BoundSubstrand substrand_right = BoundSubstrand(
      helix: helix,
      forward: forward,
      start: nick_offset,
      end: end,
      deletions: substrand_to_remove.deletions.where((d) => d >= nick_offset),
      insertions: substrand_to_remove.insertions.where((i) => i.offset >= nick_offset));

  // join new BoundSubstrands to existing strands
  int index_removed = strand.substrands.indexOf(substrand_to_remove);
  List<Substrand> substrands_5p = strand.substrands.sublist(0, index_removed).toList();
  List<Substrand> substrands_3p = strand.substrands.sublist(index_removed + 1).toList();
  BoundSubstrand substrand_5p = substrand_left;
  BoundSubstrand substrand_3p = substrand_right;
  if (!forward) {
    substrand_5p = substrand_right;
    substrand_3p = substrand_left;
  }
  substrand_5p = substrand_5p.rebuild((b) => b
    ..is_last = true
    ..is_first = substrands_5p.isEmpty);
  substrand_3p = substrand_3p.rebuild((b) => b
    ..is_first = true
    ..is_last = substrands_3p.isEmpty);
  substrands_5p.add(substrand_5p);
  substrands_3p.insert(0, substrand_3p);

  String dna_5p = null;
  String dna_3p = null;
  if (strand.dna_sequence != null) {
    int dna_length_5p = [for (var ss in substrands_5p) ss.dna_length()].reduce((l1, l2) => l1 + l2);
    dna_5p = strand.dna_sequence.substring(0, dna_length_5p);
    dna_3p = strand.dna_sequence.substring(dna_length_5p);
  }

  Strand strand_5p = Strand(substrands_5p,
      color: strand.color, dna_sequence: dna_5p, idt: strand.idt, is_scaffold: strand.is_scaffold);
  Strand strand_3p = Strand(substrands_3p,
      color: strand.is_scaffold == true ? strand.color : null,
      dna_sequence: dna_3p,
      is_scaffold: strand.is_scaffold);

  return swap_strands(strands, [strand], [strand_5p, strand_3p]);
}

BuiltList<Strand> ligate_reducer(BuiltList<Strand> strands, AppState state, actions.Ligate action) {
  DNAEnd dna_end = action.dna_end;
  BoundSubstrand substrand = state.dna_design.end_to_substrand[dna_end];
  Strand strand = state.dna_design.substrand_to_strand[substrand];
  int helix = substrand.helix;
  bool forward = substrand.forward;
  int offset = dna_end.offset;

  // Look at adjacent locations for a substrand not equal to current substrand,
  // Need strange logic with offset because BoundSubstrand.end is exclusive.
  BoundSubstrand other_substrand;
  BuiltSet<BoundSubstrand> substrands_adjacent;
  DNAEnd strand_end;
  if (dna_end.is_start)
    substrands_adjacent = state.dna_design.substrands_on_helix_at(helix, offset - 1);
  else
    substrands_adjacent = state.dna_design.substrands_on_helix_at(helix, offset);
  for (var substrand_adj in substrands_adjacent) {
    Strand strand_adj = state.dna_design.substrand_to_strand[substrand_adj];
    var ends = strand.ligatable_ends(strand_adj);
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
  BoundSubstrand ss_left, ss_right;
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
  BoundSubstrand ss_5p, ss_3p;
  Strand strand_5p, strand_3p;
  if (dna_end.is_5p && !forward) {
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

  BoundSubstrand new_substrand = BoundSubstrand(
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

  return swap_strands(strands, [strand_left, strand_right], [new_strand]);
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
  var strand_first_dna = strand1;
  var strand_second_dna = strand2;
  if (!dna_in_order_1_2) {
    strand_first_dna = strand2;
    strand_second_dna = strand1;
  }
  if (strand_first_dna.dna_sequence == null && strand_second_dna.dna_sequence == null) {
    dna = null;
  } else if (strand_first_dna.dna_sequence != null && strand_second_dna.dna_sequence != null) {
    dna = strand_first_dna.dna_sequence + strand_second_dna.dna_sequence;
  } else if (strand_first_dna.dna_sequence == null) {
    dna = constants.DNA_BASE_WILDCARD * strand_first_dna.dna_length() + strand_second_dna.dna_sequence;
  } else if (strand_second_dna.dna_sequence == null) {
    dna = strand_first_dna.dna_sequence + constants.DNA_BASE_WILDCARD * strand_second_dna.dna_length();
  }

  Strand new_strand = Strand(substrands_new,
      color: color, dna_sequence: dna, idt: idt, is_scaffold: strand1.is_scaffold || strand2.is_scaffold);
  return new_strand;
}

BuiltList<Strand> join_strands_by_crossover_reducer(
    BuiltList<Strand> strands, AppState state, actions.JoinStrandsByCrossover action) {
  // gather substrand data
  DNAEnd dna_end_first_click = action.dna_end_first_click;
  DNAEnd dna_end_second_click = action.dna_end_second_click;

  // should be going from 3p end of one to 5p end of other
  return _join(strands, dna_end_first_click, dna_end_second_click, state);
}

BuiltList<Strand> _join(
    BuiltList<Strand> strands, DNAEnd dna_end_first_click, DNAEnd dna_end_second_click, AppState state) {
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
  BoundSubstrand last_ss_from = substrands_from[last_idx_from];
  BoundSubstrand first_ss_to = substrands_to[0];
  last_ss_from = last_ss_from.rebuild((b) => b..is_last = false);
  first_ss_to = first_ss_to.rebuild((b) => b
    ..is_first = false
    ..strand_id = strand_to.id());

  // put back into Substrand lists
  substrands_from[last_idx_from] = last_ss_from;
  substrands_to[0] = first_ss_to;

  List<Substrand> substrands_new = substrands_from.build().toList() + substrands_to.build().toList();

  // create new Strand
//  Color new_color = strand_first_clicked.color;
//  if (strand_second_clicked.is_scaffold == true) {
//    new_color = strand_second_clicked.color;
//  }
//  var dna_sequence = strand_from.dna_sequence != null && strand_to.dna_sequence != null
//      ? strand_from.dna_sequence + strand_to.dna_sequence
//      : null;
//  Strand new_strand = Strand(substrands_from.build() + substrands_to.build(),
//      color: new_color,
//      dna_sequence: dna_sequence,
//      idt: strand_first_clicked.idt,
//      is_scaffold: strand_from.is_scaffold == true || strand_to.is_scaffold == true);

  Strand new_strand = join_two_strands_with_substrands(
      strand_first_clicked, strand_second_clicked, substrands_new,
      dna_in_order_1_2: first_clicked_is_from);

  return swap_strands(strands, [strand_from, strand_to], [new_strand]);
}

// put strand in list of strands and remove old
BuiltList<Strand> swap_strands(
    BuiltList<Strand> strands, Iterable<Strand> strands_to_remove, List<Strand> strands_to_add) {
  List<Strand> new_strands = strands.toList();
  for (var strand in strands_to_remove) {
    new_strands.remove(strand);
  }
  for (var strand in strands_to_add) {
    new_strands.add(strand);
  }
  return new_strands.build();
}
