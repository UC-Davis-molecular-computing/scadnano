import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:scadnano/src/state/strand.dart';

import '../serializers.dart';
import 'domain.dart';
import 'design.dart';
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
      BuiltMap<int, Helix> helices,
      BuiltList<int> helices_view_order,
      BuiltMap<int, int> helices_view_order_inverse,
      bool copy = false,
      bool keep_color = true}) {
    var strands_fixed =
        copy ? all_strands : [for (var strand in all_strands) if (!strands_moving.contains(strand)) strand];
    return StrandsMove.from((b) => b
      ..strands_moving.replace(strands_moving)
      ..strands_fixed.replace(strands_fixed)
      ..helices.replace(helices)
      ..helices_view_order.replace(helices_view_order)
      ..helices_view_order_inverse.replace(helices_view_order_inverse)
      ..original_address.replace(original_address)
      ..current_address.replace(original_address)
      ..copy = copy
      ..keep_color = keep_color
      ..allowable = true);
  }

  /************************ end BuiltValue boilerplate ************************/
  @memoized
  int get hashCode;

  BuiltList<Strand> get strands_moving;

  BuiltList<Strand> get strands_fixed;

  Address get original_address;

  Address get current_address;

  Helix get original_helix => helices[original_address.helix_idx];

  Helix get current_helix => helices[current_address.helix_idx];

  bool get allowable;

  bool get copy;

  bool get keep_color;

  BuiltMap<int, Helix> get helices;

  BuiltList<int> get helices_view_order;

  BuiltMap<int, int> get helices_view_order_inverse;

  int get num_helices => helices.length;

  int get delta_offset => current_address.offset - original_address.offset;

  int get delta_view_order => current_helix.view_order - original_helix.view_order;

  bool get delta_forward => current_address.forward != original_address.forward;

  bool get is_nontrivial => original_address != current_address;

  @memoized
  BuiltMap<int, BuiltList<Domain>> get helix_idx_to_substrands_moving =>
      construct_helix_idx_to_substrands_map(strands_moving, helices.keys);

  @memoized
  BuiltMap<int, BuiltList<Domain>> get helix_idx_to_substrands_fixed =>
      construct_helix_idx_to_substrands_map(strands_fixed, helices.keys);

  @memoized
  BuiltList<int> get view_order_moving {
    Set<int> ret = {};
    for (var strand in strands_moving) {
      for (var ss in strand.domains()) {
        ret.add(helices_view_order_inverse[ss.helix]);
      }
    }
    return ret.toBuiltList();
  }
}
