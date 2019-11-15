import 'dart:math';

import 'package:built_value/built_value.dart';

import 'bound_substrand.dart';
import 'select_mode.dart';
import 'selectable.dart';

part 'dna_end.g.dart';

abstract class DNAEnd with Selectable implements Built<DNAEnd, DNAEndBuilder> {
  DNAEnd._();
  factory DNAEnd([void Function(DNAEndBuilder) updates]) = _$DNAEnd;
//}
//
///// This is needed to make the 5' and 3' ends selectable and listenable.
//class DNAEnd
//    with Selectable {
//  BoundSubstrand substrand;
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

  String id() => 'end-' + (is_5p? '5p': '3p') + '-' + substrand_id;
}
