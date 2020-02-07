import 'package:built_value/serializer.dart';
import 'package:color/color.dart';
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:tuple/tuple.dart';

import 'dna_end.dart';
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

  //FIXME: this is not pure since it consults util.color_cycler
  factory Strand(Iterable<Substrand> substrands,
      {Color color = null, String dna_sequence = null, IDTFields idt = null, bool is_scaffold = false}) {
    if (color == null) {
      color = is_scaffold ? util.scaffold_color : util.color_cycler.next();
    }

    var strand = Strand.from((b) => b
      ..color = color
      ..substrands.replace(substrands)
      ..dna_sequence = dna_sequence
      ..idt = idt?.toBuilder()
      ..is_scaffold = is_scaffold);

    strand = strand.initialize();
    return strand;
  }

  factory Strand.from([void Function(StrandBuilder) updates]) = _$Strand;

  static Serializer<Strand> get serializer => _$strandSerializer;

  /************************ end BuiltValue boilerplate ************************/

  //FIXME: remove prev_ and next_ from Loopout so they don't need to be recalculated

  static void _finalizeBuilder(StrandBuilder builder) {
    BoundSubstrand first_ss = builder.substrands.first;
    String id = id_from_data(first_ss.helix, first_ss.offset_5p, first_ss.forward);
    // ensure Loopouts have appropriate prev and next indices for adjacent BoundSubstrands
    // (not necessary for Crossovers since they are lazily evaluated,
    // but Loopout objects are created prior to creating the Strand)
    for (int i = 0; i < builder.substrands.length; i++) {
      var substrand = builder.substrands[i];
      if (substrand is Loopout) {
        if (substrand.prev_substrand_idx != i - 1 || substrand.next_substrand_idx != i + 1) {
          var loopout = substrand.rebuild((b) => b
            ..prev_substrand_idx = i - 1
            ..next_substrand_idx = i + 1);
          builder.substrands[i] = loopout;
        }
      }
      // set strand_id on all substrands
      if (substrand is BoundSubstrand) {
        builder.substrands[i] = substrand.rebuild((b) => b..strand_id = id);
      } else if (substrand is Loopout) {
        builder.substrands[i] = substrand.rebuild((b) => b..strand_id = id);
      }
    }
  }

  /// Sets up data such as DNA sequence and part strand_id's
  /// FIXME: remove duplicated code between initialize() and _finalizeBuilder
  Strand initialize() {
    Strand strand = this;

    if (dna_sequence != null) {
      strand = strand.set_dna_sequence(dna_sequence);
    }

    String id = strand.id();
    int idx = 0;
    bool updated = false;
    var substrands_new = strand.substrands.toBuilder();
    for (var ss in strand.substrands) {
      if (ss is Loopout) {
        var loopout = ss.rebuild((l) => l
          ..strand_id = id
          ..prev_substrand_idx = idx - 1
          ..next_substrand_idx = idx + 1);
        substrands_new[idx] = loopout;
        updated = true;
      } else if (ss is BoundSubstrand) {
        var bound_ss = ss.rebuild((l) => l..strand_id = id);
        substrands_new[idx] = bound_ss;
        updated = true;
      }
      idx++;
    }
    if (updated) {
      strand = strand.rebuild((s) => s..substrands = substrands_new);
    }

    return strand;
  }

  BuiltList<Substrand> get substrands;

  @nullable
  String get dna_sequence;

  @nullable
  IDTFields get idt;

  bool get is_scaffold;

  // Since color assignment is somewhat nondeterministic, we don't want to use it to detect equality.
  // XXX: if we let the user specify a new Strand color in scadnano, the view will have to be explicitly
  // updated somehow.
//  @BuiltValueField(compare: false)
  Color get color;

  static Color DEFAULT_STRAND_COLOR = RgbColor.name('black');

  @memoized
  BuiltMap<int, BuiltList<BoundSubstrand>> get substrands_on_helix {
    var substrands_map = Map<int, List<BoundSubstrand>>();
    for (var substrand in bound_substrands()) {
      if (substrands_map.containsKey(substrand.helix)) {
        substrands_map[substrand.helix].add(substrand);
      } else {
        substrands_map[substrand.helix] = [substrand];
      }
    }
    var substrands_partially_built_map = Map<int, BuiltList<BoundSubstrand>>();
    for (var helix in substrands_map.keys) {
      substrands_partially_built_map[helix] = substrands_map[helix].build();
    }
    return substrands_partially_built_map.build();
  }

  @memoized
  BuiltList<Crossover> get crossovers {
    Set<Crossover> ret = {};
    for (int i = 0; i < substrands.length - 1; i++) {
      if (substrands[i] is BoundSubstrand && substrands[i + 1] is BoundSubstrand) {
        ret.add(Crossover(i, i + 1, id()));
      }
    }

    return BuiltList<Crossover>(ret);
  }

  SelectModeChoice select_mode() => SelectModeChoice.strand;

  String id() {
    var first_ss = this.first_bound_substrand();
    return id_from_data(first_ss.helix, first_ss.offset_5p, first_ss.forward);
  }

  static String id_from_data(int helix, int offset, bool forward) =>
      'strand-H${helix}-${offset}-${forward ? 'forward' : 'reverse'}';

  String toString() {
    var first_ss = this.first_bound_substrand();
    return 'Strand(helix=${first_ss.helix}, start=${first_ss.offset_5p}, ${first_ss.forward ? 'forward' : 'reverse'})';
  }

  List<BoundSubstrand> bound_substrands() =>
      [for (var ss in this.substrands) if (ss.is_bound_substrand()) ss as BoundSubstrand];

  List<Loopout> loopouts() => [for (var ss in this.substrands) if (ss.is_loopout()) ss];

  List<DNAEnd> ends_5p_not_first() => [for (var ss in bound_substrands().sublist(1)) ss.dnaend_5p];

  List<DNAEnd> ends_3p_not_last() =>
      [for (var ss in bound_substrands().sublist(0, bound_substrands().length - 1)) ss.dnaend_3p];

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
      json_map[constants.color_key] = color.toHexColor().toCssString();
    }

    if (this.dna_sequence != null) {
      json_map[constants.dna_sequence_key] = this.dna_sequence;
    }

    if (this.idt != null) {
      var idt_json = this.idt.to_json_serializable(suppress_indent: suppress_indent);
      json_map[constants.idt_key] = suppress_indent ? NoIndent(idt_json) : idt_json;
    }

    if (this.is_scaffold) {
      json_map[constants.is_scaffold_key] = this.is_scaffold;
    }

    json_map[constants.substrands_key] = [
      for (var ss in this.substrands) ss.to_json_serializable(suppress_indent: suppress_indent)
    ];

    return json_map;
  }

  Strand remove_dna_sequence() {
    int start_idx_ss = 0;
    List<Substrand> substrands_new = [];
    // assign DNA substrings to substrands
    for (var ss in substrands) {
      int end_idx_ss = start_idx_ss + ss.dna_length();
      Substrand ss_new = ss.set_dna_sequence(null);
      substrands_new.add(ss_new);
      start_idx_ss = end_idx_ss;
    }

    return rebuild((strand) => strand
      ..substrands.replace(substrands_new)
      ..dna_sequence = null);
  }

  /// Sets DNA sequence of strand (but does not assign complement to any Strands bound to it).
  Strand set_dna_sequence(String dna_sequence_new) {
    // truncate dna_sequence_new if too long; pad with ?'s if to short
    int seq_len = dna_sequence_new.length;
    int dna_len_strand = this.dna_length();
    if (seq_len > dna_len_strand) {
      dna_sequence_new = dna_sequence_new.substring(0, dna_len_strand);
    } else if (seq_len < dna_len_strand) {
      dna_sequence_new = dna_sequence_new + (constants.DNA_BASE_WILDCARD * (dna_len_strand - seq_len));
    }

    int start_idx_ss = 0;
    List<Substrand> substrands_new = [];
    // assign DNA substrings to substrands
    for (var ss in substrands) {
      int end_idx_ss = start_idx_ss + ss.dna_length();
      String dna_subseq = dna_sequence_new.substring(start_idx_ss, end_idx_ss);
      Substrand ss_new = ss.set_dna_sequence(dna_subseq);
      substrands_new.add(ss_new);
      start_idx_ss = end_idx_ss;
    }

    return rebuild((strand) => strand
      ..substrands.replace(substrands_new)
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
        lb.prev_substrand_idx = i - 1;
        lb.next_substrand_idx = i + 1;
        loopouts[i] = lb.build();
      }
    }

    List<Substrand> substrands = [];
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

    bool is_scaffold = false;
    if (json_map.containsKey(constants.is_scaffold_key)) {
      is_scaffold = json_map[constants.is_scaffold_key];
    }

    Strand strand = Strand(substrands, color: color, is_scaffold: is_scaffold, dna_sequence: dna_sequence);

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

//    strand = strand.initialize();

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

  /// Indicates whether `self` overlaps `other_strand`, meaning that the set of offsets occupied
  /// by `self` has nonempty intersection with those occupied by `other_strand`.
  bool overlaps(Strand other) {
    for (var substrand_self in bound_substrands()) {
      for (var substrand_other in other.bound_substrands()) {
        if (substrand_self.overlaps(substrand_other)) {
          return true;
        }
      }
    }
    return false;
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
      int ss_dna_length = substrand.dna_length();
      int end_idx = start_idx + ss_dna_length;
      return dna_sequence.substring(start_idx, end_idx);
    }
  }

  DNAEnd get dnaend_3p => last_bound_substrand().dnaend_3p;

  DNAEnd get dnaend_5p => first_bound_substrand().dnaend_5p;

  /// If this and other are ligatable (they have a pair of 5'/3' ends adjacent and aren't the same strand)
  /// return the two [DNAEnd]s that can be ligated, in other (this.end, other.end).
  Tuple2<DNAEnd, DNAEnd> ligatable_ends_with(Strand other) {
    if (this == other) {
      return null;
    } else if (_ligatable_3p_to_5p_of(other)) {
      return Tuple2<DNAEnd, DNAEnd>(dnaend_3p, other.dnaend_5p);
    } else if (_ligatable_5p_to_3p_of(other)) {
      return Tuple2<DNAEnd, DNAEnd>(dnaend_5p, other.dnaend_3p);
    } else {
      return null;
    }
  }

  bool _ligatable_3p_to_5p_of(Strand other) {
    BoundSubstrand last_ss_this = last_bound_substrand();
    BoundSubstrand first_ss_other = other.first_bound_substrand();

    return last_ss_this.forward == first_ss_other.forward &&
        last_ss_this.helix == first_ss_other.helix &&
        dnaend_3p.offset == other.dnaend_5p.offset;
  }

  bool _ligatable_5p_to_3p_of(Strand other) {
    BoundSubstrand first_ss_this = first_bound_substrand();
    BoundSubstrand last_ss_other = other.last_bound_substrand();

    return first_ss_this.forward == last_ss_other.forward &&
        first_ss_this.helix == last_ss_other.helix &&
        dnaend_5p.offset == other.dnaend_3p.offset;
  }

  /// Name to use when exporting this Strand.
  String export_name() {
    BoundSubstrand first_ss = first_bound_substrand();
    BoundSubstrand last_ss = last_bound_substrand();
    String id = '${first_ss.helix}[${first_ss.offset_5p}]${last_ss.helix}[${last_ss.offset_3p}]';
    return is_scaffold ? 'SCAF$id}' : 'ST$id';
  }
}

Color parse_json_color(Object json_obj) {
  if (json_obj is Map) {
    int r = json_obj['r'];
    int g = json_obj['g'];
    int b = json_obj['b'];
    return RgbColor(r, g, b);
  } else if (json_obj is String) {
    return HexColor(json_obj);
  } else {
    throw ArgumentError('JSON object representing color must be a Map or String, but instead it is a '
        '${json_obj.runtimeType}:\n${json_obj}');
  }
}
