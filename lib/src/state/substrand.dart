import '../json_serializable.dart';
import 'strand_part.dart';

abstract class Substrand implements JSONSerializable, StrandPart {
  int dna_length();

  bool is_loopout();

  bool is_bound_substrand() => !this.is_loopout();

  String get dna_sequence;

  Substrand set_dna_sequence(String seq);

  toJson();
}
