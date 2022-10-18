import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:react/react.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/extension.dart';

import '../serializers.dart';

part 'dna_extensions_move.g.dart';

abstract class DNAExtensionsMove
    with BuiltJsonSerializable
    implements Built<DNAExtensionsMove, DNAExtensionsMoveBuilder> {
  factory DNAExtensionsMove({BuiltList<DNAExtensionMove> moves, Point<num> start_point, Point<num> current_point}) =
      _$DNAExtensionsMove._;

  factory DNAExtensionsMove.from([void Function(DNAExtensionsMoveBuilder) updates]) = _$DNAExtensionsMove;

  DNAExtensionsMove._();

  static Serializer<DNAExtensionsMove> get serializer => _$dNAExtensionsMoveSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  BuiltList<DNAExtensionMove> get moves;

  Point<num> get start_point;

  Point<num> get current_point;

  bool get is_nontrivial => start_point != current_point;
}

abstract class DNAExtensionMove
    with BuiltJsonSerializable
    implements Built<DNAExtensionMove, DNAExtensionMoveBuilder> {
  factory DNAExtensionMove({DNAEnd dna_end}) = _$DNAExtensionMove._;

  factory DNAExtensionMove.from([void Function(DNAExtensionMoveBuilder) updates]) = _$DNAExtensionMove;

  DNAExtensionMove._();

  static Serializer<DNAExtensionMove> get serializer => _$dNAExtensionMoveSerializer;

  /************************ end BuiltValue boilerplate ************************/

  DNAEnd get dna_end;
}