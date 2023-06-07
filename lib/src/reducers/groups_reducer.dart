import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/helix.dart';

import '../state/group.dart';
import '../actions/actions.dart' as actions;
import '../extension_methods.dart';
import 'util_reducer.dart';

Reducer<BuiltMap<String, HelixGroup>> groups_local_reducer = combineReducers([
  TypedReducer<BuiltMap<String, HelixGroup>, actions.GroupAdd>(group_add_reducer),
  TypedReducer<BuiltMap<String, HelixGroup>, actions.GroupRemove>(group_remove_reducer),
  TypedReducer<BuiltMap<String, HelixGroup>, actions.GroupChange>(group_change_reducer),
  TypedReducer<BuiltMap<String, HelixGroup>, actions.GridChange>(grid_change_reducer),
]);

GlobalReducer<BuiltMap<String, HelixGroup>, AppState> groups_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltMap<String, HelixGroup>, AppState, actions.MoveHelicesToGroup>(
      move_helices_to_group_groups_reducer),
]);

BuiltMap<String, HelixGroup> grid_change_reducer(
        BuiltMap<String, HelixGroup> groups, actions.GridChange action) =>
    groups.map_values((name, group) {
      if (name == action.group_name) {
        group = group.rebuild((b) => b..grid = action.grid);
      }
      return group;
    });

BuiltMap<String, HelixGroup> group_add_reducer(
        BuiltMap<String, HelixGroup> groups, actions.GroupAdd action) =>
    groups.rebuild((b) {
      b[action.name] = action.group;
    });

BuiltMap<String, HelixGroup> group_remove_reducer(
        BuiltMap<String, HelixGroup> groups, actions.GroupRemove action) =>
    groups.rebuild((b) {
      b.remove(action.name);
    });

BuiltMap<String, HelixGroup> group_change_reducer(
        BuiltMap<String, HelixGroup> groups, actions.GroupChange action) =>
    groups.rebuild((b) {
      if (action.old_name != action.new_name) {
        b.remove(action.old_name);
      }
      b[action.new_name] = action.new_group;
    });

// The suffix "_groups_reducer" helps distinguish from the "_helices_reducer" in the
// helices_reducer.dart file, which processes this same Action on the helices map.
BuiltMap<String, HelixGroup> move_helices_to_group_groups_reducer(
    BuiltMap<String, HelixGroup> groups, AppState state, actions.MoveHelicesToGroup action) {
  var to_group_name = action.group_name;

  //TODO: this should not have duplicates
  List<String> from_group_names = [for (int idx in action.helix_idxs) state.design.helices[idx].group];

  // ensure that relative order of helix idxs in new helices_view_order is the same.
  // if there are helices already in the new group, start with those, and append new helix idxs to
  // the end based on their relative order in their old HelixGroup.
  // The order in which multiple HelixGroups are processed can be arbitrary.
  // Also track which helix idx's were removed from original groups, so we can update those groups.
  // One exception: if helices_view_order is the default (in order and contiguous)
  // in all cases, then keep that default behavior,
  // i.e., new helices_view_order should just be sorted by helix.idx.
  var groups = state.design.groups.toMap();
  var to_group = groups[to_group_name];
  List<int> new_helices_view_order = to_group.helices_view_order.toList();
  for (var from_group_name in from_group_names) {
    var from_group = groups[from_group_name];
    var new_from_helices_group_order = from_group.helices_view_order.toList();

    for (int idx in from_group.helices_view_order) {
      if (action.helix_idxs.contains(idx)) {
        // prevent indices from duplicating when moving to its own group
        if (!new_helices_view_order.contains(idx)) {
          new_helices_view_order.add(idx);
        }
        new_from_helices_group_order.remove(idx);
      }
    }

    // remove moving helix idx's from old group
    from_group = from_group.rebuild((b) => b..helices_view_order.replace(new_from_helices_group_order));
    groups[from_group_name] = from_group;
  }

  // add moving helix idx's to new group
  to_group = to_group.rebuild((b) => b..helices_view_order.replace(new_helices_view_order));
  groups[to_group_name] = to_group;

  return groups.build();
}

Design duplicate_group_groups_reducer(Design design, actions.GroupDuplicate action) {
  var groups = design.groups.toMap();
  var group_original = groups[action.groupToDuplicate];
  var new_group_name = action.name;

  var helices_original = design.helices_in_group(action.groupToDuplicate);

  Map<int, Helix> new_helices = design.helices.toMap();

  int num_helices = design.helices.length;
  int helix_idx_offset;
  List<int> new_helices_view_order = [];

  if (num_helices > 0) {
    helix_idx_offset = design.helices.keys.max + 1;
  } else {
    helix_idx_offset = 0;
  }
  helix_idx_offset -= helices_original.keys.min;
  List<int> new_idx = helices_original.keys.toList();

  for (int i = 0; i < new_idx.length; i++) {
    new_idx[i] += helix_idx_offset;
  }
  int j = 0;
  for (var helix in helices_original.values) {
    int idx = new_idx[j];
    Helix new_helix = Helix(
        idx: idx,
        grid: helix.grid,
        geometry: helix.geometry,
        grid_position: helix.grid_position,
        roll: helix.roll,
        min_offset: helix.min_offset,
        major_tick_start: helix.major_tick_start,
        max_offset: helix.max_offset,
        position: helix.position_,
        group: new_group_name);
    new_helices[idx] = new_helix;
    new_helices_view_order.add(idx);
    j++;
  }

  var new_group = HelixGroup(
    helices_view_order: new_helices_view_order,
    grid: group_original.grid,
    position: group_original.position,
    pitch: group_original.pitch,
    yaw: group_original.yaw,
    roll: group_original.roll,
  );

  groups[new_group_name] = new_group;

  return design.rebuild((d) => d..helices.replace(new_helices)..groups.replace(groups));
}
