import 'package:built_value/serializer.dart';
import 'package:color/color.dart';
import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:react/react.dart';
import 'package:tuple/tuple.dart';

import 'address.dart';
import 'helix.dart';
import 'linker.dart';
import 'modification.dart';
import '../serializers.dart';
import 'dna_end.dart';
import 'idt_fields.dart';
import 'select_mode.dart';
import 'selectable.dart';
import 'crossover.dart';
import '../json_serializable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'design.dart';
import 'domain.dart';
import 'loopout.dart';
import 'extension.dart';
import 'substrand.dart';
import 'unused_fields.dart';

part 'strand.g.dart';

abstract class Strand
    with SelectableMixin, BuiltJsonSerializable, UnusedFields, JSONSerializable
    implements Built<Strand, StrandBuilder> {
  Strand._();

  factory Strand.from([void Function(StrandBuilder) updates]) = _$Strand;

  static Serializer<Strand> get serializer => _$strandSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  //FIXME: this is not pure since it consults util.color_cycler
  factory Strand(
    Iterable<Substrand> substrands, {
    Color color = null,
    bool circular = false,
    String dna_sequence = null,
    IDTFields idt = null,
    bool is_scaffold = false,
    Modification5Prime modification_5p = null,
    Modification3Prime modification_3p = null,
    Map<int, ModificationInternal> modifications_int = const {},
    String name = null,
    Object label = null,
  }) {
    if (color == null) {
      color = is_scaffold ? util.scaffold_color : util.color_cycler.next();
    }

    var strand = Strand.from((b) => b
      ..color = color
      ..circular = circular
      ..substrands.replace(substrands)
      ..idt = idt?.toBuilder()
      ..modification_5p = modification_5p?.toBuilder()
      ..modification_3p = modification_3p?.toBuilder()
      ..modifications_int.replace(modifications_int)
      ..is_scaffold = is_scaffold
      ..name = name
      ..label = label
      ..unused_fields = MapBuilder<String, Object>({}));

    if (dna_sequence != null) {
      strand = strand.set_dna_sequence(dna_sequence);
    }

    strand = strand.initialize();
    return strand;
  }

  //FIXME: remove prev_ and next_ from Loopout so they don't need to be recalculated

  static void _finalizeBuilder(StrandBuilder builder) {
    Substrand first_ss = builder.substrands.first;
    Domain first_dom;
    if (first_ss is Domain) {
      first_dom = first_ss;
    } else {
      assert(first_ss is Extension);
      assert(builder.substrands.length > 1);
      first_dom = builder.substrands[1];
    }
    String id = id_from_data(first_dom.helix, first_dom.offset_5p, first_dom.forward);
    // ensure Loopouts have appropriate prev and next indices for adjacent Domains
    // (not necessary for Crossovers since they are lazily evaluated,
    // but Loopout objects are created prior to creating the Strand)
    for (int i = 0; i < builder.substrands.length; i++) {
      var substrand = builder.substrands[i];
      if (substrand is Loopout) {
        if (substrand.prev_domain_idx != i - 1 || substrand.next_domain_idx != i + 1) {
          var loopout = substrand.rebuild((b) => b..prev_domain_idx = i - 1);
          builder.substrands[i] = loopout;
        }
      }
      // set strand_id on all substrands
      if (substrand is Domain) {
        builder.substrands[i] = substrand.rebuild((b) => b..strand_id = id);
      } else if (substrand is Loopout) {
        builder.substrands[i] = substrand.rebuild((b) => b..strand_id = id);
      } else if (substrand is Extension) {
        builder.substrands[i] = substrand.rebuild((b) => b..strand_id = id);
      } else {
        throw AssertionError('substrand ${i} should be Domain, Loopout, or Extension, but is ${substrand}');
      }
    }
  }

  Strand initialize() {
    Strand strand = this;

    strand = _rebuild_substrands_with_new_fields_based_on_strand(strand);
    strand = _rebuild_substrands_with_new_dna_sequences_based_on_strand(strand);


    _ensure_loopouts_legal();
    _ensure_extensions_legal();

    return strand;
  }

  /// Sets up data such as DNA sequence and part strand_id's
  /// FIXME: remove duplicated code between initialize() and _finalizeBuilder
  Strand _rebuild_substrands_with_new_fields_based_on_strand(Strand strand) {
    int idx = 0;
    var substrands_new = strand.substrands.toBuilder();
    bool is_5p = true;
    for (var ss in strand.substrands) {
      var new_ss;
      if (ss is Loopout) {
        new_ss = _rebuild_loopout_with_new_fields_based_on_strand(ss, idx, strand);
      } else if (ss is Domain) {
        new_ss = _rebuild_domain_with_new_fields_based_on_strand(ss, idx, strand);
      } else if (ss is Extension) {
        new_ss = _rebuild_extension_with_new_fields_based_on_strand(ss, is_5p, strand);
      }
      assert(new_ss != null);
      substrands_new[idx] = new_ss;
      idx++;
      is_5p = false;
    }
    return strand.rebuild((s) => s..substrands = substrands_new);
  }

  _rebuild_domain_with_new_fields_based_on_strand(Domain domain, int idx, Strand strand) {
    bool is_first = idx == 0;
    bool is_last = idx == strand.substrands.length - 1;
    return domain.rebuild((b) => b
      ..strand_id = strand.id
      ..is_first = is_first
      ..is_last = is_last
      ..is_scaffold = is_scaffold);
  }

  _rebuild_loopout_with_new_fields_based_on_strand(Loopout loopout, int idx, Strand strand) {
    return loopout.rebuild((b) => b
      ..is_scaffold = is_scaffold
      ..strand_id = strand.id
      ..prev_domain_idx = idx - 1);
  }

  _rebuild_extension_with_new_fields_based_on_strand(Extension ext, bool is_5p, Strand strand) {
    Domain adjacent_domain = ext.is_5p? strand.first_domain: strand.last_domain;
    return ext.rebuild((b) => b
      ..is_scaffold = is_scaffold
      ..strand_id = strand.id
      ..adjacent_domain.replace(adjacent_domain)
      ..is_5p = is_5p);
  }

  Strand _rebuild_substrands_with_new_dna_sequences_based_on_strand(Strand strand) {
    bool strand_has_sequence = _at_least_one_substrand_has_dna_sequence(strand);
    if (!strand_has_sequence) {
      return strand;
    }
    List<Substrand> new_substrands = [];
    for (var substrand in strand.substrands) {
      new_substrands.add(_rebuild_substrand_with_dna_sequence_to_match_its_length(substrand));
    }
    return strand.rebuild((b) => b.substrands.replace(new_substrands));
  }

  bool _at_least_one_substrand_has_dna_sequence(Strand strand) {
    return strand.substrands.any((ss) => ss.dna_sequence != null);
  }

  Substrand _rebuild_substrand_with_dna_sequence_to_match_its_length(Substrand substrand) {
    String old_sequence = substrand.dna_sequence == null ? '' : substrand.dna_sequence;
    return substrand
        .set_dna_sequence(_trim_or_pad_sequence_to_desired_length(old_sequence, substrand.dna_length()));
  }

  _ensure_extensions_legal() {
    check_at_least_one_domain();
    check_only_at_ends();
    check_not_adjacent_to_loopout();
  }

  check_at_least_one_domain() {
    for (var ss in substrands) {
      if (ss is Domain) {
        return;
      }
    }
    throw StrandError(this, 'strand must have at least one domain; here are all substrands:\n${substrands}');
  }

  check_only_at_ends() {
    for (int i = 1; i < substrands.length - 1; i++) {
      if (substrands[i] is Extension) {
        throw StrandError(
            this,
            "Extension must be at 5' or 3' end, but there is an Extension at index "
            "${i}: ${substrands[i]}");
      }
    }
  }

  check_not_adjacent_to_loopout() {
    if (substrands[0] is Extension) {
      assert(substrands.length > 1);
      if (substrands[1] is Loopout) {
        throw StrandError(
            this,
            'cannot have Extension adjacent to Loopout, but first substrand is '
            'Extension: ${substrands[0]}\n and second substrand is Loopout: ${substrands[1]}');
      }
    }
    if (substrands.last is Extension) {
      assert(substrands.length > 1);
      int second_last_idx = substrands.length - 2;
      if (substrands[second_last_idx] is Loopout) {
        throw StrandError(
            this,
            'cannot have Extension adjacent to Loopout, but last substrand is '
            'Extension: ${substrands.last}\n and second-to-last substrand is Loopout: '
            '${substrands[second_last_idx]}');
      }
    }
  }

  _ensure_loopouts_legal() {
    check_loopout_not_singleton();
    check_two_consecutive_loopouts();
    check_loopouts_length();
  }

  check_loopout_not_singleton() {
    if (substrands.length == 1 && first_domain.is_loopout()) {
      throw StrandError(this, 'strand cannot have a single Loopout as its only domain');
    }
  }

  check_two_consecutive_loopouts() {
    for (int i = 0; i < substrands.length - 1; i++) {
      var domain1 = substrands[i];
      var domain2 = substrands[i + 1];
      if (domain1.is_loopout() && domain2.is_loopout()) {
        throw StrandError(this, 'cannot have two consecutive Loopouts in a strand');
      }
    }
  }

  check_loopouts_length() {
    for (var loopout in loopouts) {
      if (loopout.loopout_num_bases <= 0) {
        throw StrandError(this, 'loopout length must be positive but is ${loopout.loopout_num_bases}');
      }
    }
  }

  BuiltList<Substrand> get substrands;

  @memoized
  String get dna_sequence {
    String sequence = "";
    for (Substrand s in this.substrands) {
      if (s.dna_sequence == null) {
        return null;
      }
      sequence += s.dna_sequence;
    }
    return sequence;
  }

  @nullable
  IDTFields get idt;

  bool get is_scaffold;

  bool get circular;

  @nullable
  Modification5Prime get modification_5p;

  @nullable
  Modification3Prime get modification_3p;

  BuiltMap<int, ModificationInternal> get modifications_int;

  // Since color assignment is somewhat nondeterministic, we don't want to use it to detect equality.
  // XXX: if we let the user specify a new Strand color in scadnano, the view will have to be explicitly
  // updated somehow.
//  @BuiltValueField(compare: false)
  Color get color;

  @nullable
  String get name;

  @nullable
  @BuiltValueField(serialize: false)
  Object get label;

  static Color DEFAULT_STRAND_COLOR = RgbColor.name('black');

  @memoized
  String get idt_dna_sequence {
    if (dna_sequence == null) {
      return null;
    }

    List<String> ret_list = [];

    // 5' mod
    if (modification_5p != null && modification_5p.idt_text != null) {
      ret_list.add(modification_5p.idt_text);
    }

    // internal mods
    for (int offset = 0; offset < dna_sequence.length; offset++) {
      String base = dna_sequence[offset];
      ret_list.add(base);
      if (modifications_int.containsKey(offset)) {
        // if internal mod attached to base, replace base
        var mod = modifications_int[offset];
        if (mod.idt_text != null) {
          if (mod.allowed_bases != null) {
            if (!mod.allowed_bases.contains(base)) {
              var msg = 'internal modification ${mod} can only replace one of these bases: '
                  '${mod.allowed_bases}.join(","), but the base at offset ${offset} is ${base}';
              throw IllegalDesignError(msg);
            }
            ret_list.last = mod.idt_text; // replace base with modified base
          } else {
            ret_list.add(mod.idt_text); // append modification between two bases
          }
        }
      }
    }

    // 3' mods
    if (modification_3p != null && modification_3p.idt_text != null) {
      ret_list.add(modification_3p.idt_text);
    }

    return ret_list.join();
  }

  @memoized
  bool get has_5p_extension => substrands.first is Extension;

  @memoized
  bool get has_3p_extension => substrands.last is Extension;

  @memoized
  Address get address_5p => first_domain.address_5p;

  @memoized
  Address get address_3p => last_domain.address_3p;

  @memoized
  BuiltList<SelectableDeletion> get selectable_deletions => [
        for (var domain in domains)
          for (var deletion in domain.selectable_deletions) deletion
      ].build();

  @memoized
  BuiltList<SelectableInsertion> get selectable_insertions => [
        for (var domain in domains)
          for (var insertion in domain.selectable_insertions) insertion
      ].build();

  @memoized
  SelectableModification5Prime get selectable_modification_5p => modification_5p == null
      ? null
      : SelectableModification5Prime(modification: modification_5p, strand: this);

  @memoized
  SelectableModification3Prime get selectable_modification_3p => modification_3p == null
      ? null
      : SelectableModification3Prime(modification: modification_3p, strand: this);

  @memoized
  BuiltList<SelectableModificationInternal> get selectable_modifications_int {
    List<SelectableModificationInternal> mods = [];
    for (int i = 0; i < substrands.length; i++) {
      var substrand = substrands[i];
      if (substrand is Domain) {
        // TODO: support displaying mods on loopouts eventually
        BuiltMap<int, ModificationInternal> mods_on_ss = internal_modifications_on_substrand[i];
        for (int dna_idx_ss in mods_on_ss.keys) {
          var mod = mods_on_ss[dna_idx_ss];
          int dna_idx = get_seq_start_idx(substrand) + dna_idx_ss;
          var selectable_mod = SelectableModificationInternal(
              modification: mod, strand: this, domain: substrand, dna_idx: dna_idx);
          mods.add(selectable_mod);
        }
      }
    }
    return mods.build();
  }

  @memoized
  BuiltList<Selectable> get selectable_modifications {
    List<Selectable> mods = [];
    if (selectable_modification_5p != null) {
      mods.add(selectable_modification_5p);
    }
    if (selectable_modification_3p != null) {
      mods.add(selectable_modification_3p);
    }
    var mods_int = List<Selectable>.from(selectable_modifications_int_by_dna_idx.values);
    mods.addAll(mods_int);
    return mods.build();
  }

  @memoized
  BuiltMap<int, SelectableModificationInternal> get selectable_modifications_int_by_dna_idx {
    Map<int, SelectableModificationInternal> mods = {};
    for (int i = 0; i < substrands.length; i++) {
      var substrand = substrands[i];
      if (substrand is Domain) {
        // TODO: support displaying mods on loopouts and extensions
        BuiltMap<int, ModificationInternal> mods_on_ss = internal_modifications_on_substrand_absolute_idx[i];
        for (int dna_idx in mods_on_ss.keys) {
          var mod = mods_on_ss[dna_idx];
          var selectable_mod = SelectableModificationInternal(
              modification: mod, strand: this, domain: substrand, dna_idx: dna_idx);
          mods[dna_idx] = selectable_mod;
        }
      }
    }
    return mods.build();
  }

  @memoized
  BuiltList<SelectableModification> get all_modifications_selectable {
    List<SelectableModification> mods = [];
    if (selectable_modification_5p != null) {
      mods.add(selectable_modification_5p);
    }
    if (selectable_modification_3p != null) {
      mods.add(selectable_modification_3p);
    }
    mods.addAll(selectable_modifications_int);
    return mods.build();
  }

  /// Returns list of same length as substrands, indicating for each substrand,
  /// the internal modifications on that substrand.
  /// The modifications are represented as a map mapping an *absolute* DNA index
  /// (i.e., index on the whole strand) to the modification.
  @memoized
  BuiltList<BuiltMap<int, ModificationInternal>> get internal_modifications_on_substrand_absolute_idx {
    var mods = List<Map<int, ModificationInternal>>.filled(substrands.length, null);
    for (int i = 0; i < substrands.length; i++) {
      mods[i] = Map<int, ModificationInternal>();
    }

    for (var mod_idx in modifications_int.keys) {
      var mod = modifications_int[mod_idx];
      var ss_and_idx = _substrand_of_dna_idx(mod_idx);
      Substrand ss = ss_and_idx.item1;
      int ss_idx = index_of_substrand(ss);
      mods[ss_idx][mod_idx] = mod;
    }

    List<BuiltMap<int, ModificationInternal>> mods_built = [for (var mod in mods) mod.build()];

    return mods_built.build();
  }

  int index_of_substrand(Substrand ss) {
    for (int i = 0; i < substrands.length; i++) {
      if (ss == substrands[i]) {
        return i;
      }
    }
    throw AssertionError('ss = ${ss} is not a substrand on this strand: ${this}');
  }

  /// Returns map mapping substrands to internal modifications on that substrand.
  /// The modifications are represented as a map mapping a DNA index *within* the substrand to the
  /// modification (instead of the DNA index within the whole Strand, which is how they are represented
  /// in this.modifications_int).
  @memoized
  BuiltMap<Substrand, BuiltMap<int, ModificationInternal>> get internal_modifications_on_substrand {
    var mods = Map<Substrand, Map<int, ModificationInternal>>();
    for (var ss in substrands) {
      mods[ss] = Map<int, ModificationInternal>();
    }

    for (var mod_idx in modifications_int.keys) {
      var mod = modifications_int[mod_idx];
      var ss_and_idx = _substrand_of_dna_idx(mod_idx);
      Substrand ss = ss_and_idx.item1;
      int idx_within_ss = ss_and_idx.item2;
      mods[ss][idx_within_ss] = mod;
    }

    Map<Substrand, BuiltMap<int, ModificationInternal>> mods_built = {
      for (var ss in mods.keys) ss: mods[ss].build()
    };

    return mods_built.build();
  }

  Tuple2<Substrand, int> _substrand_of_dna_idx(int dna_idx) {
    if (dna_idx < 0) {
      throw ArgumentError('dna_idx cannot be negative but is ${dna_idx}');
    }
    if (dna_idx >= dna_length) {
      throw ArgumentError('dna_idx cannot be greater than dna_length() but dna_idx = ${dna_idx} '
          'and dna_length() = ${dna_length}');
    }
    int dna_idx_cur_ss_start = 0;
    for (var ss in substrands) {
      int dna_idx_cur_ss_end = dna_idx_cur_ss_start + ss.dna_length();
      if (dna_idx_cur_ss_start <= dna_idx && dna_idx < dna_idx_cur_ss_end) {
        return Tuple2<Substrand, int>(ss, dna_idx - dna_idx_cur_ss_start);
      }
      dna_idx_cur_ss_start = dna_idx_cur_ss_end;
    }
    throw AssertionError("should be unreachable");
  }

  @memoized
  BuiltMap<int, BuiltList<Domain>> get domains_on_helix {
    var domains_map = Map<int, List<Domain>>();
    for (var substrand in domains) {
      if (domains_map.containsKey(substrand.helix)) {
        domains_map[substrand.helix].add(substrand);
      } else {
        domains_map[substrand.helix] = [substrand];
      }
    }
    var domains_partially_built_map = Map<int, BuiltList<Domain>>();
    for (var helix in domains_map.keys) {
      domains_partially_built_map[helix] = domains_map[helix].build();
    }
    return domains_partially_built_map.build();
  }

  @memoized
  BuiltList<Linker> get linkers {
    List<Linker> linkers = [];
    for (int i = 0; i < substrands.length - 1; i++) {
      if (substrands[i] is Domain) {
        if (substrands[i + 1] is Domain) {
          linkers.add(Crossover(i, i + 1, id, is_scaffold));
        } else if (substrands[i + 1] is Loopout) {
          var loopout = substrands[i + 1];
          assert(loopout is Loopout);
          if (loopout is Loopout) {
            linkers.add(loopout);
          }
        }
      }
    }

    if (circular) {
      linkers.add(Crossover(substrands.length - 1, 0, id, is_scaffold));
    }

    return linkers.build();
  }

  @memoized
  BuiltList<Crossover> get crossovers => BuiltList<Crossover>.from([
        for (var linker in linkers)
          if (linker is Crossover) linker
      ]);

  @memoized
  BuiltList<Loopout> get loopouts => BuiltList<Loopout>.from([
        for (var linker in linkers)
          if (linker is Loopout) linker
      ]);

  @memoized
  BuiltList<Extension> get extensions => BuiltList<Extension>.from([
        if (substrands.first is Extension) substrands.first,
        if (substrands.last is Extension) substrands.last,
      ]);

  @memoized
  SelectModeChoice get select_mode => SelectModeChoice.strand;

  @memoized
  String get id {
    var first_dom = this.first_domain;
    return id_from_data(first_dom.helix, first_dom.offset_5p, first_dom.forward);
  }

  static String id_from_data(int helix, int offset, bool forward) =>
      'strand-H${helix}-${offset}-${forward ? 'forward' : 'reverse'}';

  @memoized
  BuiltList<Domain> get domains => List<Domain>.from([
        for (var ss in this.substrands)
          if (ss.is_domain()) ss as Domain
      ]).build();

  @memoized
  BuiltList<DNAEnd> get ends_5p_not_first =>
      List<DNAEnd>.from([for (var ss in domains.sublist(1)) ss.dnaend_5p]).build();

  @memoized
  BuiltList<DNAEnd> get ends_3p_not_last =>
      List<DNAEnd>.from([for (var ss in domains.sublist(0, domains.length - 1)) ss.dnaend_3p]).build();

  @memoized
  int get dna_length {
    int num = 0;
    for (var substrand in substrands) {
      num += substrand.dna_length();
    }
    return num;
  }

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    var json_map = Map<String, dynamic>();

    if (this.name != null) {
      json_map[constants.name_key] = name;
    }

    if (this.circular) {
      json_map[constants.circular_key] = circular;
    }

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

    if (this.modification_5p != null) {
      json_map[constants.modification_5p_key] = this.modification_5p.id;
    }
    if (this.modification_3p != null) {
      json_map[constants.modification_3p_key] = this.modification_3p.id;
    }
    if (this.modifications_int.isNotEmpty) {
      Map<String, dynamic> mods_map = {};
      for (int offset in this.modifications_int.keys) {
        var mod = this.modifications_int[offset];
        mods_map['${offset}'] = mod.id;
      }
      json_map[constants.modifications_int_key] = suppress_indent ? NoIndent(mods_map) : mods_map;
    }

    if (label != null) {
      json_map[constants.label_key] = label;
    }

    json_map.addAll(unused_fields.toMap());

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

    return rebuild((strand) => strand..substrands.replace(substrands_new));
  }

  /// Sets DNA sequence of strand (but does not assign complement to any Strands bound to it).
  Strand set_dna_sequence(String dna_sequence_new) {
    dna_sequence_new = _trim_or_pad_sequence_to_desired_length(dna_sequence_new, this.dna_length);

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

    return rebuild((strand) => strand..substrands.replace(substrands_new));
  }

  String _trim_or_pad_sequence_to_desired_length(String dna_sequence_new, int desired_length) {
    // truncate dna_sequence_new if too long; pad with ?'s if to short
    int seq_len = dna_sequence_new.length;
    if (seq_len > desired_length) {
      dna_sequence_new = dna_sequence_new.substring(0, desired_length);
    } else if (seq_len < desired_length) {
      dna_sequence_new = dna_sequence_new + (constants.DNA_BASE_WILDCARD * (desired_length - seq_len));
    }
    return dna_sequence_new;
  }

  static Strand from_json(Map<String, dynamic> json_map) {
    List<dynamic> substrand_jsons = util.mandatory_field(json_map, constants.substrands_key, 'Strand',
        legacy_keys: constants.legacy_substrands_keys);

    bool is_scaffold = util.optional_field(json_map, constants.is_scaffold_key, false);
    bool circular = util.optional_field(json_map, constants.circular_key, false);

    // need to parse all Domains before Loopouts,
    // because prev and next Domains need to be referenced by Loopouts
    // Also, no DNA sequence parsing yet because we want all the lengths of Substrands calculated
    // before assigning.
    Map<int, Domain> domains = {};
    int num_substrands = substrand_jsons.length;
    // we'll fill in Domains and Extensions in this loop, then calculate Loopouts later
    var substrands = List<Substrand>.filled(num_substrands, null);
    int start_dna_idx_ss = 0; // help identify dna_length of each substrand
    for (int i = 0; i < num_substrands; i++) {
      var substrand_json = substrand_jsons[i];
      int end_dna_idx_ss;
      if (substrand_json.containsKey(constants.loopout_key)) {
        // Loopout
        int loopout_length = substrand_json[constants.loopout_key];
        end_dna_idx_ss = start_dna_idx_ss + loopout_length;
        if (i == 0 || i == num_substrands - 1) {
          throw IllegalDesignError("found loopout ${substrand_json} at index ${i} in substrand list. "
              "cannot have loopouts at the beginning (index 0) or end (index ${num_substrands - 1}).\n"
              "substrands JSON list: ${substrand_jsons}");
        }
      } else if (substrand_json.containsKey(constants.extension_key)) {
        // Extension
        var ext = Extension.from_json(substrand_json);
        bool is_5p = (i == 0);
        ext = ext.rebuild((b) => b..is_5p = is_5p);
        substrands[i] = ext;
        end_dna_idx_ss = start_dna_idx_ss + ext.num_bases;
        if (0 < i && i < num_substrands - 1) {
          throw IllegalDesignError("found extension ${ext} at index ${i} in substrand list. "
              "can only have extension at beginning (index 0) or end (index ${num_substrands - 1}).\n"
              "substrands JSON list: ${substrand_jsons}");
        }
      } else if (substrand_json.containsKey(constants.helix_idx_key)) {
        // Domain
        DomainBuilder ssb = Domain.from_json(substrand_json);
        ssb.is_first = (i == 0);
        ssb.is_last = (i == substrand_jsons.length - 1);
        int num_insertions = Domain.num_insertions_in_list(ssb.insertions.build());
        int dna_length = ssb.end - ssb.start + num_insertions - ssb.deletions.length;
        ssb.is_scaffold = is_scaffold;
        end_dna_idx_ss = start_dna_idx_ss + dna_length;
        domains[i] = substrands[i] = ssb.build();
      } else {
        throw IllegalDesignError('unrecognized substrand; does not have any of these keys:\n'
            '${constants.extension_key} for an Extension, '
            '${constants.loopout_key} for a Loopout, or'
            '${constants.helix_idx_key} for a Domain.\n'
            'JSON: ${substrand_json}');
      }
      start_dna_idx_ss = end_dna_idx_ss;
    }

    // parse Loopouts now that we have all the Domains
    Map<int, Loopout> loopouts = {};
    for (int i = 0; i < substrand_jsons.length; i++) {
      var substrand_json = substrand_jsons[i];
      if (substrand_json.containsKey(constants.loopout_key)) {
        LoopoutBuilder lb = Loopout.from_json(substrand_json);
        lb.prev_domain_idx = i - 1;
        lb.is_scaffold = is_scaffold;
        loopouts[i] = lb.build();
      }
    }

    // insert Loopouts into appropriate positions in the List substrands
    for (int i in loopouts.keys) {
      substrands[i] = loopouts[i];
    }

    // go through extensions and set adjacent domains and adjacent helices
    for (int i = 0; i < substrands.length; i++) {
      if (substrands[i] is Extension) {
        Extension ext = substrands[i];
        Domain adjacent_domain = ext.is_5p ? substrands[i + 1] as Domain : substrands[i - 1] as Domain;
        ext = ext.rebuild(
            (b) => b..adjacent_domain.replace(adjacent_domain));
        substrands[i] = ext;
      }
    }

    for (int i = 0; i < num_substrands; i++) {
      if (substrands[i] == null) {
        throw AssertionError('should not have any null entries in substrands but ${i} is null:\n'
            'substrands = ${substrands}');
      }
    }

    // Now that all Substrand dna_lengths are known, we can assign DNA sequences to them
    //XXX: important to do this check after setting substrands so dna_length() is well-defined
    var dna_sequence = util.optional_field_with_null_default(json_map, constants.dna_sequence_key,
        legacy_keys: constants.legacy_dna_sequence_keys);

    var color = json_map.containsKey(constants.color_key)
        ? parse_json_color(json_map[constants.color_key])
        : DEFAULT_STRAND_COLOR;

    String name = util.optional_field_with_null_default(json_map, constants.name_key);

    Object label = util.optional_field_with_null_default(json_map, constants.label_key);

    var unused_fields = util.unused_fields_map(json_map, constants.strand_keys);

    IDTFields idt = null;
    Map<String, dynamic> idt_dict = null;
    if (json_map.containsKey(constants.idt_key)) {
      idt_dict = json_map[constants.idt_key];
      idt = IDTFields.from_json(idt_dict);
    }
    // legacy:
    // if no name is specified, but there's a name field in idt, then use that as the Strand's name
    if (name == null && idt_dict != null && idt_dict.containsKey(constants.idt_name_key)) {
      name = idt_dict[constants.idt_name_key];
    }

    Strand strand = Strand(
      substrands,
      color: color,
      circular: circular,
      name: name,
      idt: idt,
      is_scaffold: is_scaffold,
      dna_sequence: dna_sequence,
      label: label,
    ).rebuild((b) => b.unused_fields = unused_fields);

    if (strand.substrands.first is Loopout) {
      throw StrandError(strand, 'Loopout at beginning of strand not supported');
    }

    if (strand.substrands.last is Loopout) {
      throw StrandError(strand, 'Loopout at end of strand not supported');
    }

//    strand = strand.initialize();

    return strand;
  }

  @memoized
  Domain get first_domain {
    for (int i = 0; i < substrands.length; i++) {
      if (this.substrands[i] is Domain) {
        return this.substrands[i] as Domain;
      }
    }
    throw AssertionError('should not be reachable');
  }

  @memoized
  Domain get last_domain {
    for (int i = substrands.length - 1; i >= 0; i--) {
      if (this.substrands[i] is Domain) {
        return this.substrands[i] as Domain;
      }
    }
    throw AssertionError('should not be reachable');
  }

  /// Indicates whether `self` overlaps `other_strand`, meaning that the set of offsets occupied
  /// by `self` has nonempty intersection with those occupied by `other_strand`.
  bool overlaps(Strand other) {
    for (var substrand_self in domains) {
      for (var substrand_other in other.domains) {
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

  @memoized
  DNAEnd get dnaend_3p => last_domain.dnaend_3p;

  @memoized
  DNAEnd get dnaend_5p => first_domain.dnaend_5p;

  /// If this and other are ligatable (they have a pair of 5'/3' ends adjacent)
  /// return the two [DNAEnd]s that can be ligated, in other (this.end, other.end).
  Tuple2<DNAEnd, DNAEnd> ligatable_ends_with(Strand other) {
    if (_ligatable_3p_to_5p_of(other)) {
      return Tuple2<DNAEnd, DNAEnd>(dnaend_3p, other.dnaend_5p);
    } else if (_ligatable_5p_to_3p_of(other)) {
      return Tuple2<DNAEnd, DNAEnd>(dnaend_5p, other.dnaend_3p);
    } else {
      return null;
    }
  }

  bool _ligatable_3p_to_5p_of(Strand other) {
    Domain last_domain_this = last_domain;
    Domain first_domain_other = other.first_domain;

    return last_domain_this.forward == first_domain_other.forward &&
        last_domain_this.helix == first_domain_other.helix &&
        dnaend_3p.offset == other.dnaend_5p.offset;
  }

  bool _ligatable_5p_to_3p_of(Strand other) {
    Domain first_domain_this = first_domain;
    Domain last_domain_other = other.last_domain;

    return first_domain_this.forward == last_domain_other.forward &&
        first_domain_this.helix == last_domain_other.helix &&
        dnaend_5p.offset == other.dnaend_3p.offset;
  }

  /// Name to use when exporting this Strand.
  /// Prefer idt.name if defined, then this.name if defined, then default_export_name().
  String idt_export_name() {
    if (name != null) {
      return name;
    } else {
      return default_export_name();
    }
  }

  /// Name to export if Strand.name and Strand.idt.name are both not set.
  String default_export_name() {
    String id =
        '${first_domain.helix}[${first_domain.offset_5p}]${last_domain.helix}[${last_domain.offset_3p}]';
    return is_scaffold ? 'SCAF$id}' : 'ST$id';
  }
}

Color parse_json_color(Object json_obj) {
  try {
    if (json_obj is Map) {
      int r = json_obj['r'];
      int g = json_obj['g'];
      int b = json_obj['b'];
      return RgbColor(r, g, b);
    } else if (json_obj is String) {
      return HexColor(json_obj);
    } else if (json_obj is int) {
      String hex_str = util.color_decimal_int_to_hex(json_obj);
      return HexColor(hex_str);
    } else {
      throw ArgumentError.value('JSON object representing color must be a Map or String, but instead it is a '
          '${json_obj.runtimeType}:\n${json_obj}');
    }
  } on Exception {
    print("WARNING: I couldn't understand the color specification ${json_obj}, so I'm substituting black.");
    return RgbColor.name('black');
  }
}
