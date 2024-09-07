import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/dna_extensions_move.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/dna_end.dart';
import '../state/dna_ends_move.dart';
import '../state/helix.dart';
import '../state/strand.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';

import '../util.dart' as util;

// This is needed to gather the list of selected ends and package them into an action to start the moving
// of selected ends. It is needed because the click on the DNAEnd that triggers the DNAEndsMoveStart action
// does not have access to the list of all selected ends. It is middleware instead of a reducer because
// it triggers a new action to be dispatched.
dna_extensions_move_start_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.DNAExtensionsMoveStart) {
    BuiltSet<DNAEnd> selected_ends = store.state.ui_state.selectables_store.selected_dna_ends_on_extensions;
    List<DNAExtensionMove> moves = [];
    Design design = store.state.design;
    for (var end in selected_ends) {
      var extension = design.end_to_extension[end]!;
      var helix = design.helices[extension.adjacent_domain.helix]!;
      var extension_start_point = util.compute_extension_attached_end_svg(
          extension,
          extension.adjacent_domain,
          helix,
          store.state.helix_idx_to_svg_position_map[extension.adjacent_domain.helix]!.y);

      // extension_start_point is in helix group coordinate space, so add it with helix group position
      // to get canvas coordinate space
      extension_start_point += design.groups[helix.group]!.translation(design.geometry);

      var extension_end_point = util.compute_extension_free_end_svg(
          extension_start_point, extension, extension.adjacent_domain, design.geometry);
      var color = design.extension_end_to_strand(end).color;
      var move = DNAExtensionMove(
          dna_end: end,
          color: color,
          original_position: extension_end_point,
          attached_end_position: extension_start_point,
          extension: extension);
      moves.add(move);
    }

    Set<Strand> strands_affected = {};
    for (var move in moves) {
      Strand strand = design.extension_end_to_strand(move.dna_end);
      strands_affected.add(strand);
    }
    next(action);

    // important that we dispatch to app, not to store, because the app dispatch will know to route this
    // to the appropriate optimized store for moving DNAEnds
    app.dispatch(actions.DNAExtensionsMoveSetSelectedExtensionEnds(
        original_point: action.start_point,
        moves: moves.toBuiltList(),
        strands_affected: strands_affected.toBuiltSet(),
        helix: action.helix));
  } else {
    next(action);
  }
}
