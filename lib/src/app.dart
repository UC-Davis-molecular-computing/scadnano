@JS()
library app;

import 'dart:html';

import 'package:js/js.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:redux/redux.dart';
import 'package:redux_dev_tools/redux_dev_tools.dart';
import 'package:over_react/over_react.dart' as react;

import 'middleware/all_middleware.dart';
import 'middleware/throttle.dart';
import 'state/dna_ends_move.dart';
import 'state/helix_group_move.dart';
import 'state/local_storage_design_choice.dart';
import 'state/potential_crossover.dart';
import 'actions/actions.dart';
import 'reducers/dna_ends_move_reducer.dart';
import 'reducers/helix_group_move_reducer.dart';
import 'reducers/potential_crossover_reducer.dart';
import 'state/app_state.dart';
import 'state/selection_box.dart';
import 'reducers/selection_reducer.dart';
import 'view/design.dart';
import 'view/view.dart';
import 'reducers/app_state_reducer.dart';
import 'middleware/local_storage.dart';
import 'util.dart' as util;
import 'actions/actions.dart' as actions;

//import 'test.dart';
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

}

/// One instance of this class contains the global variables needed by all parts of the app.
class App {
  AppState get state => store.state;
  View view;

  Store store;

  // for optimization; too slow to store in Model since it's updated 60 times/sec
  Store<SelectionBox> store_selection_box;
  var context_selection_box = createContext();
  Store<PotentialCrossover> store_potential_crossover;
  var context_potential_crossover = createContext();
  Store<DNAEndsMove> store_dna_ends_move;
  var context_dna_ends_move = createContext();
  Store<HelixGroupMove> store_helix_group_move;
  var context_helix_group_move = createContext();

  // for optimization; don't want to dispatch Actions changing model on every keypress
  // This is updated in view/design.dart; consider moving it higher-level.
  final Set<int> keys_pressed = {};

  // when user-interacting dialog is open, disable keyboard shortcuts
  bool keyboard_shortcuts_enabled = true;

  start() async {
    if (RUN_TEST_CODE_INSTEAD_OF_APP) {
      await test_stuff();
    } else {
      warn_wrong_browser();
      react.setClientConfiguration();
      initialize_state();
      setup_undo_redo_keyboard_listeners();
      setup_save_open_dna_file_keyboard_listeners();
//    util.save_editor_content_to_js_context(state.editor_content);
      restore_all_local_storage();
      setup_warning_before_unload();
      setup_save_design_to_localStorage_before_unload();
      make_dart_functions_available_to_js(state);
      DivElement app_root_element = querySelector('#top-container');
      this.view = View(app_root_element);
      this.view.render(state);
    }
  }

  initialize_state() {
    AppState state = DEFAULT_AppState;

    if (USE_REDUX_DEV_TOOLS) {
      var middleware_plus = all_middleware + [overReactReduxDevToolsMiddleware];
      store = DevToolsStore<AppState>(app_state_reducer, initialState: state, middleware: middleware_plus);
    } else {
      store = Store<AppState>(app_state_reducer, initialState: state, middleware: all_middleware);
    }

    store_selection_box = Store<SelectionBox>(optimized_selection_box_reducer,
        initialState: null, middleware: [throttle_middleware]);

    store_potential_crossover = Store<PotentialCrossover>(optimized_potential_crossover_reducer,
        initialState: null, middleware: [throttle_middleware]);

    store_dna_ends_move = Store<DNAEndsMove>(optimized_dna_ends_move_reducer,
        initialState: null, middleware: [throttle_middleware]);

    store_helix_group_move = Store<HelixGroupMove>(optimized_helix_group_move_reducer,
        initialState: null, middleware: [throttle_middleware]);
  }

  Future<T> disable_keyboard_shortcuts_while<T>(Future<T> f()) async {
    keyboard_shortcuts_enabled = false;
    T return_value = await f();
    keyboard_shortcuts_enabled = true;
    return return_value;
  }

  dispatch_async(Action action) async {
    dispatch(action);
  }

  dispatch(Action action) {
    // dispatch most to normal store, but fast-repeated actions only go to optimized stores
    if (!(action is FastAction)) {
      store.dispatch(action);
    }

    // optimization since these actions happen too fast to update whole model without jank
    var underlying_action = action is ThrottledActionFast ? action.action : action;
    if (underlying_action is actions.SelectionBoxCreate ||
        underlying_action is actions.SelectionBoxSizeChange ||
        underlying_action is actions.SelectionBoxRemove) {
      store_selection_box.dispatch(action);
    }
    if (underlying_action is actions.PotentialCrossoverCreate ||
        underlying_action is actions.PotentialCrossoverMove ||
        underlying_action is actions.PotentialCrossoverRemove) {
      store_potential_crossover.dispatch(action);
    }
    if (underlying_action is actions.DNAEndsMoveSetSelectedEnds ||
        underlying_action is actions.DNAEndsMoveAdjustOffset ||
        underlying_action is actions.DNAEndsMoveStop) {
      store_dna_ends_move.dispatch(action);
    }
  }

  setup_warning_before_unload() {
    window.onBeforeUnload.listen((Event event) {
      if (state.ui_state.warn_on_exit_if_unsaved && state.undo_redo.undo_stack.isNotEmpty) {
        BeforeUnloadEvent e = event;
        e.returnValue = 'You have unsaved work. Are you sure you want to leave?';
      }
    });
  }

  setup_save_design_to_localStorage_before_unload() {
    window.onBeforeUnload.listen((_) {
      if (state.ui_state.local_storage_design_choice.option == LocalStorageDesignOption.on_exit ||
          state.ui_state.local_storage_design_choice.option == LocalStorageDesignOption.periodic) {
        save(state, Storable.design);
      }
    });
  }

  make_dart_functions_available_to_js(AppState state) {
    util.make_dart_function_available_to_js('dart_main_view_pointer_up', main_view_pointer_up);
  }
}

warn_wrong_browser() {
  if (!(browser.isChrome || browser.isFirefox)) {
    var msg = 'You appear to be using ${browser.name}. '
        'scadnano does not currently support this browser. '
        'Please use Chrome or Firefox instead.';
    window.alert(msg);
    print('current browser: ${browser.name}');
  }
}

/// Return null if browser is fine.
String error_message_wrong_browser() {
  String error_message = null;
  if (browser.isSafari) {
    error_message = 'You appear to be using the Safari browser. '
        'scadnano does not currently support Safari. '
        'Please use Chrome or Firefox instead.';
    print(error_message);
  }
  return error_message;
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

setup_save_open_dna_file_keyboard_listeners() {
  document.body.onKeyDown.listen((KeyboardEvent event) {
    int key = event.which;
    // ctrl+S to save
    if ((event.ctrlKey || event.metaKey) && !event.shiftKey && key == KeyCode.S && !event.altKey) {
      event.preventDefault();
      app.dispatch(actions.SaveDNAFile());
    }
    // ctrl+O to load
    if ((event.ctrlKey || event.metaKey) && !event.shiftKey && key == KeyCode.O && !event.altKey) {
      event.preventDefault();
      // TODO(benlee12): maybe this is slightly hacky.
      document.getElementById('open-form-file').click();
    }
  });
}
