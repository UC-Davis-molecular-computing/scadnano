import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/substrand.dart';
import 'package:tuple/tuple.dart';

import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import 'helices_reducer.dart';
import '../util.dart' as util;

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// reducer composition

DNADesign dna_design_reducer(DNADesign dna_design, action) {
  if (action is actions.ErrorMessageSet) {
    dna_design = error_message_set_reducer(dna_design, action);
  } else if (action is actions.Action2) {
    dna_design = dna_design_composed_reducer(dna_design, action);
//    dna_design = dna_design_whole_reducer(dna_design, action);
  }
  return dna_design;
}

// This isn't strictly necessary, but it would be nice for debugging if, whenever there is an error,
// the DNADesign in the Model is null.
DNADesign error_message_set_reducer(DNADesign dna_design, actions.ErrorMessageSet action) =>
    action.error_message == null || action.error_message.length == 0 ? dna_design : null;

DNADesign dna_design_composed_reducer(DNADesign dna_design, action) =>
    dna_design.rebuild((d) => d..helices.replace(helices_reducer(dna_design.helices, action)));

//XXX: don't need this yet, but might soon
DNADesign dna_design_global_reducer(DNADesign dna_design, AppState state, action) {
  dna_design = dna_design_global_composed_reducer(dna_design, state, action);
  dna_design = dna_design_global_whole_reducer(dna_design, state, action);
  return dna_design;
}

DNADesign dna_design_global_composed_reducer(DNADesign dna_design, AppState state, action) =>
    dna_design.rebuild((d) => d
//      ..helices.replace(helices_global_reducer(dna_design.helices, action))
//  ..strands.replace(strands_global_reducer(dna_design.strands, action))
        );

GlobalReducer<DNADesign, AppState> dna_design_global_whole_reducer = combineGlobalReducers([
  TypedGlobalReducer<DNADesign, AppState, actions.DeleteAllSelected>(dna_design_delete_all_reducer),
]);

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// delete all

DNADesign dna_design_delete_all_reducer(
    DNADesign dna_design, AppState state, actions.DeleteAllSelected action) {
  BuiltSet<Selectable> items = state.ui_state.selectables_store.selected_items;

  var strands = Set<Strand>.from(items.where((item) => item is Strand));
  var crossovers = Set<Crossover>.from(items.where((item) => item is Crossover));
  var ends = Set<DNAEnd>.from(items.where((item) => item is DNAEnd));
  var loopouts = Set<Loopout>.from(items.where((item) => item is Loopout));

  dna_design = _remove_strands(dna_design, strands);
  dna_design = _remove_crossovers(dna_design, crossovers);
//  dna_design = _remove_substrands(dna_design, ends);
//  dna_design = _remove_loopouts(dna_design, loopouts);

  return dna_design;
}

DNADesign _remove_strands(DNADesign dna_design, Iterable<Strand> strands_to_remove) =>
    dna_design.rebuild((d) => d..strands.removeWhere((strand) => strands_to_remove.contains(strand)));

DNADesign _remove_crossovers(DNADesign dna_design, Iterable<Crossover> crossovers) {
  Set<Strand> strands_to_remove = {};
  List<Strand> strands_to_add = [];
  for (var crossover in crossovers) {
    var strand = dna_design.crossover_to_strand(crossover);
    strands_to_remove.add(strand);
    var split_strands = _remove_crossover(strand, crossover);
    strands_to_add.add(split_strands.item1);
    strands_to_add.add(split_strands.item2);
  }
  var new_strands = dna_design.strands.toList();
  new_strands.removeWhere((strand) => strands_to_remove.contains(strand));
  new_strands.addAll(strands_to_add);
  return dna_design.rebuild((d) => d..strands.replace(new_strands));
}

// Splits one strand into two by removing a crossover
Tuple2<Strand, Strand> _remove_crossover(Strand strand, Crossover crossover) {
  // get substrands on either side of crossover
  List<Substrand> substrands1 = [];
  List<Substrand> substrands2 = [];
  bool crossed = false;
  for (var ss in strand.substrands) {
    if (!crossed) {
      substrands1.add(ss);
    } else {
      substrands2.add(ss);
    }
    if (crossover.prev_substrand == ss) {
      crossed = true;
    }
  }

  //XXX: This should go before updating substrands below with is_first and is_last or else they cannot be
  // found as substrands of strand
  var dna1 = dna_seq(substrands1, strand);
  var dna2 = dna_seq(substrands2, strand);

  // adjust is_first and is_last Booleans on substrands
  BoundSubstrand ss_end_strand1 = substrands1[substrands1.length - 1];
  ss_end_strand1 = ss_end_strand1.rebuild((ss) => ss.is_last = true);
  substrands1[substrands1.length - 1] = ss_end_strand1;
  BoundSubstrand ss_start_strand2 = substrands2[0];
  ss_start_strand2 = ss_start_strand2.rebuild((ss) => ss.is_first = true);
  substrands2[0] = ss_start_strand2;

  var color1 = strand.color;
  var color2 = color1;
  while (color2 == color1) {
    color2 = util.color_cycler.next();
  }

  var strand1 = Strand(
    substrands1,
    color: color1,
    dna_sequence: dna1,
    idt: strand.idt,
    is_scaffold: strand.is_scaffold,
  );
  var strand2 = Strand(
    substrands2,
    color: color2,
    dna_sequence: dna2,
  );

  return Tuple2<Strand, Strand>(strand1, strand2);
}

String dna_seq(List<Substrand> substrands, Strand strand) =>
    substrands.map((ss) => strand.dna_sequence_in(ss)).reduce((seq1, seq2) => seq1 + seq2);

//int dna_length(Iterable<Substrand> substrands) =>
//    substrands.map((ss) => ss.dna_length()).reduce((a, b) => a + b);

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix rotation set

//DNADesign helix_rotation_set_reducer(DNADesign dna_design, dispatcher.HelixRotationSet action) {
//  Helix helix_new = dna_design.helices[action.helix_idx].rebuild((h) => h
//    ..rotation = action.rotation
//    ..rotation_anchor = action.anchor);
//  ListBuilder<Helix> helix_list_builder = dna_design.helices.toBuilder();
//  helix_list_builder[action.helix_idx] = helix_new;
//
//  return dna_design.rebuild((d) => d..helices = helix_list_builder);
//}
//
//DNADesign helix_rotation_set_at_other_reducer(DNADesign dna_design, dispatcher.HelixRotationSetAtOther action) {
//  Helix helix = dna_design.helices[action.helix_idx];
//  Helix helix_other = dna_design.helices[action.helix_other_idx];
//
////  print('*' * 50 + ' setting rotation of helix ${action.helix_idx}');
//
//  num rotation = helix.angle_to(helix_other);
//  if (!action.forward) {
//    rotation = (rotation - 150) % 360;
//  }
//
//  // adjust helix rotation
//  Helix helix_new = helix.rebuild((h) => h
//    ..rotation = rotation
//    ..rotation_anchor = action.anchor);
//
//  // create new helices
//  var helices_builder = dna_design.helices.toBuilder();
//  helices_builder[action.helix_idx] = helix_new;
//
//  // update mouseover_data
//  app.store.dispatch(dispatcher.MouseoverDataUpdate());
//
//  var dna_design_new = dna_design.rebuild((d) => d..helices = helices_builder);
//
////  print('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n'
////      'Handled dispatcher.HelixRotationSetAtOther and created new DNADesign:\n$dna_design_new');
//
//  return dna_design_new;
//}
