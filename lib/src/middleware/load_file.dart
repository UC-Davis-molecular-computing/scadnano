import 'dart:html';

import 'package:quiver/async.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/actions/actions.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';
import '../util.dart' as util;

load_file_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.PrepareToLoadDNAFile && !action.unit_testing) {
    store.dispatch(actions.LoadingDialogShow());
    Future.delayed(
        const Duration(milliseconds: 50),
        () => store.dispatch(actions.LoadDNAFile(
              content: action.content,
              filename: action.filename,
              write_local_storage: action.write_local_storage,
              unit_testing: action.unit_testing,
              dna_file_type: action.dna_file_type,
            )));
  } else if (action is actions.LoadDNAFile && !action.unit_testing) {
    next(action);

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
  } else {
    next(action);
  }
}
