import 'dart:html';

import 'package:redux/redux.dart';
import '../reducers/assign_or_remove_dna_reducer.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

assign_dna_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.AssignDNA &&
      action.assign_complements &&
      action.disable_change_sequence_bound_strand) {
    // This pops up the error to the user if they try to change the DNA sequence of a bound strand
    // through assigning DNA to a strand it is bound to,
    // or other errors such as unpaired deletions/insertions.
    try {
      assign_dna_reducer(store.state.design.strands, store.state, action);
    } on ArgumentError catch (e) {
      window.alert(e.message);
      return;
    }
  }
  next(action);
}
