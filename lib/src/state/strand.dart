import 'package:built_value/serializer.dart';
import 'package:color/color.dart';
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/serializers.dart';

import 'idt_fields.dart';
import 'select_mode.dart';
import 'selectable.dart';
import 'crossover.dart';
import '../json_serializable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'dna_design.dart';
import 'bound_substrand.dart';
import 'loopout.dart';
import 'substrand.dart';

part 'strand.g.dart';

abstract class Strand with Selectable implements Built<Strand, StrandBuilder>, JSONSerializable {
  Strand._();

  factory Strand([void Function(StrandBuilder) updates]) = _$Strand;

  static Serializer<Strand> get serializer => _$strandSerializer;

  /************************ end BuiltValue boilerplate ************************/

  static Color DEFAULT_STRAND_COLOR = RgbColor.name('black');

  Color get color;

  @nullable
  String get dna_sequence;

  BuiltList<Substrand> get substrands;

  @nullable
  IDTFields get idt;

  @nullable
  bool get is_scaffold;

  @memoized
  BuiltSet<Crossover> get crossovers {
    Set<Crossover> ret = {};
    for (int i = 0; i < substrands.length - 1; i++) {
      if (substrands[i] is BoundSubstrand && substrands[i + 1] is BoundSubstrand) {
        BoundSubstrand prev_ss = substrands[i] as BoundSubstrand;
        BoundSubstrand next_ss = substrands[i + 1] as BoundSubstrand;
        ret.add(Crossover(prev_ss, next_ss));
      }
    }

    return BuiltSet<Crossover>(ret);
  }

  SelectModeChoice select_mode() => SelectModeChoice.strand;

  String id() {
    var first_ss = this.first_bound_substrand();
    return 'strand-H${first_ss.helix}-${first_ss.offset_5p}-${first_ss.forward ? 'forward' : 'reverse'}';
  }

  String toString() {
    var first_ss = this.first_bound_substrand();
    return 'Strand(helix=${first_ss.helix}, start=${first_ss.offset_5p}, ${first_ss.forward ? 'forward' : 'reverse'})';
  }

  List<BoundSubstrand> bound_substrands() =>
      [for (var ss in this.substrands) if (ss.is_bound_substrand()) ss as BoundSubstrand];

  List<Loopout> loopouts() => [for (var ss in this.substrands) if (ss.is_loopout()) ss];

  int dna_length() {
    int num = 0;
    for (var substrand in substrands) {
      num += substrand.dna_length();
    }
    return num;
  }

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    var json_map = Map<String, dynamic>();

    if (this.color != null) {
      var color_rgb = color.toRgbColor();
      String color_json = color_rgb.toCssString();
      json_map[constants.color_key] = color_json;
    }

    if (this.dna_sequence != null) {
      json_map[constants.dna_sequence_key] = this.dna_sequence;
    }

    if (this.idt != null) {
      var idt_json = this.idt.to_json_serializable(suppress_indent: suppress_indent);
      json_map[constants.idt_key] = suppress_indent ? NoIndent(idt_json) : idt_json;
    }

    if (this.is_scaffold != null) {
      json_map[constants.is_scaffold_key] = this.is_scaffold;
    }

    json_map[constants.substrands_key] = [
      for (var ss in this.substrands) ss.to_json_serializable(suppress_indent: suppress_indent)
    ];

    return json_map;
  }

  set_dna_sequence(String dna_sequence_new) {
    int start_idx_ss = 0;
    List<Substrand> substrands_new = [];
    for (var ss in substrands) {
      int end_idx_ss = start_idx_ss + ss.dna_length();
      String dna_subseq = dna_sequence_new.substring(start_idx_ss, end_idx_ss);
      Substrand ss_new = ss.set_dna_sequence(dna_subseq);
      substrands_new.add(ss_new);
      start_idx_ss = end_idx_ss;
    }

    int seq_len = dna_sequence_new.length;
    int dna_len_strand = this.dna_length();
    if (seq_len != dna_len_strand) {
      throw StrandError(this, 'Strand length $dna_len_strand does not match DNA sequence length $seq_len');
    }

    return rebuild((strand) => strand
      ..substrands = ListBuilder<Substrand>(substrands_new)
      ..dna_sequence = dna_sequence_new);
  }

  static Strand from_json(Map<String, dynamic> json_map) {
    var substrand_jsons = util.get_value(json_map, constants.substrands_key, 'Strand');

    // need to parse all BoundSubstrands before Loopouts,
    // because prev and next BoundSubstrands need to be referenced by Loopouts
    // Also, no DNA sequence parsing yet because we want all the lengths of Substrands calculated before assigning.
    Map<int, BoundSubstrand> bound_substrands = {};
    int start_idx_ss = 0;
    for (int i = 0; i < substrand_jsons.length; i++) {
      var substrand_json = substrand_jsons[i];

      int end_idx_ss;
      if (!substrand_json.containsKey(constants.loopout_key)) {
        BoundSubstrandBuilder ssb = BoundSubstrand.from_json(substrand_json);
        ssb.is_first = (i == 0);
        ssb.is_last = (i == substrand_jsons.length - 1);
        int num_insertions = BoundSubstrand.num_insertions_in_list(ssb.insertions.build());
        int dna_length = ssb.end - ssb.start + num_insertions - ssb.deletions.length;
        end_idx_ss = start_idx_ss + dna_length;
        bound_substrands[i] = ssb.build();
      } else {
        int loopout_length = substrand_json[constants.loopout_key];
        end_idx_ss = start_idx_ss + loopout_length;
      }
      start_idx_ss = end_idx_ss;
    }

    // parse Loopouts now that we have all the BoundSubstrands
    Map<int, Loopout> loopouts = {};
    for (int i = 0; i < substrand_jsons.length; i++) {
      var substrand_json = substrand_jsons[i];
      if (substrand_json.containsKey(constants.loopout_key)) {
        LoopoutBuilder lb = Loopout.from_json(substrand_json);
        lb.prev_substrand = bound_substrands[i - 1].toBuilder();
        lb.next_substrand = bound_substrands[i + 1].toBuilder();
        loopouts[i] = lb.build();
      }
    }

    var substrands = [];
    for (int i = 0; i < substrand_jsons.length; i++) {
      if (bound_substrands.containsKey(i)) {
        substrands.add(bound_substrands[i]);
      } else if (loopouts.containsKey(i)) {
        substrands.add(loopouts[i]);
      } else {
        throw AssertionError('one of bound_substrands or loopouts must contain index i=${i}');
      }
    }

    // Now that all Substrand dna_lengths are known, we can assign DNA sequences to them
    //XXX: important to do this check after setting substrands so dna_length() is well-defined
    var dna_sequence =
        json_map.containsKey(constants.dna_sequence_key) ? json_map[constants.dna_sequence_key] : null;

    var color = json_map.containsKey(constants.color_key)
        ? parse_json_color(json_map[constants.color_key])
        : DEFAULT_STRAND_COLOR;

    bool is_scaffold = null;
    if (json_map.containsKey(constants.is_scaffold_key)) {
      is_scaffold = json_map[constants.is_scaffold_key];
    }

    Strand strand = Strand((s) => s
      ..substrands = ListBuilder<Substrand>(substrands)
      ..is_scaffold = is_scaffold
      ..color = color
      ..idt = null);

    if (json_map.containsKey(constants.idt_key)) {
      try {
        var idt = IDTFields.from_json(json_map[constants.idt_key]);
        strand = strand.rebuild((s) => s..idt.replace(idt));
      } catch (err) {
        throw StrandError(strand, err.toString());
      }
    }

    if (strand.substrands.first is Loopout) {
      throw StrandError(strand, 'Loopout at beginning of strand not supported');
    }

    if (strand.substrands.last is Loopout) {
      throw StrandError(strand, 'Loopout at end of strand not supported');
    }

    if (dna_sequence != null) {
      strand = strand.set_dna_sequence(dna_sequence);
    }

    return strand;
  }

  BoundSubstrand first_bound_substrand({int starting_at = 0}) {
    for (int i = starting_at; i < this.substrands.length; i++) {
      if (this.substrands[i] is BoundSubstrand) {
        return this.substrands[i] as BoundSubstrand;
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

  /// Starting DNA subsequence index for first base of this Substrand on its
  /// parent Strand DNA sequence.
  int get_seq_start_idx(Substrand substrand) {
    // index of self in parent strand's list of substrands
    var self_substrand_idx = substrands.indexOf(substrand);
    // index of self's position within the DNA sequence of parent strand
    int self_seq_idx_start = 0;
    for (var prev_substrand in substrands.getRange(0, self_substrand_idx)) {
      self_seq_idx_start += prev_substrand.dna_length();
    }
    return self_seq_idx_start;
  }

  String dna_sequence_in(Substrand substrand) {
    if (this.dna_sequence == null) {
      return null;
    } else {
      int start_idx = get_seq_start_idx(substrand);
      return dna_sequence.substring(start_idx, start_idx + substrand.dna_length());
    }
  }
}
