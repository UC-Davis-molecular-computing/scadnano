@JS()
library app;

import 'dart:html';
import 'dart:js';

import 'package:js/js.dart';

import 'model/model.dart';

import 'dispatcher/actions.dart';
import 'util.dart' as util;
import 'dispatcher/undo_redo.dart';
import 'view/view.dart';
import 'constants.dart' as constants;
import 'dispatcher/local_storage.dart' as local_storage;

App app = App();

//@JS()
//external set set_new_design_from_json_js(Function f);

/// One instance of this class contains the global variables needed by all parts of the app.
class App {
  Model model;
  View view;

  /// Undo/Redo stacks
  UndoRedo undo_redo = UndoRedo();

  start() async {

    // make Controller.set_new_design_from_json accessible from JS so pyodide can access it after compiling
//    context[constants.js_function_name_set_new_design_from_json] =
//    set_new_design_from_json_js = allowInterop((String json_string) {
//      set_new_design_from_json(json_string);
//    });

    this.model =
        await util.model_from_url('examples/output_designs/2_staple_2_helix_origami_deletions_insertions.dna');
//        await util.model_from_url('examples/output_designs/loopouts_all_types.dna');
//        await util.model_from_url('examples/output_designs/2_staple_2_helix_origami_deletions_lots_of_insertions.dna');
//        await util.model_from_url('examples/output_designs/1_staple_1_helix_origami_mismatches.dna');
//        await util.model_from_url('examples/output_designs/1_staple_1_helix_origami.dna');


    String initial_editor_content = await
      util.file_content('examples/2_staple_2_helix_origami_deletions_insertions.py');
    this.model.editor_content = initial_editor_content;
    util.save_editor_content_to_js_context(this.model.editor_content);
    local_storage.restore_all_local_storage();
    this.setup_warning_before_unload();

    // allow Brython some way to tell us about errors that happened when compiling
    context[constants.js_function_name_set_error_message_from_python_script] = allowInterop((String msg) {
      print('dart received error message: ${msg}');
//      set_error_message(msg);
    });

    DivElement app_root_element = querySelector('#top-container');
    this.view = View(app_root_element, this.model);

    model.trigger();
  }

  send_action(ReversibleActionPack action_pack) {
//    if (action_pack is ReversibleActionPack) {
//      ReversibleActionPack rev_action_pack = action_pack;
      this.undo_redo.apply(action_pack);
//    } else {
//      action_pack.apply();
//    }
  }

  setup_warning_before_unload() {
    window.onBeforeUnload.listen((Event event) {
      if (this.undo_redo.undo_stack.isNotEmpty) {
        BeforeUnloadEvent e = event;
        e.returnValue = 'You have unsaved work. Are you sure you want to leave?';
      }
    });
  }

}
