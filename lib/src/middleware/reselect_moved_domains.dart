import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../reducers/domains_move_reducer.dart' as domains_move_reducer;
import '../state/domains_move.dart';
import '../state/design.dart';
import '../state/address.dart';
import '../state/domain.dart';
import '../state/dna_end.dart';
import '../state/strand.dart';
import '../state/strands_move.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

reselect_moved_domains_middleware(Store<AppState> store, action, NextDispatcher next) {
  // only reselect if there is more than 1 selected
  // otherwise, if the user repeatedly clicks and drags one at a time,
  // this builds up many selected items as they click each new one, moving all of them
  if ((action is actions.DomainsMoveCommit) && action.domains_move.domains_moving.length > 1) {
    Design old_design = store.state.design;
    DomainsMove domains_move = action.domains_move;

    if (!(domains_move_reducer.in_bounds(old_design, domains_move) &&
        domains_move_reducer.is_allowable(old_design, domains_move) &&
        domains_move.is_nontrivial)) {
      return;
    }

    List<Address> addresses = [];

    var new_address_helix_idx = domains_move.current_address.helix_idx;
    var new_helix = old_design.helices[new_address_helix_idx];
    var new_group = old_design.groups[new_helix.group];

    BuiltList<int> new_helices_view_order = new_group.helices_view_order;
    BuiltMap<int, int> old_helices_view_order_inverse =
        domains_move.original_helices_view_order_inverse;

    // first collect old addresses while design.end_to_substrand is still valid, convert them to
    // their new addresses so we can look them up
    for (Domain old_domain in domains_move.domains_moving) {
      // Domain old_domain = strand.first_domain;
      DNAEnd old_5p_end = old_domain.dnaend_5p;
      int old_helix_view_order = old_helices_view_order_inverse[old_domain.helix];
      int new_helix_view_order = old_helix_view_order + domains_move.delta_view_order;
      int new_helix_idx = new_helices_view_order[new_helix_view_order];
      int new_offset = old_5p_end.offset_inclusive + domains_move.delta_offset;
      var new_forward = domains_move.delta_forward != old_domain.forward;
      var address = Address(helix_idx: new_helix_idx, offset: new_offset, forward: new_forward);
      addresses.add(address);
    }

    // then apply action to commit the move
    next(action);

    // now find new ends at given addresses
    List<Domain> new_domains = [];
    Design new_design = store.state.design;
    // if domain polarity switched, the 3' end of each domain will now be where the 5' end was
    BuiltMap<Address, Domain> address_to_domain =
          domains_move.delta_forward ? new_design.address_3p_to_domain : new_design.address_5p_to_domain;
    for (var address in addresses) {
      Domain new_domain = address_to_domain[address];
      new_domains.add(new_domain);
    }
    store.dispatch(actions.SelectAll(selectables: new_domains.toBuiltList(), only: true));
  } else {
    next(action);
  }
}
