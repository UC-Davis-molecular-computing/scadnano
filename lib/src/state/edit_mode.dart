
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

class EditModeStore {
  EditModeChoice mode = EditModeChoice.select;

  EditModeStore() {
  }

  String to_json() {
    return mode.name;
  }


}
