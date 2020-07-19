import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/linker.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/substrand.dart';

import '../actions/actions.dart' as actions;

BuiltList<Strand> delete_all_reducer(
    BuiltList<Strand> strands, AppState state, actions.DeleteAllSelected action) {
  BuiltSet<Selectable> items = state.ui_state.selectables_store.selected_items;
  if (items.isEmpty) {
    return strands;
  }

  if (state.ui_state.select_mode_state.strands_selectable()) {
    var strands_to_remove = Set<Strand>.from(items.where((item) => item is Strand));
    strands = _remove_strands(strands, strands_to_remove);
  } else if (state.ui_state.select_mode_state.linkers_selectable()) {
    var crossovers = Set<Crossover>.from(items.where((item) => item is Crossover));
    var loopouts = Set<Loopout>.from(items.where((item) => item is Loopout));
    strands = _remove_crossovers_and_loopouts(strands, state, crossovers, loopouts);
  } else if (state.ui_state.select_mode_state.ends_selectable()) {
    var ends = items.where((item) => item is DNAEnd);
    var substrands = Set<Domain>.from(ends.map((end) => state.design.end_to_domain[end]));
    strands = remove_domains(strands, state, substrands);
  }

  return strands;
}

BuiltList<Strand> _remove_strands(BuiltList<Strand> strands, Iterable<Strand> strands_to_remove) =>
    strands.rebuild((b) => b..removeWhere((strand) => strands_to_remove.contains(strand)));

BuiltList<Strand> _remove_crossovers_and_loopouts(
    BuiltList<Strand> strands, AppState state, Iterable<Crossover> crossovers, Iterable<Loopout> loopouts) {
  Set<Strand> strands_to_remove = {};
  List<Strand> strands_to_add = [];

  // collect all linkers for one strand because we need special case to remove multiple from one strand
  Map<Strand, List<Linker>> strand_to_linkers = {};
  for (var crossover in crossovers) {
    var strand = state.design.crossover_to_strand[crossover];
    if (strand_to_linkers[strand] == null) {
      strand_to_linkers[strand] = [];
    }
    strand_to_linkers[strand].add(crossover);
  }
  for (var loopout in loopouts) {
    var strand = state.design.loopout_to_strand(loopout);
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
  var new_strands = state.design.strands.toList();
  new_strands.removeWhere((strand) => strands_to_remove.contains(strand));
  new_strands.addAll(strands_to_add);

  return new_strands.build();
}

// Splits one strand into many by removing crossovers and loopouts
List<Strand> _remove_linkers_from_strand(Strand strand, List<Linker> linkers) {
  // partition substrands of Strand that are separated by a linker
  // This logic is a bit complex because Loopouts are themselves Substrands, but Crossovers are not.
  linkers.sort((l1, l2) => l1.prev_domain_idx.compareTo(l2.prev_domain_idx));
  int linker_idx = 0;
  List<List<Substrand>> substrands_list = [[]];
  for (int ss_idx = 0; ss_idx < strand.substrands.length; ss_idx++) {
    var substrand = strand.substrands[ss_idx];
    substrands_list[linker_idx].add(substrand);
    if (linker_idx < linkers.length) {
      Linker linker = linkers[linker_idx];
      if (ss_idx == linker.prev_domain_idx) {
        linker_idx++;
        substrands_list.add([]);
        if (linker is Loopout) {
          ss_idx++; // so we don't put Loopout in any new Strands
        }
      }
    }
  }

  return create_new_strands_from_substrand_lists(substrands_list, strand);
}

String _dna_seq(List<Substrand> substrands, Strand strand) {
  List<String> ret = [];
  for (var ss in substrands) {
    ret.add(strand.dna_sequence_in(ss));
  }
  return ret.join('');
}

/// Creates new strands, one for each list of consecutive substrands of strand.
/// Needs strand to assign DNA sequences and to have default properties for first strand (e.g., idt).
List<Strand> create_new_strands_from_substrand_lists(List<List<Substrand>> substrands_list, Strand strand) {
  if (substrands_list.isEmpty) {
    return [];
  }
  // Find DNA sequences of new Strands.
  //XXX: This must go before updating substrands below with is_first and is_last or else they cannot be
  // found as substrands of strand by method Strand.dna_sequence_in(), called by _dna_seq
  var dna_sequences = strand.dna_sequence == null
      ? [for (var _ in substrands_list) null]
      : [for (var substrands in substrands_list) _dna_seq(substrands, strand)];

  Modification5Prime mod_5p = null;
  Modification3Prime mod_3p = null;
  if (substrands_list.first.first == strand.substrands.first) {
    mod_5p = strand.modification_5p;
  }
  if (substrands_list.last.last == strand.substrands.last) {
    mod_3p = strand.modification_3p;
  }

  var ss_to_mods = strand.internal_modifications_on_substrand;
  List<Map<int, ModificationInternal>> internal_mods_to_keep = [];

  // adjust is_first and is_last Booleans on Domains
  for (var substrands in substrands_list) {
    Map<int, ModificationInternal> internal_mods_on_these_substrands = {};

    int dna_length_cur_substrands = 0;
    // replace Loopout (prev/next)_substrand_idx's, which are now stale
    for (int i = 0; i < substrands.length; i++) {
      var substrand = substrands[i];
      BuiltMap<int, ModificationInternal> mods_this_ss = ss_to_mods[substrand];
      for (int idx_within_ss in mods_this_ss.keys) {
        ModificationInternal mod = mods_this_ss[idx_within_ss];
        internal_mods_on_these_substrands[dna_length_cur_substrands + idx_within_ss] = mod;
      }
      if (substrand is Loopout) {
        substrand = (substrand as Loopout).rebuild((loopout) => loopout
          ..prev_domain_idx = i - 1
          ..next_domain_idx = i + 1);
      }
      if (i == 0 && (substrand is Domain)) {
        substrand = (substrand as Domain).rebuild((s) => s..is_first = true);
      }
      if (i == substrands.length - 1 && (substrand is Domain)) {
        substrand = (substrand as Domain).rebuild((s) => s..is_last = true);
      }
      substrands[i] = substrand;
      dna_length_cur_substrands += substrand.dna_length();
    }

    internal_mods_to_keep.add(internal_mods_on_these_substrands);
  }

  List<Strand> new_strands = [];
  for (int i = 0; i < substrands_list.length; i++) {
    var substrands = substrands_list[i];
    var dna_sequence = dna_sequences[i];
    // assign old properties to first new strand and find new/default properties for remaining
    var idt = i == 0 ? strand.idt : null;
    var is_scaffold = strand.is_scaffold; //i == 0 ? strand.is_scaffold : false;

    Map<int, ModificationInternal> mods_int = internal_mods_to_keep[i];
    var mod_5p_cur = i == 0 ? mod_5p : null;
    var mod_3p_cur = i == substrands_list.length - 1 ? mod_3p : null;

    var color = strand.color; //i==0?strand.color:null;
    var new_strand = Strand(substrands,
        dna_sequence: dna_sequence,
        idt: idt,
        is_scaffold: is_scaffold,
        color: color,
        modification_5p: mod_5p_cur,
        modification_3p: mod_3p_cur,
        modifications_int: mods_int);
    new_strand = new_strand.initialize();
    new_strands.add(new_strand);
  }
  return new_strands;
}

BuiltList<Strand> remove_domains(BuiltList<Strand> strands, AppState state, Set<Domain> substrands) {
  Set<Strand> strands_to_remove = {};
  List<Strand> strands_to_add = [];

  // collect all Domains for one strand because we need special case to remove multiple from one strand
  Map<Strand, Set<Domain>> strand_to_substrands = {};
  for (var substrand in substrands) {
    var strand = state.design.substrand_to_strand[substrand];
    if (strand_to_substrands[strand] == null) {
      strand_to_substrands[strand] = {};
    }
    strand_to_substrands[strand].add(substrand);
  }

  // remove crossovers one strand at a time
  for (var strand in strand_to_substrands.keys) {
    strands_to_remove.add(strand);
    var split_strands = _remove_domains_from_strand(strand, strand_to_substrands[strand]);
    strands_to_add.addAll(split_strands);
  }

  // remove old strands and add new strands to DNADesign
  var new_strands = strands.toList();
  new_strands.removeWhere((strand) => strands_to_remove.contains(strand));
  new_strands.addAll(strands_to_add);

  return new_strands.build();
}

// Splits one strand into many by removing Domains
List<Strand> _remove_domains_from_strand(Strand strand, Set<Domain> substrands_to_remove) {
  // partition substrands of Strand that are separated by a Domain
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

  return create_new_strands_from_substrand_lists(substrands_list, strand);
}
