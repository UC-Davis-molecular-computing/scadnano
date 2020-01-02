
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/state/strand.dart';

import '../serializers.dart';
import 'bound_substrand.dart';
import 'dna_design.dart';
import 'helix.dart';

part 'strands_move.g.dart';

abstract class StrandsMove with BuiltJsonSerializable implements Built<StrandsMove, StrandsMoveBuilder> {
  factory StrandsMove.from([void Function(StrandsMoveBuilder) updates]) = _$StrandsMove;

  StrandsMove._();

  static Serializer<StrandsMove> get serializer => _$strandsMoveSerializer;

  factory StrandsMove(
      {BuiltList<Strand> strands_moving,
      BuiltList<Strand> all_strands,
      int original_offset,
      Helix helix,
      BuiltList<Helix> helices,
      bool copy = false}) {
    var strands_fixed =
        copy ? all_strands : [for (var strand in all_strands) if (!strands_moving.contains(strand)) strand];
    return StrandsMove.from((b) => b
      ..strands_moving.replace(strands_moving)
      ..strands_fixed.replace(strands_fixed)
      ..helices.replace(helices)
      ..helix.replace(helix)
      ..original_offset = original_offset
      ..current_offset = original_offset
      ..copy = copy
      ..allowable = true);
  }

  /************************ end BuiltValue boilerplate ************************/

  BuiltList<Strand> get strands_moving;

  BuiltList<Strand> get strands_fixed;

  Helix get helix;

  int get original_offset;

  int get current_offset;

  bool get allowable;

  bool get copy;

  BuiltList<Helix> get helices;

  int get num_helices => helices.length;

  int get delta => current_offset - original_offset;

  bool get is_nontrivial => delta != 0;

  @memoized
  BuiltList<BuiltList<BoundSubstrand>> get helix_idx_to_substrands_moving =>
      construct_helix_idx_to_substrands_map(num_helices, strands_moving);

  @memoized
  BuiltList<BuiltList<BoundSubstrand>> get helix_idx_to_substrands_fixed =>
      construct_helix_idx_to_substrands_map(num_helices, strands_fixed);
}
