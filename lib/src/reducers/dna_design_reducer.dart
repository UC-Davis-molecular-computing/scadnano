import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';

import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import 'helices_reducer.dart';

DNADesign dna_design_reducer(DNADesign dna_design, action) {
  if (action is actions.ErrorMessageSet) {
    dna_design = error_message_set_reducer(dna_design, action);
  } else if (action is actions.Action2) {
    dna_design = dna_design_composed_reducer(dna_design, action);
//    dna_design = dna_design_whole_reducer(dna_design, action);
  }
  return dna_design;
}

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

DNADesign dna_design_delete_all_reducer(
    DNADesign dna_design, AppState state, actions.DeleteAllSelected action) {
  BuiltSet<Selectable> items = state.ui_state.selectables_store.selected_items;
  var strands = List<Strand>.from(items.where((item) => item is Strand));
  dna_design = dna_design.remove_strands(strands);
  //TODO: remove other items than just Strands
  return dna_design;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Error message set

// This isn't strictly necessary, but it would be nice for debugging if, whenever there is an error,
// the DNADesign in the Model is null.
DNADesign error_message_set_reducer(DNADesign dna_design, actions.ErrorMessageSet action) =>
    action.error_message == null || action.error_message.length == 0 ? dna_design : null;

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
