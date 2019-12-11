import 'package:built_collection/built_collection.dart';

import '../state/strand.dart';

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
