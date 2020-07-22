import 'dart:html';

import 'package:redux/redux.dart';
import '../reducers/assign_or_remove_dna_reducer.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

assign_dna_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.AssignDNA && action.assign_complements & action.warn_on_change) {
    try {
      assign_dna_reducer(store.state.design.strands, action);
    } on ArgumentError catch (e) {
      window.alert(e.message);
      return;
    }
  }
  next(action);
}