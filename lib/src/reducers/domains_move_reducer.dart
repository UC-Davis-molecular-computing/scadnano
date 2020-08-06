import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/strand.dart';

import '../state/domains_move.dart';
import '../state/group.dart';
import '../state/design.dart';
import '../reducers/util_reducer.dart';
import '../state/app_state.dart';
import '../state/helix.dart';
import '../actions/actions.dart' as actions;
import '../extension_methods.dart';

GlobalReducer<DomainsMove, AppState> domains_move_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<DomainsMove, AppState, actions.DomainsMoveStartSelectedDomains>(
      domains_move_start_selected_domains_reducer),
  TypedGlobalReducer<DomainsMove, AppState, actions.DomainsMoveAdjustAddress>(domains_adjust_address_reducer),
]);

Reducer<DomainsMove> domains_move_local_reducer = combineReducers([
  TypedReducer<DomainsMove, actions.DomainsMoveStop>(domains_move_stop_reducer),
]);

DomainsMove domains_move_start_selected_domains_reducer(
    DomainsMove _, AppState state, actions.DomainsMoveStartSelectedDomains action) {
  Set<Domain> selected_domains =
      Set<Domain>.from(state.ui_state.selectables_store.selected_items.where((s) => s is Domain));
  Set<Strand> strands_of_selected_domains = {
    for (var domain in selected_domains)
      state.design.substrand_to_strand[domain]
  };
  return DomainsMove(
      domains_moving: selected_domains.toBuiltList(),
      all_domains: state.design.all_domains,
      strands_with_domains_moving: strands_of_selected_domains.toBuiltList(),
      helices: state.design.helices,
      groups: state.design.groups,
      original_address: action.address);
}

DomainsMove domains_move_stop_reducer(DomainsMove domains_move, actions.DomainsMoveStop action) => null;

DomainsMove domains_adjust_address_reducer(
    DomainsMove domains_move, AppState state, actions.DomainsMoveAdjustAddress action) {
  DomainsMove new_domains_move = domains_move.rebuild((b) => b..current_address.replace(action.address));
  if (in_bounds(state.design, new_domains_move)) {
    bool allowable = is_allowable(state.design, new_domains_move);
    return new_domains_move.rebuild((b) => b..allowable = allowable);
  } else {
    return domains_move;
  }
}

// if out of bounds, don't even bother displaying; but if in bounds but still not allowable, we display
// where the domains would go if it were allowable.
bool in_bounds(Design design, DomainsMove domains_move) {
  var current_address_helix_idx = domains_move.current_address.helix_idx;
  var current_helix = design.helices[current_address_helix_idx];
  var current_group = design.groups[current_helix.group];
  var num_helices_in_group = design.helices_in_group(current_helix.group).length;

  int original_helix_idx = domains_move.original_address.helix_idx;
  var original_helix = design.helices[original_helix_idx];
  var original_group = design.groups[original_helix.group];

  int delta_view_order = domains_move.delta_view_order;
  int delta_offset = domains_move.delta_offset;

  // look for helix out of bounds
  Set<int> view_orders_of_helices_of_moving_domains = view_order_moving(domains_move, original_group);
  int min_view_order = view_orders_of_helices_of_moving_domains.min;
  int max_view_order = view_orders_of_helices_of_moving_domains.max;
  if (min_view_order + delta_view_order < 0) return false;
  if (max_view_order + delta_view_order >= num_helices_in_group) return false;

  // look for offset out of bounds
  for (int original_helix_idx in design.helices.keys) {
    if (domains_move.domains_moving_on_helix[original_helix_idx].isEmpty) continue;

    int view_order_orig = original_group.helices_view_order_inverse[original_helix_idx];
    int new_helix_idx = current_group.helices_view_order[view_order_orig + delta_view_order];
    Helix helix = design.helices[new_helix_idx];
    for (var domain in domains_move.domains_moving_on_helix[original_helix_idx]) {
      if (domain.start + delta_offset < helix.min_offset) return false;
      if (domain.end + delta_offset > helix.max_offset) return false;
    }
  }

  return true;
}

Set<int> view_order_moving(DomainsMove domains_move, HelixGroup original_group) {
  Set<int> ret = {};
  for (var domain in domains_move.domains_moving) {
    ret.add(original_group.helices_view_order_inverse[domain.helix]);
  }
  return ret;
}

// XXX: assumes in_bounds check has already passed
bool is_allowable(Design design, DomainsMove domains_move) {
  var current_address_helix_idx = domains_move.current_address.helix_idx;
  var current_helix = design.helices[current_address_helix_idx];
  var current_group = design.groups[current_helix.group];

  int delta_view_order = domains_move.delta_view_order;
  int delta_offset = domains_move.delta_offset;
  bool delta_forward = domains_move.delta_forward;


  // look for moving domains overlapping fixed domains
  for (int original_helix_idx in design.helices.keys) {
    var domains_moving = domains_move.domains_moving_on_helix[original_helix_idx];
    if (domains_moving.isEmpty) continue;

    // if we made it here then there are substrands actually moving, so if the reducer that processed
    // the move events did its job, original_helix_idx + delta_helix_idx should be in bounds
    Helix original_helix = design.helices[original_helix_idx];
    HelixGroup original_group = design.groups[original_helix.group];
    int view_order_orig = original_group.helices_view_order_inverse[original_helix_idx];
    int new_helix_idx = current_group.helices_view_order[view_order_orig + delta_view_order];

    Helix new_helix = design.helices[new_helix_idx];
    var domains_fixed = domains_move.domains_fixed_on_helix[new_helix_idx];
    if (domains_fixed.isEmpty) continue;

    // below, note that delta_forward != dom.forward is equivalent to delta_forward XOR dom.forward, i.e.,
    // if delta_forward is false (i.e., the forward bit isn't changing) then use the value of dom.forward,
    // otherwise use its negation
    for (bool forward in [true, false]) {
      List<Point<int>> intervals_moving = domains_moving
          .where((dom) => delta_forward != (dom.forward == forward))
          .map((dom) => Point<int>(dom.start + delta_offset, dom.end - 1 + delta_offset))
          .toList();
      if (intervals_moving.isNotEmpty) {
        if (intervals_moving[0].x < new_helix.min_offset) return false;
        if (intervals_moving[intervals_moving.length - 1].y >= new_helix.max_offset) return false;
        List<Point<int>> intervals_fixed = domains_fixed
            .where((dom) => dom.forward == forward)
            .map((dom) => Point<int>(dom.start, dom.end - 1))
            .toList();
        if (intersection(intervals_moving, intervals_fixed)) return false;
      }
    }
  }

  return true;
}

/// Indicate if any of the intervals in ints1 intersect any of the intervals in ints2. Assume each
/// is disjoint within itself (i.e., no two intervals in ints1 intersection, and no two intervals
/// within ints2 intersect). and that each is sorted by start point
/// (thus also by end point by disjointness.)
/// These intervals are INCLUSIVE on both sides.
bool intersection(List<Point<int>> ints1, List<Point<int>> ints2) {
  int idx1 = 0;
  int idx2 = 0;
  while (idx1 < ints1.length && idx2 < ints2.length) {
    // step through interavls in ints2 until one is found that might intersect int1
    while (idx2 < ints2.length && ints2[idx2].y < ints1[idx1].x) {
      idx2++;
    }
    if (idx2 == ints2.length) {
      return false; // if we ran out of intervals in ints2, we're done
    } else if (ints2[idx2].x <= ints1[idx1].y) {
      return true; // o/w check for intersection
    }

    // step through interavls in ints1 until one is found that might intersect int2
    while (idx1 < ints1.length && ints1[idx1].y < ints2[idx2].x) {
      idx1++;
    }
    if (idx1 == ints1.length) {
      return false; // if we ran out of intervals in ints2, we're done
    } else if (ints1[idx1].x <= ints2[idx2].y) {
      return true; // o/w check for intersection
    }
  }

  return false;
}

Domain move_domain(
    {Domain domain,
    HelixGroup original_group,
    HelixGroup current_group,
    int delta_view_order,
    int delta_offset,
    bool delta_forward,
    bool set_first_last_false = false}) {
  num original_view_order = original_group.helices_view_order_inverse[domain.helix];
  num new_view_order = original_view_order + delta_view_order;
  int new_helix_idx = current_group.helices_view_order[new_view_order];
  assert(new_helix_idx != null);
  Domain domain_moved = domain.rebuild(
    (b) => b
      ..is_first = set_first_last_false? false: b.is_first
      ..is_last = set_first_last_false? false: b.is_last
      ..helix = new_helix_idx
      ..forward = (delta_forward != domain.forward)
      ..start = domain.start + delta_offset
      ..end = domain.end + delta_offset
      ..deletions.replace(domain.deletions.map((d) => d + delta_offset))
      ..insertions
          .replace(domain.insertions.map((i) => i.rebuild((ib) => ib..offset = i.offset + delta_offset))),
  );
  return domain_moved;
}
