import 'package:over_react/over_react.dart';
import '../view/react_bootstrap.dart';

part 'menu_dropdown_item.over_react.g.dart';

UiFactory<MenuDropdownItemProps> MenuDropdownItem = _$MenuDropdownItem;

mixin MenuDropdownItemProps on UiProps {
  late String display;
  late dynamic Function(SyntheticMouseEvent) on_click;

  // optional
  String? keyboard_shortcut;

  // optional to specify, but non-nullable since they have default values
  // https://github.com/Workiva/over_react/blob/master/doc/null_safety_and_required_props.md#defaulting-props-class-components
  late bool disabled;
  late bool active;
  late String tooltip;
}

class MenuDropdownItemComponent extends UiComponent2<MenuDropdownItemProps> {
  @override
  get defaultProps => (newProps()
    ..disabled = false
    ..active = false
    ..tooltip = '');

  @override
  render() {
    var dropdown_item = DropdownItem(
      {
        'active': props.active,
        'disabled': props.disabled,
        'onClick': props.on_click,
      },
      Dom.span()(props.display),
      props.keyboard_shortcut,
    );

    return (Dom.span() // had to put outside of DropdownItem to make tooltip show up when disabled
      ..title = props.tooltip)(dropdown_item);
  }
}
