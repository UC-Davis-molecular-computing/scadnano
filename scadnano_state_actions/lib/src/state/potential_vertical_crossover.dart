import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'domain.dart';
import 'dna_end.dart';

part 'potential_vertical_crossover.g.dart';

// Potential crossover between opposite polarity DNA ends on adjacent helices at same offset.
abstract class PotentialVerticalCrossover
    with BuiltJsonSerializable
    implements Built<PotentialVerticalCrossover, PotentialVerticalCrossoverBuilder> {
  factory PotentialVerticalCrossover.from([void Function(PotentialVerticalCrossoverBuilder) updates]) =
      _$PotentialVerticalCrossover;

  PotentialVerticalCrossover._();

  static Serializer<PotentialVerticalCrossover> get serializer => _$potentialVerticalCrossoverSerializer;

  factory PotentialVerticalCrossover({
    required int helix_idx_top,
    required int helix_idx_bot,
    required int offset,
    required bool forward_top,
    required String color,
    required Domain domain_top,
    required Domain domain_bot,
    required DNAEnd dna_end_top,
    required DNAEnd dna_end_bot,
  }) = _$PotentialVerticalCrossover._;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  int get helix_idx_top;

  int get helix_idx_bot;

  int get offset;

  bool get forward_top;

  String get color;

  Domain get domain_top;

  Domain get domain_bot;

  DNAEnd get dna_end_top;

  DNAEnd get dna_end_bot;
}
