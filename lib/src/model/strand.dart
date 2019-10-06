import 'dart:math';

import 'package:color/color.dart';
import 'package:tuple/tuple.dart';
import 'package:w_flux/w_flux.dart';

import 'strand_ui_model.dart';
import '../dispatcher/actions.dart';
import '../json_serializable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'dna_design.dart';

class StrandRemoveActionPack extends ReversibleActionPack<Action<Strand>, Strand> {
  Strand strand;

  StrandRemoveActionPack(this.strand) : super(Actions.strand_remove, strand);

  @override
  ReversibleActionPack<Action<Strand>, Strand> reverse() {
    return StrandAddActionPack(this.strand);
  }
}

class StrandAddActionPack extends ReversibleActionPack<Action<Strand>, Strand> {
  Strand strand;

  StrandAddActionPack(this.strand) : super(Actions.strand_add, strand);

  @override
  ReversibleActionPack<Action<Strand>, Strand> reverse() {
    return StrandRemoveActionPack(this.strand);
  }
}

class StrandsStore extends Store {

  List<Strand> _strands;

  List<Strand> get strands => this._strands;

  set strands(List<Strand> new_strands) {
    this._strands = new_strands;
  }

  StrandsStore() {
    this._strands = [];
  }
}

class IDTFields extends JSONSerializable {
  String name;
  String scale;
  String purification;
  String plate;
  String well;

  IDTFields(this.name, this.scale, this.purification);

  Map<String, dynamic> to_json_serializable() {
    Map<String, dynamic> json_map = {
      constants.idt_name_key: this.name,
      constants.idt_scale_key: this.scale,
      constants.idt_purification_key: this.purification
    };
    if (this.plate != null) {
      json_map[constants.idt_plate_key] = this.plate;
    }
    if (this.well != null) {
      json_map[constants.idt_well_key] = this.well;
    }
    return json_map;
  }

  IDTFields.from_json(Map<String, dynamic> json_map) {
    var field_name = 'IDTFields';
    this.name = util.get_value(json_map, constants.idt_name_key, field_name);
    this.scale = util.get_value(json_map, constants.idt_scale_key, field_name);
    this.purification = util.get_value(json_map, constants.idt_purification_key, field_name);
    if (json_map.containsKey(constants.idt_plate_key)) {
      this.plate = json_map[constants.idt_plate_key];
    }
    if (json_map.containsKey(constants.idt_scale_key)) {
      this.scale = json_map[constants.idt_scale_key];
    }
    if (this.plate == null && this.well != null) {
      throw IllegalDNADesignError("cannot set IDTFields.well to ${this.well} when plate is null\n"
          "this occurred when reading IDTFields entry:\n${json_map}");
    }
    if (this.plate != null && this.well == null) {
      throw IllegalDNADesignError("cannot set IDTFields.plate to ${this.plate} when well is null\n"
          "this occurred when reading IDTFields entry:\n${json_map}");
    }
  }
}

class Strand extends Store implements JSONSerializable {
  static Color DEFAULT_STRAND_COLOR = RgbColor.name('black');

  Color color = null;
  String dna_sequence = null;
  List<Substrand> substrands = [];
  IDTFields idt = null;

  StrandUIModel ui_model;

  Strand() {
    this.ui_model = StrandUIModel(this);
    this._handle_actions();
  }

  void _handle_actions() {
    Actions.add_strand_hover.listen((strand) {
      if (identical(strand, this)){
        this.ui_model.hover = true;
        this.trigger();
      }
    });
    Actions.remove_strand_hover.listen((strand) {
      if (identical(strand, this)){
        this.ui_model.hover = false;
        this.trigger();
      }
    });

    //XXX: the code below fires trigger() for every strand and causes a re-render of all strands
    // even though only one changed. So we substitute what triggerOnAction is shorthand for, with an
    // additiona check for equality between this and strand to avoid the re-render for most strands.
//    this.triggerOnActionV2<Strand>(Actions.add_strand_hover, (strand) {
//      strand.ui_model.hover = true;
//    });
//    this.triggerOnActionV2<Strand>(Actions.remove_strand_hover, (strand) {
//      strand.ui_model.hover = false;
//    });
  }

  String css_selector() {
    BoundSubstrand first_ss = this.bound_substrands().first;
    return 'strand-H${first_ss.helix}-${first_ss.offset_5p}-${first_ss.forward? 'forward': 'reverse'}';
  }

  String toString() {
    var first_ss = this.first_bound_substrand();
    return 'Strand(helix=${first_ss.helix}, start=${first_ss.offset_5p}), forward=${first_ss.forward}';
  }

  List<BoundSubstrand> bound_substrands() =>
      [for (var ss in this.substrands) if (ss.is_bound_substrand()) ss];

  List<BoundSubstrand> loopouts() => [for (var ss in this.substrands) if (ss.is_loopout()) ss];

  int dna_length() {
    int num = 0;
    for (var substrand in substrands) {
      num += substrand.dna_length();
    }
    return num;
  }

  Map<String, dynamic> to_json_serializable() {
    var json_map = Map<String, dynamic>();

    if (this.color != null) {
      json_map[constants.color_key] = NoIndent(this.color.toRgbColor().toMap());
    }

    if (this.dna_sequence != null) {
      json_map[constants.dna_sequence_key] = this.dna_sequence;
    }

    if (this.idt != null) {
      json_map[constants.dna_sequence_key] = NoIndent(this.idt.to_json_serializable());
    }

    json_map[constants.substrands_key] = [for (var ss in this.substrands) ss.to_json_serializable()];

    return json_map;
  }

  Strand.from_json(Map<String, dynamic> json_map) {
    this.ui_model = StrandUIModel(this);
    this._handle_actions();

    // need to use List.from because List.map returns Iterable, not List
    var name = 'Strand';
    this.substrands = List<Substrand>.from(util
        .get_value(json_map, constants.substrands_key, name)
        .map((substrand_json) => Substrand.from_json(substrand_json)));
    for (var substrand in this.substrands) {
      substrand._strand = this;
    }

    if (json_map.containsKey(constants.color_key)) {
      this.color = parse_json_color(json_map[constants.color_key]);
    } else {
      this.color = DEFAULT_STRAND_COLOR;
    }

    this.dna_sequence =
        json_map.containsKey(constants.dna_sequence_key) ? json_map[constants.dna_sequence_key] : null;
    if (this.dna_sequence != null) {
      if (this.dna_sequence.length != this.dna_length()) {
        throw StrandError(this, 'Strand length does not match DNA sequence length');
      }
    }

    if (json_map.containsKey(constants.idt_key)) {
      try {
        this.idt = IDTFields.from_json(json_map[constants.idt_key]);
      } catch (err) {
        throw StrandError(this, err.toString());
      }
    }

    if (this.substrands.first is Loopout) {
      throw StrandError(this, 'Loopout at beginning of strand not supported');
    }

    if (this.substrands.last is Loopout) {
      throw StrandError(this, 'Loopout at end of strand not supported');
    }
  }

  BoundSubstrand first_bound_substrand({int starting_at = 0}) {
    for (int i = starting_at; i < this.substrands.length; i++) {
      if (this.substrands[i] is BoundSubstrand) {
        return this.substrands[i];
      }
    }
    throw AssertionError('should not be reachable');
  }

  BoundSubstrand last_bound_substrand() {
    if (this.substrands.last is BoundSubstrand) {
      return (this.substrands.last as BoundSubstrand);
    } else {
      int len = this.substrands.length;
      assert(len >= 2);
      assert(this.substrands[len - 2] is BoundSubstrand);
      return (this.substrands[len - 2] as BoundSubstrand);
    }
  }
}

//class Substrand extends Union2Impl<BoundSubstrand,Loopout> {
//  // copying the pattern here:
//  // https://github.com/fluttercommunity/mvi_sealed_unions/blob/master/lib/trending/trending_model.dart
//
//  static final Doublet<BoundSubstrand,Loopout> factory = const Doublet<BoundSubstrand,Loopout>();
//
//  Substrand._(Union2<BoundSubstrand,Loopout> union) : super(union);
//
//  factory Substrand.loopout(int length) {
//    return Substrand._(factory(Loopout(length)));
//  }
//
//  int dna_length();
//
//  bool is_loopout();
//
//  bool is_bound_substrand() => !this.is_loopout();
//
//  String dna_sequence();
//
//
//}

abstract class Substrand extends JSONSerializable {
  // for efficiency but not serialized since it would introduce a JSON cycle
  Strand _strand;

  Strand get strand => this._strand;

  void set strand(Strand new_strand) {
    this._strand = new_strand;
  }

  int dna_length();

  bool is_loopout();

  bool is_bound_substrand() => !this.is_loopout();

  String dna_sequence();

  static Substrand from_json(Map<String, dynamic> json_map) {
    if (json_map.containsKey(constants.loopout_key)) {
      return Loopout.from_json(json_map);
    } else {
      return BoundSubstrand.from_json(json_map);
    }
  }
}

class Loopout extends Substrand {
  int length;

  Loopout(this.length);

  String toString() => 'Loopout(${this.length})';

  bool is_loopout() => true;

  int dna_length() => this.length;

  String dna_sequence() {
    String strand_seq = this.strand.dna_sequence;
    if (strand_seq == null) {
      return null;
    }

    int str_idx_left = this.get_seq_start_idx();
    int str_idx_right = str_idx_left + this.length; // EXCLUSIVE (unlike similar code for Substrand)
    String subseq = strand_seq.substring(str_idx_left, str_idx_right);
    return subseq;
  }

  /// Starting DNA subsequence index for first base of this :any:`Loopout` on its Parent
  /// :any:`Strand`'s DNA sequence.
  int get_seq_start_idx() {
    List<Substrand> substrands = this.strand.substrands;
    // index of self in parent strand's list of substrands
    int self_substrand_idx = substrands.indexOf(this);
    // index of self's position within the DNA sequence of parent strand
    int self_seq_idx_start = 0;
    for (Substrand prev_substrand in substrands.sublist(0, self_substrand_idx)) {
      self_seq_idx_start += prev_substrand.dna_length();
    }
    return self_seq_idx_start;
  }

  Loopout.from_json(Map<String, dynamic> json_map) {
    var name = 'Loopout';
    this.length = util.get_value(json_map, constants.loopout_key, name);
  }

  Map<String, dynamic> to_json_serializable() {
    var json_map = {
      constants.loopout_key: this.length,
    };
    return json_map;
  }
}

/// Represents a Substrand that is on a Helix. It may not be bound in the sense of having another
/// BoundSubstrand that overlaps it, but it could potentially bind. By constrast a Loopout cannot be bound
/// to any other Substrand since there is no Helix it is associated with.
class BoundSubstrand extends Substrand {
  int helix = -1;
  bool forward = true;
  int start = null;
  int end = null;
  List<int> deletions = [];
  List<Tuple2<int, int>> insertions = []; // elt: Pair(offset, num insertions)

  /// 5' end, INCLUSIVE
  int get offset_5p => this.forward ? this.start : this.end - 1;

  /// 3' end, INCLUSIVE
  int get offset_3p => this.forward ? this.end - 1 : this.start;

  bool is_loopout() => false;

  int dna_length() => (this.end - this.start) - this.deletions.length + this.num_insertions();

  int get visual_length => (this.end - this.start);

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
    if (this._strand.dna_sequence == null) {
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
    String strand_seq = this._strand.dna_sequence;
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

    String subseq = this._strand.dna_sequence.substring(str_idx_low, str_idx_high + 1);
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
    var substrands = this._strand.substrands;
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

  BoundSubstrand();

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
    this.helix = util.get_value(json_map, constants.helix_idx_key, name);
    this.forward = util.get_value(json_map, constants.forward_key, name);
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
}
