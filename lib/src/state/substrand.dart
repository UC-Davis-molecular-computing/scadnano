

import '../json_serializable.dart';
import 'strand_part.dart';

abstract class Substrand implements JSONSerializable, StrandPart {
  // for efficiency but not serialized since it would introduce a JSON cycle
//  Strand strand;

  int dna_length();

  bool is_loopout();

  bool is_bound_substrand() => !this.is_loopout();

  String get dna_sequence;

  Substrand set_dna_sequence(String seq);

  toJson();
}
