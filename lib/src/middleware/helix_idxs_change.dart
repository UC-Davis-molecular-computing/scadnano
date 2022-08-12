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
      Set<int> ints_so_far = {};
      List<int> all_helices = action.idx_replacements.values.toList();
      Map<int, List<int>> dupe_key_to_idxs = new Map<int, List<int>>();

      for (var old_index in old_idxs) {
        var new_index = action.idx_replacements[old_index];
        if (ints_so_far.contains(new_index)) {
          // var msg = 'First duplicate found for helix ${old_index} with new index ${new_index}. ';
          // window.alert(msg);
          // return;

          if (dupe_key_to_idxs.containsKey(new_index))
            dupe_key_to_idxs[new_index].add(old_index);
          else
            dupe_key_to_idxs[new_index] = [ old_index ];
        } else {
          ints_so_far.add(new_index);
        }
      }

      if (dupe_key_to_idxs.length != 0) {
        var msg = 'You tried to assign existing helices ';
        
        msg += dupe_key_to_idxs.entries.map((element) {
          return element.value.join(', ') + " to " + element.key.toString();
        }).join(" and helices ");

        msg += ". Each helix must have a unique new index; make sure all the integers you write are distinct from each other and do not appear elsewhere in the design";

        window.alert(msg);
        return;
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
