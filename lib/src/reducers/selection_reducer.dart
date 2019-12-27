import 'dart:html';
import 'dart:svg';

import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/dna_end_move.dart';

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
  TypedGlobalReducer<SelectablesStore, AppState, actions.DeleteAllSelected>(delete_all_reducer),
  TypedGlobalReducer<SelectablesStore, AppState, actions.DNAEndsMoveCommit>(ends_moved_reducer),
]);

SelectablesStore delete_all_reducer(
        SelectablesStore selectables_store, AppState state, actions.DeleteAllSelected action) =>
    selectables_store.clear();

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
]);

SelectablesStore select_reducer(SelectablesStore store, actions.Select action) {
  Selectable item = action.selectable;
  bool toggle = action.toggle;
  if (action.only) {
    store = store.select(item, only: true);
  } else {
    if (toggle) {
      store = store.toggle(item);
    } else {
      store = store.select(item);
    }
  }
  return store;
}

SelectablesStore select_all_reducer(SelectablesStore store, actions.SelectAll action) =>
    store.select_all(action.selectables, only: action.only);

SelectablesStore selections_clear_reducer(SelectablesStore store, actions.SelectionsClear action) =>
    store.clear();

//FIXME: If we just finished moving ends, they should remain selected
SelectablesStore ends_moved_reducer(
    SelectablesStore store, AppState state, actions.DNAEndsMoveCommit action) {
  store = store.clear();
//  for (DNAEndMove move in action.dna_ends_move.moves) {
//    DNAEnd dna_end = move.dna_end;
//    BoundSubstrand substrand = state.dna_design.end_to_substrand[dna_end];
//    int new_offset = action.dna_ends_move.current_capped_offset_of(dna_end);
//    int helix = move.dna_end.
//  }
  return store;
//  List<DNAEnd> old_ends = List<DNAEnd>.from(store.selected_items);
//  List<DNAEnd> new_ends = [];
//  for (var end in old_ends) {
//    print(end.id());
//    DNAEnd new_end = state.dna_design.selectable_by_id(end.id());
//    new_ends.add(new_end);
//  }
//  return store.select_all(new_ends);
}

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
  List<util.Box> all_bboxes = all_helices.map((helix) => helix_to_box(helix)).toList();
  List<Helix> helices_overlapping =
//      util.intersection_list(all_helices.toList(), all_bboxes, util.Box.from_selection_box(selection_box));
      util.enclosure_list(all_helices.toList(), all_bboxes, util.Box.from_selection_box(selection_box));
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
  var position3d = helix.position3d();
  num x, y, width, height;
  x = position3d.x - constants.SIDE_HELIX_RADIUS;
  y = position3d.y - constants.SIDE_HELIX_RADIUS;
  height = width = constants.SIDE_HELIX_RADIUS * 2.0;
  return util.Box(x, y, width: width, height: height);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// side_selected_helices local reducer

Reducer<BuiltSet<int>> side_selected_helices_reducer = combineReducers([
  TypedReducer<BuiltSet<int>, actions.HelixSelect>(helix_select_reducer),
  TypedReducer<BuiltSet<int>, actions.HelixSelectionsClear>(helices_selected_clear_reducer),
]);

BuiltSet<int> helix_select_reducer(BuiltSet<int> helices, actions.HelixSelect action) {
  int idx = action.helix_idx;
  bool toggle = action.toggle;
  if (!helices.contains(idx)) {
    helices = helices.rebuild((h) => h.add(idx));
  } else {
    if (toggle) {
      helices = helices.rebuild((h) => h.remove(idx));
    }
  }
  return helices;
}

BuiltSet<int> helices_selected_clear_reducer(BuiltSet<int> helices, actions.HelixSelectionsClear action) =>
    BuiltSet<int>();

///////////////////////////////////////////////////////////////////////////////////////////////////
// selection box reducer

Reducer<SelectionBox> selection_box_reducer = combineReducers([
  TypedReducer<SelectionBox, actions.SelectionBoxCreate>(selection_box_create_reducer),
  TypedReducer<SelectionBox, actions.SelectionBoxSizeChange>(selection_box_size_changed_reducer),
  TypedReducer<SelectionBox, actions.SelectionBoxRemove>(selection_box_remove_reducer),
]);

SelectionBox selection_box_create_reducer(SelectionBox selection_box, actions.SelectionBoxCreate action) =>
    SelectionBox(action.point, action.toggle, action.is_main);

SelectionBox selection_box_size_changed_reducer(
        SelectionBox selection_box, actions.SelectionBoxSizeChange action) =>
    selection_box.rebuild((s) => s..current = action.point);

SelectionBox selection_box_remove_reducer(SelectionBox selection_box, actions.SelectionBoxRemove action) =>
    null;
