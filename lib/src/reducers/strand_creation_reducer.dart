import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/strand_creation.dart';
import '../actions/actions.dart' as actions;

GlobalReducer<StrandCreation, AppState> strand_creation_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<StrandCreation, AppState, actions.StrandCreateStart>(strand_create_start_reducer),
  TypedGlobalReducer<StrandCreation, AppState, actions.StrandCreateAdjustOffset>(
      strand_create_adjust_offset_reducer),
  TypedGlobalReducer<StrandCreation, AppState, actions.StrandCreateStop>(strand_create_stop_reducer),
]);

StrandCreation strand_create_start_reducer(
        StrandCreation strand_creation, AppState state, actions.StrandCreateStart action) =>
    StrandCreation(
        helix: state.design.helices[action.address.helix_idx],
        forward: action.address.forward,
        original_offset: action.address.offset,
        color: action.color);

StrandCreation strand_create_adjust_offset_reducer(
        StrandCreation strand_creation, AppState state, actions.StrandCreateAdjustOffset action) =>
    strand_creation.rebuild((b) => b..current_offset = action.offset);

StrandCreation strand_create_stop_reducer(StrandCreation _, AppState __, actions.StrandCreateStop action) =>
    null;
