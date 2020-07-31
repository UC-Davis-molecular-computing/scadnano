import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';

import '../state/group.dart';
import '../state/design.dart';
import '../reducers/util_reducer.dart';
import '../state/app_state.dart';
import '../state/helix.dart';
import '../state/strand.dart';
import '../state/strands_move.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

GlobalReducer<StrandsMove, AppState> strands_move_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<StrandsMove, AppState, actions.StrandsMoveStart>(strands_move_start_reducer),
  TypedGlobalReducer<StrandsMove, AppState, actions.StrandsMoveStartSelectedStrands>(
      strands_move_start_selected_strands_reducer),
  TypedGlobalReducer<StrandsMove, AppState, actions.StrandsMoveAdjustAddress>(strands_adjust_address_reducer),
]);

Reducer<StrandsMove> strands_move_local_reducer = combineReducers([
  TypedReducer<StrandsMove, actions.StrandsMoveStop>(strands_move_stop_reducer),
]);

StrandsMove strands_move_start_reducer(
    StrandsMove strands_move, AppState state, actions.StrandsMoveStart action) {
  return StrandsMove(
      strands_moving: action.strands,
      all_strands: state.design.strands,
      helices: state.design.helices,
      original_address: action.address,
      copy: action.copy,
      keep_color: state.ui_state.strand_paste_keep_color);
}

StrandsMove strands_move_start_selected_strands_reducer(
    StrandsMove _, AppState state, actions.StrandsMoveStartSelectedStrands action) {
  BuiltList<Strand> selected_strands =
      BuiltList<Strand>(state.ui_state.selectables_store.selected_items.where((s) => s is Strand));
  return StrandsMove(
      strands_moving: selected_strands,
      all_strands: state.design.strands,
      helices: state.design.helices,
      original_address: action.address,
      copy: action.copy,
      keep_color: state.ui_state.strand_paste_keep_color);
}

StrandsMove strands_move_stop_reducer(StrandsMove strands_move, actions.StrandsMoveStop action) => null;

StrandsMove strands_adjust_address_reducer(
    StrandsMove strands_move, AppState state, actions.StrandsMoveAdjustAddress action) {
  StrandsMove new_strands_move = strands_move.rebuild((b) => b..current_address.replace(action.address));
  if (in_bounds(state.design, new_strands_move)) {
    bool allowable = is_allowable(state.design, new_strands_move);
    return new_strands_move.rebuild((b) => b..allowable = allowable);
  } else {
    return strands_move;
  }
}

// if out of bounds, don't even bother displaying; but if in bounds but still not allowable, we display
// where the strands would go if it were allowable.
bool in_bounds(Design design, StrandsMove strands_move) {
  var address_helix_idx = strands_move.current_address.helix_idx;
  var helix = design.helices[address_helix_idx];
  var group = design.groups[helix.group];
  var num_helices_in_group = design.helices_in_group(helix.group).length;

  int original_helix_idx = strands_move.strands_moving.first.domains().first.helix;
  var original_helix = design.helices[original_helix_idx];
  var original_group = design.groups[original_helix.group];

  int delta_view_order = strands_move.delta_view_order;
  int delta_offset = strands_move.delta_offset;

  // look for helix out of bounds
  Set<int> view_orders_of_helices_of_moving_strands = view_order_moving(strands_move, original_group);
  int min_view_order = view_orders_of_helices_of_moving_strands.reduce(min);
  int max_view_order = view_orders_of_helices_of_moving_strands.reduce(max);
  if (min_view_order + delta_view_order < 0) return false;
  if (max_view_order + delta_view_order >= num_helices_in_group) return false;

  // look for offset out of bounds
  for (int original_helix_idx in design.helices.keys) {
//    var substrands_moving = strands_move.helix_idx_to_substrands_moving[original_helix_idx];
    var substrands_moving = construct_helix_idx_to_substrands_map(
        strands_move.strands_moving, design.helices.keys)[original_helix_idx];
    if (substrands_moving.isEmpty) continue;

    int new_helix_idx =
        group.helices_view_order[design.helices[original_helix_idx].view_order + delta_view_order];
    Helix helix = design.helices[new_helix_idx];
    for (var ss in substrands_moving) {
      if (ss.start + delta_offset < helix.min_offset) return false;
      if (ss.end + delta_offset > helix.max_offset) return false;
    }
  }

  return true;
}

Set<int> view_order_moving(StrandsMove strands_move, HelixGroup original_group) {
  Set<int> ret = {};
  for (var strand in strands_move.strands_moving) {
    for (var domain in strand.domains()) {
      ret.add(original_group.helices_view_order_inverse[domain.helix]);
    }
  }
  return ret;
}

// XXX: assumes in_bounds check has already passed
bool is_allowable(Design design, StrandsMove strands_move) {
  var current_address_helix_idx = strands_move.current_address.helix_idx;
  var current_helix = design.helices[current_address_helix_idx];
  var current_group = design.groups[current_helix.group];

  int delta_view_order = strands_move.delta_view_order;
  int delta_offset = strands_move.delta_offset;
  bool delta_forward = strands_move.delta_forward;

  var helix_idx_to_substrands_moving =
      construct_helix_idx_to_substrands_map(strands_move.strands_moving, design.helices.keys);
  var helix_idx_to_substrands_fixed =
      construct_helix_idx_to_substrands_map(strands_move.strands_fixed, design.helices.keys);

  for (int original_helix_idx in design.helices.keys) {
    var substrands_moving = helix_idx_to_substrands_moving[original_helix_idx];
    if (substrands_moving.isEmpty) continue;

    // if we made it here then there are substrands actually moving, so if the reducer that processed
    // the move events did its job, original_helix_idx + delta_helix_idx should be in bounds
    int new_helix_idx =
        current_group.helices_view_order[design.helices[original_helix_idx].view_order + delta_view_order];

    Helix new_helix = design.helices[new_helix_idx];
    var substrands_fixed = helix_idx_to_substrands_fixed[new_helix_idx];
    if (substrands_fixed.isEmpty) continue;

    // below, note that delta_forward != dom.forward is equivalent to delta_forward XOR dom.forward, i.e.,
    // if delta_forward is false (i.e., the forward bit isn't changing) then use the value of dom.forward,
    // otherwise use its negation
    for (bool forward in [true, false]) {
      List<Point<int>> intervals_moving = substrands_moving
          .where((dom) => delta_forward != (dom.forward == forward))
          .map((dom) => Point<int>(dom.start + delta_offset, dom.end - 1 + delta_offset))
          .toList();
      if (intervals_moving.isNotEmpty) {
        if (intervals_moving[0].x < new_helix.min_offset) return false;
        if (intervals_moving[intervals_moving.length - 1].y >= new_helix.max_offset) return false;
        List<Point<int>> intervals_fixed = substrands_fixed
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
