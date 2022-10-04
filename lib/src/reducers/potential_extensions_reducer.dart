import 'package:redux/redux.dart';
import '../state/potential_extensions.dart';

import '../actions/actions.dart' as actions;

Reducer<PotentialExtensions> optimized_potential_extensions_reducer = combineReducers([
  // potential_extensions_reducer,
]);

// Reducer<PotentialExtensions> potential_extensions_reducer = combineReducers([
//   TypedReducer<PotentialExtensions, actions.PotentialExtensionsCreate>(potential_extensions_create_reducer),
//   TypedReducer<PotentialExtensions, actions.PotentialExtensionsMove>(potential_extensions_move_reducer),
//   TypedReducer<PotentialExtensions, actions.PotentialExtensionsRemove>(potential_extensions_remove_reducer),
// ]);

// PotentialExtensions potential_extensions_create_reducer(
//         PotentialExtensions potential_extensions, actions.PotentialExtensionsCreate action) =>
//     action.potential_extensions;

// PotentialExtensions potential_extensions_move_reducer(
//         PotentialExtensions potential_extensions, actions.PotentialExtensionsMove action) =>
//     potential_extensions.rebuild((p) => p..current_point = action.point);

// PotentialExtensions potential_extensions_remove_reducer(
//         PotentialExtensions potential_extensions, actions.PotentialExtensionsRemove action) =>
//     null;
