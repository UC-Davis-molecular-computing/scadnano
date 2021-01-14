import 'package:built_collection/built_collection.dart';
import 'dart:math';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/selectable.dart';

import '../state/helix.dart';
import '../state/design.dart';
import '../state/app_state.dart';
import '../state/mouseover_data.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

///////////////////////////////////////////////////////////////////////////////////////////////////
// mouseover_data local reducer

BuiltList<MouseoverData> mouseover_data_clear_reducer(_, actions.MouseoverDataClear action) =>
    BuiltList<MouseoverData>();

///////////////////////////////////////////////////////////////////////////////////////////////////
// mouseover_data global reducer



// BuiltList<MouseoverData> mouseover_data_group_displayed_change_reducer(_, AppState state, actions.GroupDisplayedChange action) {
//   var offset = state.ui_state.storables.slice_bar_offset;
//   var group_name = action.group_name;
//   var helices_in_group = state.design.helices_in_group(group_name).values;
//   offset = util.bounded_offset_in_helices_group(offset, helices_in_group);
//   return util.rotation_datas_at_offset_in_group(offset, state.design, group_name);
// }

// BuiltList<MouseoverData> mouseover_data_set_slice_bar_offset_reducer(_, AppState state, actions.SliceBarOffsetSet action) {
//   var offset = action.offset;
//   return util.rotation_datas_at_offset_in_group(offset, state.design, state.ui_state.displayed_group_name);
// }

// BuiltList<MouseoverData> mouseover_data_set_app_ui_state_storable_reducer(_, AppState state, actions.SetAppUIStateStorable action) {
//   var offset = action.storables.slice_bar_offset;
//   return util.rotation_datas_at_offset_in_group(offset, state.design, state.ui_state.displayed_group_name);
// }

BuiltList<MouseoverData> mouseover_data_update_reducer(
    _, AppState state, actions.MouseoverDataUpdate action) {
  var mouseover_datas = MouseoverData.from_params(state.design, action.mouseover_params);
  return mouseover_datas.toBuiltList();
}

BuiltList<MouseoverData> helix_rotation_set_at_other_mouseover_reducer(
    BuiltList<MouseoverData> mouseover_datas, AppState state, actions.HelixRollSetAtOther action) {
  Helix helix = state.design.helices[action.helix_idx];
  Helix helix_other = state.design.helices[action.helix_other_idx];
  var geometry = state.design.geometry;
  num rotation = util.rotation_between_helices(helix, helix_other, action.forward, geometry);
  return _update_mouseover_datas_with_helix_rotation(
    model: state,
    helix_idx: action.helix_idx,
    rotation: rotation,
    rotation_anchor: action.anchor,
    mouseover_datas: mouseover_datas,
  );
}

BuiltList<MouseoverData> _update_mouseover_datas_with_helix_rotation(
    {AppState model,
    int helix_idx,
    num rotation,
    int rotation_anchor,
    BuiltList<MouseoverData> mouseover_datas}) {
  Helix old_helix = model.design.helices[helix_idx];
  double old_rotation_at_rotation_anchor =
      model.design.helix_rotation_forward(old_helix.idx, rotation_anchor);
  double delta_roll = rotation - old_rotation_at_rotation_anchor;

  double new_roll = (old_helix.roll + delta_roll) % 360.0;

  Helix new_helix = old_helix.rebuild((h) => h..roll = new_roll);

  var mouseover_datas_builder = mouseover_datas.toBuilder();
  for (int i = 0; i < mouseover_datas.length; i++) {
    MouseoverData mouseover_data = mouseover_datas[i];
    if (mouseover_data.helix.idx == helix_idx) {
      mouseover_datas_builder[i] = mouseover_data.rebuild((m) => m..helix.replace(new_helix));
    }
  }

  return mouseover_datas_builder.build();
}
