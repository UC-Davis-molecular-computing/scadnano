import 'dart:async';
import 'dart:html';

import 'controller.dart';
import 'model.dart';
import 'util.dart';
import 'undo_redo.dart';
import 'view.dart';
import 'local_storage.dart' as local_storage;

App app = App();

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
//    this.model = Model.default_model();
//    this.model = await Model.from_url('examples/output_designs/few-small-helices.dna');
//    this.model = await Model.from_url('examples/output_designs/16_helix_rectangle_no_seq.dna');
    this.model =
        await model_from_url('examples/output_designs/2_staple_2_helix_origami_deletions_insertions.dna');

    local_storage.restore_all_local_storage();
    this.setup_warning_before_unload();
    this.action_notifier.stream.listen((Action action) {
      this.undo_redo.apply(action);
    });

    this.controller = Controller();

    //XXX: Controller must be created before the first render since views must
    // register as listeners to the notifiers of the Controller.
    this.view = View();
    this.view.render();
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
