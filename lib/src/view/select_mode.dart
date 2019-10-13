import 'package:over_react/over_react.dart';
import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:scadnano/src/model/select_mode.dart';

part 'select_mode.over_react.g.dart';

//TODO: check if design is a OrigamiDNADesign; if not, don't display scaffold/staple select modes

@Factory()
UiFactory<SelectModeProps> SelectMode = _$SelectMode;

@Props()
class _$SelectModeProps extends FluxUiProps<SelectModeStore, SelectModeStore> {}

@Component()
class SelectModeComponent extends FluxUiComponent<SelectModeProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    return (Dom.div())([
      (Dom.label()..key = 'label')('Select:'),
      ..._choice_buttons(),
    ]);
  }

  _choice_buttons() => [for (var choice in SelectModeChoice.values) this._choice_button(choice)];

  ReactElement _choice_button(SelectModeChoice mode) {
    return (Dom.button()
      ..onClick = ((_) => Actions.toggle_select_mode(mode))
      ..className = 'select-mode-button ' +
          (this.props.store.modes.contains(mode) ? 'select-mode-button-selected' : 'select-mode-button-unselected')
      ..key = mode.name)(mode.name);
  }
}
