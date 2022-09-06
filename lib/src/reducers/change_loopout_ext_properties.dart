import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/domain.dart';

import '../state/loopout.dart';
import '../state/extension.dart';
import '../state/strand.dart';

import '../actions/actions.dart' as actions;

Strand convert_crossover_to_loopout_reducer(Strand strand, actions.ConvertCrossoverToLoopout action) {
  Loopout loopout_new = Loopout(
    loopout_num_bases: action.length,
    prev_domain_idx: action.crossover.prev_domain_idx,
    is_scaffold: strand.is_scaffold,
  );
  var substrands = strand.substrands.toList();
  substrands.insert(action.crossover.next_domain_idx, loopout_new);

  // this could be the last crossover on a circular strand,
  // which would mean the strand now ends in a Loopout, currently disallowed
  // let's look for two consecutive domains connected by a crossover and make the latter of them
  // the "first" domain, and rotate the substrand list to start there.
  // If we can't find one, we do nothing.
  // (Should have already reported error to user though, in middleware,
  // if they tried to convert the last crossover in a circular strand to be a Loopout.)
  if (action.crossover.next_domain_idx == 0) {
    assert(substrands.first is Loopout);
    int first_dom = -1;
    for (int i = 0; i < substrands.length - 1; i++) {
      if (substrands[i] is Domain && substrands[i + 1] is Domain) {
        first_dom = i + 1;
      }
    }
    if (first_dom < 0) {
      // do nothing if we couldn't find two consecutive domains, i.e., if there's no crossovers left
      assert(strand.crossovers.length == 1);
      return strand;
    }
    substrands = substrands.sublist(first_dom) + substrands.sublist(0, first_dom);
  }
  strand = strand.rebuild((s) => s..substrands.replace(substrands));
  strand = strand.initialize();
  return strand;
}

BuiltList<Strand> convert_crossovers_to_loopouts_reducer(
    BuiltList<Strand> strands, AppState state, actions.ConvertCrossoversToLoopouts action) {
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
        loopout_num_bases: action.length,
        prev_domain_idx: prev_domain_idx,
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

BuiltList<Strand> loopouts_length_change_reducer(
    BuiltList<Strand> strands, AppState state, actions.LoopoutsLengthChange action) {
  Map<String, List<Loopout>> loopouts_on_strand_id = {};
  for (var loopout in action.loopouts) {
    String strand_id = loopout.strand_id;
    if (!loopouts_on_strand_id.containsKey(strand_id)) {
      loopouts_on_strand_id[strand_id] = [];
    }
    loopouts_on_strand_id[strand_id].add(loopout);
  }

  var strands_builder = strands.toBuilder();
  for (String strand_id in loopouts_on_strand_id.keys) {
    Strand strand = state.design.strands_by_id[strand_id];
    int strand_idx = strands.indexOf(strand);
    var substrands = strand.substrands.toList();

    List<Loopout> loopouts = loopouts_on_strand_id[strand_id];

    // sorting probably not necessary; it was needed with earlier logic
    loopouts.sort((c1, c2) => c1.prev_domain_idx - c2.prev_domain_idx);
    for (var loopout in loopouts) {
      int loopout_idx = substrands.indexOf(loopout);
      if (action.length > 0) {
        // shorten length of existing loopout
        Loopout loopout_new = loopout.rebuild((l) => l..loopout_num_bases = action.length);
        substrands[loopout_idx] = loopout_new;
      } else if (action.length == 0) {
        // convert to crossover by removing loopout
        substrands.removeAt(loopout_idx);
      }
    }
    var new_strand = strand.rebuild((s) => s..substrands.replace(substrands));
    new_strand = new_strand.initialize();
    strands_builder[strand_idx] = new_strand;
  }

  return strands_builder.build();
}

BuiltList<Strand> extensions_num_bases_change_reducer(
    BuiltList<Strand> strands, AppState state, actions.ExtensionsNumBasesChange action) {
  Map<String, List<Extension>> exts_on_strand_id = {};
  for (var ext in action.extensions) {
    String strand_id = ext.strand_id;
    if (!exts_on_strand_id.containsKey(strand_id)) {
      exts_on_strand_id[strand_id] = [];
    }
    exts_on_strand_id[strand_id].add(ext);
  }

  var strands_builder = strands.toBuilder();
  for (String strand_id in exts_on_strand_id.keys) {
    Strand strand = state.design.strands_by_id[strand_id];
    int strand_idx = strands.indexOf(strand);
    var substrands = strand.substrands.toList();

    List<Extension> exts = exts_on_strand_id[strand_id];

    for (var ext in exts) {
      int idx = substrands.indexOf(ext);
      if (action.num_bases > 0) {
        // shorten length of existing loopout
        Extension ext_new = ext.rebuild((b) => b..num_bases = action.num_bases);
        substrands[idx] = ext_new;
      } else if (action.num_bases == 0) {
        throw AssertionError('extension must have positive number of bases');
      }
    }
    var new_strand = strand.rebuild((s) => s..substrands.replace(substrands));
    new_strand = new_strand.initialize();
    strands_builder[strand_idx] = new_strand;
  }

  return strands_builder.build();
}

Strand loopout_length_change_reducer(Strand strand, actions.LoopoutLengthChange action) {
  int loopout_idx = strand.substrands.indexOf(action.loopout);
  var substrands_builder = strand.substrands.toBuilder();
  if (action.num_bases > 0) {
    // shorten length of existing loopout
    Loopout loopout_new = action.loopout.rebuild((l) => l..loopout_num_bases = action.num_bases);
    substrands_builder[loopout_idx] = loopout_new;
  } else if (action.num_bases == 0) {
    // convert to crossover by removing loopout
    substrands_builder.removeAt(loopout_idx);
  }
  strand = strand.rebuild((s) => s..substrands = substrands_builder);
  return strand;
}

Strand extension_num_bases_change_reducer(Strand strand, actions.ExtensionNumBasesChange action) {
  int idx = strand.substrands.indexOf(action.ext);
  var substrands_builder = strand.substrands.toBuilder();
  if (action.num_bases > 0) {
    Extension ext_new = action.ext.rebuild((l) => l..num_bases = action.num_bases);
    substrands_builder[idx] = ext_new;
  } else {
    throw AssertionError('extension must have positive number of bases');
  }
  strand = strand.rebuild((s) => s..substrands = substrands_builder);
  return strand;
}

Strand extension_display_length_angle_change_reducer(
    Strand strand, actions.ExtensionDisplayLengthAngleSet action) {
  int idx = strand.substrands.indexOf(action.ext);
  var substrands_builder = strand.substrands.toBuilder();
  if (action.display_length <= 0) {
    throw ArgumentError('extension must have positive display_angle');
  }
  Extension ext_new = action.ext.rebuild((b) => b
    ..display_length = action.display_length
    ..display_angle = action.display_angle);
  substrands_builder[idx] = ext_new;
  strand = strand.rebuild((s) => s..substrands = substrands_builder);
  return strand;
}
