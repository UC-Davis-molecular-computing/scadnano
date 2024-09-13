import 'dart:html';

import 'package:redux/redux.dart';
import '../state/design.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

/// Check whether user wants to remove helix that has strands on it.
helix_change_offsets_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.HelixOffsetChange) {
    var design = store.state.design;
    int helix_idx = action.helix_idx;
    bool helix_has_domains = design.domains_on_helix(helix_idx).isNotEmpty;
    var min_offset = action.min_offset;
    var max_offset = action.max_offset;
    if (min_offset != null && helix_has_domains) {
      int min_offset_of_strand = store.state.design.min_offset_of_strands_at(helix_idx);
      if (min_offset > min_offset_of_strand) {
        window.alert(message_too_small(helix_idx, min_offset, min_offset_of_strand));
        return;
      }
    }
    if (max_offset != null && helix_has_domains) {
      int max_offset_of_strand = store.state.design.max_offset_of_strands_at(helix_idx);
      if (max_offset < max_offset_of_strand) {
        window.alert(message_too_large(helix_idx, max_offset, max_offset_of_strand));
        return;
      }
    }
  } else if (action is actions.HelixOffsetChangeAll) {
    var min_offset = action.min_offset;
    var max_offset = action.max_offset;
    Design design = store.state.design;
    for (int helix_idx in design.helices.keys) {
      var domains_on_helix = design.domains_on_helix(helix_idx);
      bool helix_has_domains = domains_on_helix.isNotEmpty;
      if (min_offset != null && helix_has_domains) {
        int min_offset_of_strand = store.state.design.min_offset_of_strands_at(helix_idx);
        if (min_offset > min_offset_of_strand) {
          window.alert(message_too_small(helix_idx, min_offset, min_offset_of_strand));
          return;
        }
      }
      if (max_offset != null && helix_has_domains) {
        int max_offset_of_strand = store.state.design.max_offset_of_strands_at(helix_idx);
        if (max_offset < max_offset_of_strand) {
          window.alert(message_too_large(helix_idx, max_offset, max_offset_of_strand));
          return;
        }
      }
    }
  }
  next(action);
}

String message_too_small(int helix_idx, int proposed_offset, int offset_of_strand) {
  return 'Cannot set minimum offset to ${proposed_offset} on helix $helix_idx '
      'because there is a strand on that helix with offset ${offset_of_strand}. '
      'Please choose a smaller minimum offset or delete the strand.';
}

String message_too_large(int helix_idx, int proposed_offset, int offset_of_strand) {
  return 'Cannot set maximum offset to ${proposed_offset} on helix $helix_idx '
      'because there is a strand on that helix with offset ${offset_of_strand}. '
      'Please choose a larger maximum offset or delete the strand.';
}
