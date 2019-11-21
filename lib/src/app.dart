@JS()
library app;

import 'dart:html';
import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:js/js.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react.dart';
import 'package:redux/redux.dart';
import 'package:redux_dev_tools/redux_dev_tools.dart';
import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/model/dna_end.dart';
import 'package:scadnano/src/model/select_mode.dart';
import 'package:scadnano/src/test_built_value.dart';

import 'model/dna_design.dart';
import 'model/helix.dart';
import 'model/model.dart';
import 'dispatcher/actions_OLD.dart';

//import 'dispatcher/model_reducer.dart';
import 'model/mouseover_data.dart';
import 'serializers.dart';
import 'util.dart' as util;
import 'dispatcher/undo_redo.dart';
import 'view/view.dart';
import 'dispatcher/model_reducer.dart';
import 'dispatcher/local_storage.dart' as local_storage;
import 'dispatcher/actions.dart' as actions;
import 'built_intern.dart';

App app = App();

const USE_REDUX_DEV_TOOLS = false;
//const USE_REDUX_DEV_TOOLS = true;

const RUN_TEST_CODE_INSTEAD_OF_APP = false;
//  const TEST = true;

test_stuff() async {
  var v = TestBuiltValue(5, null, null);
  print(v);
}

/// One instance of this class contains the global variables needed by all parts of the app.
class App {
  Model get model => store.state;
  View view;

  Store store;

  /// Undo/Redo stacks
  UndoRedo undo_redo = UndoRedo();

  start() async {
    if (RUN_TEST_CODE_INSTEAD_OF_APP) {
      await test_stuff();
    } else {
      await initialize_model();

//    util.save_editor_content_to_js_context(model.editor_content);
      local_storage.restore_all_local_storage();
      this.setup_warning_before_unload();

      make_dart_functions_available_to_js(model);

      DivElement app_root_element = querySelector('#top-container');
      this.view = View(app_root_element);

      this.view.render();
    }
  }

  initialize_model() async {
    String filename = 'examples/output_designs/2_staple_2_helix_origami_deletions_insertions.dna';
//    String filename = 'examples/output_designs/1_staple_1_helix_origami.dna';
//    String filename = 'examples/output_designs/16_helix_origami_rectangle.dna';
//    String filename = 'examples/output_designs/6_helix_origami_rectangle.dna';
//    String filename = 'examples/output_designs/loopouts_all_types.dna';
//    String filename = 'examples/output_designs/2_staple_2_helix_origami_deletions_lots_of_insertions.dna';
//    String filename = 'examples/output_designs/1_staple_1_helix_origami_mismatches.dna';

    DNADesign dna_design;
    String error_message;
    try {
      dna_design = await util.dna_design_from_url(filename);
    } on IllegalDNADesignError catch (error) {
      error_message = error.cause;
    }

//    String initial_editor_content = await util.file_content(filename);
    String initial_editor_content = "";

    Model model;

    if (error_message == null) {
      model = (DEFAULT_ModelBuilder
            ..dna_design.replace(dna_design)
            ..editor_content = initial_editor_content)
          .build();
    } else {
      model = (DEFAULT_ModelBuilder
            ..error_message = error_message
            ..editor_content = initial_editor_content)
          .build();
    }

//    print('helix 0 = ${dna_design.helices[0]}');
//    print('helix 1 = ${dna_design.helices[1]}');

//    print('model.toJson(): ${model.toJson()}');
//    print('model.toJson().runtimeType: ${model.toJson().runtimeType}');
//    print('jsonEncode(model): ${jsonEncode(model)}');

    if (USE_REDUX_DEV_TOOLS) {
      store = DevToolsStore<Model>(model_reducer, initialState: model, middleware: [
        overReactReduxDevToolsMiddleware,
        local_storage.middleware_local_storage,
      ]);
    } else {
      store = Store<Model>(model_reducer, initialState: model, middleware: [
        local_storage.middleware_local_storage,
      ]);
    }
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

  make_dart_functions_available_to_js(Model model) {
    util.make_dart_function_available_to_js('dart_allow_pan', model.allow_main_view_pan);
  }
}
