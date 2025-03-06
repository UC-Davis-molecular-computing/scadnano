import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:color/color.dart';
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
import 'domain.dart';
import 'unused_fields.dart';
import 'design.dart';
import 'helix.dart';
import 'address.dart';

part 'extension.g.dart';

abstract class Extension
    with SelectableMixin, BuiltJsonSerializable, UnusedFields
    implements Built<Extension, ExtensionBuilder>, Substrand, StrandPart {
  Extension._();

  static Serializer<Extension> get serializer => _$extensionSerializer;

  factory Extension.from([void Function(ExtensionBuilder) updates]) = _$Extension;

  @memoized
  int get hashCode;

  /******************************* end built_value boilerplate ************************************/

  int get num_bases;

  double get display_length;

  double get display_angle;

  bool get is_5p;

  String? get label;

  String? get name;

  String? get dna_sequence;

  Color? get color;

  String get strand_id;

  bool get is_scaffold;

  Domain get adjacent_domain;

  factory Extension(
      {required int num_bases,
      required bool is_5p,
      required Domain adjacent_domain,
      double display_length = constants.default_display_length,
      double display_angle = constants.default_display_angle,
      String? label = null,
      String? name = null,
      String? dna_sequence = null,
      bool is_scaffold = false,
      Color? color = null,
      String strand_id = 'NONE YET',
      Map<String, dynamic>? unused_fields = null}) {
    if (unused_fields == null) {
      unused_fields = {};
    }
    return Extension.from((b) => b
      ..num_bases = num_bases
      ..display_length = display_length
      ..display_angle = display_angle
      ..is_5p = is_5p
      ..name = name
      ..label = label
      ..dna_sequence = dna_sequence
      ..color = color
      ..is_scaffold = is_scaffold
      ..adjacent_domain.replace(adjacent_domain)
      ..unused_fields.replace(unused_fields!)
      ..strand_id = strand_id);
  }

  dynamic to_json_serializable({bool suppress_indent = false}) {
    Map<String, dynamic> json_map = {constants.extension_key: num_bases};
    if (display_length != constants.default_display_length) {
      json_map[constants.display_length_key] = display_length;
    }
    if (display_angle != constants.default_display_angle) {
      json_map[constants.display_angle_key] = display_angle;
    }
    if (name != null) {
      json_map[constants.name_key] = name;
    }
    if (this.color != null) {
      json_map[constants.color_key] = color!.toHexColor().toCssString();
    }
    if (label != null) {
      json_map[constants.label_key] = label;
    }
    // if (dna_sequence != null) {
    //     json_map[constants.dna_sequence_key] = dna_sequence;
    // }
    json_map.addAll(unused_fields.toMap());
    return suppress_indent ? NoIndent(json_map) : json_map;
  }

  static Extension from_json(Map<String, dynamic> json_map) {
    var class_name = 'Extension';
    var num_bases = util.mandatory_field(json_map, constants.extension_key, class_name);
    double display_length =
        util.optional_field(json_map, constants.display_length_key, constants.default_display_length);
    double display_angle =
        util.optional_field(json_map, constants.display_angle_key, constants.default_display_angle);
    String? name = util.optional_field_with_null_default(json_map, constants.name_key);
    String? label = util.optional_field_with_null_default(json_map, constants.label_key);

    String? dna_sequence = util.optional_field_with_null_default(json_map, constants.dna_sequence_key);

    Color? color = json_map.containsKey(constants.color_key)
        ? util.parse_json_color(json_map[constants.color_key]!)
        : null;

    var unused_fields = util.unused_fields_map(json_map, constants.extension_keys);

    return Extension(
        num_bases: num_bases,
        // next two are placeholders; will be set by Strand.initialize(), but we don't want to make the
        // fields nullable since in "normal" usage they are never null
        is_5p: false,
        adjacent_domain: Domain(helix: 0, forward: true, start: 0, end: 0),
        // let Strand calculate it based on position
        display_length: display_length,
        display_angle: display_angle,
        name: name,
        label: label,
        dna_sequence: dna_sequence,
        color: color,
        unused_fields: unused_fields.build().toMap());
  }

  Extension set_dna_sequence(String? seq) => rebuild((ext) => ext..dna_sequence = seq);

  bool is_domain() => false;

  bool is_loopout() => false;

  bool is_extension() => true;

  @memoized
  SelectModeChoice get select_mode => SelectModeChoice.extension_;

  @memoized
  String get id => 'extension-${is_5p ? "5p" : "3p"}-${strand_id}';

  int dna_length() => this.num_bases;

  @override
  String type_description() => "extension";

  @memoized
  DNAEnd get dnaend_free => DNAEnd(
      is_5p: this.is_5p,
      is_start: true,
      forward: adjacent_domain.forward,
      offset: null,
      is_scaffold: is_scaffold,
      substrand_is_first: is_5p,
      substrand_is_last: !is_5p,
      is_on_extension: true,
      substrand_id: id);

  double compute_rotation() => util.compute_end_rotation(display_angle, adjacent_domain.forward, is_5p);
}
