import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../state/domain.dart';
import '../state/dna_end.dart';
import '../state/dna_ends_move.dart';
import '../state/address.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

reselect_moved_dna_ends_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.DNAEndsMoveCommit && action.dna_ends_move.moves.length > 1) {
    // only reselect if there is more than 1 selected, otherwise this builds up many selected items
    // as the user repeatedly clicks on one at a time

    List<Address> addresses = [];

    // first collect addresses while design.end_to_substrand is still valid
    for (DNAEndMove move in action.dna_ends_move.moves) {
      DNAEnd old_end = move.dna_end;
      Domain old_substrand = store.state.design.end_to_domain[old_end]!;
      int new_offset = action.dna_ends_move.current_capped_offset_of(old_end);
      addresses
          .add(Address(helix_idx: old_substrand.helix, offset: new_offset, forward: old_substrand.forward));
    }

    // then apply action
    next(action);

    // now find new ends at given addresses
    List<DNAEnd> new_ends = [];
    for (var address in addresses) {
      DNAEnd new_end = store.state.design.address_to_end[address]!;
      new_ends.add(new_end);
    }
    store.dispatch(actions.SelectAll(selectables: new_ends.toBuiltList(), only: true));
  } else {
    next(action);
  }
}
