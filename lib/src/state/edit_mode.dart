import 'dart:html';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'edit_mode.g.dart';

class EditModeChoice extends EnumClass {
  const EditModeChoice._(String name) : super(name);

  static Serializer<EditModeChoice> get serializer => _$editModeChoiceSerializer;

  static const EditModeChoice move = _$move;
  static const EditModeChoice select = _$select;
  static const EditModeChoice pencil = _$pencil;
  static const EditModeChoice nick = _$nick;
  static const EditModeChoice ligate = _$ligate;
  static const EditModeChoice insertion = _$insertion;
  static const EditModeChoice deletion = _$deletion;
  static const EditModeChoice sequence = _$sequence;
  static const EditModeChoice backbone = _$backbone;
  static const EditModeChoice loopout = _$loopout;
  static const EditModeChoice helix = _$helix;

//  static const EditModeChoice python = _$python;

  static BuiltSet<EditModeChoice> get values => _$values;

  static EditModeChoice valueOf(String name) => _$valueOf(name);

  static const Map<int, EditModeChoice> key_code_to_mode = {
    KeyCode.M: move,
    KeyCode.S: select,
    KeyCode.P: pencil,
    KeyCode.N: nick,
    KeyCode.J: ligate,
    KeyCode.I: insertion,
    KeyCode.D: deletion,
    KeyCode.Q: sequence,
    KeyCode.B: backbone,
    KeyCode.L: loopout,
    KeyCode.H: helix,
  };

  int key_code() {
    for (var key in key_code_to_mode.keys) {
      if (key_code_to_mode[key] == this) {
        return key;
      }
    }
    throw AssertionError('This should be unreachable.');
  }

  String to_json() => name;

  String display_name() {
    // edit this to display a different string than the identifier name above
    switch (this) {
      case move:
        return '(m)ove';
      case select:
        return '(s)elect';
      case pencil:
        return '(p)encil';
      case nick:
        return '(n)ick';
      case ligate:
        return '(j)oin';
      case insertion:
        return '(i)nsertion';
      case deletion:
        return '(d)eletion';
      case sequence:
        return 'se(q)uence';
      case backbone:
        return '(b)ackbone';
      case loopout:
        return '(l)oopout';
      case helix:
        return '(h)elix';
    }
    return super.toString();
  }

  @override
  String toString() => display_name();

  static EditModeChoice from_json(String the_name) {
    for (var val in values) {
      if (val.name == the_name) {
        return val;
      }
    }
    throw ArgumentError('there is no Edit Mode with name "${the_name}"');
  }
}
