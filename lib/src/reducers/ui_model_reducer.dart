import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';

import '../model/helix.dart';
import '../model/model.dart';
import '../model/ui_model.dart';
import '../model/mouseover_data.dart';
import '../model/select_mode_state.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import 'util_reducer.dart';
import 'selection_reducer.dart';

////////////////////////////////////////////////////////////////////////////////////////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ui model local reducer
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

UIModel ui_model_reducer(UIModel ui_model, action) => ui_model.rebuild((u) => u
  ..changed_since_last_save = changed_since_last_save_reducer(ui_model.changed_since_last_save, action)
  ..select_mode_state.replace(select_mode_state_reducer(ui_model.select_mode_state, action))
  ..show_dna = TypedReducer<bool, actions.SetShowDNA>(show_dna_reducer)(ui_model.show_dna, action)
  ..show_mismatches =
      TypedReducer<bool, actions.SetShowMismatches>(show_mismatches_reducer)(ui_model.show_mismatches, action)
  ..show_editor = TypedReducer<bool, actions.SetShowEditor>(show_editor_reducer)(ui_model.show_editor, action)
  ..show_mouseover_rect = TypedReducer<bool, actions.SetShowMouseoverRect>(show_mouseover_rect_reducer)(
      ui_model.show_mouseover_rect, action)
  ..side_selected_helix_idxs.replace(side_selected_helices_reducer(ui_model.side_selected_helix_idxs, action))
  ..mouse_svg_pos_side_view = side_view_mouse_svg_pos_reducer(ui_model.mouse_svg_pos_side_view, action)
  ..selection_box_main_view.replace(main_view_selection_box_reducer(ui_model.selection_box_main_view, action))
  ..selection_box_side_view.replace(side_view_selection_box_reducer(ui_model.selection_box_side_view, action))
  ..mouseover_datas.replace(mouseover_data_reducer(ui_model.mouseover_datas, action)));

bool show_dna_reducer(bool prev_show, actions.SetShowDNA action) => action.show;

bool show_mismatches_reducer(bool prev_show, actions.SetShowMismatches action) => action.show;

bool show_editor_reducer(bool prev_show, actions.SetShowEditor action) => action.show;

bool show_mouseover_rect_reducer(bool prev_show, actions.SetShowMouseoverRect action) => action.show;

Reducer<bool> changed_since_last_save_reducer = combineReducers([
  TypedReducer<bool, actions.UndoableAction>(changed_since_last_save_undoable_action_reducer),
  TypedReducer<bool, actions.SaveDNAFile>(changed_since_last_save_just_saved_reducer),
]);

bool changed_since_last_save_undoable_action_reducer(bool changed_since_last_save, actions.UndoableAction action) =>
    true;

bool changed_since_last_save_just_saved_reducer(bool changed_since_last_save, actions.SaveDNAFile action) =>
    false;

///////////////////////////////////////////////////////////////////////////////////////////////////
// mouseover_data reducer

Reducer<BuiltList<MouseoverData>> mouseover_data_reducer = combineReducers([
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataClear>(mouseover_data_clear_reducer),
  TypedReducer<BuiltList<MouseoverData>, actions.MouseoverDataUpdate>(mouseover_data_update_reducer),
]);

BuiltList<MouseoverData> mouseover_data_clear_reducer(_, actions.MouseoverDataClear action) =>
    BuiltList<MouseoverData>();

BuiltList<MouseoverData> mouseover_data_update_reducer(_, actions.MouseoverDataUpdate action) => action.mouseover_datas;

///////////////////////////////////////////////////////////////////////////////////////////////////
// side view mouse_svg_pos reducer

Reducer<Point<num>> side_view_mouse_svg_pos_reducer = combineReducers([
  TypedReducer<Point<num>, actions.SideViewMousePositionUpdate>(side_view_mouse_svg_pos_update_reducer),
  TypedReducer<Point<num>, actions.SideViewMousePositionRemove>(side_view_mouse_svg_pos_remove_reducer),
]);

Point<num> side_view_mouse_svg_pos_update_reducer(Point<num> _, actions.SideViewMousePositionUpdate action) =>
    action.point;

Point<num> side_view_mouse_svg_pos_remove_reducer(Point<num> _, actions.SideViewMousePositionRemove action) => null;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// ui model global reducer
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

UIModel ui_model_global_reducer(UIModel ui_model, Model model, action) => ui_model.rebuild((u) => u
  ..mouseover_datas.replace(mouseover_datas_global_reducer(ui_model.mouseover_datas, model, action))
  ..side_selected_helix_idxs
      .replace(side_selected_helices_global_reducer(ui_model.side_selected_helix_idxs, model, action)));

GlobalReducer<BuiltList<MouseoverData>, Model> mouseover_datas_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<MouseoverData>, Model, actions.HelixRotationSet>(helix_rotation_set_mouseover_reducer),
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
