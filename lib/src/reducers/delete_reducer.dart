import 'package:built_collection/built_collection.dart';

import '../state/app_state.dart';
import '../state/domain.dart';
import '../state/crossover.dart';
import '../state/dna_end.dart';
import '../state/linker.dart';
import '../state/loopout.dart';
import '../state/modification.dart';
import '../state/selectable.dart';
import '../state/strand.dart';
import '../state/substrand.dart';

import '../actions/actions.dart' as actions;

BuiltList<Strand> delete_all_reducer(
    BuiltList<Strand> strands, AppState state, actions.DeleteAllSelected action) {
  BuiltSet<Selectable> items = state.ui_state.selectables_store.selected_items;
  if (items.isEmpty) {
    return strands;
  }

  var select_mode_state = state.ui_state.select_mode_state;
  if (select_mode_state.strands_selectable) {
    // strands
    var strands_to_remove = Set<Strand>.from(items.where((item) => item is Strand));
    strands = _remove_strands(strands, strands_to_remove);
  } else if (select_mode_state.linkers_selectable) {
    // crossovers/loopouts
    var crossovers = Set<Crossover>.from(items.where((item) => item is Crossover));
    var loopouts = Set<Loopout>.from(items.where((item) => item is Loopout));
    strands = remove_crossovers_and_loopouts(strands, state, crossovers, loopouts);
  } else if (select_mode_state.ends_selectable) {
    // DNA ends
    var ends = items.where((item) => item is DNAEnd);
    var domains = ends.map((end) => state.design.end_to_domain[end]);
    strands = remove_domains(strands, state, domains);
  } else if (select_mode_state.domains_selectable) {
    // domains
    var domains = List<Domain>.from(items.where((item) => item is Domain));
    strands = remove_domains(strands, state, domains);
  } else if (select_mode_state.deletions_selectable || select_mode_state.insertions_selectable) {
    // deletions/insertions
    List<SelectableDeletion> deletions = select_mode_state.deletions_selectable
        ? List<SelectableDeletion>.from(items.where((item) => item is SelectableDeletion))
        : [];
    List<SelectableInsertion> insertions = select_mode_state.insertions_selectable
        ? List<SelectableInsertion>.from(items.where((item) => item is SelectableInsertion))
        : [];
    strands = remove_deletions_and_insertions(strands, state, deletions, insertions);
  } else if (select_mode_state.modifications_selectable) {
    // modifications
    var modifications =
        List<SelectableModification>.from(items.where((item) => item is SelectableModification));
    strands = remove_modifications(strands, state, modifications);
  }

  return strands;
}

BuiltList<Strand> _remove_strands(BuiltList<Strand> strands, Iterable<Strand> strands_to_remove) =>
    strands.rebuild((b) => b..removeWhere((strand) => strands_to_remove.contains(strand)));

BuiltList<Strand> remove_crossovers_and_loopouts(
    BuiltList<Strand> strands, AppState state, Iterable<Crossover> crossovers, Iterable<Loopout> loopouts) {
  // maps each strand with >= 1 domains being removed to list of strands to replace it
  Map<Strand, List<Strand>> strands_to_replace = {};

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
    List<Strand> split_strands = remove_linkers_from_strand(strand, strand_to_linkers[strand]);
    strands_to_replace[strand] = split_strands;
  }

  // remove old strands and add new strands to DNADesign; preserve order where possible
  // (i.e., look up index of strand being removed and put its replacement strands at same index)
  var new_strands = strands.toList();
  for (var strand in strands_to_replace.keys) {
    int old_strand_idx = new_strands.indexOf(strand);
    new_strands.removeAt(old_strand_idx);
    List<Strand> split_strands = strands_to_replace[strand];
    new_strands.insertAll(old_strand_idx, split_strands);
  }

  return new_strands.build();
}

// Splits one strand into many by removing crossovers and loopouts
// If the strand is circular and we only remove one linker, it stays one strand but becomes linear.
// order of returned strands is 5' to 3' in original strand
List<Strand> remove_linkers_from_strand(Strand strand, List<Linker> linkers) {
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

  // if circular, then the last list of substrands should be concatenated with the first
  if (strand.circular) {
    substrands_list[substrands_list.length - 1].addAll(substrands_list[0]);
    substrands_list[0] = substrands_list[substrands_list.length - 1];
    substrands_list.removeLast();
    strand = strand.rebuild((b) => b..circular = false);
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
/// Always makes a linear Strand, even if Strand is circular.
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
        substrand = (substrand as Loopout).rebuild((loopout) => loopout..prev_domain_idx = i - 1);
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
        name: strand.name,
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

BuiltList<Strand> remove_domains(BuiltList<Strand> strands, AppState state, Iterable<Domain> domains) {
  // maps each strand with >= 1 domains being removed to list of strands to replace it
  Map<Strand, List<Strand>> strands_to_replace = {};

  // collect all Domains for one strand because we need special case to remove multiple from one strand
  Map<Strand, Set<Domain>> strand_to_domains = {};
  for (var domain in domains) {
    var strand = state.design.substrand_to_strand[domain];
    if (strand_to_domains[strand] == null) {
      strand_to_domains[strand] = {};
    }
    strand_to_domains[strand].add(domain);
  }

  // remove domains one strand at a time
  for (var strand in strand_to_domains.keys) {
    List<Strand> split_strands = _remove_domains_from_strand(strand, strand_to_domains[strand]);
    strands_to_replace[strand] = split_strands;
  }

  // remove old strands and add new strands to DNADesign; preserve order where possible
  // (i.e., look up index of strand being removed and put its replacement strands at same index)
  var new_strands = strands.toList();
  for (var strand in strands_to_replace.keys) {
    int old_strand_idx = new_strands.indexOf(strand);
    new_strands.removeAt(old_strand_idx);
    List<Strand> split_strands = strands_to_replace[strand];
    new_strands.insertAll(old_strand_idx, split_strands);
  }

  return new_strands.build();
}

// Splits one strand into many by removing Domains
List<Strand> _remove_domains_from_strand(Strand strand, Set<Domain> domains_to_remove) {
  // partition substrands of Strand that are separated by a Domain
  List<Substrand> substrands = [];
  List<List<Substrand>> substrands_list = [substrands];
  for (int ss_idx = 0; ss_idx < strand.substrands.length; ss_idx++) {
    var substrand = strand.substrands[ss_idx];
    if (domains_to_remove.contains(substrand)) {
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

  // special case if we removed last domain
  if (substrands.isEmpty) {
    substrands_list.removeLast();
  } else if (strand.circular) {
    // if circular, then if there is more than one list of substrands remaining,
    // the last list of substrands should be concatenated with the first
    if (substrands_list.length > 1) {
      var last_substrands = substrands_list[substrands_list.length - 1];
      var first_substrands = substrands_list[0];
      last_substrands.addAll(first_substrands);
      substrands_list[0] = last_substrands;
      substrands_list.removeLast();
    }
    strand = strand.rebuild((b) => b..circular = false);
  }

  return create_new_strands_from_substrand_lists(substrands_list, strand);
}

BuiltList<Strand> remove_deletions_and_insertions(BuiltList<Strand> strands, AppState state,
    List<SelectableDeletion> deletions, List<SelectableInsertion> insertions) {
  // collect all deletions/insertions for each strand
  Map<Strand, Map<Domain, Set<SelectableDeletion>>> strand_to_deletions = {};
  Map<Strand, Map<Domain, Set<SelectableInsertion>>> strand_to_insertions = {};
  for (var strand in strands) {
    strand_to_deletions[strand] = {};
    strand_to_insertions[strand] = {};
    for (var domain in strand.domains) {
      strand_to_deletions[strand][domain] = {};
      strand_to_insertions[strand][domain] = {};
    }
  }
  for (var deletion in deletions) {
    var strand = state.design.substrand_to_strand[deletion.domain];
    strand_to_deletions[strand][deletion.domain].add(deletion);
  }
  for (var insertion in insertions) {
    var strand = state.design.substrand_to_strand[insertion.domain];
    strand_to_insertions[strand][insertion.domain].add(insertion);
  }

  // remove deletions/insertions one strand at a time
  // need to do deletions and insertions at the same time because Domain built object will be invalidated
  // after removing one of them.
  var new_strands = strands.toList();
  for (int i = 0; i < strands.length; i++) {
    Strand strand = strands[i];
    var substrands = strand.substrands.toList();
    for (int j = 0; j < substrands.length; j++) {
      if (substrands[j] is Domain) {
        var domain = substrands[j] as Domain;
        var deletions = strand_to_deletions[strand][domain];
        var insertions = strand_to_insertions[strand][domain];
        var deletions_offsets_to_remove = {for (var deletion in deletions) deletion.offset};
        var insertions_offsets_to_remove = {for (var insertion in insertions) insertion.insertion.offset};
        if (deletions_offsets_to_remove.isNotEmpty || insertions_offsets_to_remove.isNotEmpty) {
          var deletions_existing = domain.deletions.toList();
          var insertions_existing = domain.insertions.toList();
          deletions_existing.removeWhere((offset) => deletions_offsets_to_remove.contains(offset));
          insertions_existing
              .removeWhere((insertion) => insertions_offsets_to_remove.contains(insertion.offset));
          domain = domain.rebuild(
              (b) => b..deletions.replace(deletions_existing)..insertions.replace(insertions_existing));
          substrands[j] = domain;
        }
      }
    }
    strand = strand.rebuild((b) => b..substrands.replace(substrands));
    strand = strand.initialize();
    new_strands[i] = strand;
  }

  return new_strands.build();
}

BuiltList<Strand> remove_modifications(
    BuiltList<Strand> strands, AppState state, List<SelectableModification> modifications) {
  // collect all modifications for each strand
  Map<String, Set<SelectableModification>> strand_id_to_mods = {};
  for (var mod in modifications) {
    if (!strand_id_to_mods.containsKey(mod.strand.id)) {
      strand_id_to_mods[mod.strand.id] = {};
    }
    strand_id_to_mods[mod.strand.id].add(mod);
  }

  var new_strands = strands.toList();
  List<String> strand_ids = [for (var strand in strands) strand.id];
  for (String strand_id in strand_id_to_mods.keys) {
    Set<SelectableModification> selectable_mods = strand_id_to_mods[strand_id];
    int strand_idx = strand_ids.indexOf(strand_id);
    Strand strand = strands[strand_idx];

    Map<int, ModificationInternal> mods_int = strand.modifications_int.toMap();

    bool remove_5p = false;
    bool remove_3p = false;
    for (var selectable_mod in selectable_mods) {
      if (selectable_mod is SelectableModification5Prime) {
        remove_5p = true;
      } else if (selectable_mod is SelectableModification3Prime) {
        remove_3p = true;
      } else if (selectable_mod is SelectableModificationInternal) {
        mods_int.remove(selectable_mod.dna_idx);
      }
    }

    strand = strand.rebuild((b) {
      if (remove_5p) {
        b.modification_5p = null;
      }
      if (remove_3p) {
        b.modification_3p = null;
      }
      b.modifications_int.replace(mods_int);
    });

    strand = strand.initialize();
    new_strands[strand_idx] = strand;
  }

  return new_strands.build();
}
