import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/strands_copy_info.dart';

import '../state/group.dart';
import '../state/app_state.dart';
import '../state/domain.dart';
import '../state/helix.dart';
import '../state/design.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import 'util_reducer.dart';
import '../util.dart' as util;

GlobalReducer<StrandsCopyInfo, AppState> strands_copy_info_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<StrandsCopyInfo, AppState, actions.CopySelectedStrands>(copy_selected_strands_reducer),
  TypedGlobalReducer<StrandsCopyInfo, AppState, actions.StrandsCopyBufferClear>(
      strands_copy_buffer_clear_reducer),
]);

StrandsCopyInfo strands_copy_buffer_clear_reducer(
        StrandsCopyInfo _, AppState __, actions.StrandsCopyBufferClear ___) =>
    null;

StrandsCopyInfo copy_selected_strands_reducer(
    StrandsCopyInfo _, AppState state, actions.CopySelectedStrands __) {
  var selected_strands = state.ui_state.selectables_store.selected_strands.toList();
  if (selected_strands.isEmpty) {
    return null;
  }

  // find minimum helix of any selected strand, then minimum starting offset of that strand
  int extreme_helix_view_order; // max if invert_yz; min if not
  int extreme_helix_idx;
  int min_offset;
  bool min_forward;
  for (Strand strand in selected_strands) {
    for (Domain domain in strand.domains()) {
      HelixGroup group = state.design.group_of_domain(domain);
      int helix_view_order = group.helices_view_order_inverse[domain.helix];
      bool helix_is_more_extreme = extreme_helix_view_order == null ||
          (state.ui_state.invert_xy
              ? extreme_helix_view_order < helix_view_order
              : extreme_helix_view_order > helix_view_order);
      if (helix_is_more_extreme) {
        extreme_helix_view_order = helix_view_order;
        extreme_helix_idx = domain.helix;
        min_offset = domain.start; // reset this absolutely since helix got smaller
        min_forward = domain.forward; //
      } else if (min_offset == null ||
          (extreme_helix_view_order == helix_view_order && min_offset > domain.start)) {
        min_offset = domain.start;
        min_forward = domain.forward;
      }
    }
  }

  // compute default translation for repeated pasting without mouse click
  Address default_translation = compute_default_translation(selected_strands, state.design);

  var copy_info = StrandsCopyInfo(
      strands: selected_strands.toBuiltList(),
      start_address: Address(helix_idx: extreme_helix_idx, offset: min_offset, forward: min_forward),
      default_translation: default_translation);

  return copy_info;
}

/// Computes default translation (expressed by interpreting Address as a vector)
/// for pasting copied strands without mouse click.
/// Rule:
/// 1. Move strands down (in helix component of Address), keep forward the same,
///    until first helix where they can be pasted
/// 2. If 1 is not possible with existing helices, move right (incrasing offset of Address)
///    until they can be pasted
/// 3. Otherwise return null
Address compute_default_translation(List<Strand> selected_strands, Design design) {
  return null;
}
