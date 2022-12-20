import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:color/color.dart';
import 'package:react/react.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/extension.dart';

import '../serializers.dart';

part 'dna_extensions_move.g.dart';

abstract class DNAExtensionsMove
    with BuiltJsonSerializable
    implements Built<DNAExtensionsMove, DNAExtensionsMoveBuilder> {
  factory DNAExtensionsMove(
      {BuiltList<DNAExtensionMove> moves,
      Point<num> start_point,
      Point<num> current_point}) = _$DNAExtensionsMove._;

  factory DNAExtensionsMove.from(
      [void Function(DNAExtensionsMoveBuilder) updates]) = _$DNAExtensionsMove;

  DNAExtensionsMove._();

  static Serializer<DNAExtensionsMove> get serializer =>
      _$dNAExtensionsMoveSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  BuiltList<DNAExtensionMove> get moves;

  Point<num> get start_point;

  Point<num> get current_point;

  bool get is_nontrivial => start_point != current_point;

  @memoized
  BuiltList<DNAEnd> get ends_moving =>
      [for (var end_move in moves) end_move.dna_end].build();

  Point<num> current_point_of(DNAEnd end) {
    for (DNAExtensionMove move in moves) {
      if (move.dna_end == end) {
        return current_point - start_point + move.original_position;
      }
    }
    return null;
  }
}

abstract class DNAExtensionMove
    with BuiltJsonSerializable
    implements Built<DNAExtensionMove, DNAExtensionMoveBuilder> {
  factory DNAExtensionMove(
      {DNAEnd dna_end,
      Color color,
      Point<num> original_position,
      Point<num> attached_end_position,
      Extension extension}
  ) = _$DNAExtensionMove._;

  factory DNAExtensionMove.from(
      [void Function(DNAExtensionMoveBuilder) updates]) = _$DNAExtensionMove;

  DNAExtensionMove._();

  static Serializer<DNAExtensionMove> get serializer =>
      _$dNAExtensionMoveSerializer;

  /************************ end BuiltValue boilerplate ************************/

  DNAEnd get dna_end;

  Color get color;

  Point<num> get original_position;

  Point<num> get attached_end_position;
  
  Extension get extension;
}
