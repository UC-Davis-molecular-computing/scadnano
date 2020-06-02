import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:tuple/tuple.dart';

import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../state/app_state.dart';

/// Check whether user wants to remove helix that has strands on it.
helix_positions_set_based_on_crossovers_middleware(
    Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);
  if (action is actions.HelicesPositionsSetBasedOnCrossovers) {
    _async_helix_positions_set_based_on_crossovers_middleware(store.state);
  }
}

_async_helix_positions_set_based_on_crossovers_middleware(AppState state) async {
  List<Helix> helices = _get_helices_to_process(state);
  print('helices idxs: ${helices.map((e) => e.idx)}');
  List<Crossover> crossovers = _get_crossovers_to_process(state, helices);
  if (crossovers == null) return;
  print('crossovers: ${crossovers}');
}

List<Crossover> _get_crossovers_to_process(AppState state, List<Helix> helices) {
  var dna_design = state.dna_design;
  var selected_crossovers = state.ui_state.selectables_store.selected_crossovers;
  var selected_crossovers_by_prev_helix_idx =
      _get_selected_crossovers_by_prev_helix_idx(selected_crossovers, helices, dna_design);

  List<Crossover> crossovers = [];
  for (int i = 0; i < helices.length - 1; i++) {
    var h1 = helices[i];
    var h2 = helices[i + 1];
    var pair = Tuple2<int,int>(h1.idx,h2.idx);
    var crossovers_this_helices_pair = selected_crossovers_by_prev_helix_idx[pair];
    Crossover crossover;

    // first try selected crossovers, but ensure there's at most one per pair of helices
    if (crossovers_this_helices_pair.length > 1) {
      var msg = '''Can select at most one crossover between any pair of adjacent helices.
You have selected multiple crossovers between helices ${h1.idx} and ${h2.idx}.
Please select only one, or select none to default to the first crossover between them.
''';
      util.async_alert(msg);
      return null;
    } else if (crossovers_this_helices_pair.length == 1) {
      // first try selected crossovers between this pair of helices
      crossover = crossovers_this_helices_pair.first;
    } else {
      // otherwise if none are selected, find the first crossover between this pair of helices
      crossover = _first_crossover_between_helices(h1, h2, dna_design);
      if (crossover == null) {
        var msg = 'Must have at least one crossover between helices ${h1.idx} and ${h2.idx}';
        util.async_alert(msg);
        return null;
      }
    }
    crossovers.add(crossover);
  }
  return crossovers;
}

// "First" refers to having the lowest offset on helix h1.
Crossover _first_crossover_between_helices(Helix h1, Helix h2, DNADesign dna_design) {
  BuiltList<Crossover> crossovers_on_h1 = dna_design.crossovers_by_helix_idx[h1.idx];
  BuiltSet<Crossover> crossovers_on_h2 = dna_design.crossovers_by_helix_idx_as_sets[h2.idx];

  // find first crossover on h1 that also goes to h2
  for (Crossover crossover in crossovers_on_h1) {
    if (crossovers_on_h2.contains(crossover)) {
      return crossover;
    }
  }

  // maybe none on h1 go to h2
  return null;
}

// Return map mapping (prev,next) helix idx to list of crossovers between helices prev and next,
// only for values of prev,next that are adjacent in helices.
// e.g., if indices of helices are 3,2,7,5 (in that order in argument helices), returns map
// {
//   (3,2): [... list of crossovers between 2 and 3],
//   (2,7): [... list of crossovers between 2 and 7],
//   (7,5): [... list of crossovers between 5 and 7]
// }
// Sorts each list by the offset on its first helix (first meaning first in order in helices)
Map<Tuple2<int, int>, List<Crossover>> _get_selected_crossovers_by_prev_helix_idx(
    BuiltSet<Crossover> selected_crossovers, List<Helix> helices, DNADesign dna_design) {
  // this is essentially what we return, but each crossover also carries with it the start offset of
  // the helix earlier in the ordering, which helps to sort the lists of crossovers before returning
  Map<Tuple2<int, int>, List<Tuple2<int, Crossover>>> start_crossover_pairs = {};

  // initialize internal map to have empty lists
  for (int i = 0; i < helices.length - 1; i++) {
    int idx1 = helices[i].idx;
    int idx2 = helices[i + 1].idx;
    var pair_idxs = Tuple2<int, int>(idx1, idx2);
    start_crossover_pairs[pair_idxs] = [];
  }

  // populate internal map with start offsets along with lists
  for (var crossover in selected_crossovers) {
    var strand = dna_design.crossover_to_strand[crossover];
    var dom1 = strand.substrands[crossover.prev_domain_idx] as Domain;
    var dom2 = strand.substrands[crossover.next_domain_idx] as Domain;
    var idx1 = dom1.helix;
    var idx2 = dom2.helix;
    var pair_idxs = Tuple2<int, int>(idx1, idx2);
    var pair_idxs_rev = Tuple2<int, int>(idx2, idx1);
    if (start_crossover_pairs.containsKey(pair_idxs)) {
      start_crossover_pairs[pair_idxs].add(Tuple2<int, Crossover>(dom1.start, crossover));
    } else if (start_crossover_pairs.containsKey(pair_idxs_rev)) {
      start_crossover_pairs[pair_idxs_rev].add(Tuple2<int, Crossover>(dom2.start, crossover));
    }
  }

  // use internal map to construct map to return, which does not have the start offsets explicitly stored
  Map<Tuple2<int, int>, List<Crossover>> crossovers = {};
  for (var pair_idxs in start_crossover_pairs.keys) {
    List<Tuple2<int, Crossover>> start_crossover_pair_list = start_crossover_pairs[pair_idxs];
    start_crossover_pair_list.sort((start_crossover_pair1, start_crossover_pair2) {
      int start1 = start_crossover_pair1.item1;
      int start2 = start_crossover_pair2.item1;
      return start1 - start2;
    });
    List<Crossover> crossover_list = [
      for (var start_crossover_pair in start_crossover_pair_list) start_crossover_pair.item2
    ];
    crossovers[pair_idxs] = crossover_list;
  }

  return crossovers;
}

// Gets helices in order of their view order
List<Helix> _get_helices_to_process(AppState state) {
  DNADesign design = state.dna_design;
  List<Helix> helices;
  BuiltSet<int> selected_helix_idxs = state.ui_state.side_selected_helix_idxs;
  if (selected_helix_idxs.isEmpty) {
    helices = design.helices.values.toList();
  } else {
    helices = [for (var helix_idx in selected_helix_idxs) design.helices[helix_idx]];
  }
  helices.sort((h1, h2) => h1.view_order - h2.view_order);
  return helices;
}
