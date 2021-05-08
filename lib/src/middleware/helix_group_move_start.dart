import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix_group_move.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/dna_end.dart';
import '../state/dna_ends_move.dart';
import '../state/helix.dart';
import '../state/strand.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';

helix_group_move_start_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.HelixGroupMoveStart) {
    var state = store.state;
    String group_name = state.ui_state.displayed_group_name;
    HelixGroup group = state.design.groups[group_name];
    var helices_in_group = state.design.helices_in_group(group_name);

    if (helices_in_group.isNotEmpty) {
      next(action); // this lets the boolean be set that we are moving a helix group
      var helix_group_move = HelixGroupMove(
        group_name: group_name,
        group: group,
        helices: helices_in_group,
        original_mouse_point: action.mouse_point,
      );
      // important that we dispatch to app, not to store, because the app dispatch will know to route this
      // to the appropriate optimized store for moving HelixGroup
      app.dispatch(actions.HelixGroupMoveCreate(helix_group_move: helix_group_move));
    } else {
      var msg = 'Cannot move a helix group that has no helices in it.';
      window.alert(msg);
    }
  } else {
    next(action);
  }
}

/// Finds extreme (highest or lowest depending on [highest]) offset that an end at [offset] could be
/// moved to. This depends on what is the closest end that is not selected, and how many selected ends
/// are in between this end and that one.
int find_allowable_offset(Design design, DNAEnd end, BuiltSet<DNAEnd> selected_ends, bool highest) {
  Domain substrand = design.end_to_domain[end];
  int helix_idx = substrand.helix;
  Set<int> selected_offsets = selected_ends.map((e) => e.offset_inclusive).toSet();

  // offsets of (selected) ends to right (if highest==true) or left (if highest==false) of end.offset
  List<int> unselected_end_offsets_to_one_side = [];
  List<int> selected_end_offsets_to_one_side = [];
  List<Domain> other_substrands_same_dir_same_helix =
      design.domains_on_helix(helix_idx).where((ss) => ss.forward == substrand.forward).toList();
  for (var ss in other_substrands_same_dir_same_helix) {
    for (int other_offset in [ss.start, ss.end - 1]) {
      if (highest && other_offset > end.offset_inclusive) {
        if (selected_offsets.contains(other_offset)) {
          selected_end_offsets_to_one_side.add(other_offset);
        } else {
          unselected_end_offsets_to_one_side.add(other_offset);
        }
      } else if (!highest && other_offset < end.offset_inclusive) {
        if (selected_offsets.contains(other_offset)) {
          selected_end_offsets_to_one_side.add(other_offset);
        } else {
          unselected_end_offsets_to_one_side.add(other_offset);
        }
      }
    }
  }

  if (unselected_end_offsets_to_one_side.isEmpty) {
    Helix helix = design.helices[helix_idx];
    return highest ? helix.max_offset - 1 : helix.min_offset;
  }

  int closest_unselected_offset = unselected_end_offsets_to_one_side.reduce(highest ? min : max);
  int num_selected_offsets_between = selected_end_offsets_to_one_side
      .where((o) => highest ? o < closest_unselected_offset : o > closest_unselected_offset)
      .length;
  int adjust_factor = highest ? -1 - num_selected_offsets_between : 1 + num_selected_offsets_between;

  return closest_unselected_offset + adjust_factor;
}
