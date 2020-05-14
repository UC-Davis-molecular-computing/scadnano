import 'dart:html';

import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

/// Check whether user wants to remove helix that has strands on it.
helix_remove_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.HelixRemove) {
    if (store.state.dna_design.substrands_on_helix(action.helix_idx).isNotEmpty) {
      var confirm_remove = window.confirm('Helix ${action.helix_idx} has substrands on it. '
          'If you delete the helix, they will be removed. '
          'Are you sure you wish to remove helix ${action.helix_idx}?');
      if (!confirm_remove) {
        return;
      }
    }
  } else if (action is actions.HelixRemoveAllSelected) {
    var helix_idx_with_substrands = Set<int>();
    var side_selected_helix_idxs = store.state.ui_state.side_selected_helix_idxs;

    // Collect all helix_idx with substrands.
    for (int helix_idx in side_selected_helix_idxs) {
      if (store.state.dna_design.substrands_on_helix(helix_idx).isNotEmpty) {
        helix_idx_with_substrands.add(helix_idx);
      }
    }

    if (helix_idx_with_substrands.isNotEmpty) {
      var helix_idx_string = helix_idx_with_substrands.join(', ');

      var first_line_string = (helix_idx_with_substrands.length == 1)
          ? 'Selected helix ${helix_idx_string} has substrands on it. '
          : 'Selected helices: ${helix_idx_string} have substrands on them. ';

      var confirm_remove = window.confirm('${first_line_string}'
          'If you delete the selected helices, the substrands will be removed. '
          'Are you sure you wish to remove selected helices: ${side_selected_helix_idxs.join(', ')}?');
      if (!confirm_remove) {
        return;
      }
    }
  }
  next(action);
}
