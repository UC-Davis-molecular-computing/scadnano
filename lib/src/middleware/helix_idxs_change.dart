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
