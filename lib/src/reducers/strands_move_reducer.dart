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
  TypedGlobalReducer<StrandsMove, AppState, actions.StrandsMoveAdjustOffset>(strands_adjust_offset_reducer),
]);

Reducer<StrandsMove> strands_move_local_reducer = combineReducers([
  TypedReducer<StrandsMove, actions.StrandsMoveStop>(strands_move_stop_reducer),
]);

StrandsMove strands_move_start_reducer(
    StrandsMove strands_move, AppState state, actions.StrandsMoveStart action) {
  BuiltList<Strand> selected_strands =
      BuiltList<Strand>(state.ui_state.selectables_store.selected_items.where((s) => s is Strand));
  return StrandsMove(
      strands_moving: selected_strands,
      all_strands: state.dna_design.strands,
      original_offset: action.offset,
      helix: action.helix,
      helices: state.dna_design.helices,
      copy: action.copy);
}

StrandsMove strands_move_stop_reducer(StrandsMove strands_move, actions.StrandsMoveStop action) => null;

StrandsMove strands_adjust_offset_reducer(
    StrandsMove strands_move, AppState state, actions.StrandsMoveAdjustOffset action) {
  strands_move = strands_move.rebuild((b) => b..current_offset = action.offset);
  bool allowable = is_allowable(strands_move);
  return strands_move.rebuild((b) => b..allowable = allowable);
}

bool is_allowable(StrandsMove strands_move) {
  int delta = strands_move.delta;
  if (delta == 0) {
    return true;
  }
  int num_helices = strands_move.helix_idx_to_substrands_moving.length;
  for (int helix_idx = 0; helix_idx < num_helices; helix_idx++) {
    Helix helix = strands_move.helices[helix_idx];
    var substrands_moving = strands_move.helix_idx_to_substrands_moving[helix_idx];
    var substrands_fixed = strands_move.helix_idx_to_substrands_fixed[helix_idx];
    for (bool forward in [true, false]) {
      List<Point<int>> intervals_moving = substrands_moving
          .where((ss) => ss.forward == forward)
          .map((ss) => Point<int>(ss.start + delta, ss.end - 1 + delta))
          .toList();
      if (intervals_moving.isNotEmpty) {
        if (intervals_moving[0].x < helix.min_offset) {
          return false;
        }
        if (intervals_moving[intervals_moving.length - 1].y >= helix.max_offset) {
          return false;
        }
      }
      List<Point<int>> intervals_fixed = substrands_fixed
          .where((ss) => ss.forward == forward)
          .map((ss) => Point<int>(ss.start, ss.end - 1))
          .toList();
      if (intersection(intervals_moving, intervals_fixed)) {
        return false;
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
