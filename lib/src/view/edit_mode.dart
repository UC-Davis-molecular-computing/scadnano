import 'package:over_react/over_react.dart';

import '../state/edit_mode.dart';
import '../actions/actions_OLD.dart';
part 'edit_mode.over_react.g.dart';

@Factory()
UiFactory<EditModeProps> EditMode = _$EditMode;

@Props()
class _$EditModeProps extends FluxUiProps<EditModeStore, EditModeStore> {}

@Component()
class EditModeComponent extends FluxUiComponent<EditModeProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    return (Dom.div())([for (var choice in EditModeChoice.values) this._button_for_choice(choice)]);
  }

  ReactElement _button_for_choice(EditModeChoice mode) {
    return (Dom.button()
      ..onClick = ((_) => Actions_OLD.set_edit_mode(mode))
      ..className = 'mode-button ' +
          (this.props.store.mode == mode ? 'edit-mode-button-selected' : 'edit-mode-button-unselected')
      ..key = mode.name)(mode.name);
  }
}
