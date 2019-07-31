import 'dart:html';

import 'model.dart';
import 'app.dart';

/// Maintains an undo stack and a redo stack of Actions.
class UndoRedo {
  List<Action> undo_stack;
  List<Action> redo_stack;

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
      if (event.ctrlKey && !event.shiftKey && event.code == 'KeyZ' && !event.altKey) {
        undo();
      }
      // shift+ctrl+Z to redo
      if (event.ctrlKey && event.shiftKey && event.code == 'KeyZ' && !event.altKey) {
        redo();
      }
    });
  }

  reset() {
    undo_stack = [];
    redo_stack = [];
  }

  apply(Action action) {
    if (!app.model.changed_since_last_save) {
      app.model.changed_since_last_save = true;
      app.controller.notifier_model_changed_since_save.add(app.model.changed_since_last_save);
    }
    app.model = action.apply(app.model);
    redo_stack.clear();
    undo_stack.add(action);
  }

  undo() {
    if (undo_stack.isNotEmpty) {
      var most_recent_action = undo_stack.removeLast();
      var reverse_action = most_recent_action.reverse();
      app.model = reverse_action.apply(app.model);
      redo_stack.add(most_recent_action);
      if (undo_stack.isEmpty) {
        if (!app.model.changed_since_last_save) {
          app.model.changed_since_last_save = true;
          app.controller.notifier_model_changed_since_save.add(app.model.changed_since_last_save);
        }
      }
    }
  }

  redo() {
    if (redo_stack.isNotEmpty) {
      if (app.model.changed_since_last_save) {
        app.model.changed_since_last_save = false;
        app.controller.notifier_model_changed_since_save.add(app.model.changed_since_last_save);
      }
      var action_to_redo = redo_stack.removeLast();
      app.model = action_to_redo.apply(app.model);
      undo_stack.add(action_to_redo);
    }
  }
}
