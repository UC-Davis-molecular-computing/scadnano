import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../model/model.dart';

/// Taken from https://github.com/brianegan/redux_thunk/blob/master/lib/redux_thunk.dart
/// The generics used there didn't work for me for some reason, so I copied the code and hard-coded it to use
/// [Model] instead of a generic State.

typedef void ThunkAction(Store<Model> store);

void thunk_middleware(
    Store<Model> store,
    dynamic action,
    NextDispatcher next,
    ) {
  if (action is ThunkAction) {
    action(store);
  } else {
    next(action);
  }
}

