import 'package:w_flux/w_flux.dart';

import '../middleware/local_storage_middleware.dart' as local_storage;
import '../actions/actions_OLD.dart';

class EditModeChoice {
  final String name;

  static final select = EditModeChoice._('Select');
  static final pencil = EditModeChoice._('Pencil');
  static final nick = EditModeChoice._('Nick');
  static final ligate = EditModeChoice._('Ligate');
  static final insertion = EditModeChoice._('Insertion');
  static final deletion = EditModeChoice._('Deletion');
  static final sequence = EditModeChoice._('Sequence');
  static final backbone_rotation = EditModeChoice._('Backbone');
  static final python_editor = EditModeChoice._('Python');

  static List<EditModeChoice> values = [
    select,
    pencil,
    nick,
    ligate,
    insertion,
    deletion,
    sequence,
    backbone_rotation,
    python_editor
  ];

  EditModeChoice._(this.name);

  factory EditModeChoice.from_json(String the_name) {
    for (var val in values) {
      if (val.name == the_name) {
        return val;
      }
    }
    throw ArgumentError('there is no Edit Mode with name "${the_name}"');
  }

  String toString() => 'EditModeChoice(${this.name})';
}

class EditModeStore extends Store {
  EditModeChoice mode = EditModeChoice.select;

  EditModeStore() {
    handle_actions();
  }

  String to_json() {
    return mode.name;
  }

  void handle_actions() {
    triggerOnActionV2<EditModeChoice>(Actions_OLD.set_edit_mode, (new_mode) {
      //FIXME: implement this
      //      this.mode = new_mode;
//      local_storage.save(local_storage.Storable.edit_mode);
    });
  }
}
