import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/dna_ends_move.dart';
import 'package:tuple/tuple.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

reselect_moved_dna_ends_middleware(Store<AppState> store, action, NextDispatcher next) {
  List<Tuple3<int, int, bool>> addresses = [];
  if (action is actions.DNAEndsMoveCommit) {
    // first collect addresses while dna_design.end_to_substrand is still valid
    for (DNAEndMove move in action.dna_ends_move.moves) {
      DNAEnd old_end = move.dna_end;
      BoundSubstrand old_substrand = store.state.dna_design.end_to_substrand[old_end];
      int new_offset = action.dna_ends_move.current_capped_offset_of(old_end);
      addresses.add(Tuple3<int, int, bool>(old_substrand.helix, new_offset, old_substrand.forward));
    }
  }
  
  // then apply action
  next(action);

  if (action is actions.DNAEndsMoveCommit) {
    // now find new ends at given addresses
    List<DNAEnd> new_ends = [];
    for (var address in addresses) {
      DNAEnd new_end = store.state.dna_design.address_to_end[address];
      new_ends.add(new_end);
    }
    store.dispatch(actions.SelectAll(selectables: new_ends.toBuiltList(), only: true));
  }
  
}
