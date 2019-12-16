import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/bound_substrand.dart';

import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/substrand.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import 'delete_reducer.dart';

DNADesign nick_reducer(DNADesign design, actions.Nick action) {
  BoundSubstrand substrand = action.bound_substrand;
  design = remove_bound_substrands(design, {substrand});
  return design;
  //FIXME: implement this. First write reducer for creating new Strands and joining two Strands by crossover.
  // Then implement this by deleting the BoundSubstrand where the nick is to go, creating two new
  // Strands representing the BoundSubstrand on each side of the nick, and then join each of them to the
  // two other Strands by crossover. (if applicable; perhaps this BoundSubstrand is first and/or last.
}
