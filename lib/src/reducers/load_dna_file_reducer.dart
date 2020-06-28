import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/selectable.dart';

import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../state/undo_redo.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

var hline = '*' * 100;

AppState load_dna_file_reducer(AppState state, actions.LoadDNAFile action) {
  Map<String, dynamic> map;
  String error_message;
  DNADesign dna_design_new;

  try {
    map = jsonDecode(action.content);
    bool invert_y_axis = state.ui_state.invert_y_axis;
    dna_design_new = DNADesign.from_json(map, invert_y_axis);
  } on IllegalDNADesignError catch (error, stack_trace) {
    error_message = ''
        '**********************'
        '\n* illegal DNA design *'
        '\n**********************'
        '\n\nThe DNA design has the following problem:'
        '\n\n${error.cause}'
        '${util.stack_trace_message_bug_report(stack_trace)}';
  } catch (error, stack_trace) {
    error_message = "I encountered an error while reading the file ${action.filename}:"
        '\n\n$hline'
        '\n* error type:    ${error.runtimeType}'
        '\n* error message: ${error.toString()}'
        '\n$hline'
        '\n\nThat file\'s contents are printed below.'
        '${util.stack_trace_message_bug_report(stack_trace)}'
        '\n\nThe file ${action.filename} has this content:\n\n${action.content}'
    ;
  }

  if (error_message == null && dna_design_new == null) {
    error_message = constants.NO_DNA_DESIGN_MESSAGE;
  }

  AppState new_state;
  if (error_message != null) {
    new_state = state.rebuild((m) => m
      ..undo_redo.replace(UndoRedo())
      ..dna_design = null
      ..ui_state.changed_since_last_save = false
      ..error_message = error_message);
  } else if (dna_design_new != null) {
    // remove selected helices from
    BuiltSet<int> side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs;
    if (state.dna_design != null && dna_design_new.helices.length < state.dna_design.helices.length) {
      side_selected_helix_idxs = side_selected_helix_idxs
          .rebuild((s) => s.removeWhere((idx) => idx >= dna_design_new.helices.length));
    }
    var new_selectables_store = SelectablesStore();
//    new_selectables_store = new_selectables_store.register_dna_design(dna_design_new);
    var new_filename = action.filename ?? state.ui_state.loaded_filename;
    new_state = state.rebuild((m) => m
      ..undo_redo.replace(UndoRedo())
      ..dna_design = dna_design_new.toBuilder()
      ..ui_state.update((u) => u
        ..selectables_store.replace(new_selectables_store)
        ..changed_since_last_save = false
        ..storables.loaded_filename = new_filename
        ..side_selected_helix_idxs.replace(side_selected_helix_idxs))
      ..error_message = "");
  } else {
    throw AssertionError("This line should be unreachable");
  }

  return new_state;
}
