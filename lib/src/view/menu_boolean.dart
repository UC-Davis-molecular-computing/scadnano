import 'package:over_react/over_react.dart';

part 'menu_boolean.over_react.g.dart';

UiFactory<MenuBooleanProps> MenuBoolean = _$MenuBoolean;

mixin MenuBooleanProps on UiProps {
  late bool value;
  late String display;
  late dynamic Function(SyntheticFormEvent) on_change;

  // optional
  String? name;

  // optional to specify, but non-nullable since they have default values
  // https://github.com/Workiva/over_react/blob/master/doc/null_safety_and_required_props.md#defaulting-props-class-components
  late bool hide;
  late String tooltip;
}

class MenuBooleanComponent extends UiComponent2<MenuBooleanProps> {
  @override
  get defaultProps => (newProps()
    ..hide = false
    ..tooltip = '');

  @override
  render() {
    if (props.hide) {
      return null;
    }

    String? name = props.name;
    name ??= props.display.toLowerCase().replaceAll(' ', '-');

    return (Dom.span()
      ..className = 'menu-item menu-item-bool-input'
      ..id = '${name}-span'
      ..style = {'display': 'block'})(
      (Dom.label()..title = props.tooltip)(
          (Dom.input()
            ..style = {'marginRight': '1em'}
            ..checked = props.value
            ..onChange = props.on_change
            // TODO(benlee12): Add unit tests that use this.
            // ..addTestId('scadnano.MenuComponent.MenuBooleanComponent.input.${name}')
            ..type = 'checkbox')(),
          props.display),
    );
  }
}
