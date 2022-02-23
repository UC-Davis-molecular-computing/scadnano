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
  if (state.undo_redo.undo_stack.isEmpty) {
    return state;
  }
  return state_result_after_applying_undo(state, action);
}

AppState state_result_after_applying_undo(AppState state, actions.Undo action) {
  Design design_cur = state.design;
  UndoRedo undo_redo = state.undo_redo;
  ListBuilder<UndoRedoItem> undo_stack = undo_redo.undo_stack.toBuilder();
  ListBuilder<UndoRedoItem> redo_stack = undo_redo.redo_stack.toBuilder();
  for (int i = 0; i < action.num_undos; i++) {
    design_cur = push_current_design_to_redo_and_pop_design_from_undo(undo_stack, redo_stack, design_cur);
  }
  return create_new_state_with_new_design_and_undo_redo(state, design_cur, undo_stack, redo_stack);
}

AppState create_new_state_with_new_design_and_undo_redo(AppState old_state, Design new_design,
    ListBuilder<UndoRedoItem> new_undo_stack, ListBuilder<UndoRedoItem> new_redo_stack) {
  bool changed_since_last_save = new_undo_stack.isNotEmpty;

  AppState new_model = old_state.rebuild((m) => m
    ..ui_state
        .replace(old_state.ui_state.rebuild((u) => u..changed_since_last_save = changed_since_last_save))
    ..design.replace(new_design)
    ..undo_redo.replace(old_state.undo_redo.rebuild((u) => u
      ..undo_stack = new_undo_stack
      ..redo_stack = new_redo_stack)));
  return new_model;
}

Design push_current_design_to_redo_and_pop_design_from_undo(
    ListBuilder<UndoRedoItem> undo_stack, ListBuilder<UndoRedoItem> redo_stack, Design current_design) {
  UndoRedoItem undo_redo_item_prev = undo_stack.removeLast();
  String short_description_prev = undo_redo_item_prev.short_description;
  redo_stack.add(new UndoRedoItem(short_description_prev, current_design));
  return undo_redo_item_prev.design;
}

AppState redo_reducer(AppState state, actions.Redo action) {
  UndoRedo undo_redo = state.undo_redo;
  if (undo_redo.redo_stack.isEmpty) {
    return state;
  } else {
    Design design_cur = state.design;
    ListBuilder<UndoRedoItem> undo_stack = undo_redo.undo_stack.toBuilder();
    ListBuilder<UndoRedoItem> redo_stack = undo_redo.redo_stack.toBuilder();

    UndoRedoItem undo_redo_item_next = redo_stack.removeLast();
    Design design_next = undo_redo_item_next.design;
    String short_description_next = undo_redo_item_next.short_description;
    undo_stack.add(new UndoRedoItem(short_description_next, design_cur));

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
        ..undo_stack.add(new UndoRedoItem(action.short_description(), state.design))
        ..redo_stack.clear())));
