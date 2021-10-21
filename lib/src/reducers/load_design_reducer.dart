import 'dart:convert';

import 'package:built_collection/built_collection.dart';

import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../state/app_state.dart';
import '../state/design.dart';
import '../state/mouseover_data.dart';
import '../state/selectable.dart';
import '../state/undo_redo.dart';
import '../util.dart' as util;

AppState load_design_reducer(AppState state, actions.LoadDesign action) {
  return update_design_and_filename(state, action.design, action.filename);
}

/// Returns new AppState after updating design and filename.
AppState update_design_and_filename(AppState state, Design design_new, String filename) {
  // Design should not be null.
  assert(design_new != null);

  AppState new_state;
  BuiltSet<int> side_selected_helix_idxs = BuiltSet<int>();

  // Select helices if "clear helix selection when loading new design" is disabled
  if (!state.ui_state.clear_helix_selection_when_loading_new_design) {
    side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs;

    // remove selected helices from
    if (state.design != null && design_new.helices.length < state.design.helices.length) {
      side_selected_helix_idxs =
          side_selected_helix_idxs.rebuild((s) => s.removeWhere((idx) => idx >= design_new.helices.length));
    }
  }

  var new_selectables_store = SelectablesStore();
  var new_filename = filename ?? state.ui_state.loaded_filename;

  // if new design doesn't have same group names, need to pick a new one
  var storables = state.ui_state.storables;
  var displayed_group_name = storables.displayed_group_name;
  if (!design_new.groups.containsKey(displayed_group_name)) {
    storables = storables.rebuild((b) => b..displayed_group_name = design_new.groups.keys.first);
  }

  new_state = state.rebuild((m) => m
    ..undo_redo.replace(UndoRedo())
    ..design = design_new.toBuilder()
    ..ui_state.update((u) => u
      ..storables.replace(storables)
      ..selectables_store.replace(new_selectables_store)
      ..changed_since_last_save = false
      ..storables.loaded_filename = new_filename
      ..storables.side_selected_helix_idxs.replace(side_selected_helix_idxs))
    ..error_message = "");

  return new_state;
}
