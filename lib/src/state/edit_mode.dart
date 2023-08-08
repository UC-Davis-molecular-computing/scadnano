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
        return '(s)';
      case rope_select:
        return '(r)';
      case pencil:
        return '(p)';
      case nick:
        return '(n)';
      case ligate:
        return '(l)';
      case insertion:
        return '(i)';
      case deletion:
        return '(d)';
      case move_group:
        return '(m)';
    }
    return super.toString();
  }

  @memoized
  String get tooltip {
    // tooltip descriptions
    switch (this) {
      case select:
        return '''\
(s)elect: This is similar to the Select edit mode in cadnano. It allows one to
select one or more items and delete, move, or copy/paste them. Which are 
allowed to be selected depends on the "Select Mode", shown when in select edit 
mode or rope select edit mode. By holding Shift or Ctrl and click-dragging,
a rectangular box can be drawn that will select everything in the box.''';
      case rope_select:
        return '''\
(r)ope select: This is similar to select mode, but when holding Shift or Ctrl, 
it allows one to draw a general polygon (a "rope"), rather than just a 
rectangle. This is useful, for example, for selecting many objects along a
diagonal, where a rectangle containing all of them would also contain many
objects off the diagonal that are not intended to be selected.''';
      case pencil:
        return '''\
(p)encil: Allows one to add new Strands (with a single domain) by clicking and dragging.''';
      case nick:
        return '''\
(n)ick: Clicking on a bound domain will split it into two at that position.''';
      case ligate:
        return '''\
(l)igate: If two bound domains point in the same direction and have abutting
5'/3' ends, then clicking on either will join them into a single strand.''';
      case insertion:
        return '''\
(i)nsertion: Clicking on a bound domain adds an insertion at that offset.
Clicking an existing insertion removes it.''';
      case deletion:
        return '''\
(d)eletion: Clicking on a bound domain adds a deletion at that offset.
Clicking an existing deletion removes it.''';
      case move_group:
        return '''\
(m)ove group: This mode allows one to translate the currently selected helix
group in the main view by clicking and dragging (i.e., to change its
position.x and position.y coordinates, which can also be set manually under
the menu Group → adjust current group). When in this mode, press either the
Ctrl (Cmd on Mac) or Shift key and then click+drag with the cursor. (Without
pressing Ctrl or Shift, the normal panning of the view will occur, without
changing the position of any helix group.)''';
    }
    return super.toString();
  }

  @override
  String toString() => display_name();

  @memoized
  String get image_file {
    // edit this to display a different string than the identifier name above
    switch (this) {
      case select:
        return 'images/edit_mode_icons/select.svg';
      case rope_select:
        return 'images/edit_mode_icons/rope_select.svg';
      case pencil:
        return 'images/edit_mode_icons/pencil.svg';
      case nick:
        return 'images/edit_mode_icons/nick.svg';
      case ligate:
        return 'images/edit_mode_icons/ligate.svg';
      case insertion:
        return 'images/edit_mode_icons/insertion.svg';
      case deletion:
        return 'images/edit_mode_icons/deletion.svg';
      case move_group:
        return 'images/edit_mode_icons/move_group.svg';
    }
    return '';
  }

  static EditModeChoice from_json(String the_name) {
    for (var val in values) {
      if (val.name == the_name) {
        return val;
      }
    }
    throw ArgumentError('there is no Edit Mode with name "${the_name}"');
  }
}
