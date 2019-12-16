import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/helix.dart';

import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import 'change_loopout_length.dart';
import 'util_reducer.dart';

Reducer<BuiltList<Strand>> strands_local_reducer = combineReducers([]);

GlobalReducer<BuiltList<Strand>, AppState> strands_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandPartAction>(strands_part_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandCreate>(strand_create),
//  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.HelixRemove>(helix_remove_strand_global_reducer),

//  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.ConvertCrossoverToLoopout>(
//      convert_crossover_to_loopout_reducer),
//  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.LoopoutLengthChange>(loopout_length_change_reducer),
]);

// takes a part of a strand and looks up the strand it's in by strand_id, then applies reducer to strand
BuiltList<Strand> strands_part_reducer(
    BuiltList<Strand> strands, AppState state, actions.StrandPartAction action) {
  Strand strand = state.dna_design.strands_by_id[action.strand_part.strand_id];
  int strand_idx = strands.indexOf(strand);

  strand = strand_part_reducer(strand, action);
  strand = strand.initialize();

  var strands_builder = strands.toBuilder();
  strands_builder[strand_idx] = strand;
  return strands_builder.build();
}

Reducer<Strand> strand_part_reducer = combineReducers([
  TypedReducer<Strand, actions.ConvertCrossoverToLoopout>(convert_crossover_to_loopout_reducer),
  TypedReducer<Strand, actions.LoopoutLengthChange>(loopout_length_change_reducer),
]);

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// create Strand

BuiltList<Strand> strand_create(BuiltList<Strand> strands, AppState state, actions.StrandCreate action) {
  int helix_idx = action.helix_idx;
  int offset = action.offset;
  bool forward = action.forward;

  // ensure 3' end is where mouse clicked
  int start = offset;
  int end = offset + 2;
  if (forward) {
    start = offset - 1;
    end = offset + 1;
  }

  BoundSubstrand substrand = BoundSubstrand(helix: helix_idx, forward: forward, start: start, end: end);
  Strand strand = Strand([substrand]);
  var new_strands = strands.rebuild((s) => s..add(strand));

  return new_strands;
}
