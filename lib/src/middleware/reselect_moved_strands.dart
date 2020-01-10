import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/helix.dart';

import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/strands_move.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

reselect_moved_strands_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.StrandsMoveCommit && action.strands_move.strands_moving.length > 1) {
    // only reselect if there is more than 1 selected, otherwise this builds up many selected items
    // as the user repeatedly clicks on one at a time

    List<Address> addresses = [];
    StrandsMove strands_move = action.strands_move;

    // first collect addresses while dna_design.end_to_substrand is still valid
    for (Strand strand in strands_move.strands_moving) {
      BoundSubstrand old_substrand = strand.first_bound_substrand();
      DNAEnd old_5p_end = old_substrand.dnaend_5p;
      int new_helix_idx = old_substrand.helix + strands_move.delta_helix_idx;
      int new_offset = old_5p_end.offset_inclusive + strands_move.delta_offset;
      var new_forward = strands_move.delta_forward != old_substrand.forward;
      var address = Address(helix_idx: new_helix_idx, offset: new_offset, forward: new_forward);
      addresses.add(address);
    }

    // then apply action
    next(action);

    // now find new ends at given addresses
    List<Strand> new_strands = [];
    DNADesign new_dna_design = store.state.dna_design;
    // if strand polarity switched, the 3' end of each strand will now be where the 5' end was
    BuiltMap<Address, Strand> address_to_strand = strands_move.delta_forward
        ? new_dna_design.address_3p_to_strand
        : new_dna_design.address_5p_to_strand;
    for (var address in addresses) {
      Strand new_strand = address_to_strand[address];
      new_strands.add(new_strand);
    }
    store.dispatch(actions.SelectAll(selectables: new_strands.toBuiltList(), only: true));
  } else {
    next(action);
  }
}
