import 'dart:html';

import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';

/// Check whether user wants to remove helix that has strands on it.
group_remove_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.GroupRemove) {
    var helix_idxs_in_group = store.state.design.helix_idxs_in_group[action.name]!;
    if (helix_idxs_in_group.isNotEmpty) {
      var confirm_remove = window.confirm('Group "${action.name}" has helices in it. '
          'If you delete the group, the helices will be removed, '
          'including any portions of strands on them.\n\n'
          'Are you sure you wish to remove group "${action.name}"?');
      if (!confirm_remove) {
        return;
      }
    }
    var helices_remove_action = actions.BatchAction(
        [for (int idx in helix_idxs_in_group) actions.HelixRemove(idx)]..add(action), "remove group");
    store.dispatch(helices_remove_action);
  } else {
    next(action);
  }
}
