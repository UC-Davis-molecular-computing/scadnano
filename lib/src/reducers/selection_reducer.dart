import 'dart:math';

import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/selection_rope.dart';
import '../state/edit_mode.dart';
import '../state/select_mode.dart';

import '../state/selectable.dart';
import '../state/helix.dart';
import '../state/app_state.dart';
import '../state/selection_box.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../middleware/selections_intersect_box_compute.dart' as select;
import '../constants.dart' as constants;
import 'util_reducer.dart';

SelectablesStore selectables_store_reducer(SelectablesStore selectables_store, AppState state, action) {
  selectables_store = selectables_store_local_reducer(selectables_store, action);
  selectables_store = selectables_store_global_reducer(selectables_store, state, action);
  return selectables_store;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// selectables global reducer

GlobalReducer<SelectablesStore, AppState> selectables_store_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<SelectablesStore, AppState, actions.Select>(select_reducer),
  TypedGlobalReducer<SelectablesStore, AppState, actions.SelectOrToggleItems>(select_or_toggle_items_reducer),
  TypedGlobalReducer<SelectablesStore, AppState, actions.SelectAllSelectable>(select_all_selectables_reducer),
]);

// is item currently selectable, given all the information about select modes, whether it's part of
// a staple or scaffold, whether the design is an origami?
currently_selectable(AppState state, Selectable item) {
  var edit_modes = state.ui_state.edit_modes;
  var select_modes = state.ui_state.select_mode_state.modes;
  if (!(edit_modes.contains(EditModeChoice.select) || edit_modes.contains(EditModeChoice.rope_select))) {
    return false;
  }
  if (!select_modes.contains(item.select_mode)) {
    return false;
  }
  if (state.design.is_origami) {
    if (item.is_scaffold && !select_modes.contains(SelectModeChoice.scaffold)) {
      return false;
    }
    if (!item.is_scaffold && !select_modes.contains(SelectModeChoice.staple)) {
      return false;
    }
  }
  return true;
}

SelectablesStore select_reducer(SelectablesStore selectables_store, AppState state, actions.Select action) {
  Selectable item = action.selectable;
  if (!currently_selectable(state, item)) {
    // if this type of item is not selectable, do nothing
    return selectables_store;
  }
  bool toggle = action.toggle;
  if (action.only) {
    selectables_store = selectables_store.select(item, only: true);
  } else {
    if (toggle) {
      selectables_store = selectables_store.toggle(item);
    } else {
      selectables_store = selectables_store.select(item);
    }
  }
  return selectables_store;
}

SelectablesStore select_all_selectables_reducer(
    SelectablesStore selectables_store, AppState state, actions.SelectAllSelectable action) {
  BuiltSet<SelectModeChoice> modes = state.ui_state.select_mode_state.modes;
  bool scaffold_selectable = modes.contains(SelectModeChoice.scaffold);
  bool staple_selectable = modes.contains(SelectModeChoice.staple);

  List<Selectable> selected = [];
  for (var strand in state.design.strands) {
    if (!state.design.is_origami ||
        (strand.is_scaffold && scaffold_selectable) ||
        (!strand.is_scaffold && staple_selectable)) {
      if (modes.contains(SelectModeChoice.strand)) selected.add(strand);
      if (modes.contains(SelectModeChoice.loopout)) selected.addAll(strand.loopouts);
      if (modes.contains(SelectModeChoice.extension_)) selected.addAll(strand.extensions);
      if (modes.contains(SelectModeChoice.crossover)) selected.addAll(strand.crossovers);
      if (modes.contains(SelectModeChoice.deletion)) selected.addAll(strand.selectable_deletions);
      if (modes.contains(SelectModeChoice.insertion)) selected.addAll(strand.selectable_insertions);
      if (modes.contains(SelectModeChoice.modification)) selected.addAll(strand.selectable_modifications);
      if (modes.contains(SelectModeChoice.end_5p_strand)) selected.add(strand.dnaend_5p);
      if (modes.contains(SelectModeChoice.end_3p_strand)) selected.add(strand.dnaend_3p);
      if (modes.contains(SelectModeChoice.end_5p_domain)) selected.addAll(strand.ends_5p_not_first);
      if (modes.contains(SelectModeChoice.end_3p_domain)) selected.addAll(strand.ends_3p_not_last);
    }
  }

  return selectables_store.select_all(selected);
}

SelectablesStore select_or_toggle_items_reducer(
        SelectablesStore selectables_store, AppState state, actions.SelectOrToggleItems action) =>
    action.toggle ? selectables_store.toggle_all(action.items) : selectables_store.select_all(action.items);

///////////////////////////////////////////////////////////////////////////////////////////////////
// selectables local reducer

Reducer<SelectablesStore> selectables_store_local_reducer = combineReducers([
  TypedReducer<SelectablesStore, actions.SelectAll>(select_all_reducer),
  TypedReducer<SelectablesStore, actions.SelectionsClear>(selections_clear_reducer),
  TypedReducer<SelectablesStore, actions.DesignChangingAction>(design_changing_action_reducer),
  TypedReducer<SelectablesStore, actions.SelectModeToggle>(selections_clear_reducer),
  TypedReducer<SelectablesStore, actions.SelectModesSet>(selections_clear_reducer),
  TypedReducer<SelectablesStore, actions.SelectModesAdd>(selections_clear_reducer),
]);

// because the DNADesign changed, some selected items may no longer be valid
SelectablesStore design_changing_action_reducer(
        SelectablesStore selectables_store, actions.DesignChangingAction action) =>
    action is actions.HelicesPositionsSetBasedOnCrossovers ? selectables_store : selectables_store.clear();

SelectablesStore select_all_reducer(SelectablesStore selectables_store, actions.SelectAll action) =>
    selectables_store.select_all(action.selectables, only: action.only);

SelectablesStore selections_clear_reducer(SelectablesStore selectables_store, _) => selectables_store.clear();

///////////////////////////////////////////////////////////////////////////////////////////////////
// side_selected_helices global reducer

GlobalReducer<BuiltSet<int>, AppState> side_selected_helices_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltSet<int>, AppState, actions.HelixSelectionsAdjust>(helix_selections_adjust_reducer),
]);

BuiltSet<int> helix_selections_adjust_reducer(
    BuiltSet<int> helix_idxs_selected, AppState state, actions.HelixSelectionsAdjust action) {
  //FIXME: this reducer isn't pure. Move into middleware similar to selections_intersect_box_compute
  bool toggle = action.toggle;
  var selection_box = action.selection_box;
  var all_helices_in_displayed_group = state.design.helices_in_group(state.ui_state.displayed_group_name);
  List<select.Box> all_bboxes =
      all_helices_in_displayed_group.values.map((helix) => helix_to_box(helix, state.ui_state.invert_y)).toList();
  var selection_box_as_box = select.Box.from_selection_box(selection_box);
  List<Helix> helices_overlapping =
      select.enclosure_list(all_helices_in_displayed_group.values, all_bboxes, selection_box_as_box);
//      util.intersection_list(all_helices.toList(), all_bboxes, util.Box.from_selection_box(selection_box));
  List<int> helix_idxs_overlapping = helices_overlapping.map((helix) => helix.idx).toList();

  // start with all previously selected helices
  SetBuilder<int> helices_idxs_selected_new = helix_idxs_selected.toBuilder();

  // add all helices under selection box
  helices_idxs_selected_new.addAll(helix_idxs_overlapping);

  // if toggling, remove those that were already selected
  if (toggle) {
    for (var idx_overlapping in helix_idxs_overlapping) {
      if (helix_idxs_selected.contains(idx_overlapping)) {
        helices_idxs_selected_new.remove(idx_overlapping);
      }
    }
  }

  return helices_idxs_selected_new.build();
}

select.Box helix_to_box(Helix helix, bool invert_y) {
  //FIXME: this is making boxes that are not far enough apart
  var position3d = helix.position3d;
  num x, y, width, height;
  var svg_pos = util.position3d_to_side_view_svg(position3d, invert_y, helix.geometry);
  x = svg_pos.x - helix.geometry.helix_radius_svg;
  y = svg_pos.y - helix.geometry.helix_radius_svg;
  height = width = helix.geometry.helix_radius_svg * 2.0;
  return select.Box(x, y, width: width, height: height);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// side_selected_helices local reducer

Reducer<BuiltSet<int>> side_selected_helices_reducer = combineReducers([
  TypedReducer<BuiltSet<int>, actions.HelixSelect>(helix_select_reducer),
  TypedReducer<BuiltSet<int>, actions.HelixSelectionsClear>(helices_selected_clear_reducer),
  TypedReducer<BuiltSet<int>, actions.HelixRemoveAllSelected>(helices_remove_all_selected_reducer),
  TypedReducer<BuiltSet<int>, actions.HelixRemove>(helix_remove_selected_reducer),
]);

BuiltSet<int> helix_select_reducer(BuiltSet<int> side_selected_helix_idxs, actions.HelixSelect action) {
  int idx = action.helix_idx;
  bool toggle = action.toggle;
  if (!side_selected_helix_idxs.contains(idx)) {
    side_selected_helix_idxs = side_selected_helix_idxs.rebuild((h) => h.add(idx));
  } else {
    if (toggle) {
      side_selected_helix_idxs = side_selected_helix_idxs.rebuild((h) => h.remove(idx));
    }
  }
  return side_selected_helix_idxs;
}

BuiltSet<int> helices_selected_clear_reducer(BuiltSet<int> _, actions.HelixSelectionsClear action) =>
    BuiltSet<int>();

BuiltSet<int> helices_remove_all_selected_reducer(BuiltSet<int> _, actions.HelixRemoveAllSelected action) =>
    BuiltSet<int>();

BuiltSet<int> helix_remove_selected_reducer(BuiltSet<int> selected_helices, actions.HelixRemove action) =>
    selected_helices.rebuild((b) => b..remove(action.helix_idx));

///////////////////////////////////////////////////////////////////////////////////////////////////
// selection box reducer

Reducer<SelectionBox> optimized_selection_box_reducer = combineReducers([
  selection_box_reducer,
]);

Reducer<SelectionBox> selection_box_reducer = combineReducers([
  TypedReducer<SelectionBox, actions.SelectionBoxCreate>(selection_box_create_reducer),
  TypedReducer<SelectionBox, actions.SelectionBoxSizeChange>(selection_box_size_changed_reducer),
  TypedReducer<SelectionBox, actions.SelectionBoxRemove>(selection_box_remove_reducer),
]);

SelectionBox selection_box_create_reducer(SelectionBox _, actions.SelectionBoxCreate action) =>
    SelectionBox(action.point, action.toggle, action.is_main);

SelectionBox selection_box_size_changed_reducer(
        SelectionBox selection_box, actions.SelectionBoxSizeChange action) =>
    selection_box.rebuild((s) => s..current = action.point);

SelectionBox selection_box_remove_reducer(SelectionBox _, actions.SelectionBoxRemove __) => null;

///////////////////////////////////////////////////////////////////////////////////////////////////
// selection rope reducer

Reducer<SelectionRope> optimized_selection_rope_reducer = combineReducers([
  selection_rope_reducer,
]);

Reducer<SelectionRope> selection_rope_reducer = combineReducers([
  TypedReducer<SelectionRope, actions.SelectionRopeCreate>(selection_rope_create_reducer),
  TypedReducer<SelectionRope, actions.SelectionRopeMouseMove>(selection_rope_mouse_move_reducer),
  TypedReducer<SelectionRope, actions.SelectionRopeAddPoint>(selection_rope_add_point_reducer),
  TypedReducer<SelectionRope, actions.SelectionRopeRemove>(selection_rope_remove_reducer),
]);

SelectionRope selection_rope_create_reducer(SelectionRope _, actions.SelectionRopeCreate action) =>
    SelectionRope(action.toggle);

SelectionRope selection_rope_mouse_move_reducer(SelectionRope rope, actions.SelectionRopeMouseMove action) {
  // if no points have been added, is_main should be null; if so we set it according to the action
  if (rope.is_main == null) {
    rope = rope.rebuild((b) => b..is_main = action.is_main_view);
  }

  // if action and rope disagree about is_main,
  // then the click just occurred in a different view than the first click, so we ignore it
  if (rope.is_main != action.is_main_view) {
    return rope;
  }

  return rope.rebuild((b) => b..current_point = action.point);
}

SelectionRope selection_rope_add_point_reducer(SelectionRope rope, actions.SelectionRopeAddPoint action) {
  // if no points have been added, is_main should be null; if so we set it according to the action
  if (rope.is_main == null) {
    rope = rope.rebuild((b) => b..is_main = action.is_main_view);
  }

  // if action and rope disagree about is_main,
  // then the click just occurred in a different view than the first click, so we ignore it
  if (rope.is_main != action.is_main_view) {
    return rope;
  }

  // otherwise, add the point, as long as it keeps the polygon's lines non-self-intersecting;
  // otherwise ignore it
  List<Point<num>> points = rope.points.toList();
  if (points.length <= 1 || !rope.creates_self_intersection(action.point)) {
    points.add(action.point);
    rope = rope.rebuild((b) => b..points.replace(points));
  }

  return rope;
}

SelectionRope selection_rope_remove_reducer(SelectionRope _, actions.SelectionRopeRemove __) => null;
