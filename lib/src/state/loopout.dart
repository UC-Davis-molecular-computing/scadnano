import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/built_value.dart';

import 'package:scadnano/src/serializers.dart';
import 'package:scadnano/src/state/select_mode.dart';
import '../json_serializable.dart';
import 'linker.dart';
import 'selectable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'strand_part.dart';
import 'substrand.dart';

part 'loopout.g.dart';

abstract class Loopout
    with Selectable, BuiltJsonSerializable
    implements Built<Loopout, LoopoutBuilder>, Substrand, Linker, StrandPart {
  factory Loopout(int loopout_length, int prev_domain_idx, int next_domain_idx) => Loopout.from((b) => b
    ..loopout_length = loopout_length
    ..prev_domain_idx = prev_domain_idx
    ..next_domain_idx = next_domain_idx
    ..unused_fields = MapBuilder<String, Object>({}));

  factory Loopout.from([void Function(LoopoutBuilder) updates]) = _$Loopout;

  Loopout._();

  static Serializer<Loopout> get serializer => _$loopoutSerializer;

  /************************ end BuiltValue boilerplate ************************/

  int get loopout_length;

  int get prev_domain_idx;

  int get next_domain_idx;

  @nullable
  String get dna_sequence;

  @nullable
  String get strand_id;

  BuiltMap<String, Object> get unused_fields;

  Loopout set_dna_sequence(String seq) => rebuild((loopout) => loopout..dna_sequence = seq);

  bool is_domain() => false;

  bool is_loopout() => true;

  SelectModeChoice select_mode() => SelectModeChoice.loopout;

  String id() => 'loopout-${prev_domain_idx + 1}-${strand_id}';

  int dna_length() => this.loopout_length;
  
  @memoized
  int get hashCode;

  static LoopoutBuilder from_json(Map<String, dynamic> json_map) {
    var name = 'Loopout';
    int loopout_length = util.get_value(json_map, constants.loopout_key, name);
    return LoopoutBuilder()
      ..loopout_length = loopout_length
      ..unused_fields = util.unused_fields_map(json_map, constants.loopout_keys);
  }

  dynamic to_json_serializable({bool suppress_indent = false}) {
    Map<String, Object> json_map = {
      constants.loopout_key: this.loopout_length,
    };
    json_map.addAll(unused_fields.toMap());
    return suppress_indent ? NoIndent(json_map) : json_map;
  }
}
