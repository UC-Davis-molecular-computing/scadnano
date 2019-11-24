import 'dart:html';

import '../actions/actions_OLD.dart';
import '../app.dart';

//TODO: exception currently thrown when undoing remove helix

/// Maintains an undo stack and a redo stack of Actions.
class UndoRedo {
  List<ReversibleActionPack> undo_stack;
  List<ReversibleActionPack> redo_stack;

//  List<Model> undo_stack;
//  List<Model> redo_stack;

  UndoRedo() {
    setup_undo_redo_keyboard_listeners();
    reset();
  }

  setup_undo_redo_keyboard_listeners() {
    document.body.onKeyPress.listen((KeyboardEvent event) {
//      print('charCode: ${event.charCode}');
//      print(' keyCode: ${event.keyCode}');
//      print('    code: ${event.code}');
//      print('     key: ${event.key}');
//      print('   which: ${event.which}');

      // ctrl+Z to undo
      if ((event.ctrlKey || event.metaKey) && !event.shiftKey && event.code == 'KeyZ' && !event.altKey) {
        undo();
      }
      // shift+ctrl+Z to redo
      if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.code == 'KeyZ' && !event.altKey) {
        redo();
      }
    });
  }

  reset() {
    undo_stack = [];
    redo_stack = [];
  }

  apply(ReversibleActionPack action) {
    if (!app.model.ui_model.changed_since_last_save) {
      //FIXME: send an action to update this bool
      //app.model.changed_since_last_save = true;
    }
    action.apply();
    redo_stack.clear();
    undo_stack.add(action);
  }

  undo() {
    if (undo_stack.isNotEmpty) {
      var most_recent_action = undo_stack.removeLast();
      var reverse_action = most_recent_action.reverse();
      reverse_action.apply();
      redo_stack.add(most_recent_action);
      if (undo_stack.isEmpty) {
        if (!app.model.ui_model.changed_since_last_save) {
          //FIXME: send action
//          app.model.changed_since_last_save = true;
        }
      }
    }
  }

  redo() {
    if (redo_stack.isNotEmpty) {
      if (app.model.ui_model.changed_since_last_save) {
          //FIXME: send action
//        app.model.changed_since_last_save = false;
      }
      var action_to_redo = redo_stack.removeLast();
      action_to_redo.apply();
      undo_stack.add(action_to_redo);
    }
  }
}
