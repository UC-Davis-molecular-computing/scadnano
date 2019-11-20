
/// A Reducer that changes some "local state" (a substree of the full state tree),
/// but requires reaching into a larger substree (global state) to know how to apply the action.
typedef LocalState GlobalReducer<LocalState, GlobalState>(
    LocalState local_state, GlobalState global_state, dynamic action);

/// Class-based version of [GlobalReducer].
abstract class GlobalReducerClass<LocalState, GlobalState> {
  LocalState call(LocalState local_state, GlobalState state, dynamic action);
}

class TypedGlobalReducer<LocalState, GlobalState, Action>
    implements GlobalReducerClass<LocalState, GlobalState> {
  final LocalState Function(LocalState local_state, GlobalState global_state, Action action) reducer;

  TypedGlobalReducer(this.reducer);

  @override
  LocalState call(LocalState local_state, GlobalState global_state, dynamic action) {
    if (action is Action) {
      return reducer(local_state, global_state, action);
    }

    return local_state;
  }
}

GlobalReducer<LocalState, GlobalState> combineGlobalReducers<LocalState, GlobalState>(
    Iterable<GlobalReducer<LocalState, GlobalState>> reducers) {
  return (LocalState local_state, GlobalState global_state, dynamic action) {
    for (final reducer in reducers) {
      local_state = reducer(local_state, global_state, action);
    }
    return local_state;
  };
}
