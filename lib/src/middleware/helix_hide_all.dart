import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../util.dart' as util;

/// Check whether all helices are about to be hidden (assuming there are any helices in the design)
/// and warn user this might not be what they want.
helix_hide_all_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);

  if ((action is actions.SetOnlyDisplaySelectedHelices ||
          action is actions.HelixSelect ||
          action is actions.HelixSelectionsAdjust ||
          action is actions.HelixSelectionsClear ||
          action is actions.HelixRemoveAllSelected ||
          action is actions.HelixRemove ||
          action is actions.LoadDNAFile ||
          action is actions.SetAppUIStateStorable) &&
      !store.state.has_error) {
    var ui_state = store.state.ui_state;
    var design = store.state.design;
    if (ui_state.only_display_selected_helices &&
        ui_state.side_selected_helix_idxs.isEmpty &&
        design.helices.isNotEmpty) {
      var msg =
          'The option "Display only selected helices" is enabled. '
          'Since no helices are selected, none will be displayed in the main view.\n\n'
          'To display the helices, either select some helices in the side view, or disable the option '
          '"View-->Helices-->Display only selected helices".';
      util.async_alert(msg);
    }
  }
}
