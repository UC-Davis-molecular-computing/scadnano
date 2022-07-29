import 'dart:html';

import 'package:redux/redux.dart';
import '../state/design.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

/// Check whether user wants to remove helix that has strands on it.
helix_idxs_change_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.HelixIdxsChange) {
    Set<int> existing_idxs = store.state.design.helices.keys.toSet();
    Set<int> old_idxs = action.idx_replacements.keys.toSet();
    Set<int> remaining_idxs = existing_idxs.difference(old_idxs);
    var new_indices = action.idx_replacements.values.toSet();

    if (new_indices.length != action.idx_replacements.length) {
      Set<int> intsSoFar = {};
      List<int> all_helices = action.idx_replacements.values.toList();

      for (var old_index in old_idxs) {
        var new_index = action.idx_replacements[old_index];
        if (intsSoFar.contains(new_index)) {
          var msg = 'First duplicate found for helix ${old_index} with new index ${new_index}. ';
          window.alert(msg);
          return;
        } else {
          intsSoFar.add(new_index);
        }
      }
    }

    for (int new_idx in action.idx_replacements.values) {
      if (remaining_idxs.contains(new_idx)) {
        var msg = 'Index ${new_idx} is already taken.';
        window.alert(msg);
        return;
      }
    }
  }
  next(action);
}
