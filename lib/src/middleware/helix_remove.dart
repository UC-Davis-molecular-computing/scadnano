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
  }
  next(action);
}