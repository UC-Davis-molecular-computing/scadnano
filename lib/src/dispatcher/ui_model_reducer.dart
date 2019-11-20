import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:redux/redux.dart';
import 'package:built_value/built_value.dart';
import 'package:scadnano/src/model/helix.dart';

import '../model/model.dart';
import '../model/ui_model.dart';
import '../model/mouseover_data.dart';
import '../model/select_mode_state.dart';
import '../model/selectable.dart';
import '../model/selection_box.dart';
import 'actions.dart' as actions;
import '../util.dart' as util;
import '../built_intern.dart';
import 'global_reducers.dart';

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ui model local reducer
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

UIModel ui_model_reducer(UIModel ui_model, action) => ui_model.rebuild((u) => u
  ..select_mode_state.replace(select_mode_state_reducer(ui_model.select_mode_state, action))
  ..show_dna = show_dna_reducer(ui_model.show_dna, action)
  ..show_mismatches = show_mismatches_reducer(ui_model.show_mismatches, action)
  ..show_editor = show_editor_reducer(ui_model.show_editor, action)
  ..side_selected_helices.replace(side_selected_helices_reducer(ui_model.side_selected_helices, action))
  ..mouse_svg_pos_side_view = side_view_mouse_svg_pos_reducer(ui_model.mouse_svg_pos_side_view, action)
  ..selection_box_main_view.replace(main_view_selection_box_reducer(ui_model.selection_box_main_view, action))
  ..selection_box_side_view.replace(side_view_selection_box_reducer(ui_model.selection_box_side_view, action))
  ..mouseover_datas.replace(mouseover_data_reducer(ui_model.mouseover_datas, action)));

bool show_dna_reducer(bool prev_show, action) => action is actions.SetShowDNA ? action.show_dna : prev_show;

bool show_mismatches_reducer(bool prev_show, action) =>
    action is actions.SetShowMismatches ? action.show_mismatches : prev_show;

bool show_editor_reducer(bool prev_show, action) =>
    action is actions.SetShowEditor ? action.show_editor : prev_show;

///////////////////////////////////////////////////////////////////////////////////////////////////
// side_selected_helices reducer

Reducer<BuiltSet<int>> side_selected_helices_reducer = combineReducers([
  TypedReducer<BuiltSet<int>, actions.HelicesSelectedToggle>(helices_selected_toggle_reducer),
  TypedReducer<BuiltSet<int>, actions.HelicesSelectedSelect>(helices_selected_select_reducer),
  TypedReducer<BuiltSet<int>, actions.HelicesSelectedClear>(helices_selected_clear_reducer),
]);

BuiltSet<int> helices_selected_toggle_reducer(BuiltSet<int> helices, actions.HelicesSelectedToggle action) {
  var helices_to_add = SetBuilder<int>();
  var helices_to_remove = SetBuilder<int>();
  for (var helix in action.helices) {
    if (helices.contains(helix)) {
      helices_to_remove.add(helix);
    } else {
      helices_to_add.add(helix);
    }
  }
  var new_helices = helices.toBuilder();
  new_helices.removeAll(helices_to_remove.build());
  new_helices.addAll(helices_to_add.build());
  return new_helices.build().intern();
}

BuiltSet<int> helices_selected_select_reducer(BuiltSet<int> helices, actions.HelicesSelectedSelect action) {
  var new_helices = helices.toBuilder();
  new_helices.addAll(action.helices);
  return new_helices.build().intern();
}

BuiltSet<int> helices_selected_clear_reducer(BuiltSet<int> helices, actions.HelicesSelectedClear action) {
  return BuiltSet<int>().intern();
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// mouseover_data reducer

Reducer<BuiltList<MouseoverData>> mouseover_data_reducer = combineReducers([
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataClear>(mouseover_data_clear_reducer),
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataUpdate>(mouseover_data_update_reducer),
]);

BuiltList<MouseoverData> mouseover_data_clear_reducer(_, action) => BuiltList<MouseoverData>();

BuiltList<MouseoverData> mouseover_data_update_reducer(_, actions.MouseoverDataUpdate action) {
//  print('mouseover_data_update_reducer called');
  return action.mouseover_datas;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// side view mouse_svg_pos reducer

Reducer<Point<num>> side_view_mouse_svg_pos_reducer = combineReducers([
  TypedReducer<Point<num>, actions.SideViewMousePositionUpdate>(side_view_mouse_svg_pos_update_reducer),
  TypedReducer<Point<num>, actions.SideViewMousePositionRemove>(side_view_mouse_svg_pos_remove_reducer),
]);

Point<num> side_view_mouse_svg_pos_update_reducer(Point<num> _, actions.SideViewMousePositionUpdate action) =>
    action.point;

Point<num> side_view_mouse_svg_pos_remove_reducer(Point<num> _, actions.SideViewMousePositionRemove action) =>
    null;

///////////////////////////////////////////////////////////////////////////////////////////////////
// side view selection box reducer

Reducer<SelectionBox> side_view_selection_box_reducer = combineReducers([
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxRemove>(side_view_selection_box_remove_reducer),
  TypedReducer<SelectionBox, actions.SideViewSelectionBoxSizeChanged>(
      side_view_selection_box_size_changed_reducer),
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
  TypedReducer<SelectionBox, actions.MainViewSelectionBoxSizeChanged>(
      main_view_selection_box_size_changed_reducer),
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
    selection_box
        .rebuild((s) => s..current = util.transform_mouse_coord_to_svg_current_panzoom(action.point, true));

SelectionBox main_view_selection_box_create_toggling_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxCreateToggling action) =>
    selection_box.start_selection(action.point, true);

SelectionBox main_view_selection_box_create_selecting_reducer(
        SelectionBox selection_box, actions.MainViewSelectionBoxCreateSelecting action) =>
    selection_box.start_selection(action.point, false);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ui model global reducer
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

UIModel ui_model_global_reducer(UIModel ui_model, Model model, action) => ui_model.rebuild((u) =>
    u..mouseover_datas.replace(mouseover_datas_global_reducer(ui_model.mouseover_datas, model, action)));

GlobalReducer<BuiltList<MouseoverData>, Model> mouseover_datas_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<MouseoverData>, Model, actions.HelixRotationSet>(
      helix_rotation_set_mouseover_reducer),
  TypedGlobalReducer<BuiltList<MouseoverData>, Model, actions.HelixRotationSetAtOther>(
      helix_rotation_set_at_other_mouseover_reducer),
]);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// mouseover datas global reducer


//FIXME: implement this
BuiltList<MouseoverData> helix_rotation_set_mouseover_reducer(
    BuiltList<MouseoverData> mouseover_data, Model model, actions.HelixRotationSet action) =>
    mouseover_data;

BuiltList<MouseoverData> helix_rotation_set_at_other_mouseover_reducer(
    BuiltList<MouseoverData> mouseover_datas, Model model, actions.HelixRotationSetAtOther action) {

  num rotation = util.rotation_between_helices(model.dna_design.helices, action);
  Helix new_helix = model.dna_design.helices[action.helix_idx].rebuild((h) => h
    ..rotation = rotation
    ..rotation_anchor = action.anchor);

  var mouseover_datas_builder = mouseover_datas.toBuilder();
  for (int i = 0; i < mouseover_datas.length; i++) {
    MouseoverData mouseover_data = mouseover_datas[i];
    if (mouseover_data.helix.idx == action.helix_idx) {
      mouseover_datas_builder[i] = mouseover_data.rebuild((m) => m..helix.replace(new_helix));
    }
  }

  return mouseover_datas_builder.build();
}
