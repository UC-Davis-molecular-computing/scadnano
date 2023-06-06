// @dart=2.9

import 'dart:convert';

import 'package:test/test.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';

import 'package:scadnano/src/state/clipboard.dart';
import 'package:scadnano/src/app.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/app_ui_state.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/undo_redo.dart';
import 'package:scadnano/src/middleware/all_middleware.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

void initializeComponentTests() {
  enableTestMode();
}

Store<AppState> test_store;

void initialize_test_store(AppState state) {
  addTearDown(() {
    test_store = null;
  });

  test_store = Store<AppState>(
    app_state_reducer,
    initialState: state,
    // middleware: all_middleware,
    // we get some error about stylesheets if we include all middleware since unit tests are not running
    // in the browser
  );

  app = App();
  app.store = test_store;
}

AppState test_dispatch(Store<AppState> store, actions.Action action) {
  store.dispatch(action);
  return store.state;
}

/// Returns a [Design] based on JSON string.
Design design_from_string(String str) {
  return Design.from_json(jsonDecode(str));
}

/// Returns an [AppState] based on design.
AppState app_state_from_design(Design design, {bool in_browser = false}) {
  var ui_state = AppUIState.from_design(design);
  var state = (DEFAULT_AppState.toBuilder()
        ..design.replace(design)
        ..ui_state.replace(ui_state)
        ..error_message = ''
        ..editor_content = '')
      .build();
  return state;
}

Color DUMMY_COLOR = Color.rgb(0, 0, 0);

Strand recolor_strand(Strand strand) {
  return strand.rebuild((b) => b.color = DUMMY_COLOR);
}

BuiltList<Strand> recolor_strands(BuiltList<Strand> strands) {
  var strandsBuilder = strands.toBuilder();
  for (int i = 0; i < strands.length; ++i) {
    strandsBuilder[i] = recolor_strand(strands[i]);
  }

  return strandsBuilder.build();
}

/// Checks that two lists of strands contain the same elements.
void expect_strands_equal(BuiltList<Strand> actual_strands, BuiltList<Strand> expected_strands) {
  var actual_recolored_strands = recolor_strands(actual_strands);
  var expected_recolored_strands = recolor_strands(expected_strands);

  // Check hashing for potential quick comparison.
  if (actual_recolored_strands.hashCode != expected_recolored_strands.hashCode) {
    expect(actual_recolored_strands.length, expected_recolored_strands.length);
    for (Strand strand in expected_recolored_strands) {
      if (!actual_recolored_strands.contains(strand)) {
        print("strand ${strand} not found in actual_recolored_strands: ${actual_recolored_strands}");
      }
      expect(actual_recolored_strands.contains(strand), true);
    }
  }
}

/// Checks that two lists of helices contain the same helix (and same order).
void expect_helices_equal(BuiltMap<int, Helix> actual_helices, BuiltMap<int, Helix> expected_helices) {
  // Check hashing for potential quick comparison.
  if (actual_helices.hashCode != expected_helices.hashCode) {
    expect(actual_helices.length, expected_helices.length);
    for (int key in actual_helices.keys) {
      expect(actual_helices[key], expected_helices[key]);
    }
  }
}

/// Asserts that the [actual] matches [matcher] DNADesign.
///
/// This function makes debugging easier by splitting the giant assertion
/// into smaller assertions on individual fields.
void expect_design_equal(Design actual, Design matcher) {
  expect_helices_equal(actual.helices, matcher.helices);
  expect_strands_equal(actual.strands, matcher.strands);
  expect(actual.is_origami, matcher.is_origami);
}

/// Asserts that the [actual] matches [matcher] AppUIState.
void expect_ui_state_equal(AppUIState actual, AppUIState matcher) {
  // Not neccessary to split assertion at the moment.
  expect(actual, matcher);
}

/// Asserts that [actual] stack matches [matcher] stack.
void expect_stack_equal(BuiltList<UndoRedoItem> actual, BuiltList<UndoRedoItem> matcher) {
  expect(actual.length, matcher.length);

  for (int i = 0; i < actual.length; ++i) {
    expect_design_equal(actual[i].design, matcher[i].design);
  }
}

/// Asserts that the [actual] matches [matcher] UndoRedo.
void expect_undo_redo_equal(UndoRedo actual, UndoRedo matcher) {
  expect_stack_equal(actual.undo_stack, matcher.undo_stack);
  expect_stack_equal(actual.redo_stack, matcher.redo_stack);
}

Store<AppState> store_from_design(Design design, {bool initialize_app_instance = false}) {
  var state = app_state_from_design(design);
  var store = Store<AppState>(app_state_reducer, initialState: state, middleware: all_middleware);
  if (initialize_app_instance) {
    app.store = store;
  }
  return store;
}

void sleep_in_browser(Duration duration) {
  var ms = duration.inMilliseconds;
  var start = new DateTime.now().millisecondsSinceEpoch;
  while (true) {
    var current = new DateTime.now().millisecondsSinceEpoch;
    if (current - start >= ms) {
      break;
    }
  }
}
