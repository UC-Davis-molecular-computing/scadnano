import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import '../state/strand.dart';

import '../serializers.dart';
import 'group.dart';
import 'helix.dart';

part 'strands_move.g.dart';

abstract class StrandsMove with BuiltJsonSerializable implements Built<StrandsMove, StrandsMoveBuilder> {
  factory StrandsMove.from([void Function(StrandsMoveBuilder) updates]) = _$StrandsMove;

  StrandsMove._();

  static Serializer<StrandsMove> get serializer => _$strandsMoveSerializer;

  factory StrandsMove(
      {BuiltList<Strand> strands_moving,
      BuiltList<Strand> all_strands,
      BuiltMap<int, Helix> helices,
      BuiltMap<String, HelixGroup> groups,
      Address original_address,
      bool copy = false,
      bool keep_color = true}) {
    var strands_fixed =
        copy ? all_strands : [for (var strand in all_strands) if (!strands_moving.contains(strand)) strand];
    return StrandsMove.from((b) => b
      ..strands_moving.replace(strands_moving)
      ..strands_fixed.replace(strands_fixed)
      ..helices.replace(helices)
      ..groups.replace(groups)
      ..original_address.replace(original_address)
      ..current_address.replace(original_address)
      ..copy = copy
      ..keep_color = keep_color
      ..allowable = true);
  }

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  BuiltList<Strand> get strands_moving;

  BuiltList<Strand> get strands_fixed;

  BuiltMap<int, Helix> get helices;

  BuiltMap<String, HelixGroup> get groups;

  Address get original_address;

  Address get current_address;

  bool get allowable;

  bool get copy;

  bool get keep_color;

  Helix get original_helix => helices[original_address.helix_idx];

  Helix get current_helix => helices[current_address.helix_idx];

  int get original_view_order => groups[original_helix.group].helices_view_order_inverse[original_helix.idx];

  int get current_view_order => groups[current_helix.group].helices_view_order_inverse[current_helix.idx];

  int get delta_offset => current_address.offset - original_address.offset;

  int get delta_view_order => current_view_order - original_view_order;

  bool get delta_forward => current_address.forward != original_address.forward;

  bool get is_nontrivial => original_address != current_address;
}
