import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/middleware/insertion_deletion_pairing.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/dna_ends_move.dart';
import 'package:scadnano/src/state/strands_move.dart';
import 'package:scadnano/src/state/substrand.dart';
import 'package:tuple/tuple.dart';

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
  TypedReducer<BuiltList<Strand>, actions.StrandsMoveCommit>(strands_move_commit_reducer),
  TypedReducer<BuiltList<Strand>, actions.AssignDNA>(assign_dna_reducer),
  TypedReducer<BuiltList<Strand>, actions.RemoveDNA>(remove_dna_reducer),
  TypedReducer<BuiltList<Strand>, actions.ReplaceStrands>(replace_strands_reducer),
//  TypedReducer<BuiltList<Strand>, actions.ScaffoldSet>(scaffold_set_reducer),
  TypedReducer<BuiltList<Strand>, actions.SingleStrandAction>(strands_single_strand_reducer),
]);

GlobalReducer<BuiltList<Strand>, AppState> strands_global_reducer = combineGlobalReducers([
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.DNAEndsMoveCommit>(
      strands_dna_ends_move_commit_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandPartAction>(strands_part_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.StrandCreateCommit>(strand_create),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.DeleteAllSelected>(delete_all_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.Nick>(nick_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.Ligate>(ligate_reducer),
  TypedGlobalReducer<BuiltList<Strand>, AppState, actions.JoinStrandsByCrossover>(
      join_strands_by_crossover_reducer),
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
]);

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// move strands

BuiltList<Strand> strands_move_commit_reducer(BuiltList<Strand> strands, actions.StrandsMoveCommit action) {
  if (action.strands_move.allowable && action.strands_move.is_nontrivial) {
    var strands_builder = strands.toBuilder();
    for (var strand in action.strands_move.strands_moving) {
      int strand_idx = strands.indexOf(strand);
      if (action.strands_move.copy) {
        Strand new_strand = single_strand_commit_stop_reducer(strand, action.strands_move);
        new_strand = new_strand.initialize();
        strands_builder.add(new_strand);
      } else {
        strand = single_strand_commit_stop_reducer(strand, action.strands_move);
        strand = strand.initialize();
        strands_builder[strand_idx] = strand;
      }
    }
    return strands_builder.build();
  } else {
    return strands;
  }
}

Strand single_strand_commit_stop_reducer(Strand strand, StrandsMove strands_move) {
  int delta_view_order = strands_move.delta_view_order;
  int delta_offset = strands_move.delta_offset;
  bool delta_forward = strands_move.delta_forward;

  strand = moved_strand(strand,
      delta_view_order: delta_view_order,
      delta_offset: delta_offset,
      delta_forward: delta_forward,
      helices_view_order: strands_move.helices_view_order,
      helices_view_order_inverse: strands_move.helices_view_order_inverse);
  if (strands_move.copy && !strands_move.keep_color && !strand.is_scaffold) {
    //FIXME: this makes the reducer not pure
    strand = strand.rebuild((b) => b..color = util.color_cycler.next());
  }
  return strand;
}

Strand moved_strand(Strand strand,
    {int delta_view_order,
    int delta_offset,
    bool delta_forward,
    BuiltList<int> helices_view_order,
    BuiltMap<int, int> helices_view_order_inverse}) {
  List<Substrand> substrands = strand.substrands.toList();
  if (delta_forward) {
    substrands = substrands.reversed.toList();
  }
  for (int i = 0; i < substrands.length; i++) {
    Substrand substrand = substrands[i];
    Substrand new_substrand = substrand;
    if (substrand is Domain) {
      Domain bound_ss_moved = substrand.rebuild(
        (b) => b
          ..is_first = i == 0
          ..is_last = i == substrands.length - 1
          ..helix = helices_view_order[helices_view_order_inverse[substrand.helix] + delta_view_order]
          ..forward = (delta_forward != substrand.forward)
          ..start = substrand.start + delta_offset
          ..end = substrand.end + delta_offset
          ..deletions.replace(substrand.deletions.map((d) => d + delta_offset))
          ..insertions.replace(
              substrand.insertions.map((i) => i.rebuild((ib) => ib..offset = i.offset + delta_offset))),
      );
      new_substrand = bound_ss_moved;
    }
    substrands[i] = new_substrand;
  }
  strand = strand.rebuild((b) => b..substrands.replace(substrands));
  strand = strand.initialize();
  return strand;
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
    Domain substrand = strand.domains()[ss_idx];
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
            Domain other_ss = find_paired_substrand(design, bound_ss, offset);
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
  var existing_substrands_start = state.design.substrands_on_helix_at(helix_idx, start);
  var existing_substrands_end = state.design.substrands_on_helix_at(helix_idx, end - 1);
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
]);

Strand scaffold_set_reducer(Strand strand, actions.ScaffoldSet action) {
  Color new_color = action.is_scaffold ? util.ColorCycler.scaffold_color : util.color_cycler.next();
  strand = strand.rebuild((b) => b
    ..is_scaffold = action.is_scaffold
    ..color = new_color);
  return strand;
}

Strand strand_color_set_reducer(Strand strand, actions.StrandColorSet action) =>
    strand.rebuild((b) => b..color = action.color);
