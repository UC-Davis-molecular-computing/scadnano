import 'dart:convert';
//import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/dna_file_type.dart';
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
    switch (action.dna_file_type) {
      case DNAFileType.scadnano_file:
        design_new = Design.from_json_str(action.content, state.ui_state.invert_y);
        break;
      case DNAFileType.cadnano_file:
        design_new = Design.from_cadnano_v2_json_str(action.content, state.ui_state.invert_y);
        break;
    }
  } on IllegalDesignError catch (error, stack_trace) {
    error_message = '''
******************
* illegal design *
******************

The design has the following problem:

${error.cause}
${util.stack_trace_message_bug_report(stack_trace)}''';
  } catch (error, stack_trace) {
    //window.alert('I was unable to process that file. Only scadnano .sc files are supported for opening via the menu File-->Open or dragging onto the browser. If you are trying to import a cadnano file (ending. in .json), use the menu option File-->Import cadnano v2. Here is the full error message:');
    error_message = "I encountered an error while reading the file ${action.filename}:"
        '\n\n$hline'
        '\n* error type:    ${error.runtimeType}'
        '\n* error message: ${error.toString()}'
        '\n$hline'
        '\nIf the file is imported from cadnano, use the option of importing "cadnano v2".'
        '\nTo do this, go to the menu options, then perform Select File --> Import "cadnano v2".'
        '\nImporting a .json file is not allowed when selecting the "Open" option. Use a file with the .sc extension.'
        '\nIt is the same thing for dragging a file into the browser. A .json file will also cause an error, even if it is dragged in.'
        '\nEssentially, for .sc files, you can use the open or drag and drop feature. For .json files, you have to import "cadnano v2".'
        '\n\nThat file\'s contents are printed below.'
        '${util.stack_trace_message_bug_report(stack_trace)}'
        '\n\nThe file ${action.filename} has this content:\n\n${action.content}';
  }

  if (error_message == null && design_new == null) {
    error_message = constants.NO_DESIGN_MESSAGE_HTML;
  }

  AppState new_state;
  if (error_message != null) {
    new_state = state.rebuild((m) => m
      ..undo_redo.replace(UndoRedo())
      ..design = null
      ..ui_state.changed_since_last_save = false
      ..error_message = error_message);
  } else if (design_new != null) {
    BuiltSet<int> side_selected_helix_idxs = BuiltSet<int>();

    // Select helices if "clear helix selection when loading new design" is disabled
    if (!state.ui_state.clear_helix_selection_when_loading_new_design) {
      side_selected_helix_idxs = state.ui_state.side_selected_helix_idxs;

      // remove selected helices from
      if (state.design != null && design_new.helices.length < state.design.helices.length) {
        side_selected_helix_idxs =
            side_selected_helix_idxs.rebuild((s) => s.removeWhere((idx) => idx >= design_new.helices.length));
      }
    }

    var new_selectables_store = SelectablesStore();
    var new_filename = action.filename ?? state.ui_state.loaded_filename;

    // if new design doesn't have same group names, need to pick a new one
    var storables = state.ui_state.storables;
    var displayed_group_name = storables.displayed_group_name;
    if (!design_new.groups.containsKey(displayed_group_name)) {
      storables = storables.rebuild((b) => b..displayed_group_name = design_new.groups.keys.first);
    }

    new_state = state.rebuild((m) => m
      ..undo_redo.replace(UndoRedo())
      ..design = design_new.toBuilder()
      ..ui_state.update((u) => u
        ..storables.replace(storables)
        ..selectables_store.replace(new_selectables_store)
        ..changed_since_last_save = false
        ..storables.loaded_filename = new_filename
        ..storables.side_selected_helix_idxs.replace(side_selected_helix_idxs))
      ..error_message = "");
  } else {
    throw AssertionError("This line should be unreachable");
  }

  return new_state;
}