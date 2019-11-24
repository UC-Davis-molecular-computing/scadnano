import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';

import '../model/dna_design.dart';
import '../model/undo_redo.dart';
import '../model/model.dart';
import '../actions/actions.dart' as actions;
import 'util_reducer.dart';

Reducer<Model> undo_redo_reducer = combineReducers([
  TypedReducer<Model, actions.Undo>(undo_reducer),
  TypedReducer<Model, actions.Redo>(redo_reducer),
  TypedReducer<Model, actions.UndoRedoClear>(undo_redo_clear_reducer),
  TypedReducer<Model, actions.UndoableAction>(undo_redo_undoable_action_reducer),
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

    //XXX: I shouldn't be doing a side effect here, but this is easier to check for than in middleware
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

Model undo_redo_undoable_action_reducer(Model model, actions.UndoableAction action) {
  print('undo_redo pushing to undo stack');
  UndoRedo undo_redo = model.undo_redo;
  return model.rebuild((m) => m
    ..undo_redo.replace(undo_redo.rebuild((u) => u
      ..undo_stack.add(model.dna_design)
      ..redo_stack.clear())));
}

//=>
//    undo_redo.rebuild((u) => u
//      ..undo_stack.add(model.dna_design)
//      ..redo_stack.clear());

//  apply(ReversibleActionPack action) {
//    if (!app.model.ui_model.changed_since_last_save) {
//      //FIXME: send an action to update this bool
//      //app.model.changed_since_last_save = true;
//    }
//    action.apply();
//    redo_stack.clear();
//    undo_stack.add(action);
//  }
//
//  undo() {
//    if (undo_stack.isNotEmpty) {
//      var most_recent_action = undo_stack.removeLast();
//      var reverse_action = most_recent_action.reverse();
//      reverse_action.apply();
//      redo_stack.add(most_recent_action);
//      if (undo_stack.isEmpty) {
//        if (!app.model.ui_model.changed_since_last_save) {
//          //FIXME: send action
////          app.model.changed_since_last_save = true;
//        }
//      }
//    }
//  }
//
//  redo() {
//    if (redo_stack.isNotEmpty) {
//      if (app.model.ui_model.changed_since_last_save) {
//        //FIXME: send action
////        app.model.changed_since_last_save = false;
//      }
//      var action_to_redo = redo_stack.removeLast();
//      action_to_redo.apply();
//      undo_stack.add(action_to_redo);
//    }
//  }
