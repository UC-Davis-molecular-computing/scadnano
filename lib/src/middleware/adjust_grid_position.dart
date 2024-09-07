import 'package:redux/redux.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../state/grid_position.dart';
import '../state/helix.dart';

/// Disallows setting grid_position of Helix to overlap with existing helix.
adjust_grid_position_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.HelixGridPositionSet) {
    if (!is_grid_position_occupied(store.state.design.helices.values, action.grid_position)) {
      next(action);
    }
  } else {
    next(action);
  }
}

/// Returns `true` if a helix in `helicies` already occupies `grid_position`.
bool is_grid_position_occupied(Iterable<Helix> helices, GridPosition grid_position) {
  for (Helix helix in helices) {
    if (helix.grid_position == grid_position) {
      return true;
    }
  }
  return false;
}
