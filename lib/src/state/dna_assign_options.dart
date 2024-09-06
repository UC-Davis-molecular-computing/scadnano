// @dart=2.9
import 'dart:math';

import 'package:built_value/serializer.dart';

import 'package:built_value/built_value.dart';
import '../serializers.dart';
import 'grid.dart';
import '../util.dart' as util;

part 'dna_assign_options.g.dart';

final DEFAULT_dna_assign_options_builder = DNAAssignOptionsBuilder();
final DEFAULT_dna_assign_options = DEFAULT_dna_assign_options_builder.build();

abstract class DNAAssignOptions
    with BuiltJsonSerializable
    implements Built<DNAAssignOptions, DNAAssignOptionsBuilder> {
  factory DNAAssignOptions.from([void Function(DNAAssignOptionsBuilder) updates]) = _$DNAAssignOptions;

  DNAAssignOptions._();

  static Serializer<DNAAssignOptions> get serializer => _$dNAAssignOptionsSerializer;

  factory DNAAssignOptions(
      {String dna_sequence,
      bool use_predefined_dna_sequence = false,
      bool assign_complements = true,
      bool disable_change_sequence_bound_strand = true,
      int m13_rotation = 5587}) {
    return DNAAssignOptions.from((b) => b
      ..dna_sequence = dna_sequence
      ..use_predefined_dna_sequence = use_predefined_dna_sequence
      ..assign_complements = assign_complements
      ..disable_change_sequence_bound_strand = disable_change_sequence_bound_strand
      ..m13_rotation = m13_rotation);
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  @nullable
  String get dna_sequence;

  bool get use_predefined_dna_sequence;

  bool get assign_complements;

  bool get disable_change_sequence_bound_strand;

  int get m13_rotation;

  static void _initializeBuilder(DNAAssignOptionsBuilder b) {
    b.dna_sequence = null;
    b.use_predefined_dna_sequence = false;
    b.assign_complements = true;
    b.disable_change_sequence_bound_strand = true;
    b.m13_rotation = 5587;
  }
}
