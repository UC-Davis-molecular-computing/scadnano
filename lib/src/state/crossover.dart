import 'package:built_value/serializer.dart';
import '../state/strand_part.dart';

import '../serializers.dart';
import 'linker.dart';
import 'select_mode.dart';
import 'selectable.dart';

import 'package:built_value/built_value.dart';

part 'crossover.g.dart';

abstract class Crossover
    with SelectableMixin, BuiltJsonSerializable
    implements Built<Crossover, CrossoverBuilder>, Linker, StrandPart {
  factory Crossover(int prev_domain_idx, int next_domain_idx, bool is_scaffold, String strand_id) =>
      Crossover.from((b) => b
        ..prev_domain_idx = prev_domain_idx
        ..next_domain_idx = next_domain_idx
        ..is_scaffold = is_scaffold
        ..strand_id = strand_id);

  factory Crossover.from([void Function(CrossoverBuilder) updates]) = _$Crossover;

  Crossover._();

  static Serializer<Crossover> get serializer => _$crossoverSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  // idx's within Strand.substrands (not Strand.domains)
  int get prev_domain_idx;

  int get next_domain_idx;

  bool get is_scaffold;

  String get strand_id;

  @memoized
  SelectModeChoice get select_mode => SelectModeChoice.crossover;

  @memoized
  String get id => 'crossover-${prev_domain_idx}-${next_domain_idx}-${strand_id}';
}
