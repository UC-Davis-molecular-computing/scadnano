import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'linker.dart';
import 'select_mode.dart';
import 'selectable.dart';
//import 'bound_substrand.dart';

import 'package:built_value/built_value.dart';

part 'crossover.g.dart';

abstract class Crossover with Selectable, BuiltJsonSerializable implements Built<Crossover, CrossoverBuilder>, Linker {
//  factory Crossover(BoundSubstrand prev_substrand, BoundSubstrand next_substrand) =>
//      Crossover.from((b) => b..prev_substrand.replace(prev_substrand)..next_substrand.replace(next_substrand));
  factory Crossover(int prev_substrand_idx, int next_substrand_idx, String strand_id) => Crossover.from((b) => b
    ..prev_substrand_idx = prev_substrand_idx
    ..next_substrand_idx = next_substrand_idx
    ..strand_id = strand_id);

  factory Crossover.from([void Function(CrossoverBuilder) updates]) = _$Crossover;

  Crossover._();

  static Serializer<Crossover> get serializer => _$crossoverSerializer;

  /************************ end BuiltValue boilerplate ************************/

//  BoundSubstrand get prev_substrand;
//  BoundSubstrand get next_substrand;

  int get prev_substrand_idx;
  int get next_substrand_idx;

  String get strand_id;

  SelectModeChoice select_mode() => SelectModeChoice.crossover;

  String id() => 'crossover-${prev_substrand_idx}-${next_substrand_idx}-${strand_id}';
}
