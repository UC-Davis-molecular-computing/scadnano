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

BuiltList<MouseoverData> mouseover_data_update_reducer(_, AppState state, actions.MouseoverDataUpdate action) {
  var mouseover_datas = MouseoverData.from_params(state.dna_design, action.mouseover_params);
  return mouseover_datas.toBuiltList();
}

BuiltList<MouseoverData> helix_rotation_set_mouseover_reducer(
    BuiltList<MouseoverData> mouseover_datas, AppState model, actions.HelixRotationSet action) =>
    _update_mouseover_datas_with_helix_rotation(
      model: model,
      helix_idx: action.helix_idx,
      rotation: action.rotation,
      rotation_anchor: action.anchor,
      mouseover_datas: mouseover_datas,
    );

BuiltList<MouseoverData> helix_rotation_set_at_other_mouseover_reducer(
    BuiltList<MouseoverData> mouseover_datas, AppState model, actions.HelixRotationSetAtOther action) =>
    _update_mouseover_datas_with_helix_rotation(
      model: model,
      helix_idx: action.helix_idx,
      rotation: util.rotation_between_helices(model.dna_design.helices, action),
      rotation_anchor: action.anchor,
      mouseover_datas: mouseover_datas,
    );

BuiltList<MouseoverData> _update_mouseover_datas_with_helix_rotation(
    {AppState model, int helix_idx, num rotation, int rotation_anchor, BuiltList<MouseoverData> mouseover_datas}) {
  Helix new_helix = model.dna_design.helices[helix_idx].rebuild((h) => h
    ..rotation = rotation
    ..rotation_anchor = rotation_anchor);

  var mouseover_datas_builder = mouseover_datas.toBuilder();
  for (int i = 0; i < mouseover_datas.length; i++) {
    MouseoverData mouseover_data = mouseover_datas[i];
    if (mouseover_data.helix.idx == helix_idx) {
      mouseover_datas_builder[i] = mouseover_data.rebuild((m) => m..helix.replace(new_helix));
    }
  }

  return mouseover_datas_builder.build();
}
