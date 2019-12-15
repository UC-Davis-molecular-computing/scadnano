import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/linker.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/substrand.dart';

import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import 'change_loopout_length.dart';
import 'nick_join_reducers.dart';
import 'util_reducer.dart';
import '../util.dart' as util;

Reducer<BuiltList<Strand>> strands_local_reducer = combineReducers([]);

GlobalReducer<BuiltList<Strand>, AppState> strands_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandPartAction>(strands_part_reducer),
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



