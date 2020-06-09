import 'package:over_react/over_react.dart';

part 'menu_boolean.over_react.g.dart';

UiFactory<MenuBooleanProps> MenuBoolean = _$MenuBoolean;

mixin MenuBooleanPropsMixin on UiProps {
  bool value;
  bool hide;
  String tooltip;
  String display;
  String name;
  dynamic Function(SyntheticFormEvent) onChange;
}

class MenuBooleanProps = UiProps with MenuBooleanPropsMixin;

class MenuBooleanComponent extends UiComponent2<MenuBooleanProps> {
  @override
  get defaultProps => (newProps()..hide = false);

  @override
  render() {
    var name = props.name;
    name ??= props.display.toLowerCase().replaceAll(' ', '-');

    if (!props.hide) {
      return (Dom.span()
        ..className = 'menu-item'
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
    } else {
      return null;
    }
  }
}
