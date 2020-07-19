import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/strands_move.dart';
import '../actions/actions.dart' as actions;

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
      original_address: action.address,
      helices: state.design.helices,
      helices_view_order: state.design.helices_view_order,
      helices_view_order_inverse: state.design.helices_view_order_inverse,
      copy: action.copy,
      keep_color: state.ui_state.strand_paste_keep_color);
}

StrandsMove strands_move_start_selected_strands_reducer(
    StrandsMove strands_move, AppState state, actions.StrandsMoveStartSelectedStrands action) {
  BuiltList<Strand> selected_strands =
      BuiltList<Strand>(state.ui_state.selectables_store.selected_items.where((s) => s is Strand));
  return StrandsMove(
      strands_moving: selected_strands,
      all_strands: state.design.strands,
      original_address: action.address,
      helices: state.design.helices,
      helices_view_order: state.design.helices_view_order,
      helices_view_order_inverse: state.design.helices_view_order_inverse,
      copy: action.copy,
      keep_color: state.ui_state.strand_paste_keep_color);
}

StrandsMove strands_move_stop_reducer(StrandsMove strands_move, actions.StrandsMoveStop action) => null;

StrandsMove strands_adjust_address_reducer(
    StrandsMove strands_move, AppState state, actions.StrandsMoveAdjustAddress action) {
  StrandsMove new_strands_move = strands_move.rebuild((b) => b..current_address.replace(action.address));
  if (in_bounds(new_strands_move)) {
    bool allowable = is_allowable(new_strands_move);
    return new_strands_move.rebuild((b) => b..allowable = allowable);
  } else {
    return strands_move;
  }
}

// if out of bounds, don't even bother displaying; but if in bounds but still not allowable, we display
// where the strands would go if it were allowable.
bool in_bounds(StrandsMove strands_move) {
  int delta_view_order = strands_move.delta_view_order;
  int delta_offset = strands_move.delta_offset;

  // look for helix out of bounds
  int min_view_order_moving = strands_move.view_order_moving.reduce(min);
  int max_view_order_moving = strands_move.view_order_moving.reduce(max);
  if (min_view_order_moving + delta_view_order < 0) return false;
  if (max_view_order_moving + delta_view_order >= strands_move.helices.length) return false;

  // look for offset out of bounds
  for (int original_helix_idx in strands_move.helices.keys) {
    var substrands_moving = strands_move.helix_idx_to_substrands_moving[original_helix_idx];
    if (substrands_moving.isEmpty) continue;

    int new_helix_idx = strands_move
        .helices_view_order[strands_move.helices[original_helix_idx].view_order + delta_view_order];
    Helix helix = strands_move.helices[new_helix_idx];
    for (var ss in substrands_moving) {
      if (ss.start + delta_offset < helix.min_offset) return false;
      if (ss.end + delta_offset > helix.max_offset) return false;
    }
  }

  return true;
}

// XXX: assumes in_bounds check has already passed
bool is_allowable(StrandsMove strands_move) {
  int delta_view_order = strands_move.delta_view_order;
  int delta_offset = strands_move.delta_offset;
  bool delta_forward = strands_move.delta_forward;

  int num_helices = strands_move.helix_idx_to_substrands_moving.length;
  for (int original_helix_idx in strands_move.helices.keys) {
    var substrands_moving = strands_move.helix_idx_to_substrands_moving[original_helix_idx];
    if (substrands_moving.isEmpty) continue;

    // if we made it here then there are substrands actually moving, so if the reducer that processed
    // the move events did its job, original_helix_idx + delta_helix_idx should be in bounds
    int new_helix_idx = strands_move
        .helices_view_order[strands_move.helices[original_helix_idx].view_order + delta_view_order];
    // This assertion no longer holds because helix idx no longer need to be consecutive.
    // assert(0 <= new_helix_idx && new_helix_idx < num_helices);

    Helix new_helix = strands_move.helices[new_helix_idx];
    var substrands_fixed = strands_move.helix_idx_to_substrands_fixed[new_helix_idx];
    if (substrands_fixed.isEmpty) continue;

    // below, note that delta_forward != ss.forward is equivalent to delta_forward XOR ss.forward, i.e.,
    // if delta_forward is false (i.e., the forward bit isn't changing) then use the value of ss.forward,
    // otherwise use its negation
    for (bool forward in [true, false]) {
      List<Point<int>> intervals_moving = substrands_moving
          .where((ss) => delta_forward != (ss.forward == forward))
          .map((ss) => Point<int>(ss.start + delta_offset, ss.end - 1 + delta_offset))
          .toList();
      if (intervals_moving.isNotEmpty) {
        if (intervals_moving[0].x < new_helix.min_offset) return false;
        if (intervals_moving[intervals_moving.length - 1].y >= new_helix.max_offset) return false;
        List<Point<int>> intervals_fixed = substrands_fixed
            .where((ss) => ss.forward == forward)
            .map((ss) => Point<int>(ss.start, ss.end - 1))
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
/// These interavls are INCLUSIVE on both sides.
bool intersection(List<Point<int>> ints1, List<Point<int>> ints2) {
//  print('  ints1: $ints1');
//  print('  ints2: $ints2');
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
