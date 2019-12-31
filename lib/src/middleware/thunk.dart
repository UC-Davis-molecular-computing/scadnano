import 'package:redux/redux.dart';

import '../state/app_state.dart';

/// Taken from https://github.com/brianegan/redux_thunk/blob/master/lib/redux_thunk.dart
/// The generics used there didn't work for me for some reason, so I copied the code and hard-coded it to use
/// [AppState] instead of a generic State.

typedef void ThunkAction(Store<AppState> store);

void thunk_middleware(
    Store<AppState> store,
    dynamic action,
    NextDispatcher next,
    ) {
  if (action is ThunkAction) {
    action(store);
  } else {
    next(action);
  }
}

