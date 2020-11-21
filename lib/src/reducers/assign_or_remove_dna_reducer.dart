import 'package:built_collection/built_collection.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/loopout.dart';
import '../state/substrand.dart';
import 'package:tuple/tuple.dart';

import '../state/strand.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../constants.dart' as constants;

BuiltList<Strand> remove_dna_reducer(BuiltList<Strand> strands, actions.RemoveDNA action) {
  List<int> idxs = [];
  Strand strand = action.strand;

  if (action.remove_all) {
    idxs = [for (int idx = 0; idx < strands.length; idx++) idx];
  } else {
    int strand_idx = strands.indexOf(strand);
    idxs = [strand_idx];
    if (action.remove_complements) {
      // collect indices of strands bound to this one
      for (int i = 0; i < strands.length; i++) {
        Strand other_strand = strands[i];
        if (i != strand_idx && other_strand.overlaps(strand)) {
          idxs.add(i);
        }
      }
    }
  }

  List<Strand> strands_builder = strands.toList();
  for (int idx in idxs) {
    strands_builder[idx] = strands_builder[idx].remove_dna_sequence();
  }

  return strands_builder.toBuiltList();
}

BuiltList<Strand> assign_dna_reducer_complement_from_bound_strands(
    BuiltList<Strand> strands, AppState state, actions.AssignDNAComplementFromBoundStrands action) {
  List<Strand> all_strands = strands.toList();
  for (var strand_to_assign in action.strands) {
    int strand_to_assign_idx = strands.indexOf(strand_to_assign);
    bool strand_changed = false;
    for (var strand_with_dna in state.design.strands_overlapping[strand_to_assign]) {
      if (strand_with_dna.dna_sequence != null) {
        String new_dna = compute_dna_complement_from(strand_to_assign, strand_with_dna, false);
        strand_to_assign = strand_to_assign.set_dna_sequence(new_dna);
        strand_changed = true;
      }
    }
    if (strand_changed) {
      all_strands[strand_to_assign_idx] = strand_to_assign;
    }
  }
  return all_strands.build();
}

BuiltList<Strand> assign_dna_reducer(BuiltList<Strand> strands, actions.AssignDNA action) {
  Strand strand = action.strand;
  int strand_idx = strands.indexOf(strand); // need index before we start changing strand

  if (strand.dna_sequence != null) strand = strand.remove_dna_sequence();

  String seq = action.dna_sequence;
  seq = util.remove_whitespace_and_uppercase(seq);
  seq = util.pad_dna(seq, strand.dna_length());
  seq = merge_sequences_if_necessary(strand, seq);

  // first overwrite this strand in the builder list
  List<Strand> strands_builder = strands.toList();
  Strand strand_with_new_sequence = strand.set_dna_sequence(seq);
  strands_builder[strand_idx] = strand_with_new_sequence;

  // then assign to other strands if requested
  if (action.assign_complements) {
    for (int i = 0; i < strands_builder.length; i++) {
      Strand other_strand = strands_builder[i];
      // note that possibly strand==other_strand; it might bind to itself at some point and we want to
      // allow a partial assignment to one substrand to automatically assign the complement to the domain.
      // However, if there are no wildcards in the assigned sequence we can safely skip strand.
      if (strand == other_strand && !strand.dna_sequence.contains(constants.DNA_BASE_WILDCARD)) {
        continue;
      }
      if (other_strand.overlaps(strand)) {
        String new_dna =
            compute_dna_complement_from(other_strand, strand_with_new_sequence, action.warn_on_change);
        if (new_dna != other_strand.dna_sequence) {
          strands_builder[i] = other_strand.set_dna_sequence(new_dna);
        }
      }
    }
  }
  return strands_builder.toBuiltList();
}

// Lexicographically compare (start,end) overlap coordinates of o1 and o2.
int compare_overlap(Tuple2<Tuple2<int, int>, Domain> o1, Tuple2<Tuple2<int, int>, Domain> o2) {
  int o1_start = o1.item1.item1;
  int o1_end = o1.item1.item2;
  int o2_start = o2.item1.item1;
  int o2_end = o2.item1.item2;
  if (o1_start != o2_start) {
    return o1_start - o2_start;
  } else {
    return o1_end - o2_end;
  }
}

/// Assuming a DNA sequence has been assigned to `strand_from`, assign its Watson-Crick
/// complement to the portions of `strand_to` that are bound to `other`.
///
/// Generally this is not called directly; use :py:meth:`DNADesign.assign_dna` to assign
/// a DNA sequence to a :any:`Strand`. The method :py:meth:`DNADesign.assign_dna` will calculate
/// which other :any:`Strand`'s need
/// to be assigned via :py:meth:`Strand.assign_dna_complement_from`.
///
/// However, it is permitted to assign the field :py:data:`Strand.dna_sequence` directly
/// via the method :py:meth:`Strand.set_dna_sequence`.
/// This is used, for instance, to assign a DNA sequence to a :any:`Strand` bound to another
/// :any:`Strand`
/// with an assigned DNA sequence where they overlap. In this case no error checking
/// about sequence complementarity is done. This can be used to intentionally assign *mismatching*
/// DNA sequences to :any:`Strand`'s that are bound on a :any:`Helix`.
String compute_dna_complement_from(Strand strand_to, Strand strand_from, bool error_on_change) {
  bool already_assigned = strand_to.dna_sequence != null;

  // put DNA sequences to assign to substrands in List, one position per substrand
  List<String> strand_complement_builder = [];
  if (already_assigned) {
    for (var substrand in strand_to.substrands) {
      strand_complement_builder.add(substrand.dna_sequence);
    }
  } else {
    for (var substrand in strand_to.substrands) {
      String wildcards = constants.DNA_BASE_WILDCARD * substrand.dna_length();
      strand_complement_builder.add(wildcards);
    }
  }

  for (int ss_idx = 0; ss_idx < strand_to.substrands.length; ss_idx++) {
    Substrand substrand_to = strand_to.substrands[ss_idx];
    String substrand_to_dna_sequence;
    if (substrand_to is Loopout) {
      substrand_to_dna_sequence = constants.DNA_BASE_WILDCARD * substrand_to.dna_length();
    } else if (substrand_to is Domain) {
      int helix_idx = substrand_to.helix;
      List<Domain> substrands_on_helix_from = strand_from.domains_on_helix[helix_idx]?.toList() ?? [];
      List<Tuple2<Tuple2<int, int>, Domain>> overlaps = [];
      for (var substrand_from in substrands_on_helix_from) {
        if (substrand_to != substrand_from && substrand_to.overlaps(substrand_from)) {
          Tuple2<int, int> overlap = substrand_to.compute_overlap(substrand_from);
          overlaps.add(Tuple2<Tuple2<int, int>, Domain>(overlap, substrand_from));
        }
      }
      overlaps.sort(compare_overlap);

      List<String> substrand_complement_builder = [];
      int start_idx = substrand_to.start;
      // repeatedly insert wildcards into gaps, then reverse WC complement
      for (var overlap in overlaps) {
        int overlap_left = overlap.item1.item1;
        int overlap_right = overlap.item1.item2;
        Domain substrand_from = overlap.item2;
        // wildcards = DNA_base_wildcard * (overlap_left - start_idx)
        int num_wildcard_bases = substrand_to.dna_length_in(start_idx, overlap_left - 1);
        String wildcards = constants.DNA_BASE_WILDCARD * num_wildcard_bases;

        String other_seq = substrand_from.dna_sequence_in(overlap_left, overlap_right - 1);
        String overlap_complement = util.wc(other_seq);
        substrand_complement_builder.add(wildcards);
        substrand_complement_builder.add(overlap_complement);
        start_idx = overlap_right;
      }
      // last wildcard for gap between last overlap and end
      // last_wildcards = DNA_base_wildcard * (substrand_to.end - start_idx)
      int last_num_wildcard_bases = substrand_to.dna_length_in(start_idx, substrand_to.end - 1);
      String last_wildcards = constants.DNA_BASE_WILDCARD * last_num_wildcard_bases;

      substrand_complement_builder.add(last_wildcards);

      // If pointing left, each individual overlap sequence was reverse orientation in wc(),
      // but not the list of all of them put together until now.
      if (!substrand_to.forward) {
        substrand_complement_builder = substrand_complement_builder.reversed.toList();
      }

      substrand_to_dna_sequence = substrand_complement_builder.join('');
    }

    // merge with existing pre-assigned sequence
    String existing_substrand_to_dna_sequence = strand_complement_builder[ss_idx];
    var merge = error_on_change ? util.merge_wildcards : util.merge_wildcards_favor_first;
    String merged_substrand_to_dna_sequence =
        merge(substrand_to_dna_sequence, existing_substrand_to_dna_sequence, constants.DNA_BASE_WILDCARD);
    strand_complement_builder[ss_idx] = merged_substrand_to_dna_sequence;
  }

  String strand_complement = strand_complement_builder.join('');
  String new_dna_sequence = strand_complement;
  if (strand_to.dna_sequence != null) {
    // previously we threw an error, but now we will default to the new sequence. The user should use
    // the option "warn if assigning different sequence to bound strand" when assigning DNA to avoid this
    // choice silently overwriting their DNA
    if (!error_on_change) {
      new_dna_sequence = util.merge_wildcards_favor_first(
          new_dna_sequence, strand_to.dna_sequence, constants.DNA_BASE_WILDCARD);
    } else {
      try {
        new_dna_sequence =
            util.merge_wildcards(strand_to.dna_sequence, new_dna_sequence, constants.DNA_BASE_WILDCARD);
      } on ArgumentError {
        Domain ss_to = strand_to.first_domain();
        Domain ss_from = strand_from.first_domain();
        var msg = 'strand starting at helix ${ss_to.helix}, offset ${ss_to.offset_5p} has '
            'length '
            '${strand_to.dna_length()} and already has a partial DNA sequence assignment of length '
            '${strand_to.dna_sequence.length}, which is \n'
            '${strand_to.dna_sequence}, '
            'but you tried to assign sequence of length ${new_dna_sequence.length} to it, which '
            'is\n${new_dna_sequence} (this assignment was indirect, since you assigned directly '
            'to a strand bound to this one). This occurred while directly assigning a DNA '
            'sequence to the strand whose 5\' end is at helix ${ss_from.helix}, and is of '
            'length ${strand_from.dna_length}.';
        throw IllegalDesignError(msg);
      }
    }
  }
  return new_dna_sequence;
}

String merge_sequences_if_necessary(Strand strand, String seq) {
  if (strand.dna_sequence != null) {
    try {
      seq = util.merge_wildcards(seq, strand.dna_sequence, constants.DNA_BASE_WILDCARD);
    } on ArgumentError {
      var first_ss = strand.first_domain();
      var msg = 'strand starting at helix ${first_ss.helix}, offset ${first_ss.offset_5p} has '
          'length '
          '${strand.dna_length()} and already has a DNA sequence assignment of length '
          '${strand.dna_sequence.length}, which is \n'
          '${strand.dna_sequence}, '
          'but you tried to assign a different sequence of length ${seq.length} to '
          'it, which is\n{$seq}.';
      throw IllegalDesignError(msg);
    }
  }
  return seq;
}
