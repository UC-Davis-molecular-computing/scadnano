// @dart=2.9
import 'package:redux/redux.dart';
import '../state/potential_crossover.dart';

import '../actions/actions.dart' as actions;

Reducer<PotentialCrossover> optimized_potential_crossover_reducer = combineReducers([
  potential_crossover_reducer,
]);

Reducer<PotentialCrossover> potential_crossover_reducer = combineReducers([
  TypedReducer<PotentialCrossover, actions.PotentialCrossoverCreate>(potential_crossover_create_reducer),
  TypedReducer<PotentialCrossover, actions.PotentialCrossoverMove>(potential_crossover_move_reducer),
  TypedReducer<PotentialCrossover, actions.PotentialCrossoverRemove>(potential_crossover_remove_reducer),
]);

PotentialCrossover potential_crossover_create_reducer(
        PotentialCrossover potential_crossover, actions.PotentialCrossoverCreate action) =>
    action.potential_crossover;

PotentialCrossover potential_crossover_move_reducer(
        PotentialCrossover potential_crossover, actions.PotentialCrossoverMove action) =>
    potential_crossover.rebuild((p) => p..current_point = action.point);

PotentialCrossover potential_crossover_remove_reducer(
        PotentialCrossover potential_crossover, actions.PotentialCrossoverRemove action) =>
    null;
