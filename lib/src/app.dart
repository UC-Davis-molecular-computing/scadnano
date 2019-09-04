@JS()
library app;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'package:js/js.dart';
import 'controller.dart';
import 'model.dart';
import 'actions.dart';
import 'util.dart' as util;
import 'undo_redo.dart';
import 'view.dart';
import 'constants.dart' as constants;
import 'local_storage.dart' as local_storage;

App app = App();

@JS()
external set set_new_design_from_json_js(Function f);

/// One instance of this class contains the global variables needed by all parts of the app.
class App {
  Model model;
  View view;
  Controller controller;

  /// Undo/Redo stacks
  UndoRedo undo_redo = UndoRedo();

  /// Listener for Actions that indicate desired changes to the Model
  StreamController<Action> action_notifier = StreamController<Action>();

  start() async {

    // make Controller.set_new_design_from_json accessible from JS so pyodide can access it after compiling
//    context[constants.js_function_name_set_new_design_from_json] =
    set_new_design_from_json_js = allowInterop((String json_string) {
      set_new_design_from_json(json_string);
    });

    this.controller = Controller();

    this.model =
        await util.model_from_url('examples/output_designs/2_staple_2_helix_origami_deletions_insertions.dna');
//        await util.model_from_url('examples/output_designs/loopouts_all_types.dna');
//        await util.model_from_url('examples/output_designs/2_staple_2_helix_origami_deletions_lots_of_insertions.dna');
//        await util.model_from_url('examples/output_designs/1_staple_1_helix_origami_mismatches.dna');
//        await util.model_from_url('examples/output_designs/1_staple_1_helix_origami.dna');

    util.save_editor_content_to_js_context(model.editor_content);

    local_storage.restore_all_local_storage();
    this.setup_warning_before_unload();
    this.action_notifier.stream.listen((Action action) {
      this.undo_redo.apply(action);
    });


    // allow Brython some way to tell us about errors that happened when compiling
    context[constants.js_function_name_set_error_message_from_python_script] = allowInterop((String msg) {
      print('dart received error message: ${msg}');
      set_error_message(msg);
    });

    //XXX: Controller must be created before the first render since views must
    // register as listeners to the notifiers of the Controller.
    DivElement app_root_element = querySelector('#top-container');
    this.view = View(app_root_element);
    this.view.render();

    app.controller.setup_subscriptions();
  }

  send_action(Action action) {
    this.action_notifier.sink.add(action);
  }

  setup_warning_before_unload() {
    //TODO: change check for undo stack empty to check for changes since last save
    // (set "unsaved work" flag in UIModel)
    window.onBeforeUnload.listen((Event event) {
      if (this.undo_redo.undo_stack.isNotEmpty) {
        BeforeUnloadEvent e = event;
        e.returnValue = 'You have unsaved work. Are you sure you want to leave?';
      }
    });
  }

}
