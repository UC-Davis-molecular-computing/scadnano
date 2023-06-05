import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../reducers/strands_move_reducer.dart' as strands_move_reducer;
import '../state/design.dart';
import '../state/address.dart';
import '../state/domain.dart';
import '../state/dna_end.dart';
import '../state/strand.dart';
import '../state/strands_move.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

reselect_moved_copied_strands_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (( //action is actions.StrandsAutoPaste ||
          action is actions.StrandsMoveCommit) &&
      (action.strands_move.copy || action.strands_move.strands_moving.length > 1)) {
    if (!(strands_move_reducer.in_bounds_and_allowable(store.state.design, action.strands_move) &&
        (action.strands_move.is_nontrivial || action.strands_move.copy))) {
      return;
    }

    // if moving (not copying), only reselect if there is more than 1 selected
    // otherwise, if the user repeatedly clicks and drags one at a time,
    // this builds up many selected items as they click each new one, moving all of them

    Design design = store.state.design;

    List<Address> addresses = [];
    StrandsMove strands_move = action.strands_move;

    var new_address_helix_idx = strands_move.current_address.helix_idx;
    var new_helix = design.helices[new_address_helix_idx];
    var new_group = design.groups[new_helix.group];

    // var old_address_helix_idx = strands_move.original_address.helix_idx;
    // var old_helix = design.helices[old_address_helix_idx];
    // var old_group = design.groups[old_helix.group];

    BuiltList<int> new_helices_view_order = new_group.helices_view_order;
    BuiltMap<int, int> old_helices_view_order_inverse =
        action.strands_move.original_helices_view_order_inverse;

    // first collect old addresses while design.end_to_substrand is still valid, convert them to
    // their new addresses so we can look them up
    for (Strand strand in strands_move.strands_moving) {
      Domain old_domain = strand.first_domain;
      DNAEnd old_5p_end = old_domain.dnaend_5p;
      int old_helix_view_order = old_helices_view_order_inverse[old_domain.helix];
      int new_helix_view_order = old_helix_view_order + strands_move.delta_view_order;
      int new_helix_idx = new_helices_view_order[new_helix_view_order];
      int new_offset = old_5p_end.offset_inclusive + strands_move.delta_offset;
      var new_forward = strands_move.delta_forward != old_domain.forward;
      var address = Address(helix_idx: new_helix_idx, offset: new_offset, forward: new_forward);
      addresses.add(address);
    }

    // then apply action to commit the move
    next(action);

    // now find new ends at given addresses
    List<Strand> new_strands = [];
    Design new_design = store.state.design;
    // if strand polarity switched, the 3' end of each strand will now be where the 5' end was
    BuiltMap<Address, Strand> address_to_strand =
        strands_move.delta_forward ? new_design.address_3p_to_strand : new_design.address_5p_to_strand;
    for (var address in addresses) {
      Strand new_strand = address_to_strand[address];
      new_strands.add(new_strand);
    }
    store.dispatch(actions.SelectAll(selectables: new_strands.toBuiltList(), only: true));
  } else {
    next(action);
  }
}
