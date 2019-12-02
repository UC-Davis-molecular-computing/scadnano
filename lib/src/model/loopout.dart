import 'package:built_value/serializer.dart';
import 'package:scadnano/src/model/bound_substrand.dart';
import 'package:scadnano/src/model/select_mode.dart';
import 'package:built_value/built_value.dart';
import 'package:scadnano/src/serializers.dart';

import 'selectable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'substrand.dart';

part 'loopout.g.dart';

abstract class Loopout with Selectable, BuiltJsonSerializable implements Built<Loopout, LoopoutBuilder>, Substrand {
  factory Loopout(int loopout_length, BoundSubstrand prev_substrand, BoundSubstrand next_substrand) =>
      Loopout.from((b) => b
        ..loopout_length = loopout_length
        ..prev_substrand.replace(prev_substrand)
        ..next_substrand.replace(next_substrand));

  factory Loopout.from([void Function(LoopoutBuilder) updates]) = _$Loopout;

  Loopout._();

  static Serializer<Loopout> get serializer => _$loopoutSerializer;

  /************************ end BuiltValue boilerplate ************************/

  int get loopout_length;

  @nullable
  String get dna_sequence;

  BoundSubstrand get prev_substrand;

  BoundSubstrand get next_substrand;

  Loopout set_dna_sequence(String seq) => rebuild((loopout) => loopout..dna_sequence = seq);

  bool is_bound_substrand() => false;

  bool is_loopout() => true;

  SelectModeChoice select_mode() => SelectModeChoice.loopout;

  String id() => 'loopout'
      '-H${prev_substrand.helix}-${prev_substrand.offset_3p}'
      '-H${next_substrand.helix}-${next_substrand.offset_5p}';

  String toString() => 'Loopout(${this.loopout_length})';

  int dna_length() => this.loopout_length;

  static LoopoutBuilder from_json(Map<String, dynamic> json_map) {
    var name = 'Loopout';
    int loopout_length = util.get_value(json_map, constants.loopout_key, name);
    return LoopoutBuilder()..loopout_length = loopout_length;
  }

  Map<String, dynamic> to_json_serializable({bool suppress_indent = false}) {
    var json_map = {
      constants.loopout_key: this.loopout_length,
    };
    return json_map;
  }

//  toJson() => to_json_serializable(suppress_indent: false);

}
