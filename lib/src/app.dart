@JS()
library app;

import 'dart:html';

import 'package:js/js.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:redux/redux.dart';
import 'package:redux_dev_tools/redux_dev_tools.dart';
import 'package:scadnano/src/middleware/all_middleware.dart';
import 'package:over_react/over_react.dart' as react;
import 'package:scadnano/src/middleware/throttle.dart';
import 'package:scadnano/src/state/app_ui_state.dart';

import 'actions/actions.dart';
import 'state/dna_design.dart';
import 'state/app_state.dart';
import 'state/selection_box.dart';
import 'state/undo_redo.dart';
import 'reducers/selection_reducer.dart';
import 'view/view.dart';
import 'reducers/app_state_reducer.dart';
import 'middleware/local_storage.dart';
import 'middleware/all_middleware.dart';
import 'util.dart' as util;
import 'actions/actions.dart' as actions;
//import 'constants.dart' as constants;

// global variable for whole program
App app = App();

//const USE_REDUX_DEV_TOOLS = false;
const USE_REDUX_DEV_TOOLS = true;

const RUN_TEST_CODE_INSTEAD_OF_APP = false;
//const RUN_TEST_CODE_INSTEAD_OF_APP = true;

//const DEBUG_SELECT = true;
const DEBUG_SELECT = false;

test_stuff() async {
//  print('hi');
//  BoundSubstrand ss1 = BoundSubstrand((s) => s
//    ..helix = 3
//    ..forward = false
//    ..start = 16
//    ..end = 32
//    ..deletions.replace([])
//    ..insertions.replace([])
//    ..is_first = true
//    ..is_last = false);

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
  AppState get state => store.state;
  View view;

  Store store;

  // for optimization; too slow to store in Model since it's updated 60 times/sec
  Store store_selection_box;
  var context_selection_box = createContext();

  // for optimization; don't want to dispatch Actions changing model on every keypress
  // This is updated in view/design.dart; consider moving it higher-level.
  final Set<int> keys_pressed = {};

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

//    util.save_editor_content_to_js_context(state.editor_content);
      restore_all_local_storage();
      this.setup_warning_before_unload();

      make_dart_functions_available_to_js(state);

      DivElement app_root_element = querySelector('#top-container');
      this.view = View(app_root_element);

      this.view.render(state);
    }
  }

  initialize_model() async {
    String filename_in_directory = '2_staple_2_helix_origami_deletions_insertions.dna';
//    String filename_in_directory = '6_helix_origami_rectangle_helices_out_of_order.dna';
//    String filename_in_directory = '6_helix_origami_rectangle.dna';
//    String filename_in_directory = '16_helix_origami_rectangle.dna';
//    String filename_in_directory = '16_helix_origami_barrel_from_algoSST_paper-rotator.dna';
//    String filename_in_directory = '1_staple_1_helix_origami.dna';
//    String filename_in_directory = '6_helix_bundle_honeycomb.dna';
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

    AppState state;

    if (error_message == null) {
      var ui_state = AppUIState.from_dna_design(dna_design);
      state = (DEFAULT_AppStateBuilder
            ..dna_design.replace(dna_design)
            ..ui_state.replace(ui_state)
            ..editor_content = initial_editor_content)
          .build();
    } else {
      state = (DEFAULT_AppStateBuilder
            ..error_message = error_message
            ..editor_content = initial_editor_content)
          .build();
    }

    if (USE_REDUX_DEV_TOOLS) {
      var middleware_plus = all_middleware + [overReactReduxDevToolsMiddleware];
      store = DevToolsStore<AppState>(app_state_reducer, initialState: state, middleware: middleware_plus);
    } else {
      store = Store<AppState>(app_state_reducer, initialState: state, middleware: all_middleware);
    }

    store_selection_box = Store<SelectionBox>(optimized_selection_box_reducer,
        initialState: null, middleware: [throttle_middleware_selection_box]);
  }

  dispatch(Action action) {
    var underlying_action = action is ThrottledAction ? action.action : action;
    if (underlying_action is actions.SelectionBoxCreate ||
        underlying_action is actions.SelectionBoxSizeChange ||
        underlying_action is actions.SelectionBoxRemove) {
      // optimization since selection box size changes happen too fast to update whole model without jank
      store_selection_box.dispatch(action);
    } else {
      store.dispatch(action);
    }
  }

  setup_warning_before_unload() {
    window.onBeforeUnload.listen((Event event) {
      if (this.undo_redo.undo_stack.isNotEmpty) {
        BeforeUnloadEvent e = event;
        e.returnValue = 'You have unsaved work. Are you sure you want to leave?';
      }
    });
  }

  make_dart_functions_available_to_js(AppState model) {
//    util.make_dart_function_available_to_js('dart_allow_pan', state.allow_main_view_pan);
  }
}

setup_undo_redo_keyboard_listeners() {
  // below doesn't work with onKeyPress
  // previous solution with onKeyPress used event.code == 'KeyZ' and worked inconsistently
  document.body.onKeyDown.listen((KeyboardEvent event) {
    int key = event.which;
//    print('*' * 100);
//    print('charCode: ${event.charCode}');
//    print(' keyCode: ${event.keyCode}');
//    print('    code: ${event.code}');
//    print('     key: ${event.key}');
//    print('   which: ${event.which}');
//    print("Control: ${event.getModifierState('control')}"); // modifiers.control);
//    print("KeyCode: ${event.key.codeUnitAt(0)}");

    // ctrl+Z to undo
    if ((event.ctrlKey || event.metaKey) && !event.shiftKey && key == KeyCode.Z && !event.altKey) {
      if (app.state.undo_redo.undo_stack.isNotEmpty) {
        app.dispatch(actions.Undo());
      }
    }
    // shift+ctrl+Z to redo
    if ((event.ctrlKey || event.metaKey) && event.shiftKey && key == KeyCode.Z && !event.altKey) {
      if (app.state.undo_redo.redo_stack.isNotEmpty) {
        app.dispatch(actions.Redo());
      }
    }
  });
}
