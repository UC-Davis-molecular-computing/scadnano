import 'package:redux/redux.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/grid.dart';
import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import 'helices_reducer.dart';
import 'inline_insertions_deletions_reducer.dart';
import 'strands_reducer.dart';

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// reducer composition

DNADesign dna_design_reducer(DNADesign dna_design, action) {
  if (dna_design != null) {
    dna_design = dna_design_composed_local_reducer(dna_design, action);
    dna_design = dna_design_whole_local_reducer(dna_design, action);
  }
  return dna_design;
}

DNADesign dna_design_global_reducer(DNADesign dna_design, AppState state, action) {
  dna_design = dna_design_composed_global_reducer(dna_design, state, action);
  dna_design = dna_design_whole_global_reducer(dna_design, state, action);
  return dna_design;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// composed/whole and local/global distinctions explained below

// composed: operate on slices of the DNADesign
// local: don't need the whole AppState
DNADesign dna_design_composed_local_reducer(DNADesign dna_design, action) => dna_design?.rebuild((d) => d
  ..grid = TypedReducer<Grid, actions.GridChange>(grid_local_reducer)(dna_design.grid, action)
  ..helices.replace(helices_local_reducer(dna_design.helices, action))
  ..strands.replace(strands_local_reducer(dna_design.strands, action)));

Grid grid_local_reducer(Grid grid, actions.GridChange action) => action.grid;

// composed: operate on slices of the DNADesign
// global: need the whole AppState
DNADesign dna_design_composed_global_reducer(DNADesign dna_design, AppState state, action) =>
    dna_design?.rebuild((d) => d
      ..helices.replace(helices_global_reducer(dna_design.helices, state, action))
      ..strands.replace(strands_global_reducer(dna_design.strands, state, action)));

// whole: operate on the whole DNADesign
// local: don't need the whole AppState
Reducer<DNADesign> dna_design_whole_local_reducer = combineReducers([
  TypedReducer<DNADesign, actions.ErrorMessageSet>(dna_design_error_message_set_reducer),
  TypedReducer<DNADesign, actions.InlineInsertionsDeletions>(inline_insertions_deletions_reducer),
]);

// This isn't strictly necessary, but it would be nice for debugging if, whenever there is an error,
// the DNADesign in the Model is null.
DNADesign dna_design_error_message_set_reducer(DNADesign dna_design, actions.ErrorMessageSet action) =>
    action.error_message == null || action.error_message.length == 0 ? dna_design : null;

// whole: operate on the whole DNADesign
// global: need the whole AppState
GlobalReducer<DNADesign, AppState> dna_design_whole_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<DNADesign, AppState, actions.HelixAdd>(helix_add_dna_design_reducer),
  TypedGlobalReducer<DNADesign, AppState, actions.HelixRemove>(helix_remove_dna_design_global_reducer),
  TypedGlobalReducer<DNADesign, AppState, actions.HelixRemoveAllSelected>(
      helix_remove_all_selected_dna_design_global_reducer),
]);
