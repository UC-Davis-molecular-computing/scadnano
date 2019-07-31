import 'dart:async';
import 'dart:html';

import 'controller.dart';
import 'model.dart';
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
    this.model = Model.default_model();
    // this.model = await Model.from_url('examples/output_designs/few-small-helices.dna');
//    this.model = await Model.from_url('examples/output_designs/16_helix_rectangle_no_seq.dna');

    local_storage.restore_all_local_storage();
    this.setup_warning_before_unload();
    this.action_notifier.stream.listen((Action action) {
      this._apply(action);
    });

    app.controller = Controller();

    //XXX: Controller must be created before the first render since views must
    // register as listeners to the notifiers of the Controller.
    app.view = View();
  }

  send_action(Action action) {
    this.action_notifier.sink.add(action);
  }

  ///XXX: only call internally; clients should put action in the stream by calling send_action
  _apply(Action action) {
    this.undo_redo.apply(action);
  }

  setup_warning_before_unload() {
    //TODO: change check for undo stack empty to check for changes since last save
    // (set "unsaved work" flag in UIModel)
    window.onBeforeUnload.listen((Event event) {
      if (this.undo_redo.undo_stack.isNotEmpty) {
        BeforeUnloadEvent e = event;
        e.returnValue =
            'You have unsaved work. Are you sure you want to leave?';
      }
    });
  }

  /// This should only be called when loading a brand new DNADesign from a file.
  /// For changes to the existing model, Actions should be dispatched via
  /// app.sendAction(the_action);
  set_new_design(DNADesign new_design) {
    this.model.changed_since_last_save = false;
    this.model.dna_design = new_design;
    this.undo_redo.reset();
    this
        .view
        .render(); // crucially does not re-render menu since new model is being loaded
  }
}
