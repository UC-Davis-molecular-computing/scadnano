import 'package:redux/redux.dart';

import 'app_ui_state_reducer.dart';
import 'design_reducer.dart';
import 'undo_redo_reducer.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import 'load_dna_file_reducer.dart';

AppState app_state_reducer(AppState state, action) {
  AppState original_state = state;

  // If wrapped in SkipUndo, unpack it and remember undoable_action_reducer shouldn't push onto undo stack.
  bool modify_undo_redo_stacks = true;
  if (action is actions.SkipUndo) {
    modify_undo_redo_stacks = false;
    action = action.undoable_action;
  }

  // This is a bit of a special case.
  if (action is actions.LoadDNAFile) {
    return load_dna_file_reducer(state, action);
  }

  //XXX: I had a lot of bugs when I introduced local variables to track all the updates to the state below.
  // Repeatedly updating the variable state seems safer.

  // crucial that this is done first so design holds the "current" value (not next)
  state = undo_redo_reducer(state, action);
  if (modify_undo_redo_stacks) {
    state = undoable_action_reducer(state, action);
  }

  // "local" reducers can operate on one slice of the state and need only read that same slice
  state = state.rebuild((m) => m
    ..design = design_reducer(state.design, action)?.toBuilder()
    ..ui_state.replace(ui_state_local_reducer(state.ui_state, action))
    ..error_message =
        TypedReducer<String, actions.ErrorMessageSet>(error_message_reducer)(state.error_message, action)
    ..editor_content = editor_content_reducer(state.editor_content, action));

  // "global" reducers operate on a slice of the state but need another part of the state.
  // For consistency, everyone gets the version of the state before any action was applied.
  // This ensures that, for example, when a DeleteAllSelected action is dispatched, above, the
  // selection reducer sets the set of selected items to empty, yet the delete_all_reducer that deletes the
  // items from the DNADesign can still see the set of selected items in
  // original_state.ui_state.selectables_store.
  state = state.rebuild((m) => m
    ..design = design_global_reducer(state.design, original_state, action)?.toBuilder()
    ..ui_state.replace(ui_state_global_reducer(state.ui_state, original_state, action)));

  // Batch actions are grouped together but should just have one entry on the undo stack.
  // So we set a variable telling the Undo reducer not to put anything on the stack for any of these atomic actions.
  // However, it has already put something on the stack above for the BatchAction itself.
  // This seems like it belongs in undo_redo_reducer, but the logic was tricky to handle, so we make a special case.
  if (action is actions.BatchAction) {
    for (actions.UndoableAction atomic_action in action.actions) {
      state = app_state_reducer(state, actions.SkipUndo(atomic_action));
    }
  }

  if (state == null) {
    // this is a check on myself since null is implicitly returned when there is no return statement
    throw ArgumentError('reducer returned a null state, which is disallowed');
  }

  return state;
}

String error_message_reducer(String error_message, actions.ErrorMessageSet action) => action.error_message;

String editor_content_reducer(String editor_content, action) {
  return editor_content;
}
