import 'dart:html';

import 'package:quiver/async.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/actions/actions.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';
import '../util.dart' as util;

load_file_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.LoadDNAFile && !action.unit_testing) {
    store.dispatch(actions.LoadingDialogShow());
    var design_view = app?.view?.design_view;
    if (design_view != null) {
      design_view.render_loading_dialog();
    }
    print("Loading");
  }
  next(action);

  if (action is actions.LoadDNAFile && !action.unit_testing) {
    document.title = action.filename;
    var design_view = app?.view?.design_view;
    if (design_view != null) {
      design_view.render(store.state);
    }

    // re-center if necessary
    if (store.state.ui_state.autofit && store.state.design != null) {
      util.fit_and_center();
    }
    store.dispatch(actions.LoadingDialogHide());
    print("Not Loading");
  }
}
