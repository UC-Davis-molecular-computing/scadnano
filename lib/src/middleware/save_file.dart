import 'dart:html';

import 'package:redux/redux.dart';

import '../json_serializable.dart';
import '../actions/actions.dart' as actions;
import '../model/app_state.dart';
import '../util.dart' as util;

AppState save_file_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);

  AppState model = store.state;
  if (action is actions.SaveDNAFile) {
    String content = json_encode(model.dna_design);
    String default_filename = model.ui_state.loaded_filename;
    util.save_file(default_filename, content);
    change_tab_title(false);
  } else if (action is actions.UndoableAction) {
    change_tab_title(true);
  } else if (action is actions.Undo || action is actions.Redo) {
    bool changed_since_last_save = model.undo_redo.undo_stack.isNotEmpty;
    change_tab_title(changed_since_last_save);
  }
}

// puts * in front of filename in tab title if unsaved changes are present
change_tab_title(bool changed_since_last_save) {
  if (changed_since_last_save && !document.title.startsWith('*')) {
    document.title = '*' + document.title;
  } else if (!changed_since_last_save && document.title.startsWith('*')) {
    document.title = document.title.substring(1);
  }
}
