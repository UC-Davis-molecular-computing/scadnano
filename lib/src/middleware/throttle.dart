
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/selection_box.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

// indicates time an action of given type was last dispatched.
final Map<Type,int> _throttled_types = {};

//const _DEBUG = true;
const _DEBUG = false;

/// Applies [ThrottledAction]s only every [action.interval_sec] seconds and discards the rest.
throttle_middleware_app_state(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.ThrottledAction) {
    var throttled_action = action.action;
    int last_time = _throttled_types[throttled_action.runtimeType];
    int current_time = DateTime.now().microsecondsSinceEpoch;
    if (last_time == null || (current_time - last_time) / 1e6 >= action.interval_sec) {
      _throttled_types[throttled_action.runtimeType] = current_time;
      next(throttled_action);
      if (_DEBUG) {
        print('throttle allowed action');
      }
    } else if (_DEBUG) {
      print('throttle blocked action');
    }
  } else {
    next(action);
  }
}

/// Applies [ThrottledAction]s only every [action.interval_sec] seconds and discards the rest.
throttle_middleware_selection_box(Store<SelectionBox> store, action, NextDispatcher next) {
  if (action is actions.ThrottledAction) {
    var throttled_action = action.action;
    int last_time = _throttled_types[throttled_action.runtimeType];
    int current_time = DateTime.now().microsecondsSinceEpoch;
    if (last_time == null || (current_time - last_time) / 1e6 >= action.interval_sec) {
      _throttled_types[throttled_action.runtimeType] = current_time;
      next(throttled_action);
      if (_DEBUG) {
        print('throttle allowed action');
      }
    } else if (_DEBUG) {
      print('throttle blocked action');
    }
  } else {
    next(action);
  }
}