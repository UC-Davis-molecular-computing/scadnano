import 'dart:math';

import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';

import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/strand.dart';
import 'delete_reducer.dart' as delete_reducer;
import '../state/helix.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'selection_reducer.dart';
import '../extension_methods.dart';

Reducer<BuiltMap<int, Helix>> helices_local_reducer = combineReducers([
  TypedReducer<BuiltMap<int, Helix>, actions.HelixOffsetChangeAll>(helix_offset_change_all_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixMajorTickDistanceChangeAll>(
      helix_major_tick_distance_change_all_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixMajorTicksChangeAll>(helix_major_ticks_change_all_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixIndividualAction>(helix_individual_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.GridChange>(helix_grid_change_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixGridPositionSet>(helix_grid_position_set_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixPositionSet>(helix_position_set_reducer),
]);

GlobalReducer<BuiltMap<int, Helix>, AppState> helices_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixSelect>(helix_select_helices_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixSelectionsAdjust>(
      helix_selections_adjust_helices_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixSelectionsClear>(
      helix_selections_clear_helices_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.SetOnlyDisplaySelectedHelices>(
    set_only_display_selected_helices_reducer,
  ),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixRollSetAtOther>(
    helix_roll_set_at_other_reducer,
  ),
]);

BuiltMap<int, Helix> helix_individual_reducer(
    BuiltMap<int, Helix> helices, actions.HelixIndividualAction action) {
  Helix helix = helices[action.helix_idx];
  var new_helix = _helix_individual_reducers(helix, action);
  if (new_helix != helix) {
    var helices_map = helices.toMap();
    helices_map[action.helix_idx] = new_helix;
    helices_map = util.helices_assign_svg(helices_map, new_helix.grid);
    return helices_map.build();
  } else {
    return helices;
  }
}

Reducer<Helix> _helix_individual_reducers = combineReducers([
  TypedReducer<Helix, actions.HelixOffsetChange>(helix_offset_change_reducer),
  TypedReducer<Helix, actions.HelixMajorTickDistanceChange>(helix_major_tick_distance_change_reducer),
  TypedReducer<Helix, actions.HelixMajorTicksChange>(helix_major_ticks_change_reducer),
  TypedReducer<Helix, actions.HelixRollSet>(helix_roll_set_reducer),
]);

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// change min/max offsets

Helix helix_offset_change_reducer(Helix helix, actions.HelixOffsetChange action) =>
    _change_offset_one_helix(helix, action.min_offset, action.max_offset);

Helix _change_offset_one_helix(Helix helix, int min_offset, int max_offset) => helix.rebuild((b) => b
  ..min_offset = min_offset ?? helix.min_offset
  ..max_offset = max_offset ?? helix.max_offset);

BuiltMap<int, Helix> helix_offset_change_all_reducer(
    BuiltMap<int, Helix> helices, actions.HelixOffsetChangeAll action) {
  Helix map_func(Helix helix) => _change_offset_one_helix(helix, action.min_offset, action.max_offset);
  var helices_after = helices.map_values(map_func);
  var grid = helices.values.first.grid;
  var helices_after_svg_adjusted = util.helices_assign_svg(helices_after.toMap(), grid);
  return helices_after_svg_adjusted.build();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// change major ticks

BuiltMap<int, Helix> helix_major_tick_distance_change_all_reducer(
        BuiltMap<int, Helix> helices, actions.HelixMajorTickDistanceChangeAll action) =>
    helices.map_values((helix) => _change_major_tick_distance_one_helix(helix, action.major_tick_distance));

BuiltMap<int, Helix> helix_major_ticks_change_all_reducer(
        BuiltMap<int, Helix> helices, actions.HelixMajorTicksChangeAll action) =>
    helices.map_values((helix) => _change_major_ticks_one_helix(helix, action.major_ticks));

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

Helix helix_roll_set_reducer(Helix helix, actions.HelixRollSet action) =>
    helix.rebuild((h) => h..roll = action.roll);

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// set rotation of backbone

BuiltMap<int, Helix> helix_roll_set_at_other_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixRollSetAtOther action) {
  Helix helix = helices[action.helix_idx];
  Helix helix_other = helices[action.helix_other_idx];

  num rotation = util.rotation_between_helices(helix, helix_other, action.forward);
  double old_rotation_at_anchor = state.dna_design.helix_rotation_forward(helix, action.anchor);
  double delta_roll = rotation - old_rotation_at_anchor;
  double new_roll = (helix.roll + delta_roll) % 360.0;

  // adjust helix roll
  Helix helix_new = helix.rebuild((h) => h..roll = new_roll);

  // create new helices
  var helices_builder = helices.toBuilder();
  helices_builder[action.helix_idx] = helix_new;
  return helices_builder.build();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// helix add/remove

DNADesign helix_add_dna_design_local_reducer(DNADesign design, actions.HelixAdd action) {
  int max_idx_current;
  int new_idx;
  int min_offset;
  int max_offset;

  int num_helices = design.helices.length;
  if (num_helices > 0) {
    max_idx_current = design.helices.keys.reduce(max);
    new_idx = max_idx_current + 1;
    min_offset = design.min_offset;
    max_offset = design.max_offset;
  } else {
    new_idx = 0;
    min_offset = constants.default_min_offset;
    max_offset = constants.default_max_offset;
  }

  Helix helix = Helix(
    idx: new_idx,
    grid: design.grid,
    grid_position: action.grid_position,
    position: action.position,
    min_offset: min_offset,
    max_offset: max_offset,
    view_order: num_helices,
  );
  Map<int, Helix> helices = design.helices.toMap();
  helices[helix.idx] = helix;
  helices = util.helices_assign_svg(helices, design.grid);

  return design.rebuild((d) => d..helices.replace(helices));
}

DNADesign helix_remove_dna_design_global_reducer(
    DNADesign design, AppState state, actions.HelixRemove action) {
  Set<Domain> substrands_on_helix = design.domains_on_helix(action.helix_idx).toSet();
  var strands_with_substrands_removed =
      delete_reducer.remove_bound_substrands(design.strands, state, substrands_on_helix);
  // var strands_with_helix_indices_updated =
  //     change_all_bound_substrand_helix_idxs(strands_with_substrands_removed, action.helix_idx, -1);
  var new_helices = remove_helix_assuming_no_bound_substrands(design.helices, action);
  var new_helices_list = util.helices_assign_svg(new_helices.toMap(), design.grid);
  return design
      .rebuild((d) => d..helices.replace(new_helices_list)..strands.replace(strands_with_substrands_removed));
}

DNADesign helix_remove_all_selected_dna_design_global_reducer(
    DNADesign design, AppState state, actions.HelixRemoveAllSelected action) {
  var helix_idxs = state.ui_state.side_selected_helix_idxs;
  Set<Domain> substrands_on_helices = design.domains_on_helices(helix_idxs).toSet();

  var strands_with_substrands_removed =
      delete_reducer.remove_bound_substrands(design.strands, state, substrands_on_helices);

  var new_helices = remove_helices_assuming_no_bound_substrands(design.helices, helix_idxs);
  var new_helices_list = util.helices_assign_svg(new_helices.toMap(), design.grid);
  return design
      .rebuild((d) => d..helices.replace(new_helices_list)..strands.replace(strands_with_substrands_removed));
}

/// Change (by amount `increment`) all helix_idx's of all Domains with helix >= helix_idx.
List<Strand> change_all_bound_substrand_helix_idxs(BuiltList<Strand> strands, int helix_idx, int increment) {
  List<Strand> new_strands = strands.toList();
  for (int i = 0; i < strands.length; i++) {
    Strand strand = strands[i];
    StrandBuilder strand_builder = strand.toBuilder();
    for (int j = 0; j < strand.substrands.length; j++) {
      if (strand.substrands[j] is Domain) {
        Domain bound_substrand = strand.substrands[j];
        if (bound_substrand.helix >= helix_idx) {
          DomainBuilder bound_substrand_builder = bound_substrand.toBuilder();
          bound_substrand_builder.helix += increment;
          strand_builder.substrands[j] = bound_substrand_builder.build();
        }
      }
    }
    new_strands[i] = strand_builder.build();
  }
  return new_strands;
}

/// Remove helix from list, assuming no Domains are on it.
BuiltMap<int, Helix> remove_helix_assuming_no_bound_substrands(
    BuiltMap<int, Helix> helices, actions.HelixRemove action) {
  Map<int, Helix> helices_builder = helices.toMap();
  int removed_view_order = helices[action.helix_idx].view_order;
  helices_builder.remove(action.helix_idx);
  for (int i in helices_builder.keys) {
    HelixBuilder helix_builder = helices_builder[i].toBuilder();
//    if (i >= action.helix_idx) {
//      helix_builder.idx = i;
//    }
    if (helix_builder.view_order >= removed_view_order) {
      helix_builder.view_order--;
    }
    helices_builder[i] = helix_builder.build();
  }
  return helices_builder.build();
}

BuiltMap<int, Helix> remove_helices_assuming_no_bound_substrands(
    BuiltMap<int, Helix> helices, Iterable<int> helix_idxs) {
  Map<int, Helix> helices_builder = helices.toMap();
  BuiltList<int> removed_view_orders =
      BuiltList<int>([for (var helix_idx in helix_idxs) helices[helix_idx].view_order]);
  helices_builder.removeWhere((helix_idx, _) => helix_idxs.contains(helix_idx));

  for (int i in helices_builder.keys) {
    HelixBuilder helix_builder = helices_builder[i].toBuilder();
    // The view order decrements by the number of removed view orders that was less than it.
    helix_builder.view_order -= _count_less_than(removed_view_orders, helix_builder.view_order);
    helices_builder[i] = helix_builder.build();
  }
  return helices_builder.build();
}

/// Returns the number of values in list that are less than x.
_count_less_than(Iterable<int> list, int x) {
  int count = 0;
  for (var ele in list) {
    if (ele < x) {
      count++;
    }
  }
  return count;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// grid change, so helix must change positions

BuiltMap<int, Helix> helix_grid_change_reducer(BuiltMap<int, Helix> helices, actions.GridChange action) {
  Map<int, HelixBuilder> helices_builder = helices.toMap().map_values((h) => h.toBuilder());
  for (int i in helices.keys) {
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

  BuiltMap<int, Helix> new_helices =
      {for (var helix in helices_builder.values) helix.idx: helix.build()}.build();
  return new_helices;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// change helix position

Helix helix_individual_grid_position_set_reducer(Helix helix, actions.HelixGridPositionSet action) =>
    helix.rebuild((b) => b
      ..position_ = null
      ..grid_position.replace(action.grid_position)
      ..svg_position = null);

BuiltMap<int, Helix> helix_grid_position_set_reducer(
    BuiltMap<int, Helix> helices, actions.HelixGridPositionSet action) {
  Helix helix = helices[action.helix_idx];
  var new_helix = helix_individual_grid_position_set_reducer(helix, action);
  if (new_helix != helix) {
    var helices_map = helices.toBuilder();
    helices_map[action.helix_idx] = new_helix;
    var new_helices = helices_map.build();
    new_helices = _reassign_svg_positions(new_helices, null);
    return new_helices;
  } else {
    return helices;
  }
}

Helix helix_individual_position_set_reducer(Helix helix, actions.HelixPositionSet action) =>
    helix.rebuild((b) => b
      ..position_.replace(action.position)
      ..grid_position = null
      ..svg_position = null);

BuiltMap<int, Helix> helix_position_set_reducer(
    BuiltMap<int, Helix> helices, actions.HelixPositionSet action) {
  Helix helix = helices[action.helix_idx];
  var new_helix = helix_individual_position_set_reducer(helix, action);
  if (new_helix != helix) {
    var helices_map = helices.toBuilder();
    helices_map[action.helix_idx] = new_helix;
    var new_helices = helices_map.build();
    new_helices = _reassign_svg_positions(new_helices, null);
    return new_helices;
  } else {
    return helices;
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// select/unselect Helices (so SVG positions need to be recalculated

BuiltMap<int, Helix> _reassign_svg_positions(
    BuiltMap<int, Helix> helices, BuiltSet<int> selected_helix_idxs) {
  if (helices.length == 0) {
    return helices;
  }
  Grid grid = helices.values.first.grid;
  Map<int, Helix> helices_map = helices.toMap();
  helices_map = util.helices_assign_svg(helices_map, grid, selected_helix_idxs);
  return BuiltMap<int, Helix>(helices_map);
}

BuiltMap<int, Helix> helix_select_helices_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixSelect action) {
  var selected_helix_idxs = helix_select_reducer(state.ui_state.side_selected_helix_idxs, action);
  if (state.ui_state.only_display_selected_helices) {
    return _reassign_svg_positions(helices, selected_helix_idxs);
  } else {
    return helices;
  }
}

BuiltMap<int, Helix> helix_selections_adjust_helices_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixSelectionsAdjust action) {
  var selected_helix_idxs =
      helix_selections_adjust_reducer(state.ui_state.side_selected_helix_idxs, state, action);
  if (state.ui_state.only_display_selected_helices) {
    return _reassign_svg_positions(helices, selected_helix_idxs);
  } else {
    return helices;
  }
}

BuiltMap<int, Helix> helix_selections_clear_helices_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixSelectionsClear action) {
  if (state.ui_state.only_display_selected_helices) {
    return _reassign_svg_positions(helices, BuiltSet<int>());
  } else {
    return helices;
  }
}

BuiltMap<int, Helix> set_only_display_selected_helices_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.SetOnlyDisplaySelectedHelices action) {
  if (action.show) {
    return _reassign_svg_positions(helices, state.ui_state.side_selected_helix_idxs);
  } else {
    var all_helix_idxs = BuiltSet<int>(state.dna_design.helices.keys);
    return _reassign_svg_positions(helices, all_helix_idxs);
  }
}
