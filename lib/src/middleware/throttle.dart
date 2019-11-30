
import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../model/model.dart';

// indicates time an action of given type was last dispatched.
final Map<Type,int> _throttled_types = {};

/// Applies [ThrottledAction]s only every [action.interval_sec] seconds and discards the rest.
Model throttle_middleware(Store<Model> store, action, NextDispatcher next) {
  if (action is actions.ThrottledAction) {
    var throttled_action = action.action;
    int last_time = _throttled_types[throttled_action.runtimeType];
    int current_time = DateTime.now().microsecondsSinceEpoch;
    if (last_time == null || (current_time - last_time) / 1e6 >= action.interval_sec) {
      _throttled_types[throttled_action.runtimeType] = current_time;
      next(throttled_action);
    }
  } else {
    next(action);
  }
}