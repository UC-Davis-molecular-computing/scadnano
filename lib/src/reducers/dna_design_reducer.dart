import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/linker.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/substrand.dart';

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

DNADesign dna_design_delete_all_reducer(DNADesign dna_design, AppState state, actions.DeleteAllSelected action) {
  BuiltSet<Selectable> items = state.ui_state.selectables_store.selected_items;

  if (state.ui_state.select_mode_state.modes.contains(SelectModeChoice.strand)) {
    var strands = Set<Strand>.from(items.where((item) => item is Strand));
    dna_design = _remove_strands(dna_design, strands);
  } else if (state.ui_state.select_mode_state.modes.contains(SelectModeChoice.crossover) ||
      state.ui_state.select_mode_state.modes.contains(SelectModeChoice.loopout)) {
    var crossovers = Set<Crossover>.from(items.where((item) => item is Crossover));
    var loopouts = Set<Loopout>.from(items.where((item) => item is Loopout));
    dna_design = _remove_crossovers_and_loopouts(dna_design, crossovers, loopouts);
  } else if (state.ui_state.select_mode_state.modes
      .difference(SelectModeChoice.ends.toBuiltSet())
      .isNotEmpty) {
    var ends = items.where((item) => item is DNAEnd);
    var substrands = Set<BoundSubstrand>.from(ends.map((end) => state.dna_design.end_to_substrand[end]));
    dna_design = _remove_substrands(dna_design, substrands);
  }

  return dna_design;
}

DNADesign _remove_strands(DNADesign dna_design, Iterable<Strand> strands_to_remove) =>
    dna_design.rebuild((d) => d..strands.removeWhere((strand) => strands_to_remove.contains(strand)));

DNADesign _remove_crossovers_and_loopouts(DNADesign dna_design, Iterable<Crossover> crossovers,
    Iterable<Loopout> loopouts) {
  Set<Strand> strands_to_remove = {};
  List<Strand> strands_to_add = [];

  // collect all crossovers for one strand because we need special case to remove multiple from one strand
  Map<Strand, List<Linker>> strand_to_linkers = {};
  for (var crossover in crossovers) {
    var strand = dna_design.crossover_to_strand[crossover];
    if (strand_to_linkers[strand] == null) {
      strand_to_linkers[strand] = [];
    }
    strand_to_linkers[strand].add(crossover);
  }
  for (var loopout in loopouts) {
    var strand = dna_design.loopout_to_strand(loopout);
    if (strand_to_linkers[strand] == null) {
      strand_to_linkers[strand] = [];
    }
    strand_to_linkers[strand].add(loopout);
  }

  // remove crossovers one strand at a time
  for (var strand in strand_to_linkers.keys) {
    strands_to_remove.add(strand);
    var split_strands = _remove_linkers_from_strand(strand, strand_to_linkers[strand]);
    strands_to_add.addAll(split_strands);
  }

  // remove old strands and add new strands to DNADesign
  var new_strands = dna_design.strands.toList();
  new_strands.removeWhere((strand) => strands_to_remove.contains(strand));
  new_strands.addAll(strands_to_add);

  return dna_design.rebuild((d) => d..strands.replace(new_strands));
}

// Splits one strand into two by removing a crossover
List<Strand> _remove_linkers_from_strand(Strand strand, List<Linker> linkers) {
//  // find indexes of each substrand between linkers, including those before first and after last
//  List<int> idxs = [0];
//  for (var linker in linkers) {
//    int next_idx = linker.next_substrand_idx;
//    idxs.add(next_idx);
//  }
//  idxs.sort();
//  idxs.add(strand.substrands.length);
//
//  // split strand.substrands by idxs
//  List<List<Substrand>> substrands_list = [];
//  for (int i = 0; i < idxs.length - 1; i++) {
//    var substrands = List<Substrand>.from(strand.substrands.sublist(idxs[i], idxs[i + 1]));
//    substrands_list.add(substrands);
//  }

  linkers.sort((l1, l2) => l1.prev_substrand_idx.compareTo(l2.prev_substrand_idx));

  int linker_idx = 0;
  List<List<Substrand>> substrands_list = [[]];
  for (int i = 0; i < strand.substrands.length; i++) {
    var substrand = strand.substrands[i];
    substrands_list[linker_idx].add(substrand);
    if (linker_idx < linkers.length) {
      Linker linker = linkers[linker_idx];
      if (i == linker.prev_substrand_idx) {
        linker_idx++;
        substrands_list.add([]);
        if (linker is Loopout) {
          i++; // so we don't put Loopout in any new Strands
        }
      }
    }
  }

  //XXX: This should go before updating substrands below with is_first and is_last or else they cannot be
  // found as substrands of strand
  var dnas = [for (var substrands in substrands_list) dna_seq(substrands, strand)];

  // adjust is_first and is_last Booleans on BoundSubstrands
  for (var substrands in substrands_list) {
    var first_bound_ss = substrands[0] as BoundSubstrand;
    int last = substrands.length - 1;
    substrands[0] = first_bound_ss.rebuild((s) => s..is_first = true);
    //XXX: important to get variable from substrands[last] AFTER above assignment to substrands[0],
    // in case List is length 1 and the first object is the last object.
    // This ensures both fields are set to true.
    var last_bound_ss = substrands[last] as BoundSubstrand;
    substrands[last] = last_bound_ss.rebuild((s) => s..is_last = true);
    // replace Loopout prev/next idxs, which are now stale
    for (int i = 0; i < substrands.length; i++) {
      var substrand = substrands[i];
      if (substrand is Loopout) {
        substrands[i] = substrand.rebuild((loopout) =>
        loopout
          ..prev_substrand_idx = i - 1
          ..next_substrand_idx = i + 1);
      }
    }
  }

  List<Strand> new_strands = [];
  for (int i = 0; i < substrands_list.length; i++) {
    var substrands = substrands_list[i];
    var dna = dnas[i];
    // assign old properties to first new strand and find new/default properties for remaining
    var color = i == 0 ? strand.color : util.color_cycler.next();
    var idt = i == 0 ? strand.idt : null;
    var is_scaffold = i == 0 ? strand.is_scaffold : false;
    var new_strand = Strand(substrands, color: color, dna_sequence: dna, idt: idt, is_scaffold: is_scaffold);
    new_strands.add(new_strand);
  }

  return new_strands;
}

String dna_seq(List<Substrand> substrands, Strand strand) =>
    substrands.map((ss) => strand.dna_sequence_in(ss)).reduce((seq1, seq2) => seq1 + seq2);

DNADesign _remove_substrands(DNADesign dna_design, Set<BoundSubstrand> substrands) {
  //FIXME: implement this
  return dna_design;
}

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
