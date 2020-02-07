import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/serializers.dart';
import 'package:scadnano/src/state/strand_part.dart';
import 'package:tuple/tuple.dart';
import 'package:built_collection/built_collection.dart';

import 'dna_end.dart';
import '../json_serializable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'substrand.dart';

part 'bound_substrand.g.dart';

abstract class Insertion
    with BuiltJsonSerializable
    implements Built<Insertion, InsertionBuilder>, JSONSerializable, StrandPart {
  int get offset;

  int get length;

  dynamic toJson() => [offset, length];

  dynamic to_json_serializable({bool suppress_indent = false}) => toJson();

  Insertion fromJson(List list) => Insertion(list[0], list[1]);

  /************************ begin BuiltValue boilerplate ************************/
  factory Insertion(int offset, int count) => Insertion.from((b) => b
    ..offset = offset
    ..length = count);

  factory Insertion.from([void Function(InsertionBuilder) updates]) = _$Insertion;

  Insertion._();

  static Serializer<Insertion> get serializer => _$insertionSerializer;
}

/// Represents a Substrand that is on a Helix. It may not be bound in the sense of having another
/// BoundSubstrand that overlaps it, but it could potentially bind. By constrast a Loopout cannot be bound
/// to any other Substrand since there is no Helix it is associated with.
abstract class BoundSubstrand
    with BuiltJsonSerializable
    implements Built<BoundSubstrand, BoundSubstrandBuilder>, Substrand {
  BoundSubstrand._();

  static Serializer<BoundSubstrand> get serializer => _$boundSubstrandSerializer;

  factory BoundSubstrand.from([void Function(BoundSubstrandBuilder) updates]) = _$BoundSubstrand;

  // named argument constructor
  factory BoundSubstrand(
      {int helix,
      bool forward,
      int start,
      int end,
      Iterable<int> deletions,
      Iterable<Insertion> insertions,
      String dna_sequence,
      String strand_id,
      bool is_first = false,
      bool is_last = false}) {
    if (deletions == null) {
      deletions = BuiltList<int>();
    }
    if (insertions == null) {
      insertions = BuiltList<Insertion>();
    }
    return BoundSubstrand.from((b) => b
      ..helix = helix
      ..forward = forward
      ..start = start
      ..end = end
      ..deletions.replace(deletions)
      ..insertions.replace(insertions)
      ..dna_sequence = dna_sequence
      ..strand_id = strand_id
      ..is_first = is_first
      ..is_last = is_last);
  }

//  static void _initializeBuilder(BoundSubstrandBuilder b) => b
//    ..deletions.replace([])
//    ..insertions.replace([])
//    ..is_first = false
//    ..is_last = false;

//  static void _finalizeBuilder(void Function(BoundSubstrandBuilder builder)) {
//  static void _finalizeBuilder(BoundSubstrandBuilder builder) {
////    BoundSubstrand bss = builder.build();
////    BoundSubstrand bss_interned = intern(bss);
//    BoundSubstrand bss_interned = build_interned(builder);
//    builder.replace(bss_interned);
//  }

  /******************************* end built_value boilerplate ************************************/

  int get helix;

  bool get forward;

  int get start;

  int get end;

  BuiltList<int> get deletions;

  BuiltList<Insertion> get insertions;

  bool get is_first;

  bool get is_last;

  // properties below here not stored in JSON, but computed from containing Strand
  @nullable
  String get dna_sequence;

  @nullable
  String get strand_id;

  @memoized
  BuiltMap<int, int> get insertion_offset_to_length =>
      BuiltMap<int, int>({for (var insertion in insertions) insertion.offset: insertion.length});

  @memoized
  DNAEnd get dnaend_start => DNAEnd(
      is_5p: forward,
      is_start: true,
      offset: start,
      substrand_is_first: is_first,
      substrand_is_last: is_last,
      substrand_id: id());

  @memoized
  DNAEnd get dnaend_end => DNAEnd(
      is_5p: !forward,
      is_start: false,
      offset: end,
      substrand_is_first: is_first,
      substrand_is_last: is_last,
      substrand_id: id());

  BoundSubstrand set_start(int start_new) => rebuild((ss) => ss..start = start_new);

  BoundSubstrand set_end(int end_new) => rebuild((ss) => ss..end = end_new);

  BoundSubstrand set_dna_sequence(String seq) => rebuild((ss) => ss..dna_sequence = seq);

  bool is_bound_substrand() => true;

  bool is_loopout() => false;

  DNAEnd get dnaend_5p => forward ? dnaend_start : dnaend_end;

  DNAEnd get dnaend_3p => forward ? dnaend_end : dnaend_start;

  String id() => 'substrand-H${helix}-${start}-${end}-${forward ? 'forward' : 'reverse'}';

  dynamic to_json_serializable({bool suppress_indent = false}) {
    var json_map = {
      constants.helix_idx_key: this.helix,
      constants.forward_key: this.forward,
      constants.start_key: this.start,
      constants.end_key: this.end,
    };
    if (this.deletions.isNotEmpty) {
      json_map[constants.deletions_key] = List<dynamic>.from(this.deletions);
    }
    if (this.insertions.isNotEmpty) {
      // need to use List.from because List.map returns Iterable, not List
      json_map[constants.insertions_key] = List<dynamic>.from(this
          .insertions
          .map((insertion) => insertion.to_json_serializable(suppress_indent: suppress_indent)));
    }

    return suppress_indent ? NoIndent(json_map) : json_map;
  }

  static BoundSubstrandBuilder from_json(Map<String, dynamic> json_map) {
    var name = 'Substrand';
    var forward = util.get_value(json_map, constants.forward_key, name);
    var helix = util.get_value(json_map, constants.helix_idx_key, name);
    var start = util.get_value(json_map, constants.start_key, name);
    var end = util.get_value(json_map, constants.end_key, name);
    var deletions = List<int>.from(util.get_value_with_default(json_map, constants.deletions_key, []));
    var insertions =
        parse_json_insertions(util.get_value_with_default(json_map, constants.insertions_key, []));

    return BoundSubstrandBuilder()
      ..forward = forward
      ..helix = helix
      ..start = start
      ..end = end
      ..deletions = ListBuilder<int>(deletions)
      ..insertions = ListBuilder<Insertion>(insertions);
  }

  static BuiltList<Insertion> parse_json_insertions(json_encoded_insertions) {
    // need to use List.from because List.map returns Iterable, not List
    return BuiltList<Insertion>(json_encoded_insertions.map((list) => Insertion(list[0], list[1])));
  }

  /// 5' end, INCLUSIVE
  int get offset_5p => this.forward ? this.start : this.end - 1;

  /// 3' end, INCLUSIVE
  int get offset_3p => this.forward ? this.end - 1 : this.start;

  int dna_length() => (this.end - this.start) - this.deletions.length + this.num_insertions();

  /// Number of bases in this [BoundSubstrand] between [left] and [right] offsets (INCLUSIVE).
  int dna_length_in(int left, int right) {
    if (!(left <= right + 1)) {
      throw ArgumentError('left = ${left} and right = ${right} but we should have left <= right + 1');
    }
    if (!(start <= left)) {
      throw ArgumentError('left = ${left} should be at least start = ${start}');
    }
    if (!(right < end)) {
      throw ArgumentError('right = ${right} should be at most end - 1 = ${end - 1}');
    }
    int num_deletions = deletions.where((d) => left <= d && d <= right).length;
    int num_insertions = insertions.where((i) => left <= i.offset && i.offset <= right).length;
    return (right - left + 1) - num_deletions + num_insertions;
  }

  int get visual_length => (this.end - this.start);

//  String toString() =>
//      'BoundSubstrand(helix=${this.helix}, forward=${this.forward}, start=${this.start}, end=${this.end})';

  /// Indicates if `offset` is the offset of a base on this substrand. (The end index should be false.)
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

  /// This is suitable for rendering along the helix lines.
  /// For deletions, spaces are added where a base would be.
  /// For insertions, all bases corresponding to the insertion
  /// (including the first one that would be represented even if there were no insertion)
  /// are replaced with a single space.
  String dna_sequence_deletions_insertions_to_spaces() {
    String seq = this.dna_sequence;
    List<int> codeunits = [];

    var deletions_set = this.deletions.toSet();
    var insertions_map = Map<int, int>.fromIterable(
      this.insertions,
      key: (insertion) => insertion.offset,
      value: (insertion) => insertion.length,
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

  /// Return DNA sequence of this Substrand in the interval of offsets given by
  ///  [`left`, `right`], INCLUSIVE.
  ///
  ///  WARNING: This is inclusive on both ends,
  ///  unlike other parts of this API where the right endpoint is exclusive.
  ///  This is to make the notion well-defined when one of the endpoints is on an offset with a
  ///  deletion or insertion.
  String dna_sequence_in(int offset_low, int offset_high) {
    if (dna_sequence == null) {
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
    if (offset_high < this.start) {
      return '';
    }

    bool five_p_on_left = this.forward;
    int str_idx_low = offset_to_substrand_dna_idx(offset_low, five_p_on_left);
    int str_idx_high = offset_to_substrand_dna_idx(offset_high, !five_p_on_left);
    if (!this.forward) {
      // these will be out of order if strand is reverse
      int swap = str_idx_low;
      str_idx_low = str_idx_high;
      str_idx_high = swap;
    }

    String subseq = dna_sequence.substring(str_idx_low, str_idx_high + 1);
    return subseq;
  }

  /// Net number of insertions from 5' end to offset_edge.
  /// Check is inclusive on the left and exclusive on the right (which is 5' depends on direction).
  int net_ins_del_length_increase_from_5p_to(int offset_edge, bool offset_closer_to_5p) {
    int length_increase = 0;
    for (int deletion in this.deletions) {
      if (this._between_5p_and_offset(deletion, offset_edge)) {
        length_increase -= 1;
      }
    }
    for (var insertion in this.insertions) {
      if (this._between_5p_and_offset(insertion.offset, offset_edge)) {
        length_increase += insertion.length;
      }
    }

    // special case for when offset_edge is an endpoint closer to the 3' end,
    // we add its extra insertions also in this case
    if (!offset_closer_to_5p) {
      var insertion_map = Map<int, int>.fromIterable(
        this.insertions,
        key: (insertion) => insertion.offset,
        value: (insertion) => insertion.length,
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

  int num_insertions() {
    return num_insertions_in_list(insertions);
  }

  static int num_insertions_in_list(Iterable<Insertion> insertions) {
    int num = 0;
    for (Insertion insertion in insertions) {
      num += insertion.length;
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
    for (var insertion in this.insertions) {
      if (offset == insertion.offset) {
        return true;
      }
    }
    return false;
  }

  /// Convert from offset on Substrand's Helix to string index on the parent Strand's DNA sequence.
  int offset_to_substrand_dna_idx(int offset, bool offset_closer_to_5p) {
    if (this.deletions.contains(offset)) {
      throw ArgumentError('offset {offset} illegally contains a deletion from {self.deletions}');
    }

    // length adjustment for insertions depends on whether this is a left or right offset
    int len_adjust = this.net_ins_del_length_increase_from_5p_to(offset, offset_closer_to_5p);

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
//    return ss_str_idx + get_seq_start_idx(substrand);
    return ss_str_idx;
  }
}
