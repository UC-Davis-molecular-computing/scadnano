import 'package:redux/redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/design.dart';

import '../state/helix_group_move.dart';
import '../actions/actions.dart' as actions;

// These interact with optimized store away from full state
Reducer<HelixGroupMove?> optimized_helix_group_move_reducer = combineReducers([
  TypedReducer<HelixGroupMove?, actions.HelixGroupMoveCreate>(helix_group_move_create_translation_reducer),
  TypedReducer<HelixGroupMove?, actions.HelixGroupMoveAdjustTranslation>(
    helix_group_move_adjust_translation_reducer,
  ),
  TypedReducer<HelixGroupMove?, actions.HelixGroupMoveStop>(helix_group_move_stop_translation_reducer),
]);

HelixGroupMove? helix_group_move_create_translation_reducer(
  HelixGroupMove? state,
  actions.HelixGroupMoveCreate action,
) => action.helix_group_move;

HelixGroupMove? helix_group_move_adjust_translation_reducer(
  HelixGroupMove? move,
  actions.HelixGroupMoveAdjustTranslation action,
) => move?.rebuild((b) => b..current_mouse_point = action.mouse_point);

HelixGroupMove? helix_group_move_stop_translation_reducer(
  HelixGroupMove? _,
  actions.HelixGroupMoveStop action,
) => null;

// This interacts with normal state
Design? helix_group_move_commit_global_reducer(
  Design? design,
  AppState state,
  actions.HelixGroupMoveCommit action,
) {
  if (design == null) {
    return null;
  }
  var helix_group_move = action.helix_group_move;
  var group_name = helix_group_move.group_name;
  var new_groups = design.groups.toMap();
  new_groups[group_name] = new_groups[group_name]!.rebuild(
    (b) => b..position.replace(helix_group_move.current_position),
  );
  return design.rebuild((b) => b..groups.replace(new_groups));
}
