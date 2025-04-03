import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';
import 'package:color/color.dart';

import '../serializers.dart';
import '../state/select_mode.dart';
import '../json_serializable.dart';
import 'linker.dart';
import 'selectable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'strand_part.dart';
import 'substrand.dart';
import 'unused_fields.dart';

part 'loopout.g.dart';

abstract class Loopout
    with SelectableMixin, BuiltJsonSerializable, UnusedFields
    implements Built<Loopout, LoopoutBuilder>, Substrand, Linker, StrandPart {
  factory Loopout.from([void Function(LoopoutBuilder) updates]) = _$Loopout;

  Loopout._();

  static Serializer<Loopout> get serializer => _$loopoutSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  factory Loopout({
    required int loopout_num_bases,
    required int prev_domain_idx,
    bool is_scaffold = false,
    String? dna_sequence = null,
    Color? color = null,
    String? name = null,
    String? label = null,
    String strand_id = 'NONE YET',
  }) => Loopout.from(
    (b) =>
        b
          ..loopout_num_bases = loopout_num_bases
          ..prev_domain_idx = prev_domain_idx
          ..is_scaffold = is_scaffold
          ..dna_sequence = dna_sequence
          ..color = color
          ..name = name
          ..label = label
          ..strand_id = strand_id
          ..unused_fields = MapBuilder<String, Object>({}),
  );

  int get loopout_num_bases;

  String? get name;

  String? get label;

  // idx's within Strand.substrands (not Strand.domains)
  int get prev_domain_idx;

  @memoized
  int get next_domain_idx => prev_domain_idx + 2;

  String? get dna_sequence;

  Color? get color;

  String get strand_id;

  Loopout set_dna_sequence(String? seq) => rebuild((loopout) => loopout..dna_sequence = seq);

  bool is_domain() => false;

  bool is_loopout() => true;

  bool is_extension() => false;

  @memoized
  SelectModeChoice get select_mode => SelectModeChoice.loopout;

  @memoized
  String get id => 'loopout-${prev_domain_idx + 1}-${strand_id}';

  int dna_length() => this.loopout_num_bases;

  @override
  String type_description() => "loopout";

  static LoopoutBuilder from_json(Map<String, dynamic> json_map) {
    var class_name = 'Loopout';
    int loopout_num_bases = util.mandatory_field(json_map, constants.loopout_key, class_name);
    String? name = util.optional_field_with_null_default(json_map, constants.name_key);
    String? label = util.optional_field_with_null_default(json_map, constants.label_key);
    Color? color =
        json_map.containsKey(constants.color_key)
            ? util.parse_json_color(json_map[constants.color_key]!)
            : null;
    return LoopoutBuilder()
      ..loopout_num_bases = loopout_num_bases
      ..name = name
      ..label = label
      ..color = color
      ..strand_id =
          'NONE YET' // placeholder, will be set by Strand
      ..unused_fields = util.unused_fields_map(json_map, constants.loopout_keys);
  }

  Object to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {constants.loopout_key: loopout_num_bases};
    if (name != null) {
      json_map[constants.name_key] = name!;
    }
    if (this.color != null) {
      json_map[constants.color_key] = color!.toHexColor().toCssString();
    }
    if (label != null) {
      json_map[constants.label_key] = label!;
    }
    json_map.addAll(unused_fields.toMap());
    return suppress_indent ? NoIndent(json_map) : json_map;
  }
}
