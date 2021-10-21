import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/reducers/load_design_reducer.dart';
import '../state/selectable.dart';

import '../state/design.dart';
import '../actions/actions.dart' as actions;
import '../state/mouseover_data.dart';
import '../state/app_state.dart';
import '../state/undo_redo.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

var hline = '*' * 100;

AppState load_dna_file_reducer(AppState state, actions.LoadDNAFile action) {
  String error_message;
  Design design_new;

  try {
    design_new = Design.from_json_str(action.content, state.ui_state.invert_xy);
  } on IllegalDesignError catch (error, stack_trace) {
    error_message = ''
        '******************'
        '\n* illegal design *'
        '\n******************'
        '\n\nThe design has the following problem:'
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
        '\n\nThe file ${action.filename} has this content:\n\n${action.content}';
  }

  if (error_message == null && design_new == null) {
    error_message = constants.NO_DESIGN_MESSAGE;
  }

  AppState new_state;
  if (error_message != null) {
    new_state = state.rebuild((m) => m
      ..undo_redo.replace(UndoRedo())
      ..design = null
      ..ui_state.changed_since_last_save = false
      ..error_message = error_message);
  } else if (design_new != null) {
    new_state =  update_design_and_filename(state, design_new, action.filename);
  } else {
    throw AssertionError("This line should be unreachable");
  }

  return new_state;
}
