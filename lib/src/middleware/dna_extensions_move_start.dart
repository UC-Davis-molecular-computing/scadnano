import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/potential_extension.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/dna_end.dart';
import '../state/dna_ends_move.dart';
import '../state/helix.dart';
import '../state/strand.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';

// This is needed to gather the list of selected ends and package them into an action to start the moving
// of selected ends. It is needed because the click on the DNAEnd that triggers the DNAEndsMoveStart action
// does not have access to the list of all selected ends. It is middleware instead of a reducer because
// it triggers a new action to be dispatched.
dna_extensions_move_start_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.DNAExtensionsMoveStart) {
    BuiltSet<DNAEnd> selected_ends = store.state.ui_state.selectables_store.selected_dna_ends_on_extensions;
    List<PotentialExtension> moves = [];
    for (var end in selected_ends) {
      var move = PotentialExtension(dna_end: end);
      moves.add(move);
    }

    Design design = store.state.design;
    Set<Strand> strands_affected = {};
    for (var move in moves) {
      Strand strand = design.end_to_strand(move.dna_end);
      strands_affected.add(strand);
    }
    next(action);

    // important that we dispatch to app, not to store, because the app dispatch will know to route this
    // to the appropriate optimized store for moving DNAEnds
    app.dispatch(actions.DNAExtensionsMoveSetSelectedExtensions(
        original_point: action.start_point,
        moves: moves.toBuiltList(),
        strands_affected: strands_affected.toBuiltSet()));
  } else {
    next(action);
  }
}
