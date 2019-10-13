import 'package:over_react/over_react.dart';
import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:scadnano/src/model/edit_mode.dart';

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
      ..onClick = ((_) => Actions.set_edit_mode(mode))
      ..className = 'edit-mode-button ' +
          (this.props.store.mode == mode ? 'edit-mode-button-selected' : 'edit-mode-button-unselected')
      ..key = mode.name)(mode.name);
  }
}
