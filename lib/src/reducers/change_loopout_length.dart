import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/strand.dart';

import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;

DNADesign convert_crossover_to_loopout_reducer(
    DNADesign dna_design, AppState state, actions.ConvertCrossoverToLoopout action) {
  Strand strand = state.ui_state.selectables_store.selectables_by_id[action.crossover.strand_id];

  return dna_design;
}

DNADesign loopout_length_change_reducer(
    DNADesign dna_design, AppState state, actions.LoopoutLengthChange action) {
  print('action: $action');
  return dna_design;
}
