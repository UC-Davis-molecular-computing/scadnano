import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/state/helix.dart';

/// Disallows setting grid_position of Helix to overlap with existing helix.
adjust_grid_position_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.HelixGridPositionSet) {
    if (!isGridPositionOccupied(store.state.dna_design.helices, action.grid_position)) {
      next(action);
    }
  } else {
    next(action);
  }
}

/// Returns `true` if a helix in `helicies` already occupies `grid_position`.
bool isGridPositionOccupied(BuiltList<Helix> helices, GridPosition grid_position) {
  for (Helix helix in helices) {
    if (helix.grid_position == grid_position) {
      return true;
    }
  }
  return false;
}
