import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/app_state.dart';

import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/strand.dart';
import 'delete_reducer.dart' as delete_reducer;
import '../state/helix.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../constants.dart' as constants;

Reducer<BuiltList<Helix>> helices_local_reducer = combineReducers([
  TypedReducer<BuiltList<Helix>, actions.HelixRotationSet>(helix_rotation_set_reducer),
  TypedReducer<BuiltList<Helix>, actions.HelixRotationSetAtOther>(helix_rotation_set_at_other_reducer),
]);

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// set rotation of backbone

BuiltList<Helix> helix_rotation_set_reducer(BuiltList<Helix> helices, actions.HelixRotationSet action) {
  Helix helix_new = helices[action.helix_idx].rebuild((h) => h
    ..rotation = action.rotation
    ..rotation_anchor = action.anchor);
  ListBuilder<Helix> helix_list_builder = helices.toBuilder();
  helix_list_builder[action.helix_idx] = helix_new;

  return helix_list_builder.build();
}

BuiltList<Helix> helix_rotation_set_at_other_reducer(
    BuiltList<Helix> helices, actions.HelixRotationSetAtOther action) {
  num rotation = util.rotation_between_helices(helices, action);

  Helix helix = helices[action.helix_idx];

  // adjust helix rotation
  Helix helix_new = helix.rebuild((h) => h
    ..rotation = rotation
    ..rotation_anchor = action.anchor);

  // create new helices
  var helices_builder = helices.toBuilder();
  helices_builder[action.helix_idx] = helix_new;
  return helices_builder.build();
}

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

DNADesign helix_remove_dna_design_global_reducer(
    DNADesign design, AppState state, actions.HelixRemove action) {
  Set<BoundSubstrand> substrands_on_helix = design.substrands_on_helix(action.helix_idx).toSet();
  var strands_with_substrands_removed =
      delete_reducer.remove_bound_substrands(design.strands, state, substrands_on_helix);
  var strands_with_helix_indices_updated =
      change_all_bound_substrand_helix_idxs(strands_with_substrands_removed, action.helix_idx, -1);
  var new_helices = remove_helix_assuming_no_bound_substrands(design.helices, action);
  return design
      .rebuild((d) => d..helices.replace(new_helices)..strands.replace(strands_with_helix_indices_updated));
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
BuiltList<Helix> remove_helix_assuming_no_bound_substrands(
    BuiltList<Helix> helices, actions.HelixRemove action) {
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
