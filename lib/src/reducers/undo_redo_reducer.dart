import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/copy_info.dart';

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
  Design new_design = state.design;
  UndoRedo undo_redo = state.undo_redo;
  CopyInfo copy_info = state.ui_state.copy_info;
  print('copy info' + copy_info.toString());
  
  Map<String, dynamic> new_design_copy_info = {
    'design' : new_design,
    'copy_info' : copy_info
  };

  ListBuilder<UndoRedoItem> undo_stack = undo_redo.undo_stack.toBuilder();
  ListBuilder<UndoRedoItem> redo_stack = undo_redo.redo_stack.toBuilder();
  for (int i = 0; i < action.num_undos; i++) {
    //new_design = push_design_to_stack_and_pop_design_from_other_stack(new_design, copy_info, redo_stack, undo_stack);
    new_design_copy_info = push_design_copy_to_stack_and_pop_design_from_other_stack(new_design, copy_info, redo_stack, undo_stack);
  }
  //return create_new_state_with_new_design_and_undo_redo(state, new_design, copy_info, undo_stack, redo_stack);
  return create_new_state_with_new_design_and_undo_redo(state, new_design_copy_info['design'], new_design_copy_info['copy_info'], undo_stack, redo_stack);
}

AppState create_new_state_with_new_design_and_undo_redo(AppState old_state, Design new_design, CopyInfo copy_info,
    ListBuilder<UndoRedoItem> new_undo_stack, ListBuilder<UndoRedoItem> new_redo_stack) {
  bool changed_since_last_save = new_undo_stack.isNotEmpty;

  AppState new_model = old_state.rebuild((m) => m
    ..ui_state
        .replace(old_state.ui_state.rebuild((u) => u
          ..changed_since_last_save = changed_since_last_save
          ..copy_info.replace(copy_info)))
    ..design.replace(new_design)
    ..undo_redo.replace(old_state.undo_redo.rebuild((u) => u
      ..undo_stack = new_undo_stack
      ..redo_stack = new_redo_stack)));
  return new_model;
}

AppState redo_reducer(AppState state, actions.Redo action) {
  UndoRedo undo_redo = state.undo_redo;
  if (undo_redo.redo_stack.isEmpty) {
    return state;
  } else {
    Design new_design = state.design;
    CopyInfo copy_info = state.ui_state.copy_info;

  Map<String, dynamic> new_design_copy_info = {
    'design' : new_design,
    'copy_info' : copy_info
  };

    ListBuilder<UndoRedoItem> undo_stack = undo_redo.undo_stack.toBuilder();
    ListBuilder<UndoRedoItem> redo_stack = undo_redo.redo_stack.toBuilder();

    for (int i = 0; i < action.num_redos; i++) {
      //new_design = push_design_to_stack_and_pop_design_from_other_stack(new_design, copy_info, undo_stack, redo_stack);
      new_design_copy_info = push_design_copy_to_stack_and_pop_design_from_other_stack(new_design, copy_info, redo_stack, undo_stack);
    }

    bool changed_since_last_save = undo_stack.isNotEmpty;

    AppState new_model = state.rebuild((m) => m
      ..ui_state.replace(state.ui_state.rebuild((u) => u
        ..changed_since_last_save = changed_since_last_save
        // ..copy_info.replace(copy_info)))
        ..copy_info.replace(new_design_copy_info['copy_info'])))
      // ..design.replace(new_design)
      ..design.replace(new_design_copy_info['design'])
      ..undo_redo.replace(undo_redo.rebuild((u) => u
        ..undo_stack = undo_stack
        ..redo_stack = redo_stack)));

    return new_model;
  }
}

Design push_design_to_stack_and_pop_design_from_other_stack(Design design_to_push, CopyInfo copy_info,
    ListBuilder<UndoRedoItem> stack_to_push_to, ListBuilder<UndoRedoItem> stack_to_pop_from) {
  UndoRedoItem popped_item = stack_to_pop_from.removeLast();
  String popped_short_description = popped_item.short_description;
  stack_to_push_to.add(new UndoRedoItem(popped_short_description, design_to_push, copy_info));
  return popped_item.design;
}

Map push_design_copy_to_stack_and_pop_design_from_other_stack(Design design_to_push, CopyInfo copy_info,
    ListBuilder<UndoRedoItem> stack_to_push_to, ListBuilder<UndoRedoItem> stack_to_pop_from) {
  UndoRedoItem popped_item = stack_to_pop_from.removeLast();
  String popped_short_description = popped_item.short_description;
  stack_to_push_to.add(new UndoRedoItem(popped_short_description, design_to_push, copy_info));

  Map<String, dynamic> design_copy_info = {
    'design': popped_item.design,
    'copy_info': popped_item.copy_info
  };
  return design_copy_info;
}

AppState undo_redo_clear_reducer(AppState state, actions.UndoRedoClear action) =>
    state.rebuild((m) => m..undo_redo.replace(UndoRedo()));

AppState undoable_action_typed_reducer(AppState state, actions.UndoableAction action) =>
    state.rebuild((m) => m
      ..undo_redo.replace(state.undo_redo.rebuild((u) => u
        ..undo_stack.add(new UndoRedoItem(action.short_description(), state.design, state.ui_state.copy_info))
        ..redo_stack.clear())));
