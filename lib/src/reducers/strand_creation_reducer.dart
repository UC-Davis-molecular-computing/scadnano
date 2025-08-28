import 'package:scadnano/src/state/address.dart';
import '../reducers/util_reducer.dart';
import '../state/app_state.dart';
import '../state/strand_creation.dart';
import '../actions/actions.dart' as actions;

GlobalReducer<StrandCreation?, AppState> strand_creation_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<StrandCreation?, AppState, actions.StrandCreateStart>(strand_create_start_reducer),
  TypedGlobalReducer<StrandCreation?, AppState, actions.StrandCreateAdjustOffset>(
    strand_create_adjust_offset_reducer,
  ),
  TypedGlobalReducer<StrandCreation?, AppState, actions.StrandCreateStop>(strand_create_stop_reducer),
]);

StrandCreation? strand_create_start_reducer(
  StrandCreation? _,
  AppState state,
  actions.StrandCreateStart action,
) => StrandCreation(
  helix: state.design.helices[action.address.helix_idx]!,
  forward: action.address.forward,
  original_offset: action.address.offset,
  color: action.color,
);

StrandCreation? strand_create_adjust_offset_reducer(
  StrandCreation? strand_creation,
  AppState state,
  actions.StrandCreateAdjustOffset action,
) {
  if (strand_creation == null) {
    return null;
  }
  int new_offset = action.offset;
  int old_offset = strand_creation.current_offset;

  var new_address = Address(
    helix_idx: strand_creation.helix.idx,
    offset: new_offset,
    forward: strand_creation.forward,
  );
  if (state.ui_state.dynamically_update_helices) {
    if (old_offset != new_offset &&
        !state.design.is_occupied(new_address, strand_creation) && // can't draw strand over existing strand
        new_offset !=
            strand_creation
                .original_offset // can't put start and end at same offset
    // state.design.helices[strand_creation.helix.idx].min_offset <= new_offset && // can't go off end of helix
    // new_offset < state.design.helices[strand_creation.helix.idx].max_offset
    ) {
      return strand_creation.rebuild((b) => b..current_offset = action.offset);
    }
  } else {
    if (old_offset != new_offset &&
        !state.design.is_occupied(new_address, strand_creation) && // can't draw strand over existing strand
        new_offset != strand_creation.original_offset && // can't put start and end at same offset
        state.design.helices[strand_creation.helix.idx]!.min_offset <=
            new_offset && // can't go off end of helix
        new_offset < state.design.helices[strand_creation.helix.idx]!.max_offset) {
      return strand_creation.rebuild((b) => b..current_offset = action.offset);
    }
  }
  return strand_creation;
}

StrandCreation? strand_create_stop_reducer(StrandCreation? _, AppState __, actions.StrandCreateStop action) =>
    null;
