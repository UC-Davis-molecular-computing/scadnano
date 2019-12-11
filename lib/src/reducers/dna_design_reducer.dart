import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/strand.dart';

import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import 'change_loopout_length.dart';
import 'delete_reducer.dart';
import 'helices_reducer.dart';
import 'strands_reducer.dart';

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// reducer composition

DNADesign dna_design_reducer(DNADesign dna_design, action) {
  if (action is actions.ErrorMessageSet) {
    dna_design = error_message_set_reducer(dna_design, action);
  } else if (action is actions.Action) {
    dna_design = dna_design_composed_local_reducer(dna_design, action);
    dna_design = dna_design_whole_local_reducer(dna_design, action);
  }
  return dna_design;
}

// This isn't strictly necessary, but it would be nice for debugging if, whenever there is an error,
// the DNADesign in the Model is null.
DNADesign error_message_set_reducer(DNADesign dna_design, actions.ErrorMessageSet action) =>
    action.error_message == null || action.error_message.length == 0 ? dna_design : null;

DNADesign dna_design_global_reducer(DNADesign dna_design, AppState state, action) {
  dna_design = dna_design_composed_global_reducer(dna_design, state, action);
  dna_design = dna_design_whole_global_reducer(dna_design, state, action);
  return dna_design;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// composed/whole and local/global distinctions explained below

// composed: operate on slices of the DNADesign
// local: don't need the whole AppState
DNADesign dna_design_composed_local_reducer(DNADesign dna_design, action) => dna_design.rebuild((d) => d
  ..helices.replace(helices_reducer(dna_design.helices, action))
  ..strands.replace(strands_reducer(dna_design.strands, action)));

// composed: operate on slices of the DNADesign
// global: need the whole AppState
DNADesign dna_design_composed_global_reducer(DNADesign dna_design, AppState state, action) =>
    dna_design.rebuild((d) => d
//      ..helices.replace(helices_global_reducer(dna_design.helices, state, action))
      ..strands.replace(strands_global_reducer(dna_design.strands, state, action)));

// whole: operate on the whole DNADesign
// local: don't need the whole AppState
Reducer<DNADesign> dna_design_whole_local_reducer = combineReducers([]);

// whole: operate on the whole DNADesign
// global: need the whole AppState
GlobalReducer<DNADesign, AppState> dna_design_whole_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<DNADesign, AppState, actions.DeleteAllSelected>(dna_design_delete_all_reducer),
]);

GlobalReducer<BuiltList<Strand>, AppState> strands_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandPartAction>(strands_part_reducer),
//  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.ConvertCrossoverToLoopout>(
//      convert_crossover_to_loopout_reducer),
//  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.LoopoutLengthChange>(loopout_length_change_reducer),
]);

// takes a part of a strand and looks up the strand it's in by strand_id, then applies reducer to strand
BuiltList<Strand> strands_part_reducer(
    BuiltList<Strand> strands, AppState state, actions.StrandPartAction action) {
  Strand strand = state.dna_design.strands_by_id[action.strand_part.strand_id];
  int strand_idx = strands.indexOf(strand);

  strand = strand_part_reducer(strand, action);
  strand = strand.initialize();

  var strands_builder = strands.toBuilder();
  strands_builder[strand_idx] = strand;
  return strands_builder.build();
}

Reducer<Strand> strand_part_reducer = combineReducers([
  TypedReducer<Strand, actions.ConvertCrossoverToLoopout>(convert_crossover_to_loopout_reducer),
  TypedReducer<Strand, actions.LoopoutLengthChange>(loopout_length_change_reducer),
]);
