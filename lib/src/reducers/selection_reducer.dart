import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../model/helix.dart';
import '../model/model.dart';
import '../model/selection_box.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'util_reducer.dart';

///////////////////////////////////////////////////////////////////////////////////////////////////
// side_selected_helices global reducer

GlobalReducer<BuiltSet<int>, Model> side_selected_helices_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltSet<int>, Model, actions.HelixSelectionsAdjust>(helix_selections_adjust_reducer),
]);

BuiltSet<int> helix_selections_adjust_reducer(
    BuiltSet<int> helix_idxs_selected, Model model, actions.HelixSelectionsAdjust action) {
  bool toggle = model.ui_model.selection_box_side_view.toggling;
  var selection_box = model.ui_model.selection_box_side_view;
  var all_helices = model.dna_design.helices;
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
  TypedReducer<BuiltSet<int>, actions.HelicesSelectedClear>(helices_selected_clear_reducer),
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

BuiltSet<int> helices_selected_clear_reducer(BuiltSet<int> helices, actions.HelicesSelectedClear action) {
  return BuiltSet<int>();
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// side view selection box reducer

Reducer<SelectionBox> side_view_selection_box_reducer = combineReducers([
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxRemove>(side_view_selection_box_remove_reducer),
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxSizeChanged>(side_view_selection_box_size_changed_reducer),
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxCreateToggling>(
      side_view_selection_box_create_toggling_reducer),
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxCreateSelecting>(
      side_view_selection_box_create_selecting_reducer),
]);

SelectionBox side_view_selection_box_remove_reducer(
        SelectionBox selection_box, actions.SideViewSelectionBoxRemove action) =>
    DEFAULT_SelectionBox;

SelectionBox side_view_selection_box_size_changed_reducer(
        SelectionBox selection_box, actions.SideViewSelectionBoxSizeChanged action) =>
    selection_box.rebuild((s) => s..current = action.point);

SelectionBox side_view_selection_box_create_toggling_reducer(
        SelectionBox selection_box, actions.SideViewSelectionBoxCreateToggling action) =>
    selection_box.start_selection(action.point, true);

SelectionBox side_view_selection_box_create_selecting_reducer(
        SelectionBox selection_box, actions.SideViewSelectionBoxCreateSelecting action) =>
    selection_box.start_selection(action.point, false);

///////////////////////////////////////////////////////////////////////////////////////////////////
// main view selection box reducer

Reducer<SelectionBox> main_view_selection_box_reducer = combineReducers([
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxRemove>(main_view_selection_box_remove_reducer),
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxSizeChanged>(main_view_selection_box_size_changed_reducer),
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxCreateToggling>(
      main_view_selection_box_create_toggling_reducer),
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxCreateSelecting>(
      main_view_selection_box_create_selecting_reducer),
]);

SelectionBox main_view_selection_box_remove_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxRemove action) =>
    DEFAULT_SelectionBox;

SelectionBox main_view_selection_box_size_changed_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxSizeChanged action) =>
//    selection_box.rebuild((s) => s..current = action.point);
    selection_box.rebuild((s) => s..current = util.transform_mouse_coord_to_svg_current_panzoom(action.point, true));

SelectionBox main_view_selection_box_create_toggling_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxCreateToggling action) =>
    selection_box.start_selection(action.point, true);

SelectionBox main_view_selection_box_create_selecting_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxCreateSelecting action) =>
    selection_box.start_selection(action.point, false);
