// @dart=2.9
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart';
import 'package:redux/redux.dart';

import '../state/group.dart';
import '../state/design.dart';
import '../reducers/util_reducer.dart';
import '../state/app_state.dart';
import '../state/helix.dart';
import '../state/strand.dart';
import '../state/strands_move.dart';
import '../actions/actions.dart' as actions;
import '../extension_methods.dart';
import '../constants.dart' as constants;

GlobalReducer<StrandsMove, AppState> strands_move_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<StrandsMove, AppState, actions.StrandsMoveStart>(strands_move_start_reducer),
  TypedGlobalReducer<StrandsMove, AppState, actions.StrandsMoveStartSelectedStrands>(
      strands_move_start_selected_strands_reducer),
  TypedGlobalReducer<StrandsMove, AppState, actions.StrandsMoveAdjustAddress>(strands_adjust_address_reducer),
]);

Reducer<StrandsMove> strands_move_local_reducer = combineReducers([
  TypedReducer<StrandsMove, actions.StrandsMoveStop>(strands_move_stop_reducer),
]);

StrandsMove strands_move_start_reducer(StrandsMove _, AppState state, actions.StrandsMoveStart action) {
  return StrandsMove(
      strands_moving: action.strands,
      all_strands: state.design.strands,
      helices: state.design.helices,
      groups: state.design.groups,
      original_helices_view_order_inverse: action.original_helices_view_order_inverse,
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
      groups: state.design.groups,
      original_helices_view_order_inverse: action.original_helices_view_order_inverse,
      original_address: action.address,
      copy: action.copy,
      keep_color: state.ui_state.strand_paste_keep_color);
}

StrandsMove strands_move_stop_reducer(StrandsMove strands_move, actions.StrandsMoveStop action) => null;

// - in_bounds checks whether the strand is in a legal address given the helices, but allows it to overlap
// other strands
// - is_allowable checks whether the strand overlaps other strands

StrandsMove strands_adjust_address_reducer(
    StrandsMove strands_move, AppState state, actions.StrandsMoveAdjustAddress action) {
  StrandsMove new_strands_move = strands_move.rebuild((b) => b..current_address.replace(action.address));
  // if out of bounds, don't even bother displaying; but if in bounds but still not allowable, we display
  // where the strands would go if it were allowable. That's why we want both Boolean values separately.
  if (in_bounds(state.design, new_strands_move)) {
    bool allowable = is_allowable(state.design, new_strands_move);
    return new_strands_move.rebuild((b) => b..allowable = allowable);
  } else {
    return strands_move;
  }
}

bool in_bounds_and_allowable(Design design, StrandsMove strands_move) {
  // only calculate original_helix_idxs_set once for both in_bounds and is_allowable
  Set<int> original_helix_idxs_set = populate_original_helices_idxs_set(strands_move);
  return in_bounds(design, strands_move, original_helix_idxs_set: original_helix_idxs_set) &&
      is_allowable(design, strands_move, original_helix_idxs_set: original_helix_idxs_set);
}

bool in_bounds(Design design, StrandsMove strands_move, {Set<int> original_helix_idxs_set = null}) {
  constants.strand_bounds_status status = get_strand_bounds_details(design, strands_move,
      original_helix_idxs_set: original_helix_idxs_set)['status'];
  if (status == constants.strand_bounds_status.in_bounds ||
      status == constants.strand_bounds_status.in_bounds_with_min_offset_changes ||
      status == constants.strand_bounds_status.in_bounds_with_max_offset_changes) return true;
  return false;
}

Map get_strand_bounds_details(Design design, StrandsMove strands_move,
    {Set<int> original_helix_idxs_set = null}) {
  // collect helix idxs on moving strands (if new design, may be different from design.helices.keys
  if (original_helix_idxs_set == null) {
    original_helix_idxs_set = populate_original_helices_idxs_set(strands_move);
  }

  var current_address_helix_idx = strands_move.current_address.helix_idx;
  if (!design.helices.containsKey(current_address_helix_idx)) {
    return {
      'status': constants.strand_bounds_status.helix_not_in_design
    }; // helix is not in design, so cannot be in bounds
  }
  var current_helix = design.helices[current_address_helix_idx];
  var current_group = design.groups[current_helix.group];
  var num_helices_in_group = design.helices_in_group(current_helix.group).length;

  int delta_view_order = strands_move.delta_view_order;
  int delta_offset = strands_move.delta_offset;

  // look for helix out of bounds
  Set<int> view_orders_of_helices_of_moving_strands = view_order_moving(strands_move);
  int min_view_order = view_orders_of_helices_of_moving_strands.min;
  int max_view_order = view_orders_of_helices_of_moving_strands.max;
  if (min_view_order + delta_view_order < 0)
    return {'status': constants.strand_bounds_status.helix_out_of_bounds};
  if (max_view_order + delta_view_order >= num_helices_in_group)
    return {'status': constants.strand_bounds_status.helix_out_of_bounds};

  // look for offset out of bounds
  Map out_of_bounds_min_offset_changes = {};
  Map out_of_bounds_max_offset_changes = {};
  Map in_bounds_min_offset_changes = {};
  Map in_bounds_max_offset_changes = {};
  for (int original_helix_idx in original_helix_idxs_set) {
    var helix_idx_to_domains_map =
        construct_helix_idx_to_domains_map(strands_move.strands_moving, original_helix_idxs_set);
    var domains_moving = helix_idx_to_domains_map[original_helix_idx];
    if (domains_moving.isEmpty) continue;

    int view_order_orig = strands_move.original_helices_view_order_inverse[original_helix_idx];
    int new_helix_idx = current_group.helices_view_order[view_order_orig + delta_view_order];
    Helix helix = design.helices[new_helix_idx];

    int outOfBoundsNewMinOffset = helix.min_offset;
    int outOfBoundsNewMaxOffset = helix.max_offset;
    int inBoundsNewMinOffset = helix.min_offset;
    int inBoundsNewMaxOffset = helix.max_offset;
    int originalMinOffset = strands_move.helices[helix.idx].min_offset;
    int originalMaxOffset = strands_move.helices[helix.idx].max_offset;
    int max_offset_of_helix = design.max_offset_of_strands_at(helix.idx);
    int min_offset_of_helix = design.min_offset_of_strands_at(helix.idx);

    for (var domain in domains_moving) {
      if (domain.start + delta_offset < helix.min_offset)
        outOfBoundsNewMinOffset = [outOfBoundsNewMinOffset, domain.start + delta_offset].min;
      else if (domain.start + delta_offset > helix.min_offset)
        inBoundsNewMinOffset = [
          [inBoundsNewMinOffset, domain.start + delta_offset].max,
          originalMinOffset,
          min_offset_of_helix
        ].min;
      if (domain.end + delta_offset > helix.max_offset)
        outOfBoundsNewMaxOffset = [outOfBoundsNewMaxOffset, domain.end + delta_offset].max;
      else if (domain.end + delta_offset < helix.max_offset)
        inBoundsNewMaxOffset = [
          [inBoundsNewMaxOffset, domain.end + delta_offset].min,
          originalMaxOffset,
          max_offset_of_helix
        ].max;
      // if (domain.start + delta_offset < helix.min_offset) return "min_offset_out_of_bounds";
      // if (domain.end + delta_offset > helix.max_offset) return "max_offset_out_of_bounds";
    }
    if (outOfBoundsNewMinOffset < helix.min_offset)
      out_of_bounds_min_offset_changes[helix.idx] = outOfBoundsNewMinOffset;
    if (outOfBoundsNewMaxOffset > helix.max_offset)
      out_of_bounds_max_offset_changes[helix.idx] = outOfBoundsNewMaxOffset;
    if (inBoundsNewMinOffset > helix.min_offset)
      in_bounds_min_offset_changes[helix.idx] = inBoundsNewMinOffset;
    if (inBoundsNewMaxOffset < helix.max_offset)
      in_bounds_max_offset_changes[helix.idx] = inBoundsNewMaxOffset;
  }
  if (out_of_bounds_min_offset_changes.isNotEmpty)
    return {
      'status': constants.strand_bounds_status.min_offset_out_of_bounds,
      'offsets': out_of_bounds_min_offset_changes
    };
  if (out_of_bounds_max_offset_changes.isNotEmpty)
    return {
      'status': constants.strand_bounds_status.max_offset_out_of_bounds,
      'offsets': out_of_bounds_max_offset_changes
    };
  if (in_bounds_min_offset_changes.isNotEmpty)
    return {
      'status': constants.strand_bounds_status.in_bounds_with_min_offset_changes,
      'offsets': in_bounds_min_offset_changes
    };
  if (in_bounds_max_offset_changes.isNotEmpty)
    return {
      'status': constants.strand_bounds_status.in_bounds_with_max_offset_changes,
      'offsets': in_bounds_max_offset_changes
    };
  return {'status': constants.strand_bounds_status.in_bounds};
}

// collect helix idxs on moving strands (if new design, may be different from design.helices.keys
Set<int> populate_original_helices_idxs_set(StrandsMove strands_move) {
  Set<int> original_helix_idxs_set = {};
  for (var strand in strands_move.strands_moving) {
    for (var domain in strand.domains) {
      original_helix_idxs_set.add(domain.helix);
    }
  }
  return original_helix_idxs_set;
}

Set<int> view_order_moving(StrandsMove strands_move) {
  Set<int> ret = {};
  for (var strand in strands_move.strands_moving) {
    for (var domain in strand.domains) {
      var view_order_of_helix = strands_move.original_helices_view_order_inverse[domain.helix];
      if (view_order_of_helix == null) {
        throw AssertionError(
            "Helix: ${domain.helix}, has no inverse in strands_move.original_helices_view_order_inverse ${strands_move.original_helices_view_order_inverse}");
      }
      ret.add(view_order_of_helix);
    }
  }
  return ret;
}

// XXX: assumes in_bounds check has already passed
bool is_allowable(Design design, StrandsMove strands_move, {Set<int> original_helix_idxs_set = null}) {
  // collect helix idxs on moving strands (if new design, may be different from design.helices.keys
  if (original_helix_idxs_set == null) {
    original_helix_idxs_set = populate_original_helices_idxs_set(strands_move);
  }

  var current_address_helix_idx = strands_move.current_address.helix_idx;
  var current_helix = design.helices[current_address_helix_idx];
  var current_group = design.groups[current_helix.group];

  int delta_view_order = strands_move.delta_view_order;
  int delta_offset = strands_move.delta_offset;
  bool delta_forward = strands_move.delta_forward;

  var helix_idx_to_substrands_moving =
      construct_helix_idx_to_domains_map(strands_move.strands_moving, original_helix_idxs_set);
  var helix_idx_to_substrands_fixed =
      construct_helix_idx_to_domains_map(strands_move.strands_fixed, design.helices.keys);

  for (int original_helix_idx in original_helix_idxs_set) {
    var domains_moving = helix_idx_to_substrands_moving[original_helix_idx];
    if (domains_moving.isEmpty) continue;

    // if we made it here then there are substrands actually moving, so if the reducer that processed
    // the move events did its job, original_helix_idx + delta_helix_idx should be in bounds
    // Helix original_helix = design.helices[original_helix_idx];
    // HelixGroup original_group = design.groups[original_helix.group];
    // int view_order_orig = original_group.helices_view_order_inverse[original_helix_idx];
    int view_order_orig = strands_move.original_helices_view_order_inverse[original_helix_idx];
    int new_helix_idx = current_group.helices_view_order[view_order_orig + delta_view_order];

    Helix new_helix = design.helices[new_helix_idx];
    var domains_fixed = helix_idx_to_substrands_fixed[new_helix_idx];
    if (domains_fixed.isEmpty) continue;

    // below, note that delta_forward != dom.forward is equivalent to delta_forward XOR dom.forward, i.e.,
    // if delta_forward is false (i.e., the forward bit isn't changing) then use the value of dom.forward,
    // otherwise use its negation
    for (bool forward in [true, false]) {
      List<Point<int>> intervals_moving = domains_moving
          .where((dom) => delta_forward != (dom.forward == forward))
          .map((dom) => Point<int>(dom.start + delta_offset, dom.end - 1 + delta_offset))
          .toList();
      sort_intervals_by_start(intervals_moving);
      if (intervals_moving.isNotEmpty) {
        if (intervals_moving[0].x < new_helix.min_offset) return false;
        if (intervals_moving[intervals_moving.length - 1].y >= new_helix.max_offset) return false;
        List<Point<int>> intervals_fixed = domains_fixed
            .where((dom) => dom.forward == forward)
            .map((dom) => Point<int>(dom.start, dom.end - 1))
            .toList();
        sort_intervals_by_start(intervals_fixed);
        if (intersection(intervals_moving, intervals_fixed)) return false;
      }
    }
  }
  return true;
}

int interval_comparator(Point interval1, Point interval2) => interval1.x - interval2.x;

/// Sort intervals in ints by start point (in place).
void sort_intervals_by_start(List<Point<int>> intervals) {
  intervals.sort(interval_comparator);
}

/// Indicate if any of the intervals in ints1 intersect any of the intervals in ints2. Assume each
/// is disjoint within itself (i.e., no two intervals in ints1 intersect, and no two intervals
/// within ints2 intersect) and that each is sorted by start point
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
