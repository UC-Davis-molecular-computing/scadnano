
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

  @nullable
  String get dna_sequence;

  set_dna_sequence(String seq);

  /// Order this substrand appears in the Strand
//  int order() => strand.substrands.indexOf(this);

//  handle_actions();

  register_selectables(SelectablesStore store);
}
