import 'package:redux/redux.dart';
import 'package:scadnano/src/state/dna_end_move.dart';

import '../actions/actions.dart' as actions;

Reducer<DNAEndsMove> optimized_dna_ends_move_reducer = combineReducers([
  dna_ends_move_reducer,
]);

Reducer<DNAEndsMove> dna_ends_move_reducer = combineReducers([
  TypedReducer<DNAEndsMove, actions.DNAEndsMoveSetSelectedEnds>(dna_ends_move_set_selected_ends_reducer),
  TypedReducer<DNAEndsMove, actions.DNAEndsMoveAdjustOffset>(dna_ends_move_adjust_reducer),
  TypedReducer<DNAEndsMove, actions.DNAEndsMoveStop>(dna_ends_move_stop_reducer),
]);

DNAEndsMove dna_ends_move_set_selected_ends_reducer(
        DNAEndsMove _, actions.DNAEndsMoveSetSelectedEnds action) =>
    DNAEndsMove(
        moves: action.moves,
        original_offset: action.original_offset,
        current_offset: action.original_offset,
        helix: action.helix,
        strands_affected: action.strands_affected);

DNAEndsMove dna_ends_move_adjust_reducer(DNAEndsMove move, actions.DNAEndsMoveAdjustOffset action) =>
    move.rebuild((b) => b..current_offset = action.offset);

DNAEndsMove dna_ends_move_stop_reducer(DNAEndsMove move, actions.DNAEndsMoveStop action) => null;
