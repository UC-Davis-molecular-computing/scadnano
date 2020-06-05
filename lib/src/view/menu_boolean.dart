import 'package:over_react/over_react.dart';

part 'menu_boolean.over_react.g.dart';

UiFactory<MenuBooleanProps> MenuBoolean = _$MenuBoolean;

mixin MenuBooleanPropsMixin on UiProps {
  bool value;
  String tooltip;
  String display;
  String name;
  dynamic Function(SyntheticFormEvent) onChange;
}

class MenuBooleanProps = UiProps with MenuBooleanPropsMixin;

class MenuBooleanComponent extends UiComponent2<MenuBooleanProps> {
  @override
  render() {
    return (Dom.span()
      ..className = 'menu-item'
      ..id = '${props.name}-span'
      ..style = {'display': 'block'})(
      (Dom.label()..title = props.tooltip)(
          (Dom.input()
            ..style = {'marginRight': '1em'}
            ..checked = props.value
            ..onChange = props.onChange
            // TODO(benlee12): Add unit tests that use this.
            // ..addTestId('scadnano.MenuComponent.MenuBooleanComponent.input.${props.name}')
            ..type = 'checkbox')(),
          props.display),
    );
  }
}
