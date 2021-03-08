import 'dart:html';
import 'package:redux/redux.dart';
import 'package:scadnano/src/json_serializable.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

copy_selected_objects_to_clipboard_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action == actions.CopySelectedStrandsToClipboard) {
    var clipboard_string = '';
    for (var item in store.state.ui_state.selectables_store.selected_strands) {
      clipboard_string += json_encode(item) + '\n';
    }
    window.navigator.clipboard.writeText(clipboard_string);
  }
  next(action);
}
