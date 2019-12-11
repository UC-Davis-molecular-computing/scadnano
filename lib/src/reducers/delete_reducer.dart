import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/linker.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';

import '../state/dna_design.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;

DNADesign dna_design_delete_all_reducer(
    DNADesign dna_design, AppState state, actions.DeleteAllSelected action) {
  BuiltSet<Selectable> items = state.ui_state.selectables_store.selected_items;
  if (items.isEmpty) {
    return dna_design;
  }

  if (state.ui_state.select_mode_state.strands_selectable()) {
    var strands = Set<Strand>.from(items.where((item) => item is Strand));
    dna_design = _remove_strands(dna_design, strands);
  } else if (state.ui_state.select_mode_state.linkers_selectable()) {
    var crossovers = Set<Crossover>.from(items.where((item) => item is Crossover));
    var loopouts = Set<Loopout>.from(items.where((item) => item is Loopout));
    dna_design = _remove_crossovers_and_loopouts(dna_design, crossovers, loopouts);
  } else if (state.ui_state.select_mode_state.ends_selectable()) {
    var ends = items.where((item) => item is DNAEnd);
    var substrands = Set<BoundSubstrand>.from(ends.map((end) => state.dna_design.end_to_substrand[end]));
    dna_design = _remove_bound_substrands(dna_design, substrands);
  }

  return dna_design;
}

DNADesign _remove_strands(DNADesign dna_design, Iterable<Strand> strands_to_remove) =>
    dna_design.rebuild((d) => d..strands.removeWhere((strand) => strands_to_remove.contains(strand)));

DNADesign _remove_crossovers_and_loopouts(
    DNADesign dna_design, Iterable<Crossover> crossovers, Iterable<Loopout> loopouts) {
  Set<Strand> strands_to_remove = {};
  List<Strand> strands_to_add = [];

  // collect all linkers for one strand because we need special case to remove multiple from one strand
  Map<Strand, List<Linker>> strand_to_linkers = {};
  for (var crossover in crossovers) {
    var strand = dna_design.crossover_to_strand[crossover];
    if (strand_to_linkers[strand] == null) {
      strand_to_linkers[strand] = [];
    }
    strand_to_linkers[strand].add(crossover);
  }
  for (var loopout in loopouts) {
    var strand = dna_design.loopout_to_strand(loopout);
    if (strand_to_linkers[strand] == null) {
      strand_to_linkers[strand] = [];
    }
    strand_to_linkers[strand].add(loopout);
  }

  // remove linkers one strand at a time
  for (var strand in strand_to_linkers.keys) {
    strands_to_remove.add(strand);
    var split_strands = _remove_linkers_from_strand(strand, strand_to_linkers[strand]);
    strands_to_add.addAll(split_strands);
  }

  // remove old strands and add new strands to DNADesign
  var new_strands = dna_design.strands.toList();
  new_strands.removeWhere((strand) => strands_to_remove.contains(strand));
  new_strands.addAll(strands_to_add);

  return dna_design.rebuild((d) => d..strands.replace(new_strands));
}

// Splits one strand into many by removing crossovers and loopouts
List<Strand> _remove_linkers_from_strand(Strand strand, List<Linker> linkers) {
  // partition substrands of Strand that are separated by a linker
  // This logic is a bit complex because Loopouts are themselves Substrands, but Crossovers are not.
  linkers.sort((l1, l2) => l1.prev_substrand_idx.compareTo(l2.prev_substrand_idx));
  int linker_idx = 0;
  List<List<Substrand>> substrands_list = [[]];
  for (int ss_idx = 0; ss_idx < strand.substrands.length; ss_idx++) {
    var substrand = strand.substrands[ss_idx];
    substrands_list[linker_idx].add(substrand);
    if (linker_idx < linkers.length) {
      Linker linker = linkers[linker_idx];
      if (ss_idx == linker.prev_substrand_idx) {
        linker_idx++;
        substrands_list.add([]);
        if (linker is Loopout) {
          ss_idx++; // so we don't put Loopout in any new Strands
        }
      }
    }
  }

  return _create_new_strands_from_substrand_lists(substrands_list, strand);
}

String _dna_seq(List<Substrand> substrands, Strand strand) {
  List<String> ret = [];
  for (var ss in substrands) {
    ret.add(strand.dna_sequence_in(ss));
  }
  return ret.join('');
}
//=>
//    substrands.map((ss) => strand.dna_sequence_in(ss)).reduce((seq1, seq2) => seq1 + seq2);

/// Creates new strands, one for each list of consecutive substrands of strand.
/// Needs strand to assign DNA sequences and to have default properties for first strand (e.g., idt).
List<Strand> _create_new_strands_from_substrand_lists(List<List<Substrand>> substrands_list, Strand strand) {
  // Find DNA sequences of new Strands.
  //XXX: This must go before updating substrands below with is_first and is_last or else they cannot be
  // found as substrands of strand by method Strand.dna_sequence_in(), called by _dna_seq
  var dna_sequences = [for (var substrands in substrands_list) _dna_seq(substrands, strand)];

  // adjust is_first and is_last Booleans on BoundSubstrands
  for (var substrands in substrands_list) {
    var first_bound_ss = substrands[0] as BoundSubstrand;
    int last = substrands.length - 1;
    substrands[0] = first_bound_ss.rebuild((s) => s..is_first = true);
    //XXX: important to get variable from substrands[last] AFTER above assignment to substrands[0],
    // in case List is length 1 and the first object is the last object.
    // This ensures both fields are set to true.
    var last_bound_ss = substrands[last] as BoundSubstrand;
    substrands[last] = last_bound_ss.rebuild((s) => s..is_last = true);

    // replace Loopout (prev/next)_substrand_idx's, which are now stale
    for (int i = 0; i < substrands.length; i++) {
      var substrand = substrands[i];
      if (substrand is Loopout) {
        substrands[i] = substrand.rebuild((loopout) => loopout
          ..prev_substrand_idx = i - 1
          ..next_substrand_idx = i + 1);
      }
    }
  }

  List<Strand> new_strands = [];
  for (int i = 0; i < substrands_list.length; i++) {
    var substrands = substrands_list[i];
    var dna_sequence = dna_sequences[i];
    // assign old properties to first new strand and find new/default properties for remaining
    var color = i == 0 ? strand.color : util.color_cycler.next();
    var idt = i == 0 ? strand.idt : null;
    var is_scaffold = i == 0 ? strand.is_scaffold : false;
    var new_strand =
        Strand(substrands, color: color, dna_sequence: dna_sequence, idt: idt, is_scaffold: is_scaffold);
    new_strands.add(new_strand);
  }
  return new_strands;
}

DNADesign _remove_bound_substrands(DNADesign dna_design, Set<BoundSubstrand> substrands) {
  Set<Strand> strands_to_remove = {};
  List<Strand> strands_to_add = [];

  // collect all BoundSubstrands for one strand because we need special case to remove multiple from one strand
  Map<Strand, Set<BoundSubstrand>> strand_to_substrands = {};
  for (var substrand in substrands) {
    var strand = dna_design.substrand_to_strand[substrand];
    if (strand_to_substrands[strand] == null) {
      strand_to_substrands[strand] = {};
    }
    strand_to_substrands[strand].add(substrand);
  }

  // remove crossovers one strand at a time
  for (var strand in strand_to_substrands.keys) {
    strands_to_remove.add(strand);
    var split_strands = _remove_bound_substrands_from_strand(strand, strand_to_substrands[strand]);
    strands_to_add.addAll(split_strands);
  }

  // remove old strands and add new strands to DNADesign
  var new_strands = dna_design.strands.toList();
  new_strands.removeWhere((strand) => strands_to_remove.contains(strand));
  new_strands.addAll(strands_to_add);

  return dna_design.rebuild((d) => d..strands.replace(new_strands));
}

// Splits one strand into many by removing BoundSubstrands
List<Strand> _remove_bound_substrands_from_strand(Strand strand, Set<BoundSubstrand> substrands_to_remove) {
  // partition substrands of Strand that are separated by a BoundSubstrand
  List<Substrand> substrands = [];
  List<List<Substrand>> substrands_list = [substrands];
  for (int ss_idx = 0; ss_idx < strand.substrands.length; ss_idx++) {
    var substrand = strand.substrands[ss_idx];
    if (substrands_to_remove.contains(substrand)) {
      // also remove previous substrand if it is a Loopout
      if (substrands.isNotEmpty && substrands.last is Loopout) {
        substrands.removeLast();
      }
      // start new list of substrands if we added some to previous
      if (substrands.isNotEmpty) {
        substrands = [];
        substrands_list.add(substrands);
      }
      // if Loopout is next, remove it (i.e., leave it out by skipping its index)
      if (ss_idx < strand.substrands.length - 1 && strand.substrands[ss_idx + 1] is Loopout) {
        ss_idx++;
      }
    } else {
      // add to existing list of substrands
      substrands.add(substrand);
    }
  }

  // special case if we removed last bound substrand
  if (substrands.isEmpty) {
    substrands_list.removeLast();
  }

  return _create_new_strands_from_substrand_lists(substrands_list, strand);
}
