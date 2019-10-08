import 'package:w_flux/w_flux.dart';
import '../dispatcher/actions.dart';

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

  EditModeChoice._(this.name);

  String toString() => 'EditModeChoice(${this.name})';
}

class EditModeStore extends Store {
  EditModeChoice mode = EditModeChoice.select;

  EditModeStore() {
    triggerOnActionV2<EditModeChoice>(Actions.set_edit_mode, (new_mode) {
      this.mode = new_mode;
    });
  }
}

//class EditModeActionPack extends ActionPack {
//  EditModeActionPack(EditModeChoice mode) : super(Actions.set_edit_mode, mode);
//}