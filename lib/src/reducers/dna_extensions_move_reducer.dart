import 'package:redux/redux.dart';
import '../state/dna_extensions_move.dart';

import '../actions/actions.dart' as actions;

Reducer<DNAExtensionsMove> optimized_dna_extensions_move_reducer = combineReducers([
  dna_extensions_move_reducer,
]);

Reducer<DNAExtensionsMove> dna_extensions_move_reducer = combineReducers([
  TypedReducer<DNAExtensionsMove, actions.DNAExtensionsMoveSetSelectedExtensions>(
      dna_extensions_move_set_selected_ends_reducer),
  TypedReducer<DNAExtensionsMove, actions.DNAExtensionsMoveAdjustOffset>(
      dna_extensions_move_adjust_reducer),
  TypedReducer<DNAExtensionsMove, actions.DNAExtensionsMoveStop>(dna_extensions_move_stop_reducer),
]);

DNAExtensionsMove dna_ends_move_set_selected_ends_reducer(
        DNAExtensionsMove _, actions.DNAExtensionsMoveSetSelectedExtensions action) =>
    DNAExtensionsMove(
        moves: action.moves,
        original_offset: action.original_offset,
        current_offset: action.original_offset,
        helix: action.helix);

DNAEndsMove dna_ends_move_adjust_reducer(DNAEndsMove move, actions.DNAEndsMoveAdjustOffset action) =>
    move.rebuild((b) => b..current_offset = action.offset);

DNAEndsMove dna_ends_move_stop_reducer(DNAEndsMove move, actions.DNAEndsMoveStop action) => null;
