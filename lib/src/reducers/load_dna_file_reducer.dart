import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/selectable.dart';

import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../state/undo_redo.dart';
import '../constants.dart' as constants;

var hline = '*' * 100;

String _stack_trace_message(stack_trace) {
  return '\n'
      '\n**********************************************************************************'
      '\n* If you believe this is due to a bug in scadnano, please file a bug report at   *'
      '\n*   ${constants.BUG_REPORT_URL}${' ' * (77 - constants.BUG_REPORT_URL.length)}*'
      '\n* Include this entire message in the email.                                      *'
      '\n**********************************************************************************'
      '\n\nstack trace:'
      '\n${stack_trace}';
}

AppState load_dna_file_reducer(AppState state, actions.LoadDNAFile action) {
  Map<String, dynamic> map;
  String error_message;
  DNADesign dna_design_new;

  try {
    map = jsonDecode(action.content);
    dna_design_new = DNADesign.from_json(map);
  } on IllegalDNADesignError catch (error, stack_trace) {
    error_message = ''
        '**********************'
        '\n* illegal DNA design *'
        '\n**********************'
        '\n\nThe DNA design has the following problem:'
        '\n\n${error.cause}'
        '${_stack_trace_message(stack_trace)}';
  } catch (error, stack_trace) {
    error_message = "I encountered an error while reading the file ${action.filename}:"
        '\n\n$hline'
        '\n* error type:    ${error.runtimeType}'
        '\n* error message: ${error.toString()}'
        '\n$hline'
        '\n\nThat file has this content:\n\n${action.content}'
        '${_stack_trace_message(stack_trace)}';
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
        ..loaded_filename = new_filename
        ..side_selected_helix_idxs.replace(side_selected_helix_idxs))
      ..error_message = "");
  } else {
    throw AssertionError("This line should be unreachable");
  }

  return new_state;
}
