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
  TypedReducer<BuiltList<Helix>, actions.HelixOffsetChangeAll>(helix_offset_change_all_reducer),
  TypedReducer<BuiltList<Helix>, actions.HelixMajorTickDistanceChangeAll>(
      helix_major_tick_distance_change_all_reducer),
  TypedReducer<BuiltList<Helix>, actions.HelixMajorTicksChangeAll>(helix_major_ticks_change_all_reducer),
  TypedReducer<BuiltList<Helix>, actions.HelixIndividualAction>(helix_individual_reducer),
  TypedReducer<BuiltList<Helix>, actions.GridChange>(helix_grid_change_reducer),
]);

BuiltList<Helix> helix_individual_reducer(BuiltList<Helix> helices, actions.HelixIndividualAction action) {
  Helix helix = helices[action.helix_idx];
  var new_helix = _helix_individual_reducers(helix, action);
  if (new_helix != helix) {
    var helices_list = helices.toBuilder();
    helices_list[action.helix_idx] = new_helix;
    return helices_list.build();
  } else {
    return helices;
  }
}

Reducer<Helix> _helix_individual_reducers = combineReducers([
  TypedReducer<Helix, actions.HelixOffsetChange>(helix_offset_change_reducer),
  TypedReducer<Helix, actions.HelixMajorTickDistanceChange>(helix_major_tick_distance_change_reducer),
  TypedReducer<Helix, actions.HelixMajorTicksChange>(helix_major_ticks_change_reducer),
  TypedReducer<Helix, actions.HelixPositionSet>(helix_position_set_reducer),
]);

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// change min/max offsets

Helix helix_offset_change_reducer(Helix helix, actions.HelixOffsetChange action) =>
    _change_offset_one_helix(helix, action.min_offset, action.max_offset);

Helix _change_offset_one_helix(Helix helix, int min_offset, int max_offset) => helix.rebuild((b) => b
  ..min_offset = min_offset ?? helix.min_offset
  ..max_offset = max_offset ?? helix.max_offset);

BuiltList<Helix> helix_offset_change_all_reducer(
        BuiltList<Helix> helices, actions.HelixOffsetChangeAll action) =>
    helices
        .map((helix) => _change_offset_one_helix(helix, action.min_offset, action.max_offset))
        .toBuiltList();

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// change major ticks

BuiltList<Helix> helix_major_tick_distance_change_all_reducer(
        BuiltList<Helix> helices, actions.HelixMajorTickDistanceChangeAll action) =>
    helices
        .map((helix) => _change_major_tick_distance_one_helix(helix, action.major_tick_distance))
        .toBuiltList();

BuiltList<Helix> helix_major_ticks_change_all_reducer(
        BuiltList<Helix> helices, actions.HelixMajorTicksChangeAll action) =>
    helices.map((helix) => _change_major_ticks_one_helix(helix, action.major_ticks)).toBuiltList();

Helix helix_major_tick_distance_change_reducer(Helix helix, actions.HelixMajorTickDistanceChange action) =>
    _change_major_tick_distance_one_helix(helix, action.major_tick_distance);

Helix helix_major_ticks_change_reducer(Helix helix, actions.HelixMajorTicksChange action) =>
    _change_major_ticks_one_helix(helix, action.major_ticks);

Helix _change_major_tick_distance_one_helix(Helix helix, int major_tick_distance) => helix.rebuild((b) => b
  ..major_tick_distance = major_tick_distance
  ..major_ticks = null);

Helix _change_major_ticks_one_helix(Helix helix, BuiltList<int> major_ticks) => helix.rebuild((b) => b
  ..major_ticks.replace(major_ticks)
  ..major_tick_distance = null);

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
      position: action.position,
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// grid change, so helix must change positions

BuiltList<Helix> helix_grid_change_reducer(BuiltList<Helix> helices, actions.GridChange action) {
  List<HelixBuilder> helices_builder = helices.map((h) => h.toBuilder()).toList();
  for (int i = 0; i < helices.length; i++) {
    Helix helix = helices[i];
    helices_builder[i].grid = action.grid;
    if (!action.grid.is_none() && helix.grid_position == null) {
      helices_builder[i].grid_position = util.position3d_to_grid(helix.position, action.grid).toBuilder();
      helices_builder[i].position_ = null;
    }
    if (action.grid.is_none() && helix.position_ == null) {
      helices_builder[i].grid_position = null;
      helices_builder[i].position_ = util.grid_to_position3d(helix.grid_position, helix.grid).toBuilder();
    }
  }

  BuiltList<Helix> new_helices = [for (var helix in helices_builder) helix.build()].build();
  return new_helices;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// change helix position

Helix helix_position_set_reducer(Helix helix, actions.HelixPositionSet action) => helix.rebuild((b) => b
  ..position_.replace(action.position)
  ..grid_position = null);
