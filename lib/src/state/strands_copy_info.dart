import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'design.dart';
import 'strand.dart';
import 'address.dart';
import 'strands_move.dart';
import '../reducers/strands_move_reducer.dart' as strands_move_reducer;

part 'strands_copy_info.g.dart';

// Represents information recorded in AppState when Ctrl+C is pressed and strands are selected
// (not including text copied to system clipboard, which is handled by
// copy_selected_object_text_to_system_clipboard_middleware)
abstract class StrandsCopyInfo
    with BuiltJsonSerializable
    implements Built<StrandsCopyInfo, StrandsCopyInfoBuilder> {
  factory StrandsCopyInfo.from([void Function(StrandsCopyInfoBuilder) updates]) = _$StrandsCopyInfo;

  StrandsCopyInfo._();

  static Serializer<StrandsCopyInfo> get serializer => _$strandsCopyInfoSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  // strands to copy; after several pastes, these remain the originally copied strands
  BuiltList<Strand> get strands;

  // Address of originally copied strands
  Address get original_address;

  // Address of most recently pasted strands,
  // or originally copied strands if no paste has happened yet
  Address get current_address;

  BuiltList<int> get helices_view_order;

  BuiltMap<int, int> get helices_view_order_inverse;

  @nullable
  AddressDifference get translation;

  // next address to paste into (no strands exist at this Address yet)
  @nullable
  Address get next_address {
    return translation == null
        ? null
        : current_address.sum(translation, helices_view_order, helices_view_order_inverse);
  }

  factory StrandsCopyInfo({
    BuiltList<Strand> strands,
    Address original_address,
    AddressDifference translation,
    BuiltList<int> helices_view_order,
    BuiltMap<int, int> helices_view_order_inverse,
  }) {
    return StrandsCopyInfo.from((b) => b
      ..strands.replace(strands)
      ..original_address.replace(original_address)
      ..current_address.replace(original_address)
      ..translation = translation?.toBuilder()
      ..helices_view_order.replace(helices_view_order)
      ..helices_view_order_inverse.replace(helices_view_order_inverse));
  }

  StrandsCopyInfo move_to_next(Design design) {
    assert(has_translation());

    if (next_translation_in_bounds_and_legal(design)) {
      return rebuild((b) => b..current_address.replace(next_address));
    } else {
      return this; //rebuild((b) => b..translation = null);
    }
  }

  bool has_translation() => translation != null;

  /// Indicates if
  bool next_translation_in_bounds_and_legal(Design design) {
    var strands_move = create_strands_move(design);
    bool in_bounds_and_legal = strands_move_reducer.in_bounds(design, strands_move) &&
        strands_move_reducer.is_allowable(design, strands_move);
    return in_bounds_and_legal;
  }

  StrandsMove create_strands_move(Design design) {
    var strands_move = StrandsMove(
      all_strands: design.strands,
      strands_moving: strands,
      helices: design.helices,
      groups: design.groups,
      original_address: original_address,
      copy: true,
      keep_color: true, // this won't really get used here
    );
    strands_move = strands_move.rebuild((b) => b..current_address.replace(next_address));
    return strands_move;
  }
}
