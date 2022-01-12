import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/domains_move.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:tuple/tuple.dart';

import 'assign_domain_names_reducer.dart';
import 'strands_move_reducer.dart' as strands_move_reducer;
import 'domains_move_reducer.dart' as domains_move_reducer;
import '../state/group.dart';
import '../middleware/insertion_deletion_batching.dart';
import '../state/app_state.dart';
import '../state/domain.dart';
import '../state/design.dart';
import '../state/dna_end.dart';
import '../state/dna_ends_move.dart';
import '../state/strands_move.dart';
import '../state/substrand.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import 'assign_or_remove_dna_reducer.dart';
import 'change_loopout_length.dart';
import 'delete_reducer.dart';
import 'insertion_deletion_reducer.dart';
import 'nick_ligate_join_by_crossover_reducers.dart';
import 'util_reducer.dart';
import '../util.dart' as util;

Reducer<BuiltList<Strand>> strands_local_reducer = combineReducers([
  TypedReducer<BuiltList<Strand>, actions.AssignDNA>(assign_dna_reducer),
  TypedReducer<BuiltList<Strand>, actions.RemoveDNA>(remove_dna_reducer),
  TypedReducer<BuiltList<Strand>, actions.ReplaceStrands>(replace_strands_reducer),
  TypedReducer<BuiltList<Strand>, actions.SingleStrandAction>(strands_single_strand_reducer),
]);

GlobalReducer<BuiltList<Strand>, AppState> strands_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.AssignDomainNameComplementFromBoundStrands>(//
      assign_domain_name_complement_from_bound_strands_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.AssignDomainNameComplementFromBoundDomains>(//
      assign_domain_name_complement_from_bound_domains_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.AssignDNAComplementFromBoundStrands>(
      assign_dna_reducer_complement_from_bound_strands),
  // TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandsAutoPaste>(strands_autopaste_strands_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandsMoveCommit>(strands_move_commit_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.DomainsMoveCommit>(domains_move_commit_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.DNAEndsMoveCommit>(
      strands_dna_ends_move_commit_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandPartAction>(strands_part_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandCreateCommit>(strand_create),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.DeleteAllSelected>(delete_all_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.Nick>(nick_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.Ligate>(ligate_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.JoinStrandsByCrossover>(
      join_strands_by_crossover_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.JoinStrandsByMultipleCrossovers>(
      join_strands_by_multiple_crossovers_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.ConvertCrossoversToLoopouts>(
      convert_crossovers_to_loopouts_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.LoopoutsLengthChange>(
      loopouts_length_change_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.InsertionsLengthChange>(
      insertions_length_change_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.Modifications5PrimeEdit>(
      modifications_5p_edit_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.Modifications3PrimeEdit>(
      modifications_3p_edit_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.ModificationsInternalEdit>(
      modifications_int_edit_reducer),
]);

BuiltList<Strand> replace_strands_reducer(BuiltList<Strand> strands, actions.ReplaceStrands action) {
  var strands_builder = strands.toBuilder();
  for (int idx in action.new_strands.keys) {
    var new_strand = action.new_strands[idx];
    strands_builder[idx] = new_strand;
  }
  return strands_builder.build();
}

// takes a part of a strand and looks up the strand it's in by strand_id, then applies reducer to strand
// action may not have the strand itself
BuiltList<Strand> strands_part_reducer(
    BuiltList<Strand> strands, AppState state, actions.StrandPartAction action) {
  Strand strand = state.design.strands_by_id[action.strand_part.strand_id];
  int strand_idx = strands.indexOf(strand);

  if (strand_idx < 0) {
    return strands;
  }

  strand = strand_part_reducer(strand, action);
  strand = strand.initialize();

  var strands_builder = strands.toBuilder();
  strands_builder[strand_idx] = strand;
  return strands_builder.build();
}

Reducer<Strand> strand_part_reducer = combineReducers([
  TypedReducer<Strand, actions.ConvertCrossoverToLoopout>(convert_crossover_to_loopout_reducer),
  TypedReducer<Strand, actions.LoopoutLengthChange>(loopout_length_change_reducer),
  TypedReducer<Strand, actions.InsertionOrDeletionAction>(insertion_deletion_reducer),
  TypedReducer<Strand, actions.SubstrandNameSet>(substrand_name_set_reducer),
]);

Strand substrand_name_set_reducer(Strand strand, actions.SubstrandNameSet action) {
  int substrand_idx = strand.substrands.indexOf(action.substrand);

  // we do the same thing no matter if its Domain or Loopout, but need to cast to call rebuild
  Substrand substrand = action.substrand;
  if (substrand is Domain) {
    substrand = (substrand as Domain).rebuild((b) => b..name = action.name);
  } else if (substrand is Loopout) {
    substrand = (substrand as Loopout).rebuild((b) => b..name = action.name);
  } else {
    throw AssertionError('substrand must either be Domain or Loopout');
  }

  var substrands = strand.substrands.toList();
  substrands[substrand_idx] = substrand;
  strand = strand.rebuild((s) => s..substrands.replace(substrands));
  return strand;
}

// ///////////////////////////////////////////////////////////////////////////////////////////////////////////
// // autopaste strands
//
// BuiltList<Strand> strands_autopaste_strands_reducer(
//     BuiltList<Strand> strands, AppState state, actions.StrandsAutoPaste _) {
//   var copy_info = state.ui_state.copy_info;
//   if (!copy_info.has_translation()) return strands;
//   if (!copy_info.next_translation_in_bounds_and_legal(state)) return strands;
//
//   var strands_move = state.ui_state.copy_info.create_strands_move(state);
//   var strands_list = strands.toList();
//
//   for (var strand in copy_info.strands) {
//     Strand new_strand = one_strand_strands_move_copy_commit_reducer(state.design, strand, strands_move);
//     new_strand = new_strand.initialize();
//     strands_list.add(new_strand);
//   }
//
//   return strands_list.toBuiltList();
// }

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// move strands/domains

BuiltList<Strand> strands_move_commit_reducer(
    BuiltList<Strand> strands, AppState state, actions.StrandsMoveCommit action) {
  if (strands_move_reducer.in_bounds_and_allowable(state.design, action.strands_move) &&
      (action.strands_move.is_nontrivial || action.strands_move.copy)) {
    // if (action.strands_move.allowable && (action.strands_move.is_nontrivial || action.strands_move.copy)) {
    // even a trivial move can be wanted if we are copying, i.e., user copied strands, deleted them,
    // and wants to paste them back in same position
    var strands_list = strands.toList();
    for (var strand in action.strands_move.strands_moving) {
      Strand new_strand =
          one_strand_strands_move_copy_commit_reducer(state.design, strand, action.strands_move);
      new_strand = new_strand.initialize();
      if (action.strands_move.copy) {
        strands_list.add(new_strand);
      } else {
        // this indexOf is only safe to do
        // (i.e., the strand will only be found in the list of all strands) if we are moving
        // if copying, we might have loaded a new design
        int strand_idx = strands.indexOf(strand);
        strands_list[strand_idx] = new_strand;
      }
    }
    return strands_list.toBuiltList();
  } else {
    return strands;
  }
}

Strand one_strand_strands_move_copy_commit_reducer(Design design, Strand strand, StrandsMove strands_move) {
  int delta_view_order = strands_move.delta_view_order;
  int delta_offset = strands_move.delta_offset;
  bool delta_forward = strands_move.delta_forward;

  // var original_group = util.original_group_from_strands_move(design, strands_move);
  var original_helices_view_order_inverse = strands_move.original_helices_view_order_inverse;
  var current_group = util.current_group_from_strands_move(design, strands_move);

  strand = move_strand(
      strand: strand,
      original_helices_view_order_inverse: original_helices_view_order_inverse,
      current_group: current_group,
      delta_view_order: delta_view_order,
      delta_offset: delta_offset,
      delta_forward: delta_forward);
  if (strands_move.copy && !strands_move.keep_color && !strand.is_scaffold) {
    //FIXME: reducer not pure; put color_cycler in design instead; and make this a Design-level reducer
    // so we can stored the update to the color_cycler state
    strand = strand.rebuild((b) => b..color = util.color_cycler.next());
  }
  return strand;
}

Strand move_strand(
    {Strand strand,
    BuiltMap<int, int> original_helices_view_order_inverse,
    HelixGroup current_group,
    int delta_view_order,
    int delta_offset,
    bool delta_forward}) {
  List<Substrand> substrands = strand.substrands.toList();

  //Don't reverse domains, this is to preserve the original order of domain names
  if (delta_forward) {
    substrands = substrands.reversed.toList();
  }

  bool is_moving = delta_view_order != 0 || delta_offset != 0 || delta_forward;

  for (int i = 0; i < substrands.length; i++) {
    Substrand substrand = substrands[i];
    Substrand new_substrand = substrand;
    // Substrands includes Domains and Loopouts,
    // but only Domains need to be processed since only they have helix idx and start/end offsets
    if (substrand is Domain) {
      if (!original_helices_view_order_inverse.containsKey(substrand.helix) && is_moving) {
        throw AssertionError('original_helices_view_order_inverse = $original_helices_view_order_inverse '
            'does not contain key (helix idx) = ${substrand.helix}');
      }
      int new_helix_idx = substrand.helix;
      if (is_moving) {
        num original_view_order = original_helices_view_order_inverse[substrand.helix];
        num new_view_order = original_view_order + delta_view_order;
        new_helix_idx = current_group.helices_view_order[new_view_order];
      }
      assert(new_helix_idx != null);
      Domain domain_moved = substrand.rebuild(
        (b) => b
          ..is_first = i == 0
          ..is_last = i == substrands.length - 1
          ..helix = new_helix_idx
          ..forward = (delta_forward != substrand.forward)
          ..start = substrand.start + delta_offset
          ..end = substrand.end + delta_offset
          ..deletions.replace(substrand.deletions.map((d) => d + delta_offset))
          ..insertions.replace(
              substrand.insertions.map((i) => i.rebuild((ib) => ib..offset = i.offset + delta_offset))),
      );
      new_substrand = domain_moved;
    }
    substrands[i] = new_substrand;
  }
  strand = strand.rebuild((b) => b..substrands.replace(substrands));
  strand = strand.initialize();
  return strand;
}

// replace all strands that had domains moved
BuiltList<Strand> domains_move_commit_reducer(
    BuiltList<Strand> strands, AppState state, actions.DomainsMoveCommit action) {
  if (action.domains_move.allowable && action.domains_move.is_nontrivial) {
    var strands_builder = strands.toBuilder();
    for (var strand in action.domains_move.domains_moving_from_strand.keys) {
      var domains = action.domains_move.domains_moving_from_strand[strand].toSet();
      int strand_idx = strands.indexOf(strand);
      Strand new_strand =
          one_strand_domains_move_commit_reducer(state.design, strand, domains, action.domains_move);
      new_strand = new_strand.initialize();
      strands_builder[strand_idx] = new_strand;
    }
    return strands_builder.build();
  } else {
    return strands;
  }
}

// replace strand with moved domains from that strand
Strand one_strand_domains_move_commit_reducer(
    Design design, Strand strand, Set<Domain> domains_on_strand, DomainsMove domains_move) {
  var substrands = strand.substrands.toList();
  for (int i = 0; i < substrands.length; i++) {
    var domain = substrands[i];
    if (domain is Domain && domains_on_strand.contains(domain)) {
      var original_group = util.original_group_from_domains_move(design, domains_move);
      var current_group = util.current_group_from_domains_move(design, domains_move);
      var moved_domain = domains_move_reducer.move_domain(
        domain: domain,
        original_group: original_group,
        current_group: current_group,
        delta_view_order: domains_move.delta_view_order,
        delta_offset: domains_move.delta_offset,
        delta_forward: domains_move.delta_forward,
      );
      substrands[i] = moved_domain;
    }
  }
  return strand.rebuild((b) => b..substrands.replace(substrands));
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// move DNA ends

BuiltList<Strand> strands_dna_ends_move_commit_reducer(
    BuiltList<Strand> strands, AppState state, actions.DNAEndsMoveCommit action) {
  DNAEndsMove move = action.dna_ends_move;
  if (move.current_offset == move.original_offset) {
    return strands;
  }
  var strands_builder = strands.toBuilder();
  Set<Strand> strands_affected = {};
  for (var move in action.dna_ends_move.moves) {
    var strand = state.design.end_to_strand(move.dna_end);
    strands_affected.add(strand);
  }

  List<InsertionDeletionRecord> records = [];

  for (var strand in strands_affected) {
    int strand_idx = strands.indexOf(strand);
    var ret = single_strand_dna_ends_commit_stop_reducer(strand, move, state.design);
    strand = ret.item1;
    records.addAll(ret.item2);
    strand = strand.initialize();
    strands_builder[strand_idx] = strand;
  }

  for (var record in records) {
    int offset = record.offset;
    int strand_idx = record.strand_idx;
    int ss_idx = record.substrand_idx;
    Strand strand = strands_builder[strand_idx];
    StrandBuilder strand_builder = strand.toBuilder();
    Domain substrand = strand.domains[ss_idx];
    DomainBuilder substrand_builder = substrand.toBuilder();
    if (substrand.deletions.contains(offset)) {
      substrand_builder.deletions.remove(offset);
    } else {
      substrand_builder.insertions.removeWhere((i) => i.offset == offset);
    }
    strand_builder.substrands[ss_idx] = substrand_builder.build();
    strands_builder[strand_idx] = strand_builder.build().initialize();
  }

  return strands_builder.build();
}

class InsertionDeletionRecord {
  int offset;
  int strand_idx;
  int substrand_idx;

  InsertionDeletionRecord({this.offset, this.strand_idx, this.substrand_idx});

  String toString() =>
      'InsertionDeletionRecord(offset=${offset}, strand_idx=$strand_idx, substrand_idx=$substrand_idx)';
}

Tuple2<Strand, List<InsertionDeletionRecord>> single_strand_dna_ends_commit_stop_reducer(
    Strand strand, DNAEndsMove all_move, Design design) {
  List<InsertionDeletionRecord> records = [];
  List<Substrand> substrands = strand.substrands.toList();

  for (int i = 0; i < substrands.length; i++) {
    Substrand substrand = substrands[i];
    Substrand new_substrand = substrand;
    if (substrand is Domain) {
      Domain bound_ss = substrand;
      for (var dnaend in [substrand.dnaend_start, substrand.dnaend_end]) {
        DNAEndMove move = find_move(all_move.moves, dnaend);
        if (move != null) {
          int new_offset = all_move.current_capped_offset_of(dnaend);

          List<int> remaining_deletions = get_remaining_deletions(substrand, new_offset, dnaend);
          List<Insertion> remaining_insertions = get_remaining_insertions(substrand, new_offset, dnaend);

          //XXX: make sure to record deletions and insertions before bound_ss changes
          List<int> deletions_removed =
              bound_ss.deletions.where((d) => !remaining_deletions.contains(d)).toList();
          List<int> insertion_offsets_removed = bound_ss.insertions
              .where((i) => !remaining_insertions.contains(i))
              .map((i) => i.offset)
              .toList();
          for (var offset in deletions_removed + insertion_offsets_removed) {
            Domain other_ss = find_paired_domain(design, bound_ss, offset);
            if (other_ss != null) {
              Strand other_strand = design.substrand_to_strand[other_ss];
              int other_ss_idx = other_strand.substrands.indexOf(other_ss);
              int other_strand_idx = design.strands.indexOf(other_strand);
              records.add(InsertionDeletionRecord(
                  offset: offset, strand_idx: other_strand_idx, substrand_idx: other_ss_idx));
            }
          }

          bound_ss = bound_ss.rebuild(
              (b) => dnaend == substrand.dnaend_start ? (b..start = new_offset) : (b..end = new_offset + 1));
          bound_ss = bound_ss.rebuild(
              (b) => b..deletions.replace(remaining_deletions)..insertions.replace(remaining_insertions));
        }
      }
      new_substrand = bound_ss;
    }
    substrands[i] = new_substrand;
  }
  return Tuple2<Strand, List<InsertionDeletionRecord>>(
      strand.rebuild((b) => b..substrands.replace(substrands)), records);
}

List<int> get_remaining_deletions(Domain substrand, int new_offset, DNAEnd dnaend) => substrand.deletions
    .where((d) => (substrand.dnaend_start == dnaend ? new_offset < d : new_offset > d))
    .toList();

List<Insertion> get_remaining_insertions(Domain substrand, int new_offset, DNAEnd dnaend) =>
    substrand.insertions
        .where((i) => (substrand.dnaend_start == dnaend ? new_offset < i.offset : new_offset > i.offset))
        .toList();

int adjust_offset(DNAEnd end, DNAEndMove move, int delta) {
  int new_offset = end.offset_inclusive + delta;
  if (move.highest_offset != null && delta > 0) {
    new_offset = min(move.highest_offset, new_offset);
  } else if (move.lowest_offset != null && delta < 0) {
    new_offset = max(move.lowest_offset, new_offset);
  }
  return new_offset;
}

DNAEndMove find_move(BuiltList<DNAEndMove> moves, DNAEnd end) {
  for (DNAEndMove move in moves) {
    if (end == move.dna_end) {
      return move;
    }
  }
  return null;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// create Strand

BuiltList<Strand> strand_create(
    BuiltList<Strand> strands, AppState state, actions.StrandCreateCommit action) {
  int helix_idx = action.helix_idx;
  int start = action.start;
  int end = action.end;
  bool forward = action.forward;

  // skip creating Strand if one is already there
  //FIXME: this doesn't seem necessary anymore, given how we've done this error checking while creating
  var existing_substrands_start = state.design.domains_on_helix_at(helix_idx, start);
  var existing_substrands_end = state.design.domains_on_helix_at(helix_idx, end - 1);
  for (var ss in existing_substrands_start.union(existing_substrands_end)) {
    if (ss.forward == forward) {
      return strands;
    }
  }

  Domain substrand = Domain(
      helix: helix_idx,
      forward: forward,
      start: start,
      end: end,
      is_first: true,
      is_last: true,
      is_scaffold: false);
  Strand strand = Strand([substrand], color: action.color, is_scaffold: false);
  var new_strands = strands.rebuild((s) => s..add(strand));

  return new_strands;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// single strand properties

// Unlike a strand part reducer, this sort of action actually stores the strand itself.
BuiltList<Strand> strands_single_strand_reducer(
    BuiltList<Strand> strands, actions.SingleStrandAction action) {
  Strand strand = action.strand;
  int strand_idx = strands.indexOf(strand);

  if (strand_idx < 0) {
    return strands;
  }

  strand = single_strand_reducer(strand, action);
  strand = strand.initialize();

  var strands_builder = strands.toBuilder();
  strands_builder[strand_idx] = strand;
  return strands_builder.build();
}

Reducer<Strand> single_strand_reducer = combineReducers([
  TypedReducer<Strand, actions.ScaffoldSet>(scaffold_set_reducer),
  TypedReducer<Strand, actions.StrandColorSet>(strand_color_set_reducer),
  TypedReducer<Strand, actions.ModificationAdd>(modification_add_reducer),
  TypedReducer<Strand, actions.ModificationRemove>(modification_remove_reducer),
  TypedReducer<Strand, actions.ModificationEdit>(modification_edit_reducer),
  TypedReducer<Strand, actions.StrandNameSet>(strand_name_set_reducer),
  TypedReducer<Strand, actions.ScalePurificationIDTFieldsAssign>(
      scale_purification_idt_fields_assign_reducer),
  TypedReducer<Strand, actions.PlateWellIDTFieldsAssign>(plate_well_idt_fields_assign_reducer),
  TypedReducer<Strand, actions.PlateWellIDTFieldsRemove>(plate_well_idt_fields_remove_reducer),
  TypedReducer<Strand, actions.IDTFieldsRemove>(idt_fields_remove_reducer),
]);

Strand idt_fields_remove_reducer(Strand strand, actions.IDTFieldsRemove action) {
  Strand strand_with_new_idt_fields = strand.rebuild((m) => m.idt = null);
  return strand_with_new_idt_fields;
}
Strand plate_well_idt_fields_remove_reducer(Strand strand, actions.PlateWellIDTFieldsRemove action) {
  if (strand.idt != null) {
    Strand strand_with_new_idt_fields;
    strand_with_new_idt_fields = strand.rebuild((m) => m.idt
      ..plate = null
      ..well = null);
    return strand_with_new_idt_fields;
  }else{
    return strand;
  }
}

Strand plate_well_idt_fields_assign_reducer(Strand strand, actions.PlateWellIDTFieldsAssign action) {
  Strand strand_with_new_idt_fields;
  strand_with_new_idt_fields = strand.rebuild((m) => m.idt.replace(action.idt_fields));
  return strand_with_new_idt_fields;
}

Strand scale_purification_idt_fields_assign_reducer(
    Strand strand, actions.ScalePurificationIDTFieldsAssign action) {
  Strand strand_with_new_idt_fields;
  strand_with_new_idt_fields = strand.rebuild((m) => m.idt.replace(action.idt_fields));
  return strand_with_new_idt_fields;
}

Strand strand_name_set_reducer(Strand strand, actions.StrandNameSet action) =>
    strand.rebuild((b) => b..name = action.name);

Strand modification_add_reducer(Strand strand, actions.ModificationAdd action) {
  Strand strand_with_new_modification;
  // first overwrite this strand in the builder list
  if (action.modification is ModificationInternal) {
    strand_with_new_modification =
        strand.rebuild((m) => m.modifications_int[action.strand_dna_idx] = action.modification);
  } else if (action.modification is Modification3Prime) {
    strand_with_new_modification = strand.rebuild((m) => m.modification_3p.replace(action.modification));
  } else if (action.modification is Modification5Prime) {
    strand_with_new_modification = strand.rebuild((m) => m.modification_5p.replace(action.modification));
  }
  return strand_with_new_modification;
}

Strand modification_remove_reducer(Strand strand, actions.ModificationRemove action) {
  Strand strand_with_new_modification;
  // first overwrite this strand in the builder list
  if (action.modification is ModificationInternal) {
    strand_with_new_modification = strand.rebuild((m) => m.modifications_int.remove(action.strand_dna_idx));
  } else if (action.modification is Modification3Prime) {
    strand_with_new_modification = strand.rebuild((m) => m.modification_3p = null);
  } else if (action.modification is Modification5Prime) {
    strand_with_new_modification = strand.rebuild((m) => m.modification_5p = null);
  }
  return strand_with_new_modification;
}

Strand modification_edit_reducer(Strand strand, actions.ModificationEdit action) {
  Strand strand_with_edited_modification;
  // first overwrite this strand in the builder list
  if (action.modification is ModificationInternal) {
    strand_with_edited_modification =
        strand.rebuild((m) => m.modifications_int[action.strand_dna_idx] = action.modification);
  } else if (action.modification is Modification3Prime) {
    strand_with_edited_modification = strand.rebuild((m) => m.modification_3p.replace(action.modification));
  } else if (action.modification is Modification5Prime) {
    strand_with_edited_modification = strand.rebuild((m) => m.modification_5p.replace(action.modification));
  }
  return strand_with_edited_modification;
}

Strand scaffold_set_reducer(Strand strand, actions.ScaffoldSet action) {
  Color new_color = action.is_scaffold ? util.ColorCycler.scaffold_color : util.color_cycler.next();
  strand = strand.rebuild((b) => b
    ..is_scaffold = action.is_scaffold
    ..color = new_color);
  return strand;
}

Strand strand_color_set_reducer(Strand strand, actions.StrandColorSet action) =>
    strand.rebuild((b) => b..color = action.color);

BuiltList<Strand> modifications_5p_edit_reducer(
    BuiltList<Strand> strands, AppState state, actions.Modifications5PrimeEdit action) {
  var new_strands = strands.toList();

  List<String> strand_ids = [for (var strand in strands) strand.id];
  for (var selectable_mod in action.modifications) {
    int strand_idx = strand_ids.indexOf(selectable_mod.strand_id);
    Strand strand = strands[strand_idx];
    strand = strand.rebuild((b) => b..modification_5p.replace(action.new_modification));
    strand = strand.initialize();
    new_strands[strand_idx] = strand;
  }

  return new_strands.build();
}

BuiltList<Strand> modifications_3p_edit_reducer(
    BuiltList<Strand> strands, AppState state, actions.Modifications3PrimeEdit action) {
  var new_strands = strands.toList();

  List<String> strand_ids = [for (var strand in strands) strand.id];
  for (var selectable_mod in action.modifications) {
    int strand_idx = strand_ids.indexOf(selectable_mod.strand_id);
    Strand strand = strands[strand_idx];
    strand = strand.rebuild((b) => b..modification_3p.replace(action.new_modification));
    strand = strand.initialize();
    new_strands[strand_idx] = strand;
  }

  return new_strands.build();
}

BuiltList<Strand> modifications_int_edit_reducer(
    BuiltList<Strand> strands, AppState state, actions.ModificationsInternalEdit action) {
  // collect all internal modifications for each strand
  Map<String, Set<SelectableModificationInternal>> strand_id_to_mods = {};
  for (var mod in action.modifications) {
    if (!strand_id_to_mods.containsKey(mod.strand.id)) {
      strand_id_to_mods[mod.strand.id] = {};
    }
    strand_id_to_mods[mod.strand.id].add(mod);
  }

  var new_strands = strands.toList();
  List<String> strand_ids = [for (var strand in strands) strand.id];
  for (String strand_id in strand_id_to_mods.keys) {
    Set<SelectableModificationInternal> selectable_mods = strand_id_to_mods[strand_id];
    int strand_idx = strand_ids.indexOf(strand_id);
    Strand strand = strands[strand_idx];

    Map<int, ModificationInternal> mods_int = strand.modifications_int.toMap();

    for (var selectable_mod in selectable_mods) {
      int dna_idx = selectable_mod.dna_idx;
      mods_int[dna_idx] = action.new_modification;
    }

    strand = strand.rebuild((b) => b.modifications_int.replace(mods_int));
    strand = strand.initialize();
    new_strands[strand_idx] = strand;
  }

  return new_strands.build();
}
