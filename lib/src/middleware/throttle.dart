
import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../model/model.dart';

// indicates time an action of given type was last dispatched.
final Map<Type,int> _throttled_types = {};

var throttle_typed_middleware = TypedMiddleware<Model, actions.ThrottledAction>(throttle_middleware);

Model throttle_middleware(Store<Model> store, dynamic action, NextDispatcher next) {
  if (action is actions.ThrottledAction) {
    var throttled_action = action.action;
    int last_time = _throttled_types[throttled_action.runtimeType];
    int current_time = DateTime.now().millisecondsSinceEpoch;
    if (last_time == null || (current_time - last_time) / 1000.0 >= action.interval_sec) {
      _throttled_types[throttled_action.runtimeType] = current_time;
//      print('allowing action through at time      $current_time');
      next(throttled_action);
    } else {
      print('action happened too recently at time $last_time; current time is $current_time');
    }
  } else {
    next(action);
  }
}