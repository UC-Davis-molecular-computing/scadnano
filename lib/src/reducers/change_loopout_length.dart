import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/crossover.dart';

import '../state/loopout.dart';
import '../state/strand.dart';

import '../actions/actions.dart' as actions;

Strand convert_crossover_to_loopout_reducer(Strand strand, actions.ConvertCrossoverToLoopout action) {
  Loopout loopout_new = Loopout(
    loopout_length: action.length,
    prev_domain_idx: action.crossover.prev_domain_idx,
    next_domain_idx: action.crossover.next_domain_idx + 1,
    is_scaffold: strand.is_scaffold,
  );
  var substrands_builder = strand.substrands.toBuilder();
  substrands_builder.insert(action.crossover.next_domain_idx, loopout_new);
  strand = strand.rebuild((s) => s..substrands = substrands_builder);
  return strand;
}

BuiltList<Strand> convert_crossovers_to_loopouts_reducer(BuiltList<Strand> strands, AppState state,
    actions.ConvertCrossoversToLoopouts action) {
  // TODO: need to dynamically calculate index of crossover as strand is being converted,
  //  since inserting loopouts earlier will increase indices

  Map<String, List<Crossover>> crossovers_on_strand_id = {};
  for (var crossover in action.crossovers) {
    String strand_id = crossover.strand_id;
    if (!crossovers_on_strand_id.containsKey(strand_id)) {
      crossovers_on_strand_id[strand_id] = [];
    }
    crossovers_on_strand_id[strand_id].add(crossover);
  }

  var strands_builder = strands.toBuilder();
  for (String strand_id in crossovers_on_strand_id.keys) {
    Strand strand = state.design.strands_by_id[strand_id];
    int strand_idx = strands.indexOf(strand);
    var substrands_builder = strand.substrands.toBuilder();

    List<Crossover> crossovers = crossovers_on_strand_id[strand_id];
    // must sort by crossover order for this logic to work with num_crossovers_processed_on_strand variable
    crossovers.sort((c1, c2) => c1.prev_domain_idx - c2.prev_domain_idx);
    int num_crossovers_processed_on_strand = 0;
    for (var crossover in crossovers) {
      int prev_domain_idx = crossover.prev_domain_idx + num_crossovers_processed_on_strand;
      int next_domain_idx = crossover.next_domain_idx + num_crossovers_processed_on_strand;
      Loopout loopout_new = Loopout(
        loopout_length: action.length,
        prev_domain_idx: prev_domain_idx,
        next_domain_idx: next_domain_idx + 1,
        is_scaffold: strand.is_scaffold,
      );
      substrands_builder.insert(next_domain_idx, loopout_new);
      num_crossovers_processed_on_strand++;
    }
    var new_strand = strand.rebuild((s) => s..substrands = substrands_builder);
    new_strand = new_strand.initialize();
    strands_builder[strand_idx] = new_strand;
  }

  return strands_builder.build();
}

Strand loopout_length_change_reducer(Strand strand, actions.LoopoutLengthChange action) {
  int loopout_idx = strand.substrands.indexOf(action.loopout);
  var substrands_builder = strand.substrands.toBuilder();
  if (action.length > 0) {
    // shorten length of existing loopout
    Loopout loopout_new = action.loopout.rebuild((l) => l..loopout_length = action.length);
    substrands_builder[loopout_idx] = loopout_new;
  } else if (action.length == 0) {
    // convert to crossover by removing loopout
    substrands_builder.removeAt(loopout_idx);
  }
  strand = strand.rebuild((s) => s..substrands = substrands_builder);
  return strand;
}
