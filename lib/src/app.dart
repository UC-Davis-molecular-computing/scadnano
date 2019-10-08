@JS()
library app;

import 'dart:html';

import 'package:js/js.dart';

import 'model/model.dart';

import 'dispatcher/actions.dart';
import 'util.dart' as util;
import 'dispatcher/undo_redo.dart';
import 'view/view.dart';
import 'dispatcher/local_storage.dart' as local_storage;

App app = App();

/// One instance of this class contains the global variables needed by all parts of the app.
class App {
  Model model;
  View view;

  /// Undo/Redo stacks
  UndoRedo undo_redo = UndoRedo();

  start() async {

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

    DivElement app_root_element = querySelector('#top-container');
    this.view = View(app_root_element, this.model);

    this.view.render();
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
