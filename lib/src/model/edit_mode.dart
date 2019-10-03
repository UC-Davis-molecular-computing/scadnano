import 'package:w_flux/w_flux.dart';
import '../dispatcher/actions.dart';

class EditModeChoice {
  final String _name;

  static final EditModeChoice select = EditModeChoice('Select');
  static final EditModeChoice pencil = EditModeChoice('Pencil');
  static final EditModeChoice nick = EditModeChoice('Nick');
  static final EditModeChoice ligate = EditModeChoice('Ligate');
  static final EditModeChoice insertion = EditModeChoice('Insertion');
  static final EditModeChoice deletion = EditModeChoice('Deletion');
  static final EditModeChoice sequence = EditModeChoice('Sequence');
  static final EditModeChoice backbone_rotation = EditModeChoice('Backbone');
  static final EditModeChoice python_editor = EditModeChoice('Python');

  EditModeChoice(this._name);

  String get name => this._name;

  String toString() => this._name;
}

class EditModeStore extends Store {
  EditModeChoice mode = EditModeChoice.select;

  EditModeStore() {
    triggerOnActionV2<EditModeChoice>(Actions.set_edit_mode, (new_mode) {
      this.mode = new_mode;
    });
  }
}

class EditModeActionPack extends ActionPack {
  EditModeActionPack(EditModeChoice mode) : super(Actions.set_edit_mode, mode);
}