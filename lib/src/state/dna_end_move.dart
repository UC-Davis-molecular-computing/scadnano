import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'dna_end.dart';
import 'helix.dart';
import 'strand.dart';

part 'dna_end_move.g.dart';

abstract class DNAEndsMove with BuiltJsonSerializable implements Built<DNAEndsMove, DNAEndsMoveBuilder> {
  factory DNAEndsMove(
      {BuiltList<DNAEndMove> moves,
      int original_offset,
      int current_offset,
      Helix helix,
      BuiltSet<Strand> strands_affected}) = _$DNAEndsMove._;

  factory DNAEndsMove.from([void Function(DNAEndsMoveBuilder) updates]) = _$DNAEndsMove;

  DNAEndsMove._();

  static Serializer<DNAEndsMove> get serializer => _$dNAEndsMoveSerializer;

  /************************ end BuiltValue boilerplate ************************/

  @nullable
  BuiltList<DNAEndMove> get moves;

  BuiltSet<Strand> get strands_affected;

  // starting offset (in units of bases) where mouse was when we started moving
  int get original_offset;

  // helix where dragging started
  Helix get helix;

  // current offset where mouse is
  // (note that some ends have offset different from start_offset, but we are trying to move all of them
  // by current_offset - start_offset, assuming that won't be too far for any of them)
  int get current_offset;

  // if false, we wouldn't actually move anything
  bool get is_nontrivial => current_offset != original_offset;
}

abstract class DNAEndMove with BuiltJsonSerializable implements Built<DNAEndMove, DNAEndMoveBuilder> {
  factory DNAEndMove({DNAEnd dna_end, int lowest_offset, int highest_offset, int current_offset}) =
      _$DNAEndMove._;

  factory DNAEndMove.from([void Function(DNAEndMoveBuilder) updates]) = _$DNAEndMove;

  DNAEndMove._();

  static Serializer<DNAEndMove> get serializer => _$dNAEndMoveSerializer;

  /************************ end BuiltValue boilerplate ************************/

  DNAEnd get dna_end;

  // lowest offset we can assign before end would run into other ends; if null, no bound
  @nullable
  int get lowest_offset;

  // largest offset we can assign before end would run into other ends; if null, no bound
  @nullable
  int get highest_offset;

  // current offset for after movement is executed (if different from dna_end.offset, it will actually move)
  int get current_offset;
}
