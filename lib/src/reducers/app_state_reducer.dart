import 'package:redux/redux.dart';

import 'app_ui_state_reducer.dart';
import 'dna_design_reducer.dart';
import 'undo_redo_reducer.dart';
import '../actions/actions.dart' as actions;
import '../model/app_state.dart';
import 'load_dna_file_reducer.dart';
import '../util.dart' as util;

AppState app_state_reducer(AppState model, action) {
//  if (action is actions.MainViewSelectionBoxSizeChanged) {
//    var selection_box = model.ui_state.selection_box_main_view;
//    selection_box = selection_box
//        .rebuild((s) => s..current = action.point);
//    var new_model = model.rebuild((m) => m..ui_state.selection_box_main_view.replace(selection_box));
//    return new_model;
//  }

  // If wrapped in SkipUndo, unpack it and remember undoable_action_reducer shouldn't push onto undo stack.
  bool modify_undo_redo_stacks = true;
  if (action is actions.SkipUndo) {
    modify_undo_redo_stacks = false;
    action = action.undoable_action;
  }

  // This is a bit of a special case.
  if (action is actions.LoadDNAFile) {
    return load_dna_file_reducer(model, action);
  }

  //XXX: I had a lot of bugs when I introduced local variables to track all the updates to the model below.
  // Repeatedly updating the variable model seems safer.

  // crucial that this is done first so dna_design holds the "current" value (not next)
  model = undo_redo_reducer(model, action);
  if (modify_undo_redo_stacks) {
    model = undoable_action_reducer(model, action);
  }

  // "local" reducers can operate on one slice of the model and need only read that same slice
  model = model.rebuild((m) => m
    ..dna_design.replace(dna_design_reducer(model.dna_design, action))
    ..ui_state.replace(ui_state_reducer(model.ui_state, action))
    ..error_message = TypedReducer<String, actions.ErrorMessageSet>(error_message_reducer)(model.error_message, action)
    ..editor_content = editor_content_reducer(model.editor_content, action));

  // "global" reducers operate on a slice of the model but need another part of the model
  // we pass the "old" parts of the model, since we don't want dispatcher to assume they will be applied
  // in a certain order. For consistency, everyone gets the version of the model before any action was applied.
  model = model.rebuild((m) => m..ui_state.replace(ui_state_global_reducer(model.ui_state, model, action)));

  // Batch actions are grouped together but should just have one entry on the undo stack.
  // So we set a variable telling the Undo reducer not to put anything on the stack for any of these atomic actions.
  // However, it has already put something on the stack above for the BatchAction itself.
  // This seems like it belongs in undo_redo_reducer, but the logic was tricky to handle, so we make a special case.
  if (action is actions.BatchAction) {
    for (actions.UndoableAction atomic_action in action.actions) {
      model = app_state_reducer(model, actions.SkipUndo(atomic_action));
    }
  }

  if (model == null) {
    // this is a check on myself since null is implicitly returned when there is no return statement
    throw ArgumentError('reducer returned a null model, which is disallowed');
  }

  return model;
}

////TODO: this shouldn't have a side effect; instead we should use "middleware", I think?
//Model save_dna_file_reducer(Model model, actions.SaveDNAFile action) {
//  // not much happens here; side effect of saving file is in middleware/save_file.dart
//  return model.rebuild((m) => m..ui_model.changed_since_last_save = false);
//}

String error_message_reducer(String error_message, actions.ErrorMessageSet action) => action.error_message;

String editor_content_reducer(String editor_content, action) {
  return editor_content;
}
