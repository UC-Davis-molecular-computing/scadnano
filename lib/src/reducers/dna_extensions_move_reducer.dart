import 'package:redux/redux.dart';
import '../state/potential_extensions.dart';

import '../actions/actions.dart' as actions;

Reducer<PotentialExtensions> optimized_dna_extensions_move_reducer = combineReducers([
  dna_extensions_move_reducer,
]);

Reducer<PotentialExtensions> dna_extensions_move_reducer = combineReducers([
  TypedReducer<PotentialExtensions, actions.DNAExtensionsMoveSetSelectedExtensions>(
      dna_extensions_move_set_selected_ends_reducer),
  TypedReducer<PotentialExtensions, actions.DNAExtensionsMoveAdjustOffset>(
      dna_extensions_move_adjust_reducer),
  TypedReducer<PotentialExtensions, actions.DNAExtensionsMoveStop>(dna_extensions_move_stop_reducer),
]);

PotentialExtensions dna_ends_move_set_selected_ends_reducer(
        PotentialExtensions _, actions.DNAExtensionsMoveSetSelectedExtensions action) =>
    PotentialExtensions(
        moves: action.moves,
        original_offset: action.original_offset,
        current_offset: action.original_offset,
        helix: action.helix);

DNAEndsMove dna_ends_move_adjust_reducer(DNAEndsMove move, actions.DNAEndsMoveAdjustOffset action) =>
    move.rebuild((b) => b..current_offset = action.offset);

DNAEndsMove dna_ends_move_stop_reducer(DNAEndsMove move, actions.DNAEndsMoveStop action) => null;
