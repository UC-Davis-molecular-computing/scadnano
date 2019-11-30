@JS()
library app;

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:redux/redux.dart';
import 'package:redux_dev_tools/redux_dev_tools.dart';
import 'package:scadnano/src/middleware/all_middleware.dart';
import 'package:over_react/over_react.dart' as react;

import 'package:scadnano/src/model/bound_substrand.dart';
import 'model/dna_design.dart';
import 'model/model.dart';

import 'util.dart' as util;
import 'model/undo_redo.dart';
import 'view/view.dart';
import 'reducers/model_reducer.dart';
import 'middleware/local_storage.dart';
import 'middleware/all_middleware.dart';
import 'actions/actions.dart' as actions;

// global variable for whole program
App app = App();

//const USE_REDUX_DEV_TOOLS = false;
const USE_REDUX_DEV_TOOLS = true;

const RUN_TEST_CODE_INSTEAD_OF_APP = false;
//const RUN_TEST_CODE_INSTEAD_OF_APP = true;

test_stuff() async {
  print('hi');
  BoundSubstrand ss1 = BoundSubstrand((s) => s
    ..helix = 3
    ..forward = false
    ..start = 16
    ..end = 32
    ..deletions.replace([])
    ..insertions.replace([])
    ..is_first = true
    ..is_last = false);

//  BoundSubstrand ss2 = BoundSubstrand((s) => s
//    ..helix = 3
//    ..forward = false
//    ..start = 16
//    ..end = 32
//    ..deletions.replace([])
//    ..insertions.replace([])
//    ..is_first = true
//    ..is_last = false);
//  int h1 = ss1.hashCode;
//  int h2 = ss2.hashCode;
//  print('ss1.hashCode: ${ss1.hashCode}');
//  print('ss2.hashCode: ${ss2.hashCode}');
//  print('ss1 == ss2:         ${ss1 == ss2}');
//  print('identical(ss1,ss2): ${identical(ss1,ss2)}');
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
//      Timer.periodic(new Duration(seconds: 1), (timer) {
//        print('${document.hasFocus()}');
//      });
//      document.onVisibilityChange.listen((ev) => print('visibility changed: $ev'));

      react.setClientConfiguration();

      await initialize_model();

      setup_undo_redo_keyboard_listeners();

//    util.save_editor_content_to_js_context(model.editor_content);
      restore_all_local_storage();
      this.setup_warning_before_unload();

      make_dart_functions_available_to_js(model);

      DivElement app_root_element = querySelector('#top-container');
      this.view = View(app_root_element);

      this.view.render(model);
    }
  }

  initialize_model() async {
    String filename_in_directory = '2_staple_2_helix_origami_deletions_insertions.dna';
//    String filename_in_directory = '16_helix_origami_rectangle.dna';
//    String filename_in_directory = '1_staple_1_helix_origami.dna';
//    String filename_in_directory = '6_helix_bundle_honeycomb.dna';
//    String filename_in_directory = '6_helix_origami_rectangle.dna';
//    String filename_in_directory = 'loopouts_all_types.dna';
//    String filename_in_directory = '2_staple_2_helix_origami_deletions_lots_of_insertions.dna';
//    String filename_in_directory = '1_staple_1_helix_origami_mismatches.dna';

    document.title = filename_in_directory;

    String directory = 'examples/output_designs/';
    String filename = directory + filename_in_directory;

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

    if (USE_REDUX_DEV_TOOLS) {
      var middleware_plus = all_middleware + [overReactReduxDevToolsMiddleware];
      store = DevToolsStore<Model>(model_reducer, initialState: model, middleware: middleware_plus);
    } else {
      store = Store<Model>(model_reducer, initialState: model, middleware: all_middleware);
    }

    void thunk_action(Store<Model> store) async {
//      print('thunk_action dispatched');
      final String searchResults = await new Future.delayed(
        new Duration(seconds: 1),
            () => "Search Results",
      );
      store.dispatch(searchResults);
    }

    store.dispatch(thunk_action);
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

setup_undo_redo_keyboard_listeners() {
  document.body.onKeyPress.listen((KeyboardEvent event) {
//      print('charCode: ${event.charCode}');
//      print(' keyCode: ${event.keyCode}');
//      print('    code: ${event.code}');
//      print('     key: ${event.key}');
//      print('   which: ${event.which}');

    // ctrl+Z to undo
    if ((event.ctrlKey || event.metaKey) && !event.shiftKey && event.code == 'KeyZ' && !event.altKey) {
      if (app.model.undo_redo.undo_stack.isNotEmpty) {
        app.store.dispatch(actions.Undo());
      }
    }
    // shift+ctrl+Z to redo
    if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.code == 'KeyZ' && !event.altKey) {
      if (app.model.undo_redo.redo_stack.isNotEmpty) {
        app.store.dispatch(actions.Redo());
      }
    }
  });
}
