import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

strand_create_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.StrandCreateStart) {
    if (store.state.design.is_occupied(action.address)) {
      return;
    }
  }
  next(action);
}