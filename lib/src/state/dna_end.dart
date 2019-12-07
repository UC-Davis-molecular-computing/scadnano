
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';
import 'select_mode.dart';
import 'selectable.dart';

part 'dna_end.g.dart';

abstract class DNAEnd with Selectable, BuiltJsonSerializable implements Built<DNAEnd, DNAEndBuilder> {
  factory DNAEnd({int offset, bool is_5p, bool substrand_is_first, bool substrand_is_last, String substrand_id}) =>
      DNAEnd.from((b) => b
        ..offset = offset
        ..is_5p = is_5p
        ..substrand_is_first = substrand_is_first
        ..substrand_is_last = substrand_is_last
        ..substrand_id = substrand_id);

  factory DNAEnd.from([void Function(DNAEndBuilder) updates]) = _$DNAEnd;

  DNAEnd._();

  static Serializer<DNAEnd> get serializer => _$dNAEndSerializer;

  /************************ end BuiltValue boilerplate ************************/

  int get offset;

  bool get is_5p;

  bool get substrand_is_first;

  bool get substrand_is_last;

  String get substrand_id;

//  DNAEnd(this.is_5p, this.substrand_is_first, this.substrand_is_last, this.substrand_id);

  SelectModeChoice select_mode() {
    if (is_5p) {
      if (substrand_is_first) {
        return SelectModeChoice.end_5p_strand;
      } else {
        return SelectModeChoice.end_5p_substrand;
      }
    } else {
      if (substrand_is_last) {
        return SelectModeChoice.end_3p_strand;
      } else {
        return SelectModeChoice.end_3p_substrand;
      }
    }
  }

  String id() => 'end-' + (is_5p ? '5p' : '3p') + '-' + substrand_id;
}
