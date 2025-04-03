import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:color/color.dart';
import 'package:tuple/tuple.dart';
import 'package:built_collection/built_collection.dart';

import 'select_mode.dart';
import 'selectable.dart';
import '../serializers.dart';
import 'strand_part.dart';
import 'dna_end.dart';
import '../json_serializable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'substrand.dart';
import 'unused_fields.dart';
import 'design.dart';
import 'helix.dart';
import 'address.dart';

part 'domain.g.dart';

abstract class Insertion
    with BuiltJsonSerializable
    implements Built<Insertion, InsertionBuilder>, JSONSerializable, StrandPart {
  int get offset;

  int get length;

  String get strand_id;

  dynamic toJson() => [offset, length];

  dynamic to_json_serializable({bool suppress_indent = false}) => toJson();

  Insertion fromJson(List list) => Insertion(list[0], list[1]);

  /************************ begin BuiltValue boilerplate ************************/
  factory Insertion(int offset, int count, [String strand_id = 'NONE YET']) => Insertion.from(
    (b) =>
        b
          ..offset = offset
          ..length = count
          ..strand_id = strand_id,
  );

  factory Insertion.from([void Function(InsertionBuilder) updates]) = _$Insertion;

  Insertion._();

  static Serializer<Insertion> get serializer => _$insertionSerializer;

  @memoized
  int get hashCode;
}

/// Represents a Substrand that is on a Helix. It may not be bound in the sense of having another
/// Domain that overlaps it, but it could potentially bind. By contrast a Loopout cannot be bound
/// to any other Substrand since there is no Helix with which it is associated.
abstract class Domain
    with SelectableMixin, BuiltJsonSerializable, UnusedFields
    implements Built<Domain, DomainBuilder>, Substrand {
  Domain._();

  static Serializer<Domain> get serializer => _$domainSerializer;

  factory Domain.from([void Function(DomainBuilder) updates]) = _$Domain;

  @memoized
  int get hashCode;

  /******************************* end built_value boilerplate ************************************/

  // named argument constructor
  factory Domain({
    required int helix,
    required bool forward,
    required int start,
    required int end,
    Iterable<int>? deletions = null,
    Iterable<Insertion>? insertions = null,
    String strand_id = 'NONE YET',
    String? dna_sequence = null,
    Color? color = null,
    bool is_scaffold = false,
    String? name = null,
    String? label = null,
    bool is_first = false,
    bool is_last = false,
  }) {
    if (deletions == null) {
      deletions = BuiltList<int>();
    }
    if (insertions == null) {
      insertions = BuiltList<Insertion>();
    }
    return Domain.from(
      (b) =>
          b
            ..helix = helix
            ..forward = forward
            ..start = start
            ..end = end
            ..deletions.replace(deletions!)
            ..insertions.replace(insertions!)
            ..name = name
            ..label = label
            ..dna_sequence = dna_sequence
            ..color = color
            ..strand_id = strand_id
            ..is_first = is_first
            ..is_last = is_last
            ..is_scaffold = is_scaffold
            ..unused_fields.replace({}),
    );
  }

  int get helix;

  bool get forward;

  int get start;

  int get end;

  BuiltList<int> get deletions;

  BuiltList<Insertion> get insertions;

  bool get is_first;

  bool get is_last;

  bool get is_scaffold;

  String? get name;

  String? get label;

  // properties below here not stored in JSON, but computed from containing Strand
  String? get dna_sequence;

  Color? get color;

  String get strand_id;

  @memoized
  String get id => 'substrand-H${helix}-${start}-${end}-${forward ? 'forward' : 'reverse'}';

  @memoized
  SelectModeChoice get select_mode => SelectModeChoice.domain;

  @memoized
  BuiltMap<int, int> get insertion_offset_to_length =>
      BuiltMap<int, int>({for (var insertion in insertions) insertion.offset: insertion.length});

  @memoized
  DNAEnd get dnaend_start => DNAEnd(
    is_5p: forward,
    is_start: true,
    forward: forward,
    offset: start,
    is_scaffold: is_scaffold,
    substrand_is_first: is_first,
    substrand_is_last: is_last,
    is_on_extension: false,
    substrand_id: id,
  );

  @memoized
  DNAEnd get dnaend_end => DNAEnd(
    is_5p: !forward,
    is_start: false,
    forward: forward,
    offset: end,
    is_scaffold: is_scaffold,
    substrand_is_first: is_first,
    substrand_is_last: is_last,
    is_on_extension: false,
    substrand_id: id,
  );

  @memoized
  BuiltList<SelectableDeletion> get selectable_deletions =>
      [
        for (int deletion in deletions)
          SelectableDeletion(offset: deletion, domain: this, is_scaffold: is_scaffold),
      ].build();

  @memoized
  BuiltList<SelectableInsertion> get selectable_insertions =>
      [
        for (var insertion in insertions)
          SelectableInsertion(insertion: insertion, domain: this, is_scaffold: is_scaffold),
      ].build();

  Domain set_start(int start_new) => rebuild((ss) => ss..start = start_new);

  Domain set_end(int end_new) => rebuild((ss) => ss..end = end_new);

  Domain set_dna_sequence(String? seq) => rebuild((ss) => ss..dna_sequence = seq);

  bool is_domain() => true;

  bool is_loopout() => false;

  bool is_extension() => false;

  DNAEnd get dnaend_5p => forward ? dnaend_start : dnaend_end;

  DNAEnd get dnaend_3p => forward ? dnaend_end : dnaend_start;

  @memoized
  Address get address_start => Address(helix_idx: helix, offset: start, forward: forward);

  // INCLUSIVE
  @memoized
  Address get address_end => Address(helix_idx: helix, offset: end - 1, forward: forward);

  @memoized
  Address get address_5p => forward ? address_start : address_end;

  @memoized
  Address get address_3p => forward ? address_end : address_start;

  @override
  String type_description() => "domain";

  dynamic to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {};
    if (name != null) {
      json_map[constants.name_key] = name;
    }
    json_map[constants.helix_idx_key] = helix;
    json_map[constants.forward_key] = forward;
    json_map[constants.start_key] = start;
    json_map[constants.end_key] = end;
    if (this.deletions.isNotEmpty) {
      json_map[constants.deletions_key] = List<dynamic>.from(this.deletions);
    }
    if (this.insertions.isNotEmpty) {
      // need to use List.from because List.map returns Iterable, not List
      json_map[constants.insertions_key] = List<dynamic>.from(
        this.insertions.map((insertion) => insertion.to_json_serializable(suppress_indent: suppress_indent)),
      );
    }
    if (this.color != null) {
      json_map[constants.color_key] = this.color!.toHexColor().toCssString();
    }
    if (this.label != null) {
      json_map[constants.label_key] = this.label;
    }

    json_map.addAll(unused_fields.toMap());

    return suppress_indent ? NoIndent(json_map) : json_map;
  }

  static DomainBuilder from_json(Map<String, dynamic> json_map) {
    var class_name = 'Domain';
    var forward = util.mandatory_field(
      json_map,
      constants.forward_key,
      class_name,
      legacy_keys: constants.legacy_forward_keys,
    );
    var helix = util.mandatory_field(json_map, constants.helix_idx_key, class_name);
    var start = util.mandatory_field(json_map, constants.start_key, class_name);
    var end = util.mandatory_field(json_map, constants.end_key, class_name);
    var deletions = List<int>.from(util.optional_field(json_map, constants.deletions_key, []));
    var insertions = parse_json_insertions(util.optional_field(json_map, constants.insertions_key, []));

    Color? color =
        json_map.containsKey(constants.color_key)
            ? util.parse_json_color(json_map[constants.color_key]!)
            : null;

    String? name = util.optional_field_with_null_default(json_map, constants.name_key);
    String? label = util.optional_field_with_null_default(json_map, constants.label_key);

    var unused_fields = util.unused_fields_map(json_map, constants.domain_keys);

    deletions = util.remove_duplicates(deletions);
    insertions = util.remove_duplicates(insertions);
    for (int i = 0; i < insertions.length; i++) {
      for (int j = i + 1; j < insertions.length; j++) {
        var ins1 = insertions[i];
        var ins2 = insertions[j];
        if (ins1.offset == ins2.offset) {
          assert(ins1.length != ins2.length);
          throw IllegalDesignError(
            'two insertions on a domain have the same offset but different lengths:'
            '\n${ins1}'
            '\n${ins2}'
            '\n${pre_domain_description(helix, forward, start, end)}',
          );
        }
      }
    }

    for (int deletion in deletions) {
      if (deletion < start) {
        throw IllegalDesignError(
          'deletion ${deletion} cannot be less than offset ${start}.\n'
          '\n${pre_domain_description(helix, forward, start, end)}',
        );
      }
      if (deletion >= end) {
        throw IllegalDesignError(
          'deletion ${deletion} cannot be greater than or equal to offset ${end}.\n'
          '\n${pre_domain_description(helix, forward, start, end)}',
        );
      }
    }

    for (Insertion insertion in insertions) {
      if (insertion.offset < start) {
        throw IllegalDesignError(
          'insertion offset ${insertion.offset} '
          'cannot be less than start offset ${start}.\n'
          '\n${pre_domain_description(helix, forward, start, end)}',
        );
      }
      if (insertion.offset >= end) {
        throw IllegalDesignError(
          'insertion offset ${insertion.offset} '
          'cannot be greater than or equal to end offset ${end}.\n'
          '\n${pre_domain_description(helix, forward, start, end)}',
        );
      }
      if (insertion.length <= 0) {
        throw IllegalDesignError(
          'insertion length ${insertion.length} '
          'cannot be less than or equal to 0.\n'
          '\n${pre_domain_description(helix, forward, start, end)}',
        );
      }
    }

    return DomainBuilder()
      ..forward = forward
      ..helix = helix
      ..start = start
      ..end = end
      ..deletions.replace(deletions)
      ..insertions.replace(insertions)
      ..color = color
      ..name = name
      ..label = label
      ..strand_id = 'NONE YET'
      ..unused_fields = unused_fields;
  }

  static String pre_domain_description(int helix, bool forward, int start, int end) =>
      'This occurred on a ${forward ? "forward" : "reverse"} Domain with'
      '\n  helix = ${helix}'
      '\n  start = ${start}'
      '\n  end   = ${end}.';

  static List<Insertion> parse_json_insertions(json_encoded_insertions) {
    // need to use List.from because List.map returns Iterable, not List
    return List<Insertion>.from(json_encoded_insertions.map((list) => Insertion(list[0], list[1])));
  }

  /// 5' end, INCLUSIVE
  @memoized
  int get offset_5p => this.forward ? this.start : this.end - 1;

  /// 3' end, INCLUSIVE
  @memoized
  int get offset_3p => this.forward ? this.end - 1 : this.start;

  int dna_length() => (this.end - this.start) - this.deletions.length + this.num_insertions;

  /// Number of bases in this [Domain] between [left] and [right] offsets (INCLUSIVE).
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

    var list_of_insertions = insertions.where((i) => left <= i.offset && i.offset <= right);
    int num_insertions = num_insertions_in_list(list_of_insertions);
    return (right - left + 1) - num_deletions + num_insertions;
  }

  int get visual_length => (this.end - this.start);

  //  String toString() =>
  //      'Domain(helix=${this.helix}, forward=${this.forward}, start=${this.start}, end=${this.end})';

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
  @memoized
  List<int> get offsets_in_5p_3p_order {
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
  String dna_sequence_deletions_insertions_to_spaces({bool reverse = false}) {
    String seq = this.dna_sequence!;
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
        int insertion_length = insertions_map[offset]!;
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

    var seq_modified = String.fromCharCodes(reverse ? codeunits.reversed : codeunits);
    return seq_modified;
  }

  /// Return DNA sequence of this Substrand in the interval of offsets given by
  ///  [`left`, `right`], INCLUSIVE.
  ///
  ///  WARNING: This is inclusive on both ends,
  ///  unlike other parts of this API where the right endpoint is exclusive.
  ///  This is to make the notion well-defined when one of the endpoints is on an offset with a
  ///  deletion or insertion.
  String? dna_sequence_in(int offset_low, int offset_high, {bool reverse = false}) {
    if (this.dna_sequence == null) {
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

    int str_idx_low = substrand_offset_to_substrand_dna_idx(offset_low, this.forward);
    int str_idx_high = substrand_offset_to_substrand_dna_idx(offset_high, !this.forward);
    if (!this.forward) {
      // these will be out of order if substrand is reverse
      int swap = str_idx_low;
      str_idx_low = str_idx_high;
      str_idx_high = swap;
    }

    String subseq = this.dna_sequence!.substring(str_idx_low, str_idx_high + 1);
    if (reverse) {
      subseq = subseq.split('').reversed.join();
    }
    return subseq;
  }

  /// Net number of insertions from 5' end to offset_edge.
  /// Check is inclusive on the left and exclusive on the right (which is 5' depends on direction).
  int net_ins_del_length_increase_from_5p_to(int offset_edge, bool forward) {
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
    if (!forward) {
      var insertion_map = Map<int, int>.fromIterable(
        this.insertions,
        key: (insertion) => insertion.offset,
        value: (insertion) => insertion.length,
      );
      if (insertion_map.containsKey(offset_edge)) {
        int insertion_length = insertion_map[offset_edge]!;
        length_increase += insertion_length;
      }
    }

    return length_increase;
  }

  bool _between_5p_and_offset(int offset_to_test, int offset_edge) {
    return (this.forward && this.start <= offset_to_test && offset_to_test < offset_edge) ||
        (!this.forward && offset_edge < offset_to_test && offset_to_test < this.end);
  }

  @memoized
  int get num_insertions => num_insertions_in_list(insertions);

  static int num_insertions_in_list(Iterable<Insertion> insertions) {
    int num = 0;
    for (Insertion insertion in insertions) {
      num += insertion.length;
    }
    return num;
  }

  bool overlaps(Domain other) {
    return (this.helix == other.helix &&
        this.forward == (!other.forward) &&
        this.compute_overlap(other) != null);
  }

  Tuple2<int, int>? compute_overlap(Domain other) {
    int overlap_start = max(this.start, other.start);
    int overlap_end = min(this.end, other.end);
    if (overlap_start >= overlap_end) {
      // overlap is empty
      return null;
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

  /// Convert from offset on [Domain]'s [Helix] to string index on this
  /// [Domain]'s substring of the parent [Strand]'s DNA sequence.
  int substrand_offset_to_substrand_dna_idx(int offset, bool forward) {
    if (this.deletions.contains(offset)) {
      throw ArgumentError('offset ${offset} illegally contains a deletion from ${this.deletions}');
    }

    // length adjustment for insertions depends on whether this is a left or right offset
    int len_adjust = this.net_ins_del_length_increase_from_5p_to(offset, forward);

    // get string index assuming this Substrand is first on Strand
    int ss_str_idx;
    if (this.forward) {
      //account for insertions and deletions
      offset += len_adjust;
      ss_str_idx = offset - this.start;
    } else {
      // account for insertions and deletions
      offset -= len_adjust;
      ss_str_idx = this.end - 1 - offset;
    }

    return ss_str_idx;
  }

  /// Convert from string index on this [Domain]'s substring of the parent [Strand]'s DNA sequence
  /// to offset on [Domain]'s [Helix].
  int substrand_dna_idx_to_substrand_offset(int ss_str_idx, bool forward) {
    int offset = this.offset_5p;
    int dna_idx_cur = 0;
    while (dna_idx_cur < ss_str_idx) {
      if (!this.deletions.contains(offset)) {
        dna_idx_cur++;
      }
      if (this.insertion_offset_to_length.containsKey(offset)) {
        int insertion_length = this.insertion_offset_to_length[offset]!;
        dna_idx_cur += insertion_length;
      }
      offset += this.forward ? 1 : -1;
    }
    return offset;
  }
}
