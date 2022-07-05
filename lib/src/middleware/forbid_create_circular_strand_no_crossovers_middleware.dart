import 'dart:html';

import 'package:redux/redux.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/strand.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../state/grid_position.dart';
import '../state/helix.dart';


/// Disallows converting all crossovers on a circular strand to loopouts, since then the first
/// substrand would necessarily be a loopout, currently disallowed.
forbid_create_circular_strand_no_crossovers_middleware(Store<AppState> store, dynamic action,
    NextDispatcher next) {
  Design design = store.state.design;

  var msg_generic = """\
Unfortunately it is not possible in scadnano to create a circular strand 
with no crossovers and only loopouts. (This is because it is unsupported 
for a strand to begin or end with a loopout, even a circular strand, 
where one is chosen arbitrarily as the "first"). 

See https://github.com/UC-Davis-molecular-computing/scadnano/issues/34""";

  if (action is actions.ConvertCrossoverToLoopout) {
    Crossover crossover = action.crossover;
    Strand strand = design.crossover_to_strand[crossover];
    if (strand.circular && strand.crossovers.length == 1) {
      var msg = """\
This is the only crossover on this circular strand. It cannot be converted
to a loopout.
${msg_generic}""";
      window.alert(msg);
      return;
    }
  } else if (action is actions.ConvertCrossoversToLoopouts) {
    // collect crossovers associated to each strand
    Map<String, List<Crossover>> crossovers_on = {};
    for (var crossover in action.crossovers) {
      String strand_id = crossover.strand_id;
      if (!crossovers_on.containsKey(strand_id)) {
        crossovers_on[strand_id] = [];
      }
      crossovers_on[strand_id].add(crossover);
    }

    // check if any strand would lose all its crossovers
    for (var strand_id in crossovers_on.keys) {
      Strand strand = design.strands_by_id[strand_id];
      List<Crossover> crossovers = crossovers_on[strand_id];
      if (strand.crossovers.length == crossovers.length) {
        int helix = strand.first_domain.helix;
        var offset_5p = strand.first_domain.offset_5p;
        var forward = strand.first_domain.forward;
        var msg = """\
The strand with 5' end at helix ${helix}, offset ${offset_5p}, forward = ${forward} 
cannot have all of its crossovers converted to Loopouts.
${msg_generic}""";
        window.alert(msg);
        return;
      }
    }
  } else if (action is actions.Ligate) {

    var dna_end = action.dna_end;
    var strand = design.end_to_strand(dna_end);

    // find other strand
    var domain = design.end_to_domain[dna_end];
    var address_end = dna_end.is_start ? domain.address_start : domain.address_end;
    int delta = dna_end.is_start ? -1 : 1;
    var address_other_end = address_end.rebuild((b) => b..offset = b.offset + delta);
    var domain_other = design.domain_on_helix_at(address_other_end);
    var strand_other = design.substrand_to_strand[domain_other];

    // if they are same strand, and there are no crossovers, warn about forbidding this ligation
    if (identical(strand, strand_other) && strand.crossovers.isEmpty) {
      var msg = """\
This strand has no crossovers so cannot be made circular.
${msg_generic}""";
      window.alert(msg);
      return;
    }
  }

  next(action);
}
