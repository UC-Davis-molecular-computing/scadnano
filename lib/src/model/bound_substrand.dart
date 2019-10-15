import 'dart:math';

import 'package:w_flux/w_flux.dart';
import 'package:tuple/tuple.dart';

import '../app.dart';
import 'composite_stores.dart';
import 'helix.dart';
import 'select_mode.dart';
import 'selectable.dart';
import '../json_serializable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'strand.dart';

/// This is needed to make the 5' and 3' ends selectable and listenable.
class DNAEnd extends Store with Selectable {
  BoundSubstrand substrand;
  int offset;
  bool is_5p;

  DNAEnd(this.is_5p, this.substrand);

//  trigger() {
//    print('calling DNAEnd.trigger() on ${id()}');
//    super.trigger();
//  }

  bool in_box(Point<num> upper_left_corner, Point<num> lower_right_corner) {
    return substrand.in_box(upper_left_corner, lower_right_corner, this);
  }


  SelectModeChoice select_mode() {
    if (is_5p) {
      if (substrand.is_first()) {
        return SelectModeChoice.end_5p_strand;
      } else {
        return SelectModeChoice.end_5p_substrand;
      }
    } else {
      if (substrand.is_last()) {
        return SelectModeChoice.end_3p_strand;
      } else {
        return SelectModeChoice.end_3p_substrand;
      }
    }
  }

  String id() => 'end-' + (is_5p? '5p': '3p') + '-' + substrand.id();
}

/// Represents a Substrand that is on a Helix. It may not be bound in the sense of having another
/// BoundSubstrand that overlaps it, but it could potentially bind. By constrast a Loopout cannot be bound
/// to any other Substrand since there is no Helix it is associated with.
class BoundSubstrand extends Substrand {
//  BoundSubstrandUIModel ui_model;

  int helix = -1;
  bool forward = true;
  DNAEnd dnaend_start;
  DNAEnd dnaend_end;

  int get start => dnaend_start.offset;

  int get end => dnaend_end.offset;

//  int start = null;
//  int end = null;
  List<int> deletions = [];
  List<Tuple2<int, int>> insertions = []; // elt: Pair(offset, num insertions)

  set start(int new_start) {
    dnaend_start.offset = new_start;
  }

  set end(int new_start) {
    dnaend_end.offset = new_start;
  }

  DNAEnd get dnaend_5p => forward ? dnaend_start : dnaend_end;

  DNAEnd get dnaend_3p => forward ? dnaend_end : dnaend_start;

  bool selected_5p() => app.model.dna_design.selectable_store.selected(dnaend_5p);

  bool selected_3p() => app.model.dna_design.selectable_store.selected(dnaend_3p);

  bool selected_start() => app.model.dna_design.selectable_store.selected(dnaend_start);

  bool selected_end() => app.model.dna_design.selectable_store.selected(dnaend_end);

  bool is_first() => this == strand.first_bound_substrand();

  bool is_last() => this == strand.last_bound_substrand();

  String id() => 'substrand-H${helix}-${start}-${end}-${forward ? 'forward' : 'reverse'}';

  BoundSubstrand() {
    _create_dna_ends();
    handle_actions();
  }

  _create_dna_ends() {
    dnaend_start = DNAEnd(forward, this);
    dnaend_end = DNAEnd(!forward, this);
  }

  handle_actions() {
    subscribe_to_stores(this, [dnaend_start, dnaend_end]);
  }

  register_selectables(SelectableStore store) {
    store.register(dnaend_end);
    store.register(dnaend_start);
  }

  dynamic to_json_serializable() {
    var json_map = {
      constants.helix_idx_key: this.helix,
      constants.forward_key: this.forward,
      constants.start_key: this.start,
      constants.end_key: this.end,
    };
    if (this.deletions.isNotEmpty) {
      json_map[constants.deletions_key] = this.deletions;
    }
    if (this.insertions.isNotEmpty) {
      // need to use List.from because List.map returns Iterable, not List
      json_map[constants.insertions_key] =
          List<dynamic>.from(this.insertions.map((insertion) => insertion.toList()));
    }
    return NoIndent(json_map);
  }

  BoundSubstrand.from_json(Map<String, dynamic> json_map) {
    var name = 'Substrand';
    this.forward = util.get_value(json_map, constants.forward_key, name);
    _create_dna_ends();

    this.helix = util.get_value(json_map, constants.helix_idx_key, name);
    this.start = util.get_value(json_map, constants.start_key, name);
    this.end = util.get_value(json_map, constants.end_key, name);
    if (json_map.containsKey(constants.deletions_key)) {
      this.deletions = List<int>.from(json_map[constants.deletions_key]);
    } else {
      this.deletions = [];
    }
    if (json_map.containsKey(constants.insertions_key)) {
      this.insertions = parse_json_insertions(json_map[constants.insertions_key]);
    } else {
      this.insertions = [];
    }
  }

  static List<Tuple2<int, int>> parse_json_insertions(json_encoded_insertions) {
    // need to use List.from because List.map returns Iterable, not List
    return List<Tuple2<int, int>>.from(
        json_encoded_insertions.map((insertion) => Tuple2<int, int>.fromList(insertion)));
  }

  /// 5' end, INCLUSIVE
  int get offset_5p => this.forward ? this.start : this.end - 1;

  /// 3' end, INCLUSIVE
  int get offset_3p => this.forward ? this.end - 1 : this.start;

  bool is_loopout() => false;

  int dna_length() => (this.end - this.start) - this.deletions.length + this.num_insertions();

  int get visual_length => (this.end - this.start);

  String toString() =>
      'BoundSubstrand(helix=${this.helix}, forward=${this.forward}, start=${this.start}, end=${this.end})';

  /// Indicates if `offset` is the offset of a base on this substrand.
  /// Note that offsets refer to visual portions of the displayed grid for the Helix.
  /// If for example, this Substrand starts at position 0 and ends at 10, and it has 5 deletions,
  /// then it contains the offset 7 even though there is no base 7 positions from the start.
  bool contains_offset(int offset) {
    return this.start <= offset && offset < this.end;
  }

  /// List of offsets (inclusive at each end) in 5' - 3' order, from 5' to `offset_stop`.
  List<int> offsets_from_5p_to(int offset_stop) {
    List<int> offsets = [];
    if (this.forward) {
      for (int offset = this.start; offset <= offset_stop; offset++) {
        offsets.add(offset);
      }
    } else {
      for (int offset = this.end - 1; offset >= offset_stop; offset--) {
        offsets.add(offset);
      }
    }
    return offsets;
  }

  /// List of offsets (inclusive at each end) in 5' - 3' order.
  List<int> offsets_in_5p_3p_order() {
    List<int> offsets = [];
    if (this.forward) {
      for (int offset = this.start; offset < this.end; offset++) {
        offsets.add(offset);
      }
    } else {
      for (int offset = this.end - 1; offset >= this.start; offset--) {
        offsets.add(offset);
      }
    }
    return offsets;
  }

  String dna_sequence() {
    if (this.strand.dna_sequence == null) {
      return null;
    } else {
//      for debugging
//      if (this.start >= 384 && this.helix_idx == 15) {
//        print(this._strand.dna_sequence);
//        var x=0;
//      }
      return this.dna_sequence_in(this.start, this.end - 1);
    }
  }

  /// Return DNA sequence of this Substrand in the interval of offsets given by
  //  [`left`, `right`], INCLUSIVE.
  //
  //  WARNING: This is inclusive on both ends,
  //  unlike other parts of this API where the right endpoint is exclusive.
  //  This is to make the notion well-defined when one of the endpoints is on an offset with a
  //  deletion or insertion.
  String dna_sequence_in(int offset_low, int offset_high) {
    String strand_seq = this.strand.dna_sequence;
    if (strand_seq == null) {
      return null;
    }
    // if on a deletion, move inward until we are off of it
    while (this.deletions.contains(offset_low)) {
      offset_low += 1;
    }
    while (this.deletions.contains(offset_high)) {
      offset_high -= 1;
    }

    if (offset_low > offset_high) {
      return '';
    }
    if (offset_low >= this.end) {
      return '';
    }
    if (offset_high < 0) {
      return '';
    }

    bool five_p_on_left = this.forward;
    int str_idx_low = this.offset_to_strand_dna_idx(offset_low, five_p_on_left);
    int str_idx_high = this.offset_to_strand_dna_idx(offset_high, !five_p_on_left);
    if (!this.forward) {
      // these will be out of order if strand is reverse
      int swap = str_idx_low;
      str_idx_low = str_idx_high;
      str_idx_high = swap;
    }

    String subseq = this.strand.dna_sequence.substring(str_idx_low, str_idx_high + 1);
    return subseq;
  }

  /// This is suitable for rendering along the helix lines.
  /// For deletions, spaces are added where a base would be.
  /// For insertions, all bases corresponding to the insertion
  /// (including the first one that would be represented even if there were no insertion)
  /// are replaced with a single space.
  String dna_sequence_deletions_insertions_to_spaces() {
    String seq = this.dna_sequence();
    List<int> codeunits = [];

    var deletions_set = this.deletions.toSet();
    var insertions_map = Map<int, int>.fromIterable(
      this.insertions,
      key: (insertion) => insertion.item1,
      value: (insertion) => insertion.item2,
    );

    int seq_idx = 0;
    int offset = this.offset_5p;
    int space_codeunit = ' '.codeUnitAt(0);
    int forward = this.forward ? 1 : -1;
    bool offset_out_of_bounds(offset) =>
        this.forward ? offset >= this.offset_3p + forward : offset <= this.offset_3p + forward;
    while (!offset_out_of_bounds(offset)) {
      if (deletions_set.contains(offset)) {
        codeunits.add(space_codeunit);
        offset += forward;
      } else if (insertions_map.containsKey(offset)) {
        codeunits.add(space_codeunit);
        int insertion_length = insertions_map[offset];
        int forward_insertion = insertion_length + 1;
        seq_idx += forward_insertion;
        offset += forward;
      } else {
        int base_codeunit = seq.codeUnitAt(seq_idx);
        codeunits.add(base_codeunit);
        seq_idx++;
        offset += forward;
      }
    }

    var seq_modified = String.fromCharCodes(codeunits);
    return seq_modified;
  }

  /// Convert from offset on Substrand's Helix to string index on the parent Strand's DNA sequence.
  int offset_to_strand_dna_idx(int offset, bool offset_closer_to_5p) {
    if (this.deletions.contains(offset)) {
      throw ArgumentError('offset {offset} illegally contains a deletion from {self.deletions}');
    }

    // length adjustment for insertions depends on whether this is a left or right offset
    int len_adjust = this._net_ins_del_length_increase_from_5p_to(offset, offset_closer_to_5p);

    // get string index assuming this Substrand is first on Strand
    int ss_str_idx = null;
    if (this.forward) {
      //account for insertions and deletions
      offset += len_adjust;
      ss_str_idx = offset - this.start;
    } else {
      // account for insertions and deletions
      offset -= len_adjust;
      ss_str_idx = this.end - 1 - offset;
    }

    // correct for existence of previous Substrands on this Strand
    return ss_str_idx + this.get_seq_start_idx();
  }

  /// Net number of insertions from 5' end to offset_edge.
  /// Check is inclusive on the left and exclusive on the right (which is 5' depends on direction).
  int _net_ins_del_length_increase_from_5p_to(int offset_edge, bool offset_closer_to_5p) {
    int length_increase = 0;
    for (int deletion in this.deletions) {
      if (this._between_5p_and_offset(deletion, offset_edge)) {
        length_increase -= 1;
      }
    }
    for (Tuple2<int, int> insertion in this.insertions) {
      int insertion_offset = insertion.item1;
      int insertion_length = insertion.item2;
      if (this._between_5p_and_offset(insertion_offset, offset_edge)) {
        length_increase += insertion_length;
      }
    }

    // special case for when offset_edge is an endpoint closer to the 3' end,
    // we add its extra insertions also in this case
    if (!offset_closer_to_5p) {
      var insertion_map = Map<int, int>.fromIterable(
        this.insertions,
        key: (insertion) => insertion.item1,
        value: (insertion) => insertion.item2,
      );
      if (insertion_map.containsKey(offset_edge)) {
        int insertion_length = insertion_map[offset_edge];
        length_increase += insertion_length;
      }
    }

    return length_increase;
  }

  bool _between_5p_and_offset(int offset_to_test, int offset_edge) {
    return (this.forward && this.start <= offset_to_test && offset_to_test < offset_edge) ||
        (!this.forward && offset_edge < offset_to_test && offset_to_test < this.end);
  }

  /// Starting DNA subsequence index for first base of this Substrand on its
  /// parent Strand DNA sequence.
  int get_seq_start_idx() {
    var substrands = this.strand.substrands;
    // index of self in parent strand's list of substrands
    var self_substrand_idx = substrands.indexOf(this);
    // index of self's position within the DNA sequence of parent strand
    int self_seq_idx_start = 0;
    for (var prev_substrand in substrands.getRange(0, self_substrand_idx)) {
      self_seq_idx_start += prev_substrand.dna_length();
    }
    return self_seq_idx_start;
  }

  int num_insertions() {
    int num = 0;
    for (Tuple2<int, int> insertion in insertions) {
      num += insertion.item2;
    }
    return num;
  }

  bool overlaps(BoundSubstrand other) {
    return (this.helix == other.helix &&
        this.forward == (!other.forward) &&
        this.compute_overlap(other).item1 >= 0);
  }

  Tuple2<int, int> compute_overlap(BoundSubstrand other) {
    int overlap_start = max(this.start, other.start);
    int overlap_end = min(this.end, other.end);
    if (overlap_start >= overlap_end) {
      // overlap is empty
      return Tuple2<int, int>(-1, -1);
    }
    return Tuple2<int, int>(overlap_start, overlap_end);
  }

  bool contains_insertion_at(int offset) {
    for (Tuple2<int, int> insertion in this.insertions) {
      if (offset == insertion.item1) {
        return true;
      }
    }
    return false;
  }

  bool in_box(Point<num> upper_left_corner, Point<num> lower_right_corner, DNAEnd dna_end) {
    Helix helix = app.model.dna_design.helices[this.helix];
    int offset = dna_end == dnaend_5p ? offset_5p : offset_3p;
    Point<num> end_point = helix.svg_base_pos(offset, forward);

    return upper_left_corner.x <= end_point.x &&
        end_point.x <= lower_right_corner.x &&
        upper_left_corner.y <= end_point.y &&
        end_point.y <= lower_right_corner.y;
  }

}
