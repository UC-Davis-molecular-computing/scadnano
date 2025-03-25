import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'app_state.dart';
import 'design.dart';
import 'strand.dart';
import 'address.dart';
import 'strands_move.dart';
import '../reducers/strands_move_reducer.dart' as strands_move_reducer;

part 'copy_info.g.dart';

/*
autopaste rules:

copied_address
last_paste_address
next_paste_address

Possible scenarios:
1. description:    No copied strands
   desired effect: paste and autopaste do nothing
   how to detect:  clipboard cannot be parsed with strand information

2. description:    copied strands can be pasted into "original" position (where helix_idx may have changed)
   desired effect: autopaste goes in original position, paste goes anywhere user chooses
   how to detect:  copied strands
*/

// Represents information recorded in AppState when Ctrl+C is pressed and strands are selected
// (not including text copied to system clipboard, which is handled by
// copy_selected_object_text_to_system_clipboard_middleware)
abstract class CopyInfo with BuiltJsonSerializable implements Built<CopyInfo, CopyInfoBuilder> {
  factory CopyInfo.from([void Function(CopyInfoBuilder) updates]) = _$CopyInfo;

  CopyInfo._();

  static Serializer<CopyInfo> get serializer => _$copyInfoSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  // strands to copy; after several pastes, these remain the originally copied strands
  BuiltList<Strand> get strands;

  // Address of originally copied strands
  Address get copied_address;

  // Address of most recently pasted strands,
  // or originally copied strands if no paste has happened yet
  Address? get prev_paste_address;

  AddressDifference? get translation;

  // next address to paste into (no strands exist at this Address yet)
  Address? get next_paste_address => this.translation == null || this.prev_paste_address == null
      ? null
      : prev_paste_address!.sum(this.translation!, helices_view_order, helices_view_order_inverse);

  // first address to paste into based on translation
  Address? get first_paste_address => this.translation == null
      ? null
      : copied_address.sum(this.translation!, helices_view_order, helices_view_order_inverse);

  BuiltList<int> get helices_view_order;

  BuiltMap<int, int> get helices_view_order_inverse;

  factory CopyInfo({
    required BuiltList<Strand> strands,
    required Address copied_address,
    required AddressDifference? translation,
    required BuiltList<int> helices_view_order,
    required BuiltMap<int, int> helices_view_order_inverse,
  }) {
    return CopyInfo.from((b) => b
      ..strands.replace(strands)
      ..copied_address.replace(copied_address)
      ..translation = translation?.toBuilder()
      ..helices_view_order.replace(helices_view_order)
      ..helices_view_order_inverse.replace(helices_view_order_inverse));
  }

  CopyInfo move_to_next(AppState state) {
    assert(has_translation());

    if (next_translation_in_bounds_and_legal(state)) {
      return rebuild((b) => b..prev_paste_address = this.next_paste_address?.toBuilder());
    } else {
      return this;
    }
  }

  bool has_translation() => translation != null;

  bool next_translation_in_bounds_and_legal(AppState state) {
    if (translation == null) {
      return false;
    }
    var strands_move = create_strands_move(state);
    bool in_bounds_and_legal = strands_move_reducer.in_bounds(state.design, strands_move) &&
        strands_move_reducer.is_allowable(state.design, strands_move);
    return in_bounds_and_legal;
  }

  /// if [start_at_copied] is true, then current_address will be set to original_address
  /// (useful when pasting into a new Design where copied strands don't exist anymore,
  /// so useful to paste to same location as original)
  /// otherwise current_address set to original_address + translation
  StrandsMove create_strands_move(AppState state, {bool start_at_copied = false}) {
    var design = state.design;
    var strands_move = StrandsMove(
      all_strands: design.strands,
      strands_moving: strands,
      helices: design.helices,
      groups: design.groups,
      original_helices_view_order_inverse: helices_view_order_inverse,
      original_address: copied_address,
      copy: true,
      keep_color: state.ui_state.strand_paste_keep_color,
    );
    if (translation != null && prev_paste_address != null && !start_at_copied) {
      // If we've already pasted (prev_paste_address is defined) and translation is defined,
      // and we are not pasting in the original copied address,
      // then we should paste into next_paste_address (calculated from translation and prev_paste_address)
      strands_move = strands_move.rebuild((b) => b..current_address.replace(this.next_paste_address!));
    } else if (translation != null && !start_at_copied) {
      // If we have not yet pasted, but translation is defined,
      // and we are not starting at original copied address,
      // then paste into copied_address + translation
      strands_move = strands_move.rebuild((b) => b..current_address.replace(this.first_paste_address!));
    }
    return strands_move;
  }
}
