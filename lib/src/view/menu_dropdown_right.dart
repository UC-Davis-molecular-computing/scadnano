import 'package:over_react/over_react.dart';
import '../view/react_bootstrap.dart';

part 'menu_dropdown_right.over_react.g.dart';

UiFactory<MenuDropdownRightProps> MenuDropdownRight = _$MenuDropdownRight;

mixin MenuDropdownRightPropsMixin on UiProps {
  String tooltip;
  String title;
  String id;
}

class MenuDropdownRightProps = UiProps with MenuDropdownRightPropsMixin;

class MenuDropdownRightComponent extends UiComponent2<MenuDropdownRightProps> {
  @override
  render() {
    var menu_dropdown_right = DropdownButton(
      {
        'title': props.title,
        'drop': 'right',
        'id': props.id,
        'variant': 'none'
      },
      props.children
    );

    if (props.tooltip == null) {
      return menu_dropdown_right;
    } else {
      return (Dom.span() // had to put outside of DropdownItem to make tooltip show up when disabled
        ..title = props.tooltip)(menu_dropdown_right);
    }
  }

}