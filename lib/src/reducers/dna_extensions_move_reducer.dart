// @dart=2.9
import 'package:redux/redux.dart';
import '../state/dna_extensions_move.dart';

import '../actions/actions.dart' as actions;

Reducer<DNAExtensionsMove> optimized_dna_extensions_move_reducer = combineReducers([
  dna_extensions_move_reducer,
]);

Reducer<DNAExtensionsMove> dna_extensions_move_reducer = combineReducers([
  TypedReducer<DNAExtensionsMove, actions.DNAExtensionsMoveSetSelectedExtensionEnds>(
      dna_extensions_move_set_selected_extension_ends_reducer),
  TypedReducer<DNAExtensionsMove, actions.DNAExtensionsMoveAdjustPosition>(
      dna_extensions_move_adjust_reducer),
  TypedReducer<DNAExtensionsMove, actions.DNAExtensionsMoveStop>(dna_extensions_move_stop_reducer),
]);

DNAExtensionsMove dna_extensions_move_set_selected_extension_ends_reducer(
        DNAExtensionsMove _, actions.DNAExtensionsMoveSetSelectedExtensionEnds action) =>
    DNAExtensionsMove(
        moves: action.moves, start_point: action.original_point, current_point: action.original_point);

DNAExtensionsMove dna_extensions_move_adjust_reducer(
        DNAExtensionsMove move, actions.DNAExtensionsMoveAdjustPosition action) =>
    move.rebuild((b) => b..current_point = action.position);

DNAExtensionsMove dna_extensions_move_stop_reducer(
        DNAExtensionsMove move, actions.DNAExtensionsMoveStop action) =>
    null;
