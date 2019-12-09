
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';

import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import 'delete_reducer.dart';
import 'helices_reducer.dart';

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

