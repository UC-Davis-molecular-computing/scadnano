import 'package:built_collection/built_collection.dart';

import '../state/helix.dart';
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

BuiltList<MouseoverData> mouseover_data_update_reducer(
    _, AppState state, actions.MouseoverDataUpdate action) {
  var mouseover_datas = MouseoverData.from_params(state.dna_design, action.mouseover_params);
  return mouseover_datas.toBuiltList();
}

BuiltList<MouseoverData> helix_rotation_set_at_other_mouseover_reducer(
    BuiltList<MouseoverData> mouseover_datas, AppState state, actions.HelixRollSetAtOther action) {
  Helix helix = state.dna_design.helices[action.helix_idx];
  Helix helix_other = state.dna_design.helices[action.helix_other_idx];
  var geometry = state.dna_design.geometry;
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
  Helix old_helix = model.dna_design.helices[helix_idx];
  double old_rotation_at_rotation_anchor =
      model.dna_design.helix_rotation_forward(old_helix, rotation_anchor);
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
