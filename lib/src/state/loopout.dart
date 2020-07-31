import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';

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
    with Selectable, BuiltJsonSerializable, UnusedFields
    implements Built<Loopout, LoopoutBuilder>, Substrand, Linker, StrandPart {
  factory Loopout(int loopout_length, int prev_domain_idx, int next_domain_idx, bool is_scaffold) => Loopout.from((b) => b
    ..loopout_length = loopout_length
    ..prev_domain_idx = prev_domain_idx
    ..next_domain_idx = next_domain_idx
    ..is_scaffold = is_scaffold
    ..unused_fields = MapBuilder<String, Object>({}));

  factory Loopout.from([void Function(LoopoutBuilder) updates]) = _$Loopout;

  Loopout._();

  static Serializer<Loopout> get serializer => _$loopoutSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  int get loopout_length;

  @nullable
  @BuiltValueField(serialize: false)
  Object get label;

  int get prev_domain_idx;

  int get next_domain_idx;

  @nullable
  String get dna_sequence;

  @nullable
  String get strand_id;

  Loopout set_dna_sequence(String seq) => rebuild((loopout) => loopout..dna_sequence = seq);

  bool is_domain() => false;

  bool is_loopout() => true;

  SelectModeChoice select_mode() => SelectModeChoice.loopout;

  String id() => 'loopout-${prev_domain_idx + 1}-${strand_id}';

  int dna_length() => this.loopout_length;

  static LoopoutBuilder from_json(Map<String, dynamic> json_map) {
    var name = 'Loopout';
    int loopout_length = util.mandatory_field(json_map, constants.loopout_key, name);
    Object label = util.optional_field_with_null_default(json_map, constants.label_key);
    return LoopoutBuilder()
      ..loopout_length = loopout_length
      ..label = label
      ..unused_fields = util.unused_fields_map(json_map, constants.loopout_keys);
  }

  dynamic to_json_serializable({bool suppress_indent = false}) {
    Map<String, Object> json_map = {
      constants.loopout_key: loopout_length,
    };
    if (label != null) {
      json_map[constants.label_key] = label;
    }
    json_map.addAll(unused_fields.toMap());
    return suppress_indent ? NoIndent(json_map) : json_map;
  }
}
