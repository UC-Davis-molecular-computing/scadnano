import 'dart:math';

import 'package:collection/collection.dart';
import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/reducers/groups_reducer.dart';
import 'package:scadnano/src/state/group.dart';
import '../reducers/util_reducer.dart';
import '../state/app_state.dart';

import '../state/domain.dart';
import '../state/design.dart';
import '../state/geometry.dart';
import '../state/strand.dart';
import 'delete_reducer.dart' as delete_reducer;
import '../state/helix.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'selection_reducer.dart';
import '../extension_methods.dart';

Reducer<BuiltMap<int, Helix>> helices_local_reducer = combineReducers([
  TypedReducer<BuiltMap<int, Helix>, actions.MoveHelicesToGroup>(move_helices_to_group_helices_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixMajorTickDistanceChangeAll>(
      helix_major_tick_distance_change_all_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixMajorTicksChangeAll>(helix_major_ticks_change_all_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixMajorTickStartChangeAll>(
      helix_major_tick_start_change_all_reducer),
  TypedReducer<BuiltMap<int, Helix>, actions.HelixMajorTickPeriodicDistancesChangeAll>(
      helix_major_tick_periodic_distances_change_all_reducer),
]);

GlobalReducer<BuiltMap<int, Helix>, AppState> helices_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.GroupChange>(helix_group_change_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.GridChange>(helix_grid_change_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixGridPositionSet>(
      helix_grid_position_set_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixPositionSet>(helix_position_set_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixOffsetChangeAll>(
      helix_offset_change_all_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixMinOffsetSetByDomainsAll>(
      helix_min_offset_set_by_domains_all_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixMaxOffsetSetByDomainsAll>(
      helix_max_offset_set_by_domains_all_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixIndividualAction>(helix_individual_reducer),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixRollSetAtOther>(
    helix_roll_set_at_other_reducer,
  ),
  TypedGlobalReducer<BuiltMap<int, Helix>, AppState, actions.HelixMaxOffsetSetByDomainsAllSameMax>(
    helix_max_offset_set_by_domains_all_same_max_reducer,
  ),
]);

BuiltMap<int, Helix> helix_individual_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixIndividualAction action) {
  Helix helix = helices[action.helix_idx];
  var new_helix = _helix_individual_reducers(helix, state, action);
  if (new_helix != helix) {
    var helices_map = helices.toMap();
    helices_map[action.helix_idx] = new_helix;
    return helices_map.build();
  } else {
    return helices;
  }
}

GlobalReducer<Helix, AppState> _helix_individual_reducers = combineGlobalReducers([
  TypedGlobalReducer<Helix, AppState, actions.HelixOffsetChange>(helix_offset_change_reducer),
  TypedGlobalReducer<Helix, AppState, actions.HelixMinOffsetSetByDomains>(
      helix_min_offset_set_by_domains_reducer),
  TypedGlobalReducer<Helix, AppState, actions.HelixMaxOffsetSetByDomains>(
      helix_max_offset_set_by_domains_reducer),
  TypedGlobalReducer<Helix, AppState, actions.HelixMajorTickDistanceChange>(
      helix_major_tick_distance_change_reducer),
  TypedGlobalReducer<Helix, AppState, actions.HelixMajorTickPeriodicDistancesChange>(
      helix_major_tick_periodic_distances_change_reducer),
  TypedGlobalReducer<Helix, AppState, actions.HelixMajorTickStartChange>(
      helix_major_tick_start_change_reducer),
  TypedGlobalReducer<Helix, AppState, actions.HelixMajorTicksChange>(helix_major_ticks_change_reducer),
  TypedGlobalReducer<Helix, AppState, actions.HelixRollSet>(helix_roll_set_reducer),
]);

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// change idx

Design helix_idx_change_reducer(Design design, AppState state, actions.HelixIdxsChange action) {
  var helices = design.helices.toMap();
  var strands = design.strands.toList();

  Map<String, HelixGroup> new_groups = change_groups(action, helices, design);

  // change helices
  for (int old_idx in action.idx_replacements.keys) {
    int new_idx = action.idx_replacements[old_idx];
    var helix = helices[old_idx].rebuild((b) => b..idx = new_idx);
    helices.remove(old_idx);
    helices[new_idx] = helix;
  }

  // change helix idx refs on domains
  for (int s = 0; s < strands.length; s++) {
    var strand = strands[s];
    var substrands = strand.substrands.toList();
    bool changed_strand = false;
    for (int d = 0; d < strand.substrands.length; d++) {
      var substrand = strand.substrands[d];
      if (substrand is Domain) {
        Domain domain = substrand;
        int new_idx = action.idx_replacements[domain.helix];
        if (new_idx != null) {
          domain = domain.rebuild((b) => b..helix = new_idx);
          substrands[d] = domain;
          changed_strand = true;
        }
      }
    }
    if (changed_strand) {
      strands[s] = strand.rebuild((b) => b..substrands.replace(substrands));
    }
  }

  //TODO: recalculate view order; first figure out if it was non-default by looking at Helix.view_order

  design = design
      .rebuild((b) => b..groups.replace(new_groups)..helices.replace(helices)..strands.replace(strands));
  return design;
}

Map<String, HelixGroup> change_groups(
    actions.HelixIdxsChange action, Map<int, Helix> helices, Design design) {
  // initialize with default view order to be the same as before the idx change
  Map<int, int> new_view_order = {};
  for (int old_idx in action.idx_replacements.keys) {
    var helix = helices[old_idx];
    var group = design.groups[helix.group];
    int view_order = group.helices_view_order_inverse[old_idx];
    new_view_order[old_idx] = view_order;
  }

  var new_groups = design.groups.toMap();
  // see if view orders should be updated
  for (var group_name in design.groups.keys) {
    var group = design.groups[group_name];
    var helix_idxs_in_group = design.helix_idxs_in_group[group_name];
    bool group_changing =
        action.idx_replacements.keys.toSet().intersection(helix_idxs_in_group.toSet()).isNotEmpty;

    if (group_changing) {
      // if group is changing, see if helices_view_order is default;
      // if so, adjust new view order to maintain that the view order is still the default (idxs in order)
      bool previous_is_default = util.helices_view_order_is_default(helix_idxs_in_group, group);

      // first update helices_view_order to contain new idxs
      List<int> helices_view_order_new = group.helices_view_order.toList();
      for (int old_idx in action.idx_replacements.keys) {
        int order_old_idx = group.helices_view_order_inverse[old_idx];
        if (order_old_idx != null) {
          int new_idx = action.idx_replacements[old_idx];
          helices_view_order_new[order_old_idx] = new_idx;
        }
      }

      // then make default if previous was default
      if (previous_is_default) {
        helices_view_order_new.sort();
      }

      var new_group = group.rebuild((b) => b..helices_view_order.replace(helices_view_order_new));
      new_groups[group_name] = new_group;
    }
  }

  return new_groups;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// change min/max offsets

Helix helix_offset_change_reducer(Helix helix, AppState _, actions.HelixOffsetChange action) =>
    _change_offset_one_helix(helix, action.min_offset, action.max_offset);

Helix _change_offset_one_helix(Helix helix, int min_offset, int max_offset) => helix.rebuild((b) => b
  ..min_offset = min_offset ?? helix.min_offset
  ..max_offset = max_offset ?? helix.max_offset);

BuiltMap<int, Helix> helix_offset_change_all_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixOffsetChangeAll action) {
  Helix map_func(_, Helix helix) => _change_offset_one_helix(helix, action.min_offset, action.max_offset);
  return helices.map_values(map_func);
}

Helix helix_min_offset_set_by_domains_reducer(
        Helix helix, AppState state, actions.HelixMinOffsetSetByDomains action) =>
    _min_offset_set_by_domains_one_helix(helix, state.design);

Helix helix_max_offset_set_by_domains_reducer(
        Helix helix, AppState state, actions.HelixMaxOffsetSetByDomains action) =>
    _max_offset_set_by_domains_one_helix(helix, state.design);

Helix _min_offset_set_by_domains_one_helix(Helix helix, Design design) {
  var domains = design.domains_on_helix(helix.idx);
  int min_offset = [for (var dom in domains) dom.start].min;
  return helix.rebuild((b) => b..min_offset = min_offset);
}

Helix _max_offset_set_by_domains_one_helix(Helix helix, Design design) {
  var domains = design.domains_on_helix(helix.idx);
  var end_offsets = [for (var dom in domains) dom.end];
  int max_offset = end_offsets.isNotEmpty ? end_offsets.max : 10;
  return helix.rebuild((b) => b..max_offset = max_offset);
}

BuiltMap<int, Helix> helix_min_offset_set_by_domains_all_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixMinOffsetSetByDomainsAll action) {
  Helix map_func(_, Helix helix) => _min_offset_set_by_domains_one_helix(helix, state.design);
  return helices.map_values(map_func);
}

BuiltMap<int, Helix> helix_max_offset_set_by_domains_all_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixMaxOffsetSetByDomainsAll action) {
  Helix map_func(_, Helix helix) => _max_offset_set_by_domains_one_helix(helix, state.design);
  return helices.map_values(map_func);
}

BuiltMap<int, Helix> helix_max_offset_set_by_domains_all_same_max_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixMaxOffsetSetByDomainsAllSameMax action) {
  Design design = state.design;
  int max_offset = null;
  for (int idx in helices.keys) {
    var domains = design.domains_on_helix(idx);
    var end_offsets = [for (var dom in domains) dom.end];
    int this_max_offset = end_offsets.isNotEmpty ? end_offsets.max : 10;
    if (max_offset == null) {
      max_offset = this_max_offset;
    } else {
      max_offset = max(max_offset, this_max_offset);
    }
  }
  if (max_offset == null) {
    max_offset = 10;
  }
  return helices.map_values((_, helix) => helix.rebuild((b) => b..max_offset = max_offset));
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// change major ticks

BuiltMap<int, Helix> helix_major_tick_distance_change_all_reducer(
        BuiltMap<int, Helix> helices, actions.HelixMajorTickDistanceChangeAll action) =>
    helices
        .map_values((_, helix) => _change_major_tick_distance_one_helix(helix, action.major_tick_distance));

BuiltMap<int, Helix> helix_major_ticks_change_all_reducer(
        BuiltMap<int, Helix> helices, actions.HelixMajorTicksChangeAll action) =>
    helices.map_values((_, helix) => _change_major_ticks_one_helix(helix, action.major_ticks));

BuiltMap<int, Helix> helix_major_tick_start_change_all_reducer(
        BuiltMap<int, Helix> helices, actions.HelixMajorTickStartChangeAll action) =>
    helices.map_values((_, helix) => _change_major_tick_start_one_helix(helix, action.major_tick_start));

BuiltMap<int, Helix> helix_major_tick_periodic_distances_change_all_reducer(
        BuiltMap<int, Helix> helices, actions.HelixMajorTickPeriodicDistancesChangeAll action) =>
    helices.map_values((_, helix) =>
        _change_major_tick_periodic_distances_one_helix(helix, action.major_tick_periodic_distances));

Helix helix_major_tick_distance_change_reducer(
        Helix helix, AppState _, actions.HelixMajorTickDistanceChange action) =>
    _change_major_tick_distance_one_helix(helix, action.major_tick_distance);

Helix helix_major_tick_periodic_distances_change_reducer(
        Helix helix, AppState _, actions.HelixMajorTickPeriodicDistancesChange action) =>
    _change_major_tick_periodic_distances_one_helix(helix, action.major_tick_periodic_distances);

Helix helix_major_tick_start_change_reducer(
        Helix helix, AppState _, actions.HelixMajorTickStartChange action) =>
    _change_major_tick_start_one_helix(helix, action.major_tick_start);

Helix helix_major_ticks_change_reducer(Helix helix, AppState _, actions.HelixMajorTicksChange action) =>
    _change_major_ticks_one_helix(helix, action.major_ticks);

Helix _change_major_tick_distance_one_helix(Helix helix, int major_tick_distance) => helix.rebuild((b) => b
  ..major_tick_periodic_distances.replace([major_tick_distance])
  ..major_ticks = null);

Helix _change_major_tick_start_one_helix(Helix helix, int major_tick_start) =>
    helix.rebuild((b) => b..major_tick_start = major_tick_start);

Helix _change_major_tick_periodic_distances_one_helix(
        Helix helix, Iterable<int> major_tick_periodic_distances) =>
    helix.rebuild((b) => b
      ..major_tick_periodic_distances.replace(major_tick_periodic_distances)
      ..major_ticks = null);

Helix _change_major_ticks_one_helix(Helix helix, BuiltList<int> major_ticks) =>
    helix.rebuild((b) => b..major_ticks.replace(major_ticks)..major_tick_periodic_distances.replace([]));

Helix helix_roll_set_reducer(Helix helix, AppState _, actions.HelixRollSet action) =>
    helix.rebuild((h) => h..roll = action.roll);

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// set rotation of backbone

BuiltMap<int, Helix> helix_roll_set_at_other_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixRollSetAtOther action) {
  Helix helix = helices[action.helix_idx];
  Helix helix_other = helices[action.helix_other_idx];

  var geometry = state.design.geometry;
  num rotation = util.rotation_between_helices(helix, helix_other, action.forward, geometry);
  double old_rotation_at_anchor = state.design.helix_rotation_forward(helix.idx, action.anchor);
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

Design helix_add_design_reducer(Design design, AppState state, actions.HelixAdd action) {
  int max_idx_current;
  int new_idx;
  int min_offset;
  int max_offset;

  int num_helices = design.helices.length;
  if (num_helices > 0) {
    max_idx_current = design.helices.keys.max;
    new_idx = max_idx_current + 1;
    min_offset = design.min_offset;
    max_offset = design.max_offset;
  } else {
    new_idx = 0;
    min_offset = constants.default_min_offset;
    max_offset = constants.default_max_offset;
  }

  // add helix's review order entry
  var group = design.groups[state.ui_state.displayed_group_name];
  var new_helices_view_order = group.helices_view_order.toList();
  new_helices_view_order.add(new_idx);
  var new_group = group.rebuild((b) => b..helices_view_order.replace(new_helices_view_order));
  var new_groups = design.groups.toMap();
  new_groups[state.ui_state.displayed_group_name] = new_group;

  Helix helix = Helix(
    idx: new_idx,
    grid: group.grid,
    group: state.ui_state.displayed_group_name,
    geometry: design.geometry,
    grid_position: action.grid_position,
    position: action.position,
    min_offset: min_offset,
    max_offset: max_offset,
    invert_y: state.ui_state.invert_y,
  );
  Map<int, Helix> new_helices = design.helices.toMap();
  new_helices[helix.idx] = helix;
  return design.rebuild((d) => d..helices.replace(new_helices)..groups.replace(new_groups));
}

Design helix_remove_design_global_reducer(Design design, AppState state, actions.HelixRemove action) {
  Set<Domain> substrands_on_helix = design.domains_on_helix(action.helix_idx).toSet();
  var strands_with_substrands_removed =
      delete_reducer.remove_domains(design.strands, state, substrands_on_helix);
  var new_helices = remove_helix_assuming_no_domains(design.helices, action);

  // remove helix's review order entry
  var group = design.groups[state.ui_state.displayed_group_name];
  var new_helices_view_order = group.helices_view_order.toList();
  new_helices_view_order.remove(action.helix_idx);
  var new_group = group.rebuild((b) => b..helices_view_order.replace(new_helices_view_order));
  var new_groups = design.groups.toMap();
  new_groups[state.ui_state.displayed_group_name] = new_group;

  return design.rebuild((d) => d
    ..helices.replace(new_helices)
    ..groups.replace(new_groups)
    ..strands.replace(strands_with_substrands_removed));
}

Design helix_remove_all_selected_design_global_reducer(
    Design design, AppState state, actions.HelixRemoveAllSelected action) {
  var helix_idxs = state.ui_state.side_selected_helix_idxs;
  Set<Domain> substrands_on_helices = design.domains_on_helices(helix_idxs).toSet();

  var strands_with_substrands_removed =
      delete_reducer.remove_domains(design.strands, state, substrands_on_helices);

  var new_helices = remove_helices_assuming_no_domains(design.helices, helix_idxs);

  // remove view order entries for helices that are being removed
  var new_groups = design.groups.toMap();
  for (var group_name in design.groups.keys) {
    var group = design.groups[group_name];
    var new_helices_view_order = group.helices_view_order.toList();
    for (var helix_idx in helix_idxs) {
      new_helices_view_order.remove(helix_idx); //automatically checks if it contains helix_idx
    }
    var new_group = group.rebuild((b) => b..helices_view_order.replace(new_helices_view_order));
    new_groups[group_name] = new_group;
  }

  return design.rebuild((d) => d
    ..helices.replace(new_helices)
    ..groups.replace(new_groups)
    ..strands.replace(strands_with_substrands_removed));
}

/// Change (by amount `increment`) all helix_idx's of all Domains with helix >= helix_idx.
List<Strand> change_all_domains_helix_idxs(BuiltList<Strand> strands, int helix_idx, int increment) {
  List<Strand> new_strands = strands.toList();
  for (int i = 0; i < strands.length; i++) {
    Strand strand = strands[i];
    StrandBuilder strand_builder = strand.toBuilder();
    for (int j = 0; j < strand.substrands.length; j++) {
      if (strand.substrands[j] is Domain) {
        Domain domain = strand.substrands[j];
        if (domain.helix >= helix_idx) {
          DomainBuilder domain_builder = domain.toBuilder();
          domain_builder.helix += increment;
          strand_builder.substrands[j] = domain_builder.build();
        }
      }
    }
    new_strands[i] = strand_builder.build();
  }
  return new_strands;
}

/// Remove helix from list, assuming no Domains are on it.
BuiltMap<int, Helix> remove_helix_assuming_no_domains(
        BuiltMap<int, Helix> helices, actions.HelixRemove action) =>
    helices.rebuild((b) => b..remove(action.helix_idx));

BuiltMap<int, Helix> remove_helices_assuming_no_domains(
        BuiltMap<int, Helix> helices, Iterable<int> helix_idxs) =>
    helices.rebuild((b) => b..removeWhere((idx, _) => helix_idxs.contains(idx)));

////////////////////////////////////////////////////////////////////////////////////////////////////////////
// grid change, so helix must change positions

BuiltMap<int, Helix> helix_grid_change_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.GridChange action) {
  // make builder of all helices
  Map<int, Helix> new_helices = helices.toMap();
  Geometry geometry = state.design.geometry;

  // process only those in this group
  var helix_idxs_in_group = state.design.helix_idxs_in_group[action.group_name];
  for (int idx in helix_idxs_in_group) {
    var helix = helices[idx];
    HelixBuilder helix_builder = helix.toBuilder();
    helix_builder.grid = action.grid;
    if (!action.grid.is_none && helix.grid_position == null) {
      helix_builder.grid_position =
          util.position3d_to_grid_position(helix.position, action.grid, geometry).toBuilder();
      helix_builder.position_ = null;
    }
    if (action.grid.is_none && helix.position_ == null) {
      helix_builder.grid_position = null;
      //NOTE: it's important to use helix.grid (i.e., the OLD grid, since util.grid_to_position3d will crash
      // if given the none grid)
      helix_builder.position_ =
          util.grid_position_to_position3d(helix.grid_position, helix.grid, geometry).toBuilder();
    }
    new_helices[idx] = helix_builder.build();
  }

  return new_helices.build();
}

BuiltMap<int, Helix> helix_group_change_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.GroupChange action) {
  return helices.map_values((idx, helix) =>
      helix.group == action.old_name ? helix.rebuild((b) => b..group = action.new_name) : helix);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// change helix position

Helix helix_individual_grid_position_set_reducer(Helix helix, actions.HelixGridPositionSet action) =>
    helix.rebuild((b) => b
      ..position_ = null
      ..grid_position.replace(action.grid_position));

BuiltMap<int, Helix> helix_grid_position_set_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixGridPositionSet action) {
  Helix helix = helices[action.helix_idx];
  var new_helix = helix_individual_grid_position_set_reducer(helix, action);
  if (new_helix != helix) {
    var helices_map = helices.toBuilder();
    helices_map[action.helix_idx] = new_helix;
    return helices_map.build();
  } else {
    return helices;
  }
}

Helix helix_individual_position_set_reducer(Helix helix, actions.HelixPositionSet action) =>
    helix.rebuild((b) => b
      ..position_.replace(action.position)
      ..grid_position = null);

BuiltMap<int, Helix> helix_position_set_reducer(
    BuiltMap<int, Helix> helices, AppState state, actions.HelixPositionSet action) {
  Helix helix = helices[action.helix_idx];
  var new_helix = helix_individual_position_set_reducer(helix, action);
  if (new_helix != helix) {
    var helices_map = helices.toBuilder();
    helices_map[action.helix_idx] = new_helix;
    return helices_map.build();
  } else {
    return helices;
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// select/unselect Helices (so SVG positions need to be recalculated)

// The suffix "_helices_reducer" helps distinguish from the "_groups_reducer" in the
// groups_reducer.dart file, which processes this same Action on the groups map.
BuiltMap<int, Helix> move_helices_to_group_helices_reducer(
    BuiltMap<int, Helix> helices, actions.MoveHelicesToGroup action) {
  var helices_map = helices.toMap();
  for (int idx in action.helix_idxs) {
    assert(helices_map.keys.contains(idx));
    var helix = helices_map[idx];
    var new_helix = helix.rebuild((b) => b..group = action.group_name);
    helices_map[idx] = new_helix;
  }
  return helices_map.build();
}
