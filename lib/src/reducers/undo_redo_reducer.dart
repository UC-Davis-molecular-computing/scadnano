import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/reducers/model_reducer.dart';

import '../app.dart';
import '../model/dna_design.dart';
import '../model/undo_redo.dart';
import '../model/model.dart';
import '../actions/actions.dart' as actions;
import 'util_reducer.dart';

// These involve direct manipulation of the undo/redo stacks.
Reducer<Model> undo_redo_reducer = combineReducers([
  TypedReducer<Model, actions.Undo>(undo_reducer),
  TypedReducer<Model, actions.Redo>(redo_reducer),
  TypedReducer<Model, actions.UndoRedoClear>(undo_redo_clear_reducer),
]);

// This logs Undoable actions on the undo stack.
Reducer<Model> undoable_action_reducer = combineReducers([
  TypedReducer<Model, actions.UndoableAction>(undoable_action_typed_reducer),
]);

Model undo_reducer(Model model, actions.Undo action) {
  UndoRedo undo_redo = model.undo_redo;
  if (undo_redo.undo_stack.isEmpty) {
    return model;
  } else {
    DNADesign dna_design_curr = model.dna_design;
    ListBuilder<DNADesign> undo_stack = undo_redo.undo_stack.toBuilder();
    ListBuilder<DNADesign> redo_stack = undo_redo.redo_stack.toBuilder();

    DNADesign dna_design_prev = undo_stack.removeLast();
    redo_stack.add(dna_design_curr);

    bool changed_since_last_save = undo_stack.isNotEmpty;

    Model new_model = model.rebuild((m) => m
      ..ui_model.replace(model.ui_model.rebuild((u) => u..changed_since_last_save = changed_since_last_save))
      ..dna_design.replace(dna_design_prev)
      ..undo_redo.replace(undo_redo.rebuild((u) => u
        ..undo_stack = undo_stack
        ..redo_stack = redo_stack)));

    return new_model;
  }
}

Model redo_reducer(Model model, actions.Redo action) {
  UndoRedo undo_redo = model.undo_redo;
  if (undo_redo.redo_stack.isEmpty) {
    return model;
  } else {
    DNADesign dna_design_curr = model.dna_design;
    ListBuilder<DNADesign> undo_stack = undo_redo.undo_stack.toBuilder();
    ListBuilder<DNADesign> redo_stack = undo_redo.redo_stack.toBuilder();

    DNADesign dna_design_next = redo_stack.removeLast();
    undo_stack.add(dna_design_curr);

    bool changed_since_last_save = undo_stack.isNotEmpty;

    Model new_model = model.rebuild((m) => m
      ..ui_model.replace(model.ui_model.rebuild((u) => u..changed_since_last_save = changed_since_last_save))
      ..dna_design.replace(dna_design_next)
      ..undo_redo.replace(undo_redo.rebuild((u) => u
        ..undo_stack = undo_stack
        ..redo_stack = redo_stack)));

    return new_model;
  }
}

Model undo_redo_clear_reducer(Model model, actions.UndoRedoClear action) =>
    model.rebuild((m) => m..undo_redo.replace(UndoRedo()));

Model undoable_action_typed_reducer(Model model, actions.UndoableAction action) =>
  model.rebuild((m) => m
    ..undo_redo.replace(model.undo_redo.rebuild((u) => u
      ..undo_stack.add(model.dna_design)
      ..redo_stack.clear())));
