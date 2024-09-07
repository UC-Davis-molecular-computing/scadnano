import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';
import '../util.dart' as util;

example_design_selected_middleware(Store<AppState> store, action, NextDispatcher next) {
  next(action);
  if (action is actions.ExampleDesignsLoad) {
    var example_designs = store.state.ui_state.example_designs;
    String url = example_designs.url;
    String filename = example_designs.selected_filename;
    _get_file_content_and_dispatch_load(store, url, filename);
  }
}

_get_file_content_and_dispatch_load(Store<AppState> store, String url, String filename) async {
  String content = await util.get_text_file_content(url);
  store.dispatch(actions.PrepareToLoadDNAFile(content: content, filename: filename));
}
