import 'package:over_react/over_react.dart';

import '../state/edit_mode.dart';

part 'edit_mode.over_react.g.dart';

@Factory()
UiFactory<EditModeProps> EditMode = _$EditMode;

@Props()
class _$EditModeProps extends UiProps {
  EditModeChoice mode;
}

@Component2()
class EditModeComponent extends UiComponent2<EditModeProps> {
  @override
  render() {
    return (Dom.div())([for (var choice in EditModeChoice.values) this._button_for_choice(choice)]);
  }

  ReactElement _button_for_choice(EditModeChoice mode) {
    return (Dom.button()
//      ..onClick = ((_) => Actions_OLD.set_edit_mode(mode))
      ..className = 'mode-button ' + (props.mode == mode ? 'edit-mode-button-selected' : 'edit-mode-button-unselected')
      ..key = mode.name)(mode.name);
  }
}
