import 'dart:html';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'edit_mode.g.dart';



class EditModeChoice extends EnumClass {
  const EditModeChoice._(String name) : super(name);

  @memoized
  int get hashCode;

  static Serializer<EditModeChoice> get serializer => _$editModeChoiceSerializer;

  /******************** end BuiltValue boilerplate *********************/

  static const EditModeChoice select = _$select;
  static const EditModeChoice rope_select = _$rope_select;
  static const EditModeChoice pencil = _$pencil; // used to join two Domains with Crossover
  static const EditModeChoice nick = _$nick;
  static const EditModeChoice ligate = _$ligate; // means join two Domains on same Helix
  static const EditModeChoice insertion = _$insertion;
  static const EditModeChoice deletion = _$deletion;
  static const EditModeChoice move_group = _$move_group;

//  static const EditModeChoice python = _$python;

  static BuiltSet<EditModeChoice> get values => _$values;

  static EditModeChoice valueOf(String name) => _$valueOf(name);

  static const Map<int, EditModeChoice> key_code_to_mode = {
    KeyCode.S: select,
    KeyCode.R: rope_select,
    KeyCode.P: pencil,
    KeyCode.N: nick,
    KeyCode.L: ligate,
    KeyCode.I: insertion,
    KeyCode.D: deletion,
    KeyCode.M: move_group,
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
        return [rope_select, pencil, nick, ligate, insertion, deletion, move_group].toBuiltSet();
      case rope_select:
        return [select, pencil, nick, ligate, insertion, deletion, move_group].toBuiltSet();
      case pencil:
        return [select, rope_select, ligate, move_group].toBuiltSet();
      case nick:
        return [select, rope_select, ligate, insertion, deletion, move_group].toBuiltSet();
      case ligate:
        return [select, rope_select, pencil, nick, insertion, deletion, move_group].toBuiltSet();
      case insertion:
        return [select, rope_select, nick, ligate, deletion, move_group].toBuiltSet();
      case deletion:
        return [select, rope_select, nick, ligate, insertion, move_group].toBuiltSet();
      case move_group:
        return [select, rope_select, pencil, nick, ligate, insertion, deletion].toBuiltSet();
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
      case rope_select:
        return '(r)ope select';
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
      case move_group:
        return '(m)ove group';
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
