import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'strand.dart';
import 'group.dart';
import 'helix.dart';
import 'address.dart';

part 'strands_move.g.dart';

abstract class StrandsMove with BuiltJsonSerializable implements Built<StrandsMove, StrandsMoveBuilder> {
  factory StrandsMove.from([void Function(StrandsMoveBuilder) updates]) = _$StrandsMove;

  StrandsMove._();

  static Serializer<StrandsMove> get serializer => _$strandsMoveSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  factory StrandsMove(
      {required BuiltList<Strand> strands_moving,
      required BuiltList<Strand> all_strands,
      required BuiltMap<int, Helix> helices,
      required BuiltMap<String, HelixGroup> groups,
      required BuiltMap<int, int> original_helices_view_order_inverse,
      required Address original_address,
      bool copy = false,
      bool keep_color = true}) {
    var strands_fixed = copy
        ? all_strands
        : [
            for (var strand in all_strands)
              if (!strands_moving.contains(strand)) strand
          ];
    if (original_helices_view_order_inverse == null) {
      throw ArgumentError('original_helices_view_order_inverse must be specified');
    }
    return StrandsMove.from((b) => b
      ..strands_moving.replace(strands_moving)
      ..strands_fixed.replace(strands_fixed)
      ..helices.replace(helices)
      ..groups.replace(groups)
      ..original_helices_view_order_inverse.replace(original_helices_view_order_inverse)
      ..original_address.replace(original_address)
      ..current_address.replace(original_address)
      ..copy = copy
      ..keep_color = keep_color
      ..allowable = true);
  }

  BuiltList<Strand> get strands_moving;

  BuiltList<Strand> get strands_fixed;

  BuiltMap<int, Helix> get helices;

  BuiltMap<String, HelixGroup> get groups;

  // Since copied Strands may come from a different Design with different groups, we need to
  // store this to know how to position them in new HelixGroups.
  BuiltMap<int, int> get original_helices_view_order_inverse;

  Address get original_address;

  Address get current_address;

  bool get allowable;

  bool get copy;

  bool get keep_color;

  Helix get current_helix => helices[current_address.helix_idx]!;

  HelixGroup get current_group => groups[current_helix.group]!;

  int get original_view_order => original_helices_view_order_inverse[original_address.helix_idx]!;

  int get current_view_order => current_group.helices_view_order_inverse[current_helix.idx]!;

  int get delta_offset => current_address.offset - original_address.offset;

  int get delta_view_order => current_view_order - original_view_order;

  bool get delta_forward => current_address.forward != original_address.forward;

  bool get is_nontrivial => original_address != current_address;
}
