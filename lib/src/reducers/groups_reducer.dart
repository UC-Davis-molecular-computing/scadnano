import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../state/group.dart';
import '../actions/actions.dart' as actions;
import '../extension_methods.dart';

Reducer<BuiltMap<String, HelixGroup>> groups_local_reducer = combineReducers([
  TypedReducer<BuiltMap<String, HelixGroup>, actions.GroupAdd>(group_add_reducer),
  TypedReducer<BuiltMap<String, HelixGroup>, actions.GroupRemove>(group_remove_reducer),
  TypedReducer<BuiltMap<String, HelixGroup>, actions.GroupChange>(group_change_reducer),
  TypedReducer<BuiltMap<String, HelixGroup>, actions.GridChange>(grid_change_reducer),
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
