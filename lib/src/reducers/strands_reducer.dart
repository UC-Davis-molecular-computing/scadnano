import 'package:redux/redux.dart';
import 'package:built_collection/built_collection.dart';


import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/reducers/util_reducer.dart';
import 'package:scadnano/src/state/strand.dart';
import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import 'change_loopout_length.dart';
import 'delete_reducer.dart';
import 'helices_reducer.dart';


BuiltList<Strand> strands_reducer(BuiltList<Strand> strands, action) {
  return strands;
//  var strands_builder = strands.toBuilder();
//  for (int i=0; <strands.length; i++) {
//    Strand strand = strands[i];
//    strand = strands_reducer(strand, action);
//  }
//  return strands_builder.build();
}

//Reducer<Strand> strand_reducer = combineReducers([
//  TypedReducer<Strand, actions.ConvertCrossoverToLoopout>(convert_crossover_to_loopout_reducer),
//  TypedReducer<Strand, actions.LoopoutLengthChange>(loopout_length_change_reducer),
//]);
