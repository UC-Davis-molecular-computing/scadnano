import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:scadnano/src/state/bound_substrand.dart';

import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';
import '../actions/actions.dart' as actions;
import 'delete_reducer.dart';

DNADesign nick_reducer(DNADesign design, actions.Nick action) {
  BoundSubstrand substrand = action.bound_substrand;
  design = remove_bound_substrands(design, {substrand});
  return design;
  //TODO: implement this. First write reducer for creating new Strands and joining two Strands by crossover.
  // Then implement this by deleting the BoundSubstrand where the nick is to go, creating two new
  // Strands representing the BoundSubstrand on each side of the nick, and then join each of them to the
  // two other Strands by crossover. (if applicable; perhaps this BoundSubstrand is first and/or last.
}

DNADesign ligate_reducer(DNADesign design, actions.Ligate action) {
  //TODO: implement this
  return design;
}

//FIXME: remove prev_ and next_ from Loopout and BoundSubstrand so they don't need to be recalculated

DNADesign join_strands_by_crossover_reducer(DNADesign design, actions.JoinStrandsByCrossover action) {
  // gather substrand data
  DNAEnd dna_end_first_click = action.potential_crossover.dna_end_first_click;
  DNAEnd dna_end_second_click = action.dna_end_second_click;
  // should be going from 3p end of one to 5p end of other
  bool first_clicked_is_from = !dna_end_first_click.is_5p;
  DNAEnd dna_end_from = first_clicked_is_from ? dna_end_first_click : dna_end_second_click;
  DNAEnd dna_end_to = first_clicked_is_from ? dna_end_second_click : dna_end_first_click;
  Strand strand_from = design.end_to_strand(dna_end_from);
  Strand strand_to = design.end_to_strand(dna_end_to);
  if (strand_from == strand_to) {
    // circular Strands not supported
    print('WARNING: circular strands not supported, so I cannot connect strand ${strand_to.id()} to itself.');
    return design;
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

  // put strand in list of strands and remove old
  List<Strand> new_strands = design.strands.toList();
  new_strands.remove(strand_from);
  new_strands.remove(strand_to);
  new_strands.add(new_strand);

  design = design.rebuild((d) => d..strands.replace(new_strands));

  return design;
}
