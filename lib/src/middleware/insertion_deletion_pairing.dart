import 'package:redux/redux.dart';
import '../state/domain.dart';
import '../state/design.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

/// Ensures that actions on insertions and deletions happen in pairs on adjacent domains.
insertion_deletion_pairing_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.InsertionOrDeletionAction) {
    Domain paired_substrand =
        find_paired_substrand(store.state.design, action.domain, action.offset);
    if (paired_substrand == null) {
      next(action);
    } else {
      var paired_action = action.clone_for_adjacent_substrand(paired_substrand);
      store.dispatch(actions.BatchAction([action, paired_action]));
    }
  } else {
    next(action);
  }
}

Domain find_paired_substrand(Design design, Domain substrand, int offset) {
  var other_substrands = design.domains_on_helix_at(substrand.helix, offset);
  for (var other_ss in other_substrands) {
    if (other_ss != substrand) {
      assert(other_ss.forward != substrand.forward);
      return other_ss;
    }
  }
  return null;
}
