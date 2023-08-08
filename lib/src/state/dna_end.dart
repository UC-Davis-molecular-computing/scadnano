import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'select_mode.dart';
import 'selectable.dart';
import 'helix.dart';

part 'dna_end.g.dart';

abstract class DNAEnd with SelectableMixin, BuiltJsonSerializable implements Built<DNAEnd, DNAEndBuilder> {
  factory DNAEnd(
          {int offset,
          bool is_5p,
          bool is_start,
          bool substrand_is_first,
          bool substrand_is_last,
          String substrand_id,
          bool is_scaffold,
          bool is_on_extension}) =>
      DNAEnd.from((b) => b
        ..offset = offset
        ..is_5p = is_5p
        ..is_start = is_start
        ..substrand_is_first = substrand_is_first
        ..substrand_is_last = substrand_is_last
        ..substrand_id = substrand_id
        ..is_scaffold = is_scaffold
        ..is_on_extension = is_on_extension);

  factory DNAEnd.from([void Function(DNAEndBuilder) updates]) = _$DNAEnd;

  DNAEnd._();

  static Serializer<DNAEnd> get serializer => _$dNAEndSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  // null if an extension free end
  @nullable
  int get offset;

  // offset is exclusive if this is an end (right side); offset_inclusive is always the exact offset
  int get offset_inclusive => is_start ? offset : offset - 1;

  bool get is_5p;

  @memoized
  bool get is_3p => !is_5p;

  bool get is_start;

  bool get is_on_extension;

  bool get substrand_is_first;

  bool get substrand_is_last;

  String get substrand_id;

//  DNAEnd(this.is_5p, this.substrand_is_first, this.substrand_is_last, this.substrand_id);

  @memoized
  SelectModeChoice get select_mode {
    if (is_5p) {
      if (substrand_is_first) {
        return SelectModeChoice.end_5p_strand;
      } else {
        return SelectModeChoice.end_5p_domain;
      }
    } else {
      if (substrand_is_last) {
        return SelectModeChoice.end_3p_strand;
      } else {
        return SelectModeChoice.end_3p_domain;
      }
    }
  }

  @memoized
  String get id => 'end-' + (is_5p ? '5p' : '3p') + '-' + substrand_id;
}
