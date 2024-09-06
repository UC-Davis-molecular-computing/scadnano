// @dart=2.9
import 'package:over_react/over_react.dart';

part 'menu_boolean.over_react.g.dart';

UiFactory<MenuBooleanProps> MenuBoolean = _$MenuBoolean;

mixin MenuBooleanPropsMixin on UiProps {
  bool value;
  String tooltip;
  String display;
  dynamic Function(SyntheticFormEvent) onChange;

  // optional
  String name;
  bool hide;
}

class MenuBooleanProps = UiProps with MenuBooleanPropsMixin;

class MenuBooleanComponent extends UiComponent2<MenuBooleanProps> {
  @override
  get defaultProps => (newProps()..hide = false);

  @override
  render() {
    if (props.hide) {
      return null;
    }

    var name = props.name;
    name ??= props.display.toLowerCase().replaceAll(' ', '-');

    return (Dom.span()
      ..className = 'menu-item menu-item-bool-input'
      ..id = '${name}-span'
      ..style = {'display': 'block'})(
      (Dom.label()..title = props.tooltip)(
          (Dom.input()
            ..style = {'marginRight': '1em'}
            ..checked = props.value
            ..onChange = props.onChange
            // TODO(benlee12): Add unit tests that use this.
            // ..addTestId('scadnano.MenuComponent.MenuBooleanComponent.input.${name}')
            ..type = 'checkbox')(),
          props.display),
    );
  }
}
