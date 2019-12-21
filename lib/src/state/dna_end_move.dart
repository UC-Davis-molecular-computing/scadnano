import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'dna_end.dart';

part 'dna_end_move.g.dart';

abstract class DNAEndsMove with BuiltJsonSerializable implements Built<DNAEndsMove, DNAEndsMoveBuilder> {
  factory DNAEndsMove({BuiltList<DNAEndMove> moves, int start_offset, int current_offset}) = _$DNAEndsMove._;

  factory DNAEndsMove.from([void Function(DNAEndsMoveBuilder) updates]) = _$DNAEndsMove;

  DNAEndsMove._();

  static Serializer<DNAEndsMove> get serializer => _$dNAEndsMoveSerializer;

  /************************ end BuiltValue boilerplate ************************/

  BuiltList<DNAEndMove> get moves;

  // starting offset (in units of bases) where mouse was when we started moving
  int get start_offset;

  // current offset where mouse is
  // (note that some ends have offset different from start_offset, but we are trying to move all of them
  // by current_offset - start_offset, assuming that won't be too far for any of them)
  int get current_offset;
}

abstract class DNAEndMove with BuiltJsonSerializable implements Built<DNAEndMove, DNAEndMoveBuilder> {
  factory DNAEndMove({DNAEnd dna_end, int lowest_offset, int highest_offset, int current_offset}) =
      _$DNAEndMove._;

  factory DNAEndMove.from([void Function(DNAEndMoveBuilder) updates]) = _$DNAEndMove;

  DNAEndMove._();

  static Serializer<DNAEndMove> get serializer => _$dNAEndMoveSerializer;

  /************************ end BuiltValue boilerplate ************************/

  DNAEnd get dna_end;

  // lowest offset we can assign before end would run into other ends
  int get lowest_offset;

  // largest offset we can assign before end would run into other ends
  int get highest_offset;

  // current offset for after movement is executed (if different from dna_end.offset, it will actually move)
  int get current_offset;
}
