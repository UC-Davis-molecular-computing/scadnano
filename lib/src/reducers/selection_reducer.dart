import 'dart:html';
import 'dart:svg';

import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/model/selectable.dart';
import 'package:scadnano/src/view/design.dart';
import '../model/helix.dart';
import '../model/app_state.dart';
import '../model/selection_box.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../constants.dart' as constants;
import '../model/selectable.dart';
import 'util_reducer.dart';

Reducer<SelectionBox> optimized_selection_box_reducer = combineReducers([
  selection_box_reducer,
]);

///////////////////////////////////////////////////////////////////////////////////////////////////
// selectables global reducer

GlobalReducer<SelectablesStore, AppState> selectables_store_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<SelectablesStore, AppState, actions.SelectionsAdjust>(selections_adjust_reducer),
]);

SelectablesStore selections_adjust_reducer(
    SelectablesStore selectables_store, AppState state, actions.SelectionsAdjust action) {
  //XXX: this is not a pure reducer. It seems difficult to put enough state into AppState to reliably detect
  // when one SVG element overlaps another in a way that is robust to future changes in how we draw.
  // Maybe figure out some way to do this with middlware so the reducer can remain pure.

  RectElement select_box = querySelector('#selection-box-main') as RectElement;
  if (select_box == null) {
    return selectables_store;
  }

  //XXX: Firefox does not have getIntersectionList or getEnclosureList
  // (no progress for 10 years on that: https://bugzilla.mozilla.org/show_bug.cgi?id=501421)
  // It didn't work well anyway in Chrome and I basically had to implement it myself anyway based
  // on bounding boxes.

  Rect select_box_bbox = select_box.getBBox();
//    util.transform_rect_svg_to_mouse_coord_main_view(select_box_bbox);

  var selectables_by_id = state.ui_state.selectables_store.selectables_by_id;

//    var elts_all = parent_svg_elt.getEnclosureList(select_box_bbox, null).map((elt) => elt as SvgElement);
//    var elts_all = parent_svg_elt.getIntersectionList(select_box_bbox, null).map((elt) => elt as SvgElement);
//    Set<SvgElement> elts_overlapping = elts_all.where((elt) => elt.classes.contains('selectable')).toSet();

//    Set<SvgElement> elts_overlapping =
//        get_intersection_list(select_box_bbox).map((elt) => elt as SvgElement).toSet();

//  Set<SvgElement> elts_overlapping = get_enclosure_list(select_box_bbox).map((elt) => elt as SvgElement).toSet();
  Set<SvgElement> elts_overlapping =
      util.enclosure_list_in_elt(MAIN_VIEW_SVG_ID, select_box_bbox).map((elt) => elt as SvgElement).toSet();

  //    print('elts_overlapping: $elts_overlapping');

//    Set<Selectable> overlapping_now = {for (var elt in elts_overlapping) selectables_by_id[elt.id]};
  List<Selectable> overlapping_now = [
    for (var elt in elts_overlapping) if (selectables_by_id.containsKey(elt.id)) selectables_by_id[elt.id]
  ];

//    print('elts_overlapping ids: ${[for (var elt in elts_overlapping) elt.id]}');
//    print('overlapping_now:      $overlapping_now');

//    List<Selectable> overlapping_now_select_mode_enabled = [
//      for (var obj in overlapping_now) if (app.model.select_mode_store.is_selectable(obj)) obj
//    ];
  List<Selectable> overlapping_now_select_mode_enabled = [];
  for (var obj in overlapping_now) {
//      print('obj: $obj');
    if (state.ui_state.select_mode_state.is_selectable(obj)) {
      overlapping_now_select_mode_enabled.add(obj);
    }
  }

//    Set<Selectable> overlapping_before = Set<Selectable>.from(selectables_overlapping);
//    Set<Selectable> newly_overlapping = overlapping_now.difference(overlapping_before);
//    Set<Selectable> newly_nonoverlapping = overlapping_before.difference(overlapping_now);

//    print('overlapping_now_select_mode_enabled: $overlapping_now_select_mode_enabled');

  SelectablesStore new_selectables_store;
  if (action.toggle) {
    new_selectables_store = selectables_store.toggle_all(overlapping_now_select_mode_enabled);
  } else {
    new_selectables_store = selectables_store.select_all(overlapping_now_select_mode_enabled);
  }

  return new_selectables_store;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// selectables local reducer

Reducer<SelectablesStore> selectables_store_reducer = combineReducers([
  TypedReducer<SelectablesStore, actions.Select>(select_reducer),
  TypedReducer<SelectablesStore, actions.SelectionsClear>(selections_clear_reducer),
]);

SelectablesStore select_reducer(SelectablesStore store, actions.Select action) {
  Selectable item = action.selectable;
  bool toggle = action.toggle;
  if (toggle) {
    store = store.toggle(item);
  } else {
    store = store.select(item);
  }
  return store;
}

SelectablesStore selections_clear_reducer(SelectablesStore store, actions.SelectionsClear action) =>
    store.clear();

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

SelectionBox selection_box_create_reducer(
        SelectionBox selection_box, actions.SelectionBoxCreate action) =>
    SelectionBox(action.point, action.toggle, action.is_main);

SelectionBox selection_box_size_changed_reducer(
        SelectionBox selection_box, actions.SelectionBoxSizeChange action) =>
    selection_box.rebuild((s) => s..current = action.point);

SelectionBox selection_box_remove_reducer(
        SelectionBox selection_box, actions.SelectionBoxRemove action) =>
    null;
