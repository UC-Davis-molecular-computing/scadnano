import 'package:built_value/serializer.dart';
import 'package:scadnano/src/state/strand_part.dart';

import '../serializers.dart';
import 'linker.dart';
import 'select_mode.dart';
import 'selectable.dart';

import 'package:built_value/built_value.dart';

part 'crossover.g.dart';

abstract class Crossover
    with Selectable, BuiltJsonSerializable
    implements Built<Crossover, CrossoverBuilder>, Linker, StrandPart {
//  factory Crossover(Domain prev_substrand, Domain next_substrand) =>
//      Crossover.from((b) => b..prev_substrand.replace(prev_substrand)..next_substrand.replace(next_substrand));
  factory Crossover(int prev_domain_idx, int next_domain_idx, String strand_id) =>
      Crossover.from((b) => b
        ..prev_domain_idx = prev_domain_idx
        ..next_domain_idx = next_domain_idx
        ..strand_id = strand_id);

  factory Crossover.from([void Function(CrossoverBuilder) updates]) = _$Crossover;

  Crossover._();

  static Serializer<Crossover> get serializer => _$crossoverSerializer;

  /************************ end BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  int get prev_domain_idx;

  int get next_domain_idx;

  @nullable
  String get strand_id;

  SelectModeChoice select_mode() => SelectModeChoice.crossover;

  String id() => 'crossover-${prev_domain_idx}-${next_domain_idx}-${strand_id}';
}
