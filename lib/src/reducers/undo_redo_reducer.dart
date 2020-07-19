
import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';

import '../state/design.dart';
import '../state/undo_redo.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;

// These involve direct manipulation of the undo/redo stacks.
Reducer<AppState> undo_redo_reducer = combineReducers([
  TypedReducer<AppState, actions.Undo>(undo_reducer),
  TypedReducer<AppState, actions.Redo>(redo_reducer),
  TypedReducer<AppState, actions.UndoRedoClear>(undo_redo_clear_reducer),
]);

// This logs Undoable actions on the undo stack.
Reducer<AppState> undoable_action_reducer = combineReducers([
  TypedReducer<AppState, actions.UndoableAction>(undoable_action_typed_reducer),
]);

AppState undo_reducer(AppState state, actions.Undo action) {
  UndoRedo undo_redo = state.undo_redo;
  if (undo_redo.undo_stack.isEmpty) {
    return state;
  } else {
    Design design_cur = state.design;
    ListBuilder<Design> undo_stack = undo_redo.undo_stack.toBuilder();
    ListBuilder<Design> redo_stack = undo_redo.redo_stack.toBuilder();

    Design design_prev = undo_stack.removeLast();
    redo_stack.add(design_cur);

    bool changed_since_last_save = undo_stack.isNotEmpty;

    AppState new_model = state.rebuild((m) => m
      ..ui_state.replace(state.ui_state.rebuild((u) => u..changed_since_last_save = changed_since_last_save))
      ..design.replace(design_prev)
      ..undo_redo.replace(undo_redo.rebuild((u) => u
        ..undo_stack = undo_stack
        ..redo_stack = redo_stack)));

    return new_model;
  }
}

AppState redo_reducer(AppState state, actions.Redo action) {
  UndoRedo undo_redo = state.undo_redo;
  if (undo_redo.redo_stack.isEmpty) {
    return state;
  } else {
    Design design_cur = state.design;
    ListBuilder<Design> undo_stack = undo_redo.undo_stack.toBuilder();
    ListBuilder<Design> redo_stack = undo_redo.redo_stack.toBuilder();

    Design design_next = redo_stack.removeLast();
    undo_stack.add(design_cur);

    bool changed_since_last_save = undo_stack.isNotEmpty;

    AppState new_model = state.rebuild((m) => m
      ..ui_state.replace(state.ui_state.rebuild((u) => u..changed_since_last_save = changed_since_last_save))
      ..design.replace(design_next)
      ..undo_redo.replace(undo_redo.rebuild((u) => u
        ..undo_stack = undo_stack
        ..redo_stack = redo_stack)));

    return new_model;
  }
}

AppState undo_redo_clear_reducer(AppState state, actions.UndoRedoClear action) =>
    state.rebuild((m) => m..undo_redo.replace(UndoRedo()));

AppState undoable_action_typed_reducer(AppState state, actions.UndoableAction action) =>
  state.rebuild((m) => m
    ..undo_redo.replace(state.undo_redo.rebuild((u) => u
      ..undo_stack.add(state.design)
      ..redo_stack.clear())));
