import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../state/select_mode.dart';
import '../state/select_mode_state.dart';

//SelectModeState select_mode_state_reducer([SelectModeState state, action])
Reducer<SelectModeState> select_mode_state_reducer = combineReducers<SelectModeState>([
  TypedReducer<SelectModeState, actions.SelectModeToggle>(toggle_select_mode_reducer),
  TypedReducer<SelectModeState, actions.SelectModesSet>(set_select_modes_reducer),
  TypedReducer<SelectModeState, actions.SelectModesAdd>(add_select_modes_reducer),
//  TypedReducer<SelectModeState, actions.EditModeToggle>(edit_mode_toggle_changes_select_mode_reducer),
//  TypedReducer<SelectModeState, actions.EditModesSet>(edit_modes_set_changes_select_mode_reducer),
]);

SelectModeState toggle_select_mode_reducer(SelectModeState state, actions.SelectModeToggle action) {
  SelectModeState new_state;
  SelectModeChoice mode = action.select_mode_choice;
  if (state.modes.contains(mode)) {
    new_state = state.remove_mode(mode);
  } else {
    new_state = state.add_mode(mode);
    if (mode == SelectModeChoice.strand) {
      new_state = new_state.remove_modes(SelectModeChoice.strand_parts);
    } else if (SelectModeChoice.strand_parts.contains(mode)) {
      new_state = new_state.remove_mode(SelectModeChoice.strand);
      if (mode == SelectModeChoice.crossover || mode == SelectModeChoice.loopout) {
        new_state = new_state.remove_modes(SelectModeChoice.ends);
      } else if (SelectModeChoice.ends.contains(mode)) {
        new_state = new_state.remove_modes([SelectModeChoice.crossover, SelectModeChoice.loopout]);
      }
    }
  }
  return new_state;
}

SelectModeState set_select_modes_reducer(SelectModeState state, actions.SelectModesSet action) =>
    state.set_modes(action.select_mode_choices);

SelectModeState add_select_modes_reducer(SelectModeState state, actions.SelectModesAdd action) {
  SelectModeState new_state = state.add_modes(action.select_modes_to_add);
  if (action.select_modes_to_add.contains(SelectModeChoice.strand)) {
    new_state = new_state.remove_modes(SelectModeChoice.strand_parts);
  } else {
    for (var mode in action.select_modes_to_add) {
      if (SelectModeChoice.strand_parts.contains(mode)) {
        new_state = new_state.remove_mode(SelectModeChoice.strand);
        if (mode == SelectModeChoice.crossover || mode == SelectModeChoice.loopout) {
          new_state = new_state.remove_modes(SelectModeChoice.ends);
        } else if (SelectModeChoice.ends.contains(mode)) {
          new_state = new_state.remove_modes([SelectModeChoice.crossover, SelectModeChoice.loopout]);
        }
      }
    }
  }
  return new_state;
}

