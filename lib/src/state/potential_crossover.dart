import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'address.dart';
import 'dna_end.dart';

part 'potential_crossover.g.dart';

abstract class PotentialCrossover
    with BuiltJsonSerializable
    implements Built<PotentialCrossover, PotentialCrossoverBuilder> {
  factory PotentialCrossover.from([void Function(PotentialCrossoverBuilder) updates]) = _$PotentialCrossover;

  PotentialCrossover._();

  static Serializer<PotentialCrossover> get serializer => _$potentialCrossoverSerializer;

  factory PotentialCrossover(
      {Address address,
      String color,
      DNAEnd dna_end_first_click,
      Point<num> start_point,
      Point<num> current_point}) = _$PotentialCrossover._;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  Address get address;

  String get color;

  DNAEnd get dna_end_first_click;

  Point<num> get start_point;

  Point<num> get current_point;
}
