import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:tuple/tuple.dart';

import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

reselect_moved_strands_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.StrandsMoveCommit && action.strands_move.strands_moving.length > 1) {
    // only reselect if there is more than 1 selected, otherwise this builds up many selected items
    // as the user repeatedly clicks on one at a time

    List<Tuple3<int, int, bool>> addresses = [];

    // first collect addresses while dna_design.end_to_substrand is still valid
    for (Strand strand in action.strands_move.strands_moving) {
      BoundSubstrand old_substrand = strand.first_bound_substrand();
      DNAEnd old_5p_end = old_substrand.dnaend_5p;
      int new_offset = old_5p_end.offset_inclusive + action.strands_move.delta_offset;
      addresses.add(Tuple3<int, int, bool>(old_substrand.helix, new_offset, old_substrand.forward));
    }

    // then apply action
    next(action);

    // now find new ends at given addresses
    List<Strand> new_strands = [];
    for (var address in addresses) {
      Strand new_strand = store.state.dna_design.address_5p_to_strand[address];
      new_strands.add(new_strand);
    }
    store.dispatch(actions.SelectAll(selectables: new_strands.toBuiltList(), only: true));
  } else {
    next(action);
  }
}
