import 'dart:html';

import 'package:redux/redux.dart';
import 'package:scadnano/src/state/grid_position.dart';

import '../state/grid.dart';
import '../state/helix.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

/// Check modify helices in preparation for a change of grid type, or prevent the change.
grid_change_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.GridChange && action.grid == Grid.honeycomb) {
    List<int> illegal_helices = [];
    List<GridPosition> illegal_grid_positions = [];
    for (Helix helix in store.state.dna_design.helices) {
      if (!helix.grid_position.in_honeycomb_lattice()) {
        illegal_helices.add(helix.idx);
        illegal_grid_positions.add(helix.grid_position);
      }
    }
    if (illegal_helices.isNotEmpty) {
      var msg = 'Helices ${illegal_helices.join(', ')} have grid positions of '
          '${illegal_grid_positions.join(', ')}, '
          'which are not in the honeycomb lattice. '
          'The honeycomb lattice disallows grid positions (h,v) with '
          'v even and h a multiple of 3 or '
          'v odd and h = 1 + a multiple of 3. '
          'To change to the honeycomb lattice, '
          'first move or remove existing helices to obey this constraint.';
      window.alert(msg);
      return;
    }
  }
  next(action);
}
