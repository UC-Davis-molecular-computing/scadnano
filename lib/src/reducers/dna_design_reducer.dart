import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:redux/redux.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/strand.dart';
import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import 'delete_reducer.dart';
import 'helices_reducer.dart';
import 'nick_join_reducers.dart';
import 'strands_reducer.dart';
import '../constants.dart' as constants;
import 'delete_reducer.dart' as delete_reducer;
import '../util.dart' as util;

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
  ..helices.replace(helices_local_reducer(dna_design.helices, action))
  ..strands.replace(strands_local_reducer(dna_design.strands, action)));

// composed: operate on slices of the DNADesign
// global: need the whole AppState
DNADesign dna_design_composed_global_reducer(DNADesign dna_design, AppState state, action) =>
    dna_design.rebuild((d) => d
//      ..helices.replace(helices_global_reducer(dna_design.helices, state, action))
      ..strands.replace(strands_global_reducer(dna_design.strands, state, action)));

// whole: operate on the whole DNADesign
// local: don't need the whole AppState
Reducer<DNADesign> dna_design_whole_local_reducer = combineReducers([
  TypedReducer<DNADesign, actions.HelixAdd>(helix_add_dna_design_local_reducer),
  TypedReducer<DNADesign, actions.HelixRemove>(helix_remove_dna_design_local_reducer),
  TypedReducer<DNADesign, actions.Nick>(nick_reducer),
]);

// whole: operate on the whole DNADesign
// global: need the whole AppState
GlobalReducer<DNADesign, AppState> dna_design_whole_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<DNADesign, AppState, actions.DeleteAllSelected>(dna_design_delete_all_reducer),
  TypedGlobalReducer<DNADesign, AppState, actions.DeleteAllSelected>(dna_design_delete_all_reducer),
]);

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// helix add/remove

DNADesign helix_add_dna_design_local_reducer(DNADesign design, actions.HelixAdd action) {
  int new_idx = design.helices.length;
  var min_offset = design.helices.length > 0 ? design.min_offset : 0;
  var max_offset = design.helices.length > 0 ? design.max_offset : constants.default_max_offset;

  Helix helix = Helix(
      idx: new_idx,
      grid: design.grid,
      grid_position: action.grid_position,
      min_offset: min_offset,
      max_offset: max_offset,
      view_order: new_idx);
  List<Helix> helices = design.helices.toList();
  helices.add(helix);

  return design.rebuild((d) => d..helices.replace(helices));
}

DNADesign helix_remove_dna_design_local_reducer(DNADesign design, actions.HelixRemove action) {
  Set<BoundSubstrand> substrands_on_helix = design.substrands_on_helix(action.helix_idx).toSet();
  design = delete_reducer.remove_bound_substrands(design, substrands_on_helix);
  var new_strands = change_all_bound_substrand_helix_idxs(design.strands, action.helix_idx, -1);
  var new_helices = remove_helix_assuming_no_bound_substrands(design.helices, action);
  return design.rebuild((d) => d
    ..helices.replace(new_helices)
    ..strands.replace(new_strands));
}

/// Change (by amount `increment`) all helix_idx's of all BoundSubstrands with helix >= helix_idx.
List<Strand> change_all_bound_substrand_helix_idxs(BuiltList<Strand> strands, int helix_idx, int increment) {
  List<Strand> new_strands = strands.toList();
  for (int i = 0; i < strands.length; i++) {
    Strand strand = strands[i];
    StrandBuilder strand_builder = strand.toBuilder();
    for (int j = 0; j < strand.substrands.length; j++) {
      if (strand.substrands[j] is BoundSubstrand) {
        BoundSubstrand bound_substrand = strand.substrands[j];
        if (bound_substrand.helix >= helix_idx) {
          BoundSubstrandBuilder bound_substrand_builder = bound_substrand.toBuilder();
          bound_substrand_builder.helix += increment;
          strand_builder.substrands[j] = bound_substrand_builder.build();
        }
      }
    }
    new_strands[i] = strand_builder.build();
  }
  return new_strands;
}

/// Remove helix from list, assuming no BoundSubstrands are on it.
BuiltList<Helix> remove_helix_assuming_no_bound_substrands(BuiltList<Helix> helices, actions.HelixRemove action) {
  ListBuilder<Helix> helices_builder = helices.toBuilder();
  int removed_view_order = helices[action.helix_idx].view_order;
  helices_builder.removeAt(action.helix_idx);
  for (int i = 0; i < helices_builder.length; i++) {
    HelixBuilder helix_builder = helices_builder[i].toBuilder();
    if (i >= action.helix_idx) {
      helix_builder.idx = i;
    }
    if (helix_builder.view_order >= removed_view_order) {
      helix_builder.view_order--;
    }
    helices_builder[i] = helix_builder.build();
  }
  return helices_builder.build();
}
