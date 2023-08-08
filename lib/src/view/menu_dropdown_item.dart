import 'package:over_react/over_react.dart';
import '../view/react_bootstrap.dart';

part 'menu_dropdown_item.over_react.g.dart';

UiFactory<MenuDropdownItemProps> MenuDropdownItem = _$MenuDropdownItem;

mixin MenuDropdownItemPropsMixin on UiProps {
  String display;
  dynamic Function(SyntheticMouseEvent) on_click;
  String keyboard_shortcut;
  bool disabled;
  bool active;
  String tooltip;
}

class MenuDropdownItemProps = UiProps with MenuDropdownItemPropsMixin;

class MenuDropdownItemComponent extends UiComponent2<MenuDropdownItemProps> {
  @override
  get defaultProps => (newProps()
    ..disabled = false
    ..active = false);

  @override
  render() {
    var dropdown_item = DropdownItem(
      {
        'active': props.active,
        'disabled': props.disabled,
        'onClick': props.on_click,
      },
      props.display,
      props.keyboard_shortcut != null
          ? (Dom.span()..className = 'dropdown-item-keyboard-shortcut-span')(props.keyboard_shortcut)
          : null,
    );

    if (props.tooltip == null) {
      return dropdown_item;
    } else {
      return (Dom.span() // had to put outside of DropdownItem to make tooltip show up when disabled
        ..title = props.tooltip)(dropdown_item);
    }
  }
}
