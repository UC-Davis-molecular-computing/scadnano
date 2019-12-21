import 'dart:html';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'edit_mode.g.dart';

class EditModeChoice extends EnumClass {
  const EditModeChoice._(String name) : super(name);

  static Serializer<EditModeChoice> get serializer => _$editModeChoiceSerializer;

  static const EditModeChoice select = _$select;
  static const EditModeChoice pencil = _$pencil; // used to join two BoundSubstrands with Crossover
  static const EditModeChoice nick = _$nick;
  static const EditModeChoice ligate = _$ligate; // means join two BoundSubstrands on same Helix
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
    KeyCode.S: select,
    KeyCode.P: pencil,
    KeyCode.N: nick,
    KeyCode.L: ligate,
    KeyCode.I: insertion,
    KeyCode.D: deletion,
    KeyCode.Q: sequence,
    KeyCode.B: backbone,
    KeyCode.O: loopout,
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

  //FIXME: this is an undirected graph but we are representing it as directed; make more DRY
  /// For a mode m, `m.excluded_modes()` is a set of other modes that are mutually exclusive with `m`.
  /// In other words, if `m` is on, then all those in `m.excluded_modes()` are turned off.
  @memoized
  BuiltSet<EditModeChoice> get excluded_modes {
    switch (this) {
      case select:
        return [pencil, loopout].toBuiltSet();
      case pencil:
        return [select, ligate].toBuiltSet();
      case nick:
        return [ligate, insertion, deletion, sequence].toBuiltSet();
      case ligate:
        return [pencil, nick, insertion, deletion, sequence].toBuiltSet();
      case insertion:
        return [nick, ligate, deletion, sequence].toBuiltSet();
      case deletion:
        return [nick, ligate, insertion, sequence].toBuiltSet();
      case sequence:
        return [nick, ligate, insertion, deletion].toBuiltSet();
      case backbone:
        return <EditModeChoice>[].toBuiltSet();
      case loopout:
        return [select].toBuiltSet();
      case helix:
        return <EditModeChoice>[].toBuiltSet();
      default:
        throw ArgumentError('${this} is not a valid EditModeChoice');
    }
  }

  String shortcut_key() => String.fromCharCodes([key_code()]);

  String to_json() => name;

  String display_name() {
    // edit this to display a different string than the identifier name above
    switch (this) {
      case select:
        return '(s)elect';
      case pencil:
        return '(p)encil';
      case nick:
        return '(n)ick';
      case ligate:
        return '(l)igate';
      case insertion:
        return '(i)nsertion';
      case deletion:
        return '(d)eletion';
      case sequence:
        return 'se(q)uence';
      case backbone:
        return '(b)ackbone';
      case loopout:
        return 'l(o)opout';
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
