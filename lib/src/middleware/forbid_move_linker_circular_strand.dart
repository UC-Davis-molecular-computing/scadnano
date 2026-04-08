import 'dart:html';

import 'package:redux/redux.dart';
import 'package:scadnano_state/src/state/app_state.dart';
import 'package:scadnano_state/src/actions/actions.dart' as actions;

/// Prevents MoveLinker action when it would create a circular strand by moving
/// a crossover/loopout to the same strand, or when the source strand is already circular
/// (not yet supported).
forbid_move_linker_circular_strand_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.MoveLinker) {
    var design = store.state.design;
    var potential_crossover = action.potential_crossover;
    var linker = potential_crossover.linker!;
    var end_to = action.dna_end_second_click;
    var strand_from = design.linker_to_strand[linker]!;
    var strand_to = design.end_to_strand(end_to);

    if (strand_from == strand_to) {
      var msg =
          'creating circular strand by moving existing crossover/loopout not supported yet'
          'first delete the crossover/loopout, then add a new one';
      window.alert(msg);
      return;
    }

    if (strand_from.circular) {
      window.alert('moving crossover/loopout from a circular strand not yet supported');
      return;
    }
  }

  next(action);
}
