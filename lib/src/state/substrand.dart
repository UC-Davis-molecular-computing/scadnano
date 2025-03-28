import 'package:color/color.dart';

import '../json_serializable.dart';
import 'strand.dart';
import 'strand_part.dart';

abstract class Substrand implements JSONSerializable, StrandPart {
  int dna_length();

  bool is_loopout();

  bool is_domain();

  bool is_extension();

  String? get dna_sequence;

  Substrand set_dna_sequence(String? seq);

  toJson();

  String? get name;

  String? get label;

  String type_description();

  String get id;

  Color? get color;

  toBuilder();
}
