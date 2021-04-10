import 'dart:html';
import 'package:redux/redux.dart';
import 'package:scadnano/src/json_serializable.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

// For now only handles Strands, but we could potentially handle selected Domains, etc.
copy_selected_object_text_to_system_clipboard_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.CopySelectedObjectTextToSystemClipboard) {
    var clipboard_strings = [];
    for (var item in store.state.ui_state.selectables_store.selected_strands) {
      clipboard_strings.add(json_encode(item));
    }
    window.navigator.clipboard.writeText('[\n${clipboard_strings.join(',\n')}]');
  }
  next(action);
}
