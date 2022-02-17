import 'dart:convert';
import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:tuple/tuple.dart';

import '../state/copy_info.dart';
import '../state/strands_move.dart';
import '../state/app_state.dart';
import '../state/domain.dart';
import '../state/helix.dart';
import '../state/address.dart';
import '../state/design.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import 'strands_move_reducer.dart' as strands_move_reducer;
import 'util_reducer.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

GlobalReducer<CopyInfo, AppState> copy_info_global_reducer = combineGlobalReducers([
  // TypedGlobalReducer<StrandsCopyInfo, AppState, actions.CopySelectedStrands>(copy_selected_strands_reducer),
  // TypedGlobalReducer<CopyInfo, AppState, actions.UpdateCopyInfo>(update_copy_info_reducer),
  // TypedGlobalReducer<CopyInfo, AppState, actions.StrandsAutoPaste>(strands_autopaste_copy_info_reducer),
  TypedGlobalReducer<CopyInfo, AppState, actions.CopySelectedStrands>(copy_selected_strands_reducer),
  TypedGlobalReducer<CopyInfo, AppState, actions.ManualPasteInitiate>(manual_paste_initiate_reducer),
  TypedGlobalReducer<CopyInfo, AppState, actions.AutoPasteInitiate>(autopaste_initiate_reducer),
  TypedGlobalReducer<CopyInfo, AppState, actions.StrandsMoveCommit>(manual_paste_copy_info_reducer),
]);

// we rely on middleware to parse system clipboard with copied strands info on paste, so when first
// copying, we reset copy_info to erase any previous state from earlier copy/pastes
CopyInfo copy_selected_strands_reducer(CopyInfo _, AppState __, actions.CopySelectedStrands ___) => null;

CopyInfo manual_paste_initiate_reducer(CopyInfo _, AppState state, actions.ManualPasteInitiate action) {
  String clipboard_content = action.clipboard_content;
  var strands_and_helices_view_order = parse_strands_and_helices_view_order_from_clipboard(clipboard_content);
  if (strands_and_helices_view_order == null) {
    return null;
  }

  List<Strand> strands = strands_and_helices_view_order[0];
  List<int> helices_view_order = strands_and_helices_view_order[1];
  Map<String, Modification> mods = strands_and_helices_view_order[2];

  if (strands.isEmpty) return null;
  // indicates helices came from more than one HelixGroup, so no way to paste
  if (helices_view_order == null) return null;

  CopyInfo copy_info = strands_copy_info_from_strand_list(state, strands, helices_view_order);
  return copy_info;
}

// auto_paste_initiate_reducer identical to manual_paste_initiate_reducer except how copy_info is handled.
// In manual_paste_initiate_reducer it is calculated from scratch.
// In auto_paste_initiate_reducer it is updated from existing if copy_info.translate is not null.
// (since copy_info.translate may have been calculated to be non-default from previous manual paste)
CopyInfo autopaste_initiate_reducer(CopyInfo copy_info, AppState state, actions.AutoPasteInitiate action) {
  String clipboard_content = action.clipboard_content;
  var strands_and_helices_view_order = parse_strands_and_helices_view_order_from_clipboard(clipboard_content);
  if (strands_and_helices_view_order == null) {
    return null;
  }

  List<Strand> strands = strands_and_helices_view_order[0];
  List<int> helices_view_order = strands_and_helices_view_order[1];

  if (strands.isEmpty) return null;
  // indicates helices came from more than one HelixGroup, so no way to paste
  if (helices_view_order == null) return null;

  if (copy_info == null || !copy_info.has_translation()) {
    // if no translation, perhaps we copied from a different design or otherwise null'ed out translation.
    // so calculate a new copy_info from scratch.
    copy_info = strands_copy_info_from_strand_list(state, strands, helices_view_order);
  }

  return copy_info;
}

List parse_strands_and_helices_view_order_from_clipboard(String clipboard_content) {
  String error_msg = 'no strand info found on system clipboard, so nothing to paste; '
      'content of system clipboard: "${clipboard_content}"';

  // try to parse JSON as a list
  Map<String, dynamic> clipboard_json;
  try {
    clipboard_json = jsonDecode(clipboard_content);
  } on Exception {
    print(error_msg);
    return null;
  } on Error {
    print(error_msg);
    return null;
  }

  // helices_view_order can be null if not all copied strands came from same HelixGroup
  // type of clipboard_json[constants.helices_view_order_key] is List<dynamic>, need to convert
  List helices_view_order_json = clipboard_json[constants.helices_view_order_key];
  List<int> helices_view_order = null;
  if (helices_view_order_json != null) {
    helices_view_order = [for (int idx in helices_view_order_json) idx];
  }

  Map<String, dynamic> mods;
  // try to interpret JSON list as list of Strands
  clipboard_json[constants.design_modifications_key].forEach((key, value){
    Modification mod;
    try {
      mod = Modification.from_json(value);
    } on Exception {
      print(error_msg);
      return null;
    } on Error {
      print(error_msg);
      return null;
    }
    mods[key] = mod;
  });
  // try to interpret JSON list as list of Strands
  List strand_jsons = clipboard_json[constants.strands_key];
  List<Strand> strands = [];
  for (var strand_json in strand_jsons) {
    Strand strand;
    try {
      strand = Strand.from_json(strand_json);
    } on Exception {
      print(error_msg);
      return null;
    } on Error {
      print(error_msg);
      return null;
    }
    strand.rebuild((m) => m
      ..modification_5p = mods[strand_json[constants.modification_5p_key]]
      ..modification_3p = mods[strand_json[constants.modification_3p_key]]
      ..modifications_int = strand_json[constants.modifications_int_key].map((a) => mods[a]));
    strands.add(strand);
  }

  return [strands, helices_view_order, mods];
}

// need to pass in helices_view_order from clipboard since these strands may be from a different design
CopyInfo strands_copy_info_from_strand_list(
    AppState state, List<Strand> selected_strands, List<int> helices_view_order) {
  if (selected_strands.isEmpty) {
    return null;
  }

  // compute helices_view_order_inverse
  Map<int, int> helices_view_order_inverse = util.invert_helices_view_order(helices_view_order);

  // find minimum helix of any selected strand, then minimum starting offset of that strand,
  int extreme_helix_view_order; // max if invert_y; min if not
  int extreme_helix_idx;
  int min_offset;
  bool min_forward;
  for (Strand strand in selected_strands) {
    for (Domain domain in strand.domains) {
      // HelixGroup group = state.design.group_of_domain(domain);
      // int helix_view_order = group.helices_view_order_inverse[domain.helix];
      int helix_view_order = helices_view_order_inverse[domain.helix];
      bool helix_is_more_extreme = extreme_helix_view_order == null ||
          (state.ui_state.invert_y
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

  // compute default next Address for repeated pasting without mouse click
  // if null, then we won't use copy_info for autopaste, but we will keep the other
  // information in copy_info for possible manual pasting
  Address next_address = compute_default_next_address(
      selected_strands, state.design, original_address, helices_view_order, helices_view_order_inverse);
  AddressDifference translation =
      next_address?.difference(original_address, helices_view_order_inverse.build());

  var copy_info = CopyInfo(
    strands: selected_strands.toBuiltList(),
    copied_address: original_address,
    translation: translation,
    helices_view_order: helices_view_order.toBuiltList(),
    helices_view_order_inverse: helices_view_order_inverse.build(),
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
Address compute_default_next_address(List<Strand> selected_strands, Design design, Address start_address,
    List<int> helices_view_order, Map<int, int> helices_view_order_inverse) {
  var group_names = design.group_names_of_strands(selected_strands);
  if (group_names == null) {
    // This means group does not exist in current design. In this case we forbid autopasting.
    return null;
  }
  if (group_names.length != 1) return null;
  var group_name = group_names.first;
  var group = design.groups[group_name];
  // ensure group.helices_view_order has all indices as helices_view_order from action.
  // If not, then these strands came from a different design and we cannot autopaste.
  // (we do allow it in case
  if (!helices_view_order.toSet().containsAll(group.helices_view_order)) {
    return null;
  }

  StrandsMove strands_move = StrandsMove(
    all_strands: design.strands,
    strands_moving: selected_strands.toBuiltList(),
    helices: design.helices,
    groups: design.groups,
    original_helices_view_order_inverse: helices_view_order_inverse.build(),
    original_address: start_address,
    copy: true,
    keep_color: true, // this won't really get used here
  );

  // Look for legal position below start_address
  var strands_move_beneath = strands_move;
  // increase translation_helix_order iteratively until we find that the strands can be pasted
  int translation_helix_order = helices_view_order_inverse[start_address.helix_idx] + 1;
  while (translation_helix_order < helices_view_order.length) {
    // compute next possible address of translation
    int next_helix_idx = helices_view_order[translation_helix_order];
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

CopyInfo manual_paste_copy_info_reducer(
    CopyInfo copy_info, AppState state, actions.StrandsMoveCommit action) {
  if (action.strands_move.copy) {
    // if user is pasting, copy_info should have something in it
    // (populated from clipboard by system_clipboard middleware
    // handling ManualPasteInitiate or AutoPasteInitiate)
    assert(copy_info != null);

    // translation vector for NEXT paste is *double* that from original to current in manually pasted strand
    var current_address = action.strands_move.current_address;

    // only calculate translation vector if paste is in same HelixGroup (generalized somewhat for
    // pasting between different designs; see definition of _same_helix_group)
    bool calculate_new_autopaste_translation = _same_helix_group(copy_info, action) &&
        !action.autopaste &&
        current_address != copy_info.copied_address;
    if (calculate_new_autopaste_translation) {
      var translation =
          current_address.difference(copy_info.copied_address, copy_info.helices_view_order_inverse);
      copy_info = copy_info.rebuild((b) => b..translation = translation.toBuilder());
    }

    copy_info = copy_info.rebuild((b) => b..prev_paste_address.replace(current_address));
  }

  return copy_info;
}

// This is more a proxy for same HelixGroup, since we cannot assume original group exists.
// (If copying from another design, the helices and groups may be totally different.)
// If copying strands from one Design to another,
// there's not really a way to tell, but we can use helices_view_order as a proxy.
bool _same_helix_group(CopyInfo copy_info, actions.StrandsMoveCommit action) {
  //TODO: make this more general: old helices is a subset of new helices, and order does not have to be same
  var current_group = action.strands_move.current_group;
  var current_helices_view_order_inverse = current_group.helices_view_order_inverse;
  return current_helices_view_order_inverse == action.strands_move.original_helices_view_order_inverse;
  // return action.strands_move.original_helix.group == action.strands_move.current_helix.group;
}
