import 'dart:html';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'edit_mode.g.dart';

class EditModeChoice extends EnumClass {
  const EditModeChoice._(String name) : super(name);

  static Serializer<EditModeChoice> get serializer => _$editModeChoiceSerializer;

  static const EditModeChoice scroll = _$scroll;
  static const EditModeChoice select = _$select;
  static const EditModeChoice pencil = _$pencil;
  static const EditModeChoice nick = _$nick;
  static const EditModeChoice join = _$ligate; // previously "ligate"; means join two BoundSubstrands on same Helix
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
    KeyCode.C: scroll,
    KeyCode.S: select,
    KeyCode.P: pencil,
    KeyCode.N: nick,
    KeyCode.J: join,
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

  //FIXME: this is an undirected graph but we are representing it as directed; make more DRY
  /// For a mode m, `m.excluded_modes()` is a set of other modes that are mutually exclusive with `m`.
  /// In other words, if `m` is on, then all those in `m.excluded_modes()` are turned off.
  BuiltSet<EditModeChoice> excluded_modes() {
    switch (this) {
      case scroll:
        return [pencil, helix].toBuiltSet();
      case select:
        return [pencil, loopout].toBuiltSet();
      case pencil:
        return [select, scroll, join].toBuiltSet();
      case nick:
        return [join, insertion, deletion, sequence].toBuiltSet();
      case join:
        return [pencil, nick, insertion, deletion, sequence].toBuiltSet();
      case insertion:
        return [nick, join, deletion, sequence].toBuiltSet();
      case deletion:
        return [nick, join, insertion, sequence].toBuiltSet();
      case sequence:
        return [nick, join, insertion, deletion].toBuiltSet();
      case backbone:
        return <EditModeChoice>[].toBuiltSet();
      case loopout:
        return [select].toBuiltSet();
      case helix:
        return [scroll].toBuiltSet();
      default:
        throw ArgumentError('${this} is not a valid EditModeChoice');
    }
  }

  String shortcut_key() => String.fromCharCodes([key_code()]);

  String to_json() => name;

  String display_name() {
    // edit this to display a different string than the identifier name above
    switch (this) {
      case scroll:
        return 's(c)roll';
      case select:
        return '(s)elect';
      case pencil:
        return '(p)encil';
      case nick:
        return '(n)ick';
      case join:
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
