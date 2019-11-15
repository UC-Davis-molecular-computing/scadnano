import 'dart:convert';

import 'package:redux/redux.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/constants.dart';
import 'package:scadnano/src/model/dna_design.dart';
import 'package:scadnano/src/model/ui_model.dart';

import '../app.dart';
import '../json_serializable.dart';
import 'actions.dart' as actions;
import '../model/model.dart';
import '../model/select_mode_state.dart';
import 'local_storage.dart' as local_storage;
import '../util.dart' as util;

Model model_reducer([Model model, action]) {
  // we make a special case for this since it's the only Action with a wholesale changeout of the Model
  if (action is actions.LoadDNAFile) {
    return load_dna_file_reducer(model, action);
  } else if (action is actions.SaveDNAFile) {
    return save_dna_file_reducer(model, action);
  }

  Model new_model = model.rebuild((m) => m
    ..dna_design = dna_design_reducer(model.dna_design, action)?.toBuilder()
    ..ui_model = ui_model_reducer(model.ui_model, action).toBuilder()
    ..error_message = error_message_reducer(model.error_message, action)
    ..editor_content = editor_content_reducer(model.editor_content, action));

  if (new_model == null) {
    // this is a check on myself since null is implicitly returned when there is no return statement
    throw ArgumentError('reducer returned a null model, which is disallowed');
  }
  return new_model;
}

Model load_dna_file_reducer(Model model, actions.LoadDNAFile action) {
  Map<String, dynamic> map = jsonDecode(action.content);
  DNADesign dna_design;
  String error_message;
  try {
    dna_design = DNADesign.from_json(map);
  } on IllegalDNADesignError catch (error) {
    error_message = error.cause;
  }

  Model new_model;
  if (error_message != null) {
    new_model = model.rebuild((m) => m
      ..dna_design = null
      ..ui_model.changed_since_last_save = false
      ..error_message = error_message);
  } else if (dna_design != null) {
    new_model = model.rebuild((m) => m
      ..dna_design = dna_design.toBuilder()
      ..ui_model.update((u) => u
        ..changed_since_last_save = false
        ..loaded_filename = action.filename)
      ..error_message = "");
  } else {
    throw AssertionError("This line should be unreachable");
  }

  app.undo_redo.reset();
  app.view.design_view.render(new_model);

  return new_model;
}

Model save_dna_file_reducer(Model model, actions.SaveDNAFile action) {
  String content = json_encode(model.dna_design);
  String default_filename = model.ui_model.loaded_filename;
  util.save_file(default_filename, content);
  return model.rebuild((m) => m..ui_model.changed_since_last_save = false);
}

String error_message_reducer([String error_message, action]) {
  if (action is actions.ErrorMessageSet) {
    return action.error_message;
  } else {
    return error_message;
  }
}

String editor_content_reducer([String editor_content, action]) {
  return editor_content;
}
