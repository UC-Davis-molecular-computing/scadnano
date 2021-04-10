import 'package:built_collection/built_collection.dart';

import '../state/strands_copy_info.dart';
import '../state/strands_move.dart';
import '../state/group.dart';
import '../state/app_state.dart';
import '../state/domain.dart';
import '../state/helix.dart';
import '../state/address.dart';
import '../state/design.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import 'strands_move_reducer.dart' as strands_move_reducer;
import 'util_reducer.dart';

GlobalReducer<StrandsCopyInfo, AppState> strands_copy_info_autopaste_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<StrandsCopyInfo, AppState, actions.CopySelectedStrands>(copy_selected_strands_reducer),
  TypedGlobalReducer<StrandsCopyInfo, AppState, actions.StrandsCopyBufferClear>(
      strands_copy_buffer_clear_reducer),
  TypedGlobalReducer<StrandsCopyInfo, AppState, actions.StrandsMoveCommit>(
      strands_manual_paste_copy_info_reducer),
  TypedGlobalReducer<StrandsCopyInfo, AppState, actions.StrandsAutoPaste>(
      strands_autopaste_copy_info_reducer),
]);

StrandsCopyInfo strands_copy_buffer_clear_reducer(
        StrandsCopyInfo _, AppState __, actions.StrandsCopyBufferClear ___) =>
    null;

// called on Ctrl+C
StrandsCopyInfo copy_selected_strands_reducer(
    StrandsCopyInfo _, AppState state, actions.CopySelectedStrands __) {
  var selected_strands = state.ui_state.selectables_store.selected_strands.toList();
  if (selected_strands.isEmpty) {
    return null;
  }

  // find minimum helix of any selected strand, then minimum starting offset of that strand,
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
  var original_address = Address(helix_idx: extreme_helix_idx, offset: min_offset, forward: min_forward);

  var group_names = state.design.group_names_of_strands(selected_strands);
  var group_name = group_names.first;
  var group = state.design.groups[group_name];

  // compute default next Address for repeated pasting without mouse click
  // if null, then we won't use copy_info for autopaste, but we will keep the other
  // information in copy_info for possible manual pasting
  Address next_address = compute_default_next_address(selected_strands, state.design, original_address);
  AddressDifference translation =
      next_address?.difference(original_address, group.helices_view_order_inverse);

  var copy_info = StrandsCopyInfo(
    strands: selected_strands.toBuiltList(),
    original_address: original_address,
    translation: translation,
    helices_view_order: group.helices_view_order,
    helices_view_order_inverse: group.helices_view_order_inverse,
  );

  return copy_info;
}

/// Computes default next_address for pasting copied strands without mouse click.
///
/// Rule:
/// 1. Move strands down (in helix component of Address), keep forward the same,
///    until first helix where they can be pasted
/// 2. If rule 1 is not possible with existing helices,
///    move right (increasing offset of Address, keep helix and forward same) until they can be pasted
/// 3. Otherwise return null
///
/// Always returns null if strands come from more than one HelixGroup
Address compute_default_next_address(List<Strand> selected_strands, Design design, Address start_address) {
  // if strands are on more than one group, cannot paste, so no translation
  var group_names = design.group_names_of_strands(selected_strands);
  if (group_names.length != 1) return null;
  var group_name = group_names.first;
  var group = design.groups[group_name];

  StrandsMove strands_move = StrandsMove(
    all_strands: design.strands,
    strands_moving: selected_strands.toBuiltList(),
    helices: design.helices,
    groups: design.groups,
    original_address: start_address,
    copy: true,
    keep_color: true, // this won't really get used here
  );

  // Look for legal position below start_address
  var strands_move_beneath = strands_move;
  // increase translation_helix_order iteratively until we find that the strands can be pasted
  int translation_helix_order = group.helices_view_order_inverse[start_address.helix_idx] + 1;
  while (translation_helix_order < group.helices_view_order.length) {
    // compute next possible address of translation
    int next_helix_idx = group.helices_view_order[translation_helix_order];
    var next_address = strands_move_beneath.current_address.rebuild((b) => b..helix_idx = next_helix_idx);
    strands_move_beneath = strands_move_beneath.rebuild((b) => b..current_address.replace(next_address));

    // test if it's legal
    if (strands_move_reducer.in_bounds(design, strands_move_beneath)) {
      bool allowable = strands_move_reducer.is_allowable(design, strands_move_beneath);
      if (allowable) {
        return strands_move_beneath.current_address;
      }
    }

    translation_helix_order++;
  }

  // If we don't find a legal translation beneath start_address, now look to the right of start_address.
  var strands_move_right = strands_move;
  Helix start_helix = design.helices[start_address.helix_idx];
  int offset = start_address.offset + 1;
  while (offset < start_helix.max_offset) {
    // compute next possible address of translation
    var next_address = strands_move_right.current_address.rebuild((b) => b..offset = offset);
    strands_move_right = strands_move_right.rebuild((b) => b..current_address.replace(next_address));

    // test if it's legal
    if (strands_move_reducer.in_bounds(design, strands_move_right)) {
      bool allowable = strands_move_reducer.is_allowable(design, strands_move_right);
      if (allowable) {
        return strands_move_right.current_address;
      }
    }

    offset++;
  }

  // if we didn't find a translation already, there is none that is legal
  return null;
}

// called on Ctrl+V
// manual paste: use the translation between copied and manually pasted Addresses as translation vector
StrandsCopyInfo strands_manual_paste_copy_info_reducer(
    StrandsCopyInfo copy_info, AppState state, actions.StrandsMoveCommit action) {
  if (action.strands_move.copy) {
    // if user is pasting, then strands must have been copied, so copy_info should have something in it
    assert(copy_info != null);

    // translation vector for NEXT paste is *double* that from original to current in manually pasted strand
    var current_address = action.strands_move.current_address;
    var translation =
        current_address.difference(copy_info.original_address, copy_info.helices_view_order_inverse);
    copy_info = copy_info.rebuild((b) => b
      ..translation = translation.toBuilder()
      // current_address might need to be replaced with original to "reset" it,
      // in case we previously pasted and thendid Undo,
      // which does not undo the current_address since it only affects the Design
      ..current_address.replace(copy_info.original_address));
    copy_info = copy_info.move_to_next(state.design);
  }

  return copy_info;
}

// called on Ctrl+Shift+V
// autopaste: update translation vector to be one farther than before
StrandsCopyInfo strands_autopaste_copy_info_reducer(
    StrandsCopyInfo copy_info, AppState state, actions.StrandsAutoPaste action) {
  // if no translation (or no copy_info at all), nothing to update
  if (copy_info == null || !copy_info.has_translation()) return copy_info;

  copy_info = copy_info.move_to_next(state.design);

  return copy_info;
}
