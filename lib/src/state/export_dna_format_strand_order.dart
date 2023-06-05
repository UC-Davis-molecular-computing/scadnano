import 'dart:typed_data';
import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

import 'export_dna_format.dart';
import '../util.dart' as util;

part 'export_dna_format_strand_order.g.dart';

class StrandOrder extends EnumClass {
  const StrandOrder._(String name) : super(name);

  static Serializer<StrandOrder> get serializer => _$strandOrderSerializer;

  static const StrandOrder five_prime = _$five_prime;
  static const StrandOrder three_prime = _$three_prime;
  static const StrandOrder five_or_three_prime = _$five_or_three_prime;
  static const StrandOrder top_left_domain_start = _$top_left_domain_start;

  static BuiltSet<StrandOrder> get values => _$values;

  static StrandOrder valueOf(String name) => _$valueOf(name);

  static const Map<StrandOrder, String> _toString_map = {
    five_prime: "5'",
    three_prime: "3'",
    five_or_three_prime: "5' or 3'",
    top_left_domain_start: "top left domain",
  };

  String toString() => _toString_map[this];

  /// Inverse of toString()
  static StrandOrder fromString(String str) {
    for (var format in _toString_map.keys) {
      String val_str = _toString_map[format];
      if (val_str == str) {
        return format;
      }
    }
    throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }
}
