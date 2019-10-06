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
    return (Dom.div())(
      this._button_for_choice(EditModeChoice.select),
      this._button_for_choice(EditModeChoice.pencil),
      this._button_for_choice(EditModeChoice.nick),
      this._button_for_choice(EditModeChoice.ligate),
      this._button_for_choice(EditModeChoice.insertion),
      this._button_for_choice(EditModeChoice.deletion),
      this._button_for_choice(EditModeChoice.sequence),
      this._button_for_choice(EditModeChoice.backbone_rotation),
      this._button_for_choice(EditModeChoice.python_editor),
    );
  }

  ReactElement _button_for_choice(EditModeChoice mode) {
    return (Dom.button()
      ..onClick = ((_) => _change_mode(mode))
      ..className = 'mode-button ' +
          (this.props.store.mode == mode
              ? 'mode-button-selected'
              : 'mode-button-unselected'))(mode.name);
  }

  _change_mode(EditModeChoice mode) {
    Actions.set_edit_mode(mode);
//    app.send_action(ActionPack(Actions.set_edit_mode, mode));
  }
}
