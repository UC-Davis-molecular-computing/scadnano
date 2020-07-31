import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';

import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

// Stops strands from being copied or moved unless they are all on the same helix group
strands_move_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.StrandsMoveStart ) {
//     || action is actions.StrandsMoveStartSelectedStrands) {
    BuiltList<Strand> selected_strands = action is actions.StrandsMoveStart
        ? action.strands
        : BuiltList<Strand>(store.state.ui_state.selectables_store.selected_items.where((s) => s is Strand));
    var group_names = store.state.design.group_names_of_strands(selected_strands);
    if (group_names.length != 1) {
      // only give alert if user tried to click and drag; otherwise they get an annoying warning just
      // for selecting the strand
      if (action is actions.StrandsMoveStart) {
        var msg = 'Cannot move or copy strands unless they are all on the same helix group.\n'
            'These strands occupy the following helix groups: ${group_names.join(", ")}';
        window.alert(msg);
      }
      return;
    }
  }
  next(action);
}
