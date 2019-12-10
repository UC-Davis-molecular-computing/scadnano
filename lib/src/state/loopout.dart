import 'package:built_value/serializer.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:built_value/built_value.dart';
import 'package:scadnano/src/serializers.dart';

import 'linker.dart';
import 'selectable.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import 'substrand.dart';

part 'loopout.g.dart';

abstract class Loopout
    with Selectable, BuiltJsonSerializable
    implements Built<Loopout, LoopoutBuilder>, Substrand, Linker {
  factory Loopout(
          int loopout_length,
//      BoundSubstrand prev_substrand, BoundSubstrand next_substrand
          int prev_substrand_idx,
          String strand_id) =>
      Loopout.from((b) => b..loopout_length = loopout_length
//        ..prev_substrand.replace(prev_substrand)
//        ..next_substrand.replace(next_substrand)
          );

  factory Loopout.from([void Function(LoopoutBuilder) updates]) = _$Loopout;

  Loopout._();

  static Serializer<Loopout> get serializer => _$loopoutSerializer;

  /************************ end BuiltValue boilerplate ************************/

  int get loopout_length;

  int get prev_substrand_idx;

  int get next_substrand_idx;

  // can't really be nullable but need a way to delay setting it until whole Strand is built
  @nullable
  String get strand_id;

  @nullable
  String get dna_sequence;


  Loopout set_dna_sequence(String seq) => rebuild((loopout) => loopout..dna_sequence = seq);

  bool is_bound_substrand() => false;

  bool is_loopout() => true;

  SelectModeChoice select_mode() => SelectModeChoice.loopout;

  String id() => 'loopout-${prev_substrand_idx + 1}-${strand_id}';

//  String toString() => 'Loopout(${this.loopout_length})';

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
