import 'dart:html';

import 'package:redux/redux.dart';
import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/middleware/edit_select_mode_change.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';
import '../util.dart' as util;

load_file_middleware(Store<AppState> store, action, NextDispatcher next) {
  // We have to distinguish between PrepareToLoadDNAFile and LoadDNAFile because the former ensures the loading dialog will show properly.
  // This is done by *delaying* LoadDNAFile by some milliseconds to allow the loading dialog to be rendered by React before Scadnano does expensive
  // computation relating to loading a new file.
  // Without this delay, Dart tries to load a new design in the same frame it tells React to show the dialog component, thus hanging the frame until
  // the new design is loaded, and the dialog component never shows.
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

    var fn = action.filename;
    if (fn != null) {
      document.title = fn;
    }
    var design_view = app.view.design_view;
    design_view.render(store.state);

    // re-center if necessary
    if (store.state.ui_state.autofit && store.state.maybe_design != null) {
      util.fit_and_center();
    }
    store.dispatch(actions.LoadingDialogHide());
    if (store.state.maybe_design != null) {
      set_selectables_css_style_rules(
          store.state.design, store.state.ui_state.edit_modes, store.state.ui_state.select_mode_state.modes);
    }
  } else {
    next(action);
  }
}
