import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import '../extension_methods.dart';
import '../serializers.dart';

import 'package:built_value/built_value.dart';

part 'address.g.dart';

// "Address" of a base; (helix, offset, direction)
// can be treated like a vector, i.e., difference between Addresses is itself an Address
abstract class Address with BuiltJsonSerializable implements Built<Address, AddressBuilder> {
  factory Address({int helix_idx, int offset, bool forward}) = _$Address._;

  factory Address.from([void Function(AddressBuilder) updates]) = _$Address;

  Address._();

  static Serializer<Address> get serializer => _$addressSerializer;

  /************************ end BuiltValue boilerplate ************************/

  int get helix_idx;

  int get offset;

  bool get forward;

  String toString() => 'H${helix_idx}-${forward ? "F" : "R"}-${offset}';

  Address sum(AddressDifference diff, BuiltList<int> helices_view_order,
      BuiltMap<int, int> helices_view_order_inverse) {
    int order_this = helices_view_order_inverse[helix_idx];
    int order_sum = order_this + diff.helix_idx_delta;

    // if off the end, compute as though there are more helices there with indices
    // greater than any in helices_view_order
    int helix_idx_sum;
    if (order_sum < helices_view_order.length) {
      helix_idx_sum = helices_view_order[order_sum];
    } else {
      int max_helix_idx = helices_view_order.max;
      helix_idx_sum = max_helix_idx + order_sum - helices_view_order.length + 1;
    }

    int offset_sum = offset + diff.offset_delta;

    bool forward_sum = forward;
    if (diff.forward_delta) {
      forward_sum = !forward_sum;
    }

    return Address(helix_idx: helix_idx_sum, offset: offset_sum, forward: forward_sum);
  }

  AddressDifference difference(Address other, BuiltMap<int, int> helices_view_order_inverse) {
    int order_this = helices_view_order_inverse[helix_idx];
    int order_other = helices_view_order_inverse[other.helix_idx];
    int helix_idx_delta = order_this - order_other;
    int offset_delta = offset - other.offset;
    bool forward_delta = (forward != other.forward);
    return AddressDifference(
        helix_idx_delta: helix_idx_delta, offset_delta: offset_delta, forward_delta: forward_delta);
  }
}

// represents a difference between two addresses
abstract class AddressDifference
    with BuiltJsonSerializable
    implements Built<AddressDifference, AddressDifferenceBuilder> {
  factory AddressDifference({int helix_idx_delta, int offset_delta, bool forward_delta}) =
      _$AddressDifference._;

  factory AddressDifference.from([void Function(AddressDifferenceBuilder) updates]) = _$AddressDifference;

  AddressDifference._();

  static Serializer<AddressDifference> get serializer => _$addressDifferenceSerializer;

  /************************ end BuiltValue boilerplate ************************/

  // not really the difference between helix idx's; is the distance between their view orders
  int get helix_idx_delta;

  int get offset_delta;

  bool get forward_delta;

  String toString() => 'diff-H${helix_idx_delta}-${forward_delta ? "F" : "R"}-${offset_delta}';

  AddressDifference times(int multiplier) {
    bool forward_delta_new = false;
    if (forward_delta && multiplier % 2 == 1) {
      forward_delta_new = true;
    }
    return AddressDifference(
        helix_idx_delta: helix_idx_delta * multiplier,
        offset_delta: offset_delta * multiplier,
        forward_delta: forward_delta_new);
  }
}
