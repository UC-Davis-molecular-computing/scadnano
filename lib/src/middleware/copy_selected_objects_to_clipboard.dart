import 'dart:html';
import 'package:redux/redux.dart';
import 'package:scadnano/src/json_serializable.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

copy_selected_objects_to_clipboard_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.CopySelectedStrandsToClipboard) {
    var clipboard_strings = [];
    for (var item in store.state.ui_state.selectables_store.selected_strands) {
      clipboard_strings.add(json_encode(item));
    }
    window.navigator.clipboard.writeText('[\n${clipboard_strings.join(',\n')}]');
  }
  next(action);
}
