import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/strand.dart';

bool are_batch_actions(dynamic action) {
  for (var action in action.actions) {
    if (!((action is actions.SingleStrandAction || action is actions.StrandPartAction))) {
      return false;
    }
  }
  return true;
}

reselected_strands_after_props_updated(Store<AppState> store, action, NextDispatcher next) {
  List<String> prevIds = store.state.ui_state.selectables_store.selected_strands.map((s) => s.id).toList();
  if ((action is actions.ChangePropertiesAction ||
          (action is actions.ChangePropertiesAction &&
              action is actions.BatchAction &&
              are_batch_actions(action))) &&
      prevIds.length > 1) {
    next(action);

    List<Strand> new_strands = [];
    Design newDesign = store.state.design;
    for (var strand in newDesign.strands) {
      if (prevIds.contains(strand.id)) {
        new_strands.add(strand);
      }
    }
    store.dispatch(actions.SelectAll(selectables: new_strands.toBuiltList(), only: true));
  } else {
    next(action);
  }
}
