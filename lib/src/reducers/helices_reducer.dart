import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';

import '../model/helix.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

Reducer<BuiltList<Helix>> helices_reducer = combineReducers([
  TypedReducer<BuiltList<Helix>, actions.HelixRotationSet>(helix_rotation_set_reducer),
  TypedReducer<BuiltList<Helix>, actions.HelixRotationSetAtOther>(helix_rotation_set_at_other_reducer),
]);


BuiltList<Helix> helix_rotation_set_reducer(
    BuiltList<Helix> helices, actions.HelixRotationSet action) {
  Helix helix_new = helices[action.helix_idx].rebuild((h) => h
    ..rotation = action.rotation
    ..rotation_anchor = action.anchor);
  ListBuilder<Helix> helix_list_builder = helices.toBuilder();
  helix_list_builder[action.helix_idx] = helix_new;

  return helix_list_builder.build();
}

BuiltList<Helix> helix_rotation_set_at_other_reducer(
    BuiltList<Helix> helices, actions.HelixRotationSetAtOther action) {
  num rotation = util.rotation_between_helices(helices, action);

  Helix helix = helices[action.helix_idx];

  // adjust helix rotation
  Helix helix_new = helix.rebuild((h) => h
    ..rotation = rotation
    ..rotation_anchor = action.anchor);

  // create new helices
  var helices_builder = helices.toBuilder();
  helices_builder[action.helix_idx] = helix_new;
  return helices_builder.build();
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Helix reducer