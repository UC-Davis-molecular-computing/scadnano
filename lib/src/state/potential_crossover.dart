import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/state/loopout.dart';

import '../serializers.dart';
import 'address.dart';
import 'crossover.dart';
import 'dna_end.dart';
import 'linker.dart';

part 'potential_crossover.g.dart';

abstract class PotentialCrossover
    with BuiltJsonSerializable
    implements Built<PotentialCrossover, PotentialCrossoverBuilder> {
  factory PotentialCrossover.from([void Function(PotentialCrossoverBuilder) updates]) = _$PotentialCrossover;

  PotentialCrossover._();

  static Serializer<PotentialCrossover> get serializer => _$potentialCrossoverSerializer;

  factory PotentialCrossover({
    Address address,
    String color,
    DNAEnd dna_end_first_click,
    Point<num> start_point,
    Point<num> current_point,
    Linker linker = null,
  }) {
    // need this because Linker is not a Built type, but its two subclasses Crossover and Loopout are,
    // so need this to satisfy the compiler that they have a toBuilder() method
    return PotentialCrossover.from((b) => b
      ..address.replace(address)
      ..color = color
      ..dna_end_first_click.replace(dna_end_first_click)
      ..start_point = start_point
      ..current_point = current_point
      ..linker = linker);
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  Address get address;

  String get color;

  DNAEnd get dna_end_first_click;

  Point<num> get start_point;

  Point<num> get current_point;

  // are we exchanging DNA ends of an existing crossover or loopout?
  // If not this is null, otherwise it is the existing crossover/loopout
  @nullable
  Linker get linker;
}
