import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';
import '../actions/actions.dart' as actions;

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

//  strands = remove_bound_substrands(strands, state, {substrand_to_remove});
//
//  // need to update state with new strands list so strand_create below sees empty space there
//  var design = state.dna_design.rebuild((d) => d..strands.replace(strands));
//  state = state.rebuild((b) => b..dna_design.replace(design));
//
//  // add two new short Strands in its place
//  int nick_offset = action.offset;
//  var action_strand_left = actions.StrandCreate(
//      helix_idx: substrand_to_remove.helix,
//      forward: substrand_to_remove.forward,
//      start: substrand_to_remove.start,
//      end: nick_offset);
//  var action_strand_right = actions.StrandCreate(
//      helix_idx: substrand_to_remove.helix,
//      forward: substrand_to_remove.forward,
//      start: nick_offset,
//      end: substrand_to_remove.end);
//  strands = strand_create(strands, state, action_strand_left);
//  strands = strand_create(strands, state, action_strand_right);
//
//  // again need to update state with new strands list so strand_create below sees empty space there
//  design = state.dna_design.rebuild((d) => d..strands.replace(strands));
//  state = state.rebuild((b) => b..dna_design.replace(design));
//
//  // join new strands to old strands (if present) by crossovers
//  if (!substrand_to_remove.is_first) {
//    DNAEnd dna_end1;
//    DNAEnd dna_end2;
//    if (substrand_to_remove.forward) {
//      dna_end1 =  (strands.last.substrands[0] as BoundSubstrand).st;
//    } else {
//
//    }
//    strands = _join(strands, dna_end1, dna_end2, state);
//  }
//  if (!substrand_to_remove.is_last) {
//    DNAEnd dna_end1;
//    DNAEnd dna_end2;
//    strands = _join(strands, dna_end1, dna_end2, state);
//  }
}

BuiltList<Strand> ligate_reducer(BuiltList<Strand> strands, AppState state, actions.Ligate action) {
  //TODO: implement this
  return strands;
}

//FIXME: remove prev_ and next_ from Loopout and BoundSubstrand so they don't need to be recalculated

BuiltList<Strand> join_strands_by_crossover_reducer(
    BuiltList<Strand> strands, AppState state, actions.JoinStrandsByCrossover action) {
  // gather substrand data
  DNAEnd dna_end_first_click = action.potential_crossover.dna_end_first_click;
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

  // create new Strand
  Color new_color = strand_first_clicked.color;
  if (strand_second_clicked.is_scaffold == true) {
    new_color = strand_second_clicked.color;
  }
  var dna_sequence = strand_from.dna_sequence != null && strand_to.dna_sequence != null
      ? strand_from.dna_sequence + strand_to.dna_sequence
      : null;
  Strand new_strand = Strand(substrands_from.build() + substrands_to.build(),
      color: new_color,
      dna_sequence: dna_sequence,
      idt: strand_first_clicked.idt,
      is_scaffold: strand_from.is_scaffold == true || strand_to.is_scaffold == true);

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
