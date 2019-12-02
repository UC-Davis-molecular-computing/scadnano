
import 'package:built_value/built_value.dart';

import '../app.dart';
import '../json_serializable.dart';
import 'bound_substrand.dart';
import 'loopout.dart';
import 'selectable.dart';
import 'strand.dart';
import '../constants.dart' as constants;

abstract class Substrand implements JSONSerializable {
  // for efficiency but not serialized since it would introduce a JSON cycle
//  Strand strand;

  int dna_length();

  bool is_loopout();

  bool is_bound_substrand() => !this.is_loopout();

  String get dna_sequence;

  Substrand set_dna_sequence(String seq);

  toJson();
}
