import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../state/edit_mode.dart';

Reducer<BuiltSet<EditModeChoice>> edit_modes_reducer = combineReducers<BuiltSet<EditModeChoice>>([
  TypedReducer<BuiltSet<EditModeChoice>, actions.EditModeToggle>(toggle_edit_mode_reducer),
  TypedReducer<BuiltSet<EditModeChoice>, actions.EditModesSet>(set_edit_modes_reducer),
]);

BuiltSet<EditModeChoice> toggle_edit_mode_reducer(
    BuiltSet<EditModeChoice> modes, actions.EditModeToggle action) {
  BuiltSet<EditModeChoice> new_modes;
  EditModeChoice mode = action.mode;
  if (modes.contains(mode)) {
    new_modes = modes.rebuild((m) => m..remove(mode));
  } else {
    new_modes = modes.rebuild((m) => m
      ..add(mode)
      ..removeAll(mode.excluded_modes));
  }
  return new_modes;
}

BuiltSet<EditModeChoice> set_edit_modes_reducer(
        BuiltSet<EditModeChoice> edit_modes, actions.EditModesSet action) =>
    action.edit_modes;
