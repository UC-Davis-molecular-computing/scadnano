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
      Address original_address,
      int original_helix_idx,
      BuiltList<Helix> helices,
      bool copy = false}) {
    var strands_fixed =
        copy ? all_strands : [for (var strand in all_strands) if (!strands_moving.contains(strand)) strand];
    return StrandsMove.from((b) => b
      ..strands_moving.replace(strands_moving)
      ..strands_fixed.replace(strands_fixed)
      ..helices.replace(helices)
      ..original_address.replace(original_address)
      ..current_address.replace(original_address)
      ..copy = copy
      ..allowable = true);
  }

  /************************ end BuiltValue boilerplate ************************/

  BuiltList<Strand> get strands_moving;

  BuiltList<Strand> get strands_fixed;

  Address get original_address;

  Address get current_address;

  Helix get original_helix => helices[original_address.helix_idx];

  Helix get current_helix => helices[current_address.helix_idx];

  bool get allowable;

  bool get copy;

  BuiltList<Helix> get helices;

  int get num_helices => helices.length;

  int get delta_offset => current_address.offset - original_address.offset;

  int get delta_helix_idx => current_address.helix_idx - original_address.helix_idx;

  bool get delta_forward => current_address.forward != original_address.forward;

  bool get is_nontrivial => original_address != current_address;

  @memoized
  BuiltList<BuiltList<BoundSubstrand>> get helix_idx_to_substrands_moving =>
      construct_helix_idx_to_substrands_map(num_helices, strands_moving);

  @memoized
  BuiltList<BuiltList<BoundSubstrand>> get helix_idx_to_substrands_fixed =>
      construct_helix_idx_to_substrands_map(num_helices, strands_fixed);

  @memoized
  BuiltList<int> get helices_moving {
    Set<int> ret = {};
    for (var strand in strands_moving) {
      for (var ss in strand.bound_substrands()) {
        ret.add(ss.helix);
      }
    }
    return ret.toBuiltList();
  }
}
