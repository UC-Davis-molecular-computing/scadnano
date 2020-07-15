import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/strand.dart';

import '../actions/actions.dart' as actions;

Strand convert_crossover_to_loopout_reducer(Strand strand, actions.ConvertCrossoverToLoopout action) {
  Loopout loopout_new = Loopout(action.length, action.crossover.prev_domain_idx,
      action.crossover.next_domain_idx + 1, strand.is_scaffold);
  var substrands_builder = strand.substrands.toBuilder();
  substrands_builder.insert(action.crossover.next_domain_idx, loopout_new);
  strand = strand.rebuild((s) => s..substrands = substrands_builder);
  return strand;
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
