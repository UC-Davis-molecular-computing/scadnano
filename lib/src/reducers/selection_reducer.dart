import 'dart:html';
import 'dart:svg';

import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/select_mode.dart';

import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/view/design.dart';
import '../state/helix.dart';
import '../state/app_state.dart';
import '../state/selection_box.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../state/selectable.dart';
import 'util_reducer.dart';

Reducer<SelectionBox> optimized_selection_box_reducer = combineReducers([
  selection_box_reducer,
]);

///////////////////////////////////////////////////////////////////////////////////////////////////
// selectables global reducer

GlobalReducer<SelectablesStore, AppState> selectables_store_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<SelectablesStore, AppState, actions.SelectionsAdjust>(selections_adjust_reducer),
  TypedGlobalReducer<SelectablesStore, AppState, actions.SelectAllSelectable>(select_all_selectables_reducer),
]);

SelectablesStore select_all_selectables_reducer(
    SelectablesStore selectables_store, AppState state, actions.SelectAllSelectable action) {
  BuiltSet<SelectModeChoice> modes = state.ui_state.select_mode_state.modes;
  bool scaffold_selectable = modes.contains(SelectModeChoice.scaffold);
  bool staple_selectable = modes.contains(SelectModeChoice.staple);

  List<Selectable> selected = [];
  for (var strand in state.dna_design.strands) {
    if (!state.dna_design.is_origami ||
        (strand.is_scaffold && scaffold_selectable) ||
        (!strand.is_scaffold && staple_selectable)) {
      if (modes.contains(SelectModeChoice.strand)) selected.add(strand);
      if (modes.contains(SelectModeChoice.loopout)) selected.addAll(strand.loopouts());
      if (modes.contains(SelectModeChoice.crossover)) selected.addAll(strand.crossovers);
      if (modes.contains(SelectModeChoice.end_5p_strand)) selected.add(strand.dnaend_5p);
      if (modes.contains(SelectModeChoice.end_3p_strand)) selected.add(strand.dnaend_3p);
      if (modes.contains(SelectModeChoice.end_5p_substrand)) selected.addAll(strand.ends_5p_not_first());
      if (modes.contains(SelectModeChoice.end_3p_substrand)) selected.addAll(strand.ends_3p_not_last());
    }
  }

  return selectables_store.select_all(selected);
}

SelectablesStore selections_adjust_reducer(
    SelectablesStore selectables_store, AppState state, actions.SelectionsAdjust action) {
  //XXX: this is not a pure reducer since it looks at SVG view properties to determine SVG object
  // intersection.
  // It seems difficult to put enough state into AppState to reliably detect when one SVG element
  // overlaps another in a way that is robust to future changes in how we draw.
  // Maybe figure out some way to do this with middleware so the reducer can remain pure.

  RectElement select_box = querySelector('#selection-box-main') as RectElement;
  if (select_box == null) {
    return selectables_store;
  }
  Rect select_box_bbox = select_box.getBBox();

  //XXX: Firefox does not have getIntersectionList or getEnclosureList
  // (no progress for 10 years on that: https://bugzilla.mozilla.org/show_bug.cgi?id=501421)
  // Besides, it didn't work well in Chrome and I basically had to implement it myself based on bounding boxes.

  Set<SvgElement> elts_overlapping = util.enclosure_list_in_elt(MAIN_VIEW_SVG_ID, select_box_bbox).toSet();

  var selectable_by_id = state.dna_design.selectable_by_id;
  List<Selectable> overlapping_now = [
//    for (var elt in elts_overlapping) if (selectables_by_id.containsKey(elt.id)) selectables_by_id[elt.id]
    for (var elt in elts_overlapping) if (selectable_by_id.containsKey(elt.id)) selectable_by_id[elt.id]
  ];

  List<Selectable> overlapping_now_select_mode_enabled = [];
  for (var obj in overlapping_now) {
    if (state.ui_state.select_mode_state.is_selectable(obj)) {
      overlapping_now_select_mode_enabled.add(obj);
    }
  }

  return action.toggle
      ? selectables_store.toggle_all(overlapping_now_select_mode_enabled)
      : selectables_store.select_all(overlapping_now_select_mode_enabled);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// selectables local reducer

Reducer<SelectablesStore> selectables_store_reducer = combineReducers([
  TypedReducer<SelectablesStore, actions.Select>(select_reducer),
  TypedReducer<SelectablesStore, actions.SelectAll>(select_all_reducer),
  TypedReducer<SelectablesStore, actions.SelectionsClear>(selections_clear_reducer),
  TypedReducer<SelectablesStore, actions.DNADesignChangingAction>(dna_design_changing_action_reducer),
  TypedReducer<SelectablesStore, actions.SelectModeToggle>(selections_clear_reducer),
  TypedReducer<SelectablesStore, actions.SelectModesSet>(selections_clear_reducer),
]);

// because the DNADesign changed, some selected items may no longer be valid
SelectablesStore dna_design_changing_action_reducer(
        SelectablesStore selectables_store, actions.DNADesignChangingAction _) =>
    selectables_store.clear();

SelectablesStore select_reducer(SelectablesStore selectables_store, actions.Select action) {
  Selectable item = action.selectable;
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
  bool toggle = action.toggle;
  var selection_box = action.selection_box;
  var all_helices = state.dna_design.helices;
  List<util.Box> all_bboxes = all_helices.values.map((helix) => helix_to_box(helix)).toList();
  var selection_box_as_box = util.Box.from_selection_box(selection_box);
  List<Helix> helices_overlapping = util.enclosure_list(all_helices.values, all_bboxes, selection_box_as_box);
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

util.Box helix_to_box(Helix helix) {
  //FIXME: this is making boxes that are not far enough apart
  var position3d = helix.position3d();
  num x, y, width, height;
  var svg_pos = util.position3d_to_side_view_svg(position3d);
  x = svg_pos.x - constants.SIDE_HELIX_RADIUS;
  y = svg_pos.y - constants.SIDE_HELIX_RADIUS;
  height = width = constants.SIDE_HELIX_RADIUS * 2.0;
  return util.Box(x, y, width: width, height: height);
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
