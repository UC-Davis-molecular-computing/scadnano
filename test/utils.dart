import 'dart:convert';

import 'package:test/test.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react_client.dart';
import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';

import 'package:scadnano/src/app.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/app_ui_state.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/undo_redo.dart';
import 'package:scadnano/src/middleware/all_middleware.dart';

void initializeComponentTests() {
  setClientConfiguration();
  enableTestMode();
}

Store<AppState> testStore;

void initializeTestStore(AppState state) {
  addTearDown(() {
    testStore = null;
  });

  testStore = Store<AppState>(
    app_state_reducer,
    initialState: state,
  );

  app.store = testStore;
}

/// Returns an [DNADesign] based on json string.
DNADesign dna_design_from_string(String str) {
  return DNADesign.from_json(jsonDecode(str));
}

/// Returns an [AppState] based on dna design.
AppState app_state_from_dna_design(DNADesign dna_design) {
  var ui_state = AppUIState.from_dna_design(dna_design);
  var state = (DEFAULT_AppStateBuilder
        ..dna_design.replace(dna_design)
        ..ui_state.replace(ui_state)
        ..error_message = ''
        ..editor_content = '')
      .build();
  return state;
}

/// Returns an [AppState] based on dna_design_json
/// and initial DNA design state. This is used to generate
/// expected app states by adding the initial action to
/// the undo stack as well as changing changed_since_last_save
/// to true.
AppState expected_state_from_json_string(String dna_design_json, DNADesign initial_design) {
  return app_state_from_dna_design(DNADesign.from_json(json.decode(dna_design_json))).rebuild((b) => b
    ..undo_redo.undo_stack.add(initial_design)
    ..ui_state.changed_since_last_save = true);
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
void expect_dna_design_equal(DNADesign actual, DNADesign matcher) {
  expect(actual.version, matcher.version);
  expect(actual.grid, matcher.grid);
  expect(actual.major_tick_distance, matcher.major_tick_distance);
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
void expect_stack_equal(BuiltList<DNADesign> actual, BuiltList<DNADesign> matcher) {
  expect(actual.length, matcher.length);

  for (int i = 0; i < actual.length; ++i) {
    expect_dna_design_equal(actual[i], matcher[i]);
  }
}

/// Asserts that the [actual] matches [matcher] UndoRedo.
void expect_undo_redo_equal(UndoRedo actual, UndoRedo matcher) {
  expect_stack_equal(actual.undo_stack, matcher.undo_stack);
  expect_stack_equal(actual.redo_stack, matcher.redo_stack);
}

/// Asserts that the [actual] matches [matcher] AppState.
///
/// This function makes debugging easier by splitting the giant assertion
/// into smaller assertions on individual fields.
void expect_app_state_equal(AppState actual, AppState matcher) {
  expect_dna_design_equal(actual.dna_design, matcher.dna_design);
  expect_ui_state_equal(actual.ui_state, matcher.ui_state);
  expect_undo_redo_equal(actual.undo_redo, matcher.undo_redo);
  expect(actual.error_message, matcher.error_message);
  expect(actual.editor_content, matcher.editor_content);
}

Store<AppState> store_from_dna_design(DNADesign dna_design) {
  var state = app_state_from_dna_design(dna_design);
  var store = Store<AppState>(app_state_reducer, initialState: state, middleware: all_middleware);
  app.store = store;
  return store;
}
