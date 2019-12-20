import 'package:redux/redux.dart';

import 'package:scadnano/src/state/edit_mode.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../state/app_state.dart';

/// If mode contains "move", allow panning with mouse click and drag, otherwise not.
/// This is a side effect since it involves using JS global variables to talk to the SVG pan zoom library
/// that is external to React and the Redux store.
edit_mode_allow_pan_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);
  if (action is actions.EditModesSet || action is actions.EditModeToggle) {
    bool allow_pan = store.state.ui_state.edit_modes.contains(EditModeChoice.scroll);
    util.set_allow_pan(allow_pan);
  }
}