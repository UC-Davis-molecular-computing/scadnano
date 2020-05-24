import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'bound_substrand.dart';
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
    int helix_idx_top,
    int helix_idx_bot,
    int offset,
    bool forward_top,
    String color,
    BoundSubstrand substrand_top,
    BoundSubstrand substrand_bot,
    DNAEnd dna_end_top,
    DNAEnd dna_end_bot,
  }) = _$PotentialVerticalCrossover._;

  /************************ end BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  int get helix_idx_top;

  int get helix_idx_bot;

  int get offset;

  bool get forward_top;

  String get color;

  BoundSubstrand get substrand_top;

  BoundSubstrand get substrand_bot;

  DNAEnd get dna_end_top;

  DNAEnd get dna_end_bot;
}
