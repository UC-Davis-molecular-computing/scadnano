import 'dart:html';

import 'package:over_react/over_react.dart';
import '../view/react_bootstrap.dart';

part 'menu_dropdown_right.over_react.g.dart';

UiFactory<MenuDropdownRightProps> MenuDropdownRight = _$MenuDropdownRight;

mixin MenuDropdownRightProps on UiProps {
  String tooltip;
  String title;
  String id;
  bool disallow_overflow;     // IMPORTANT: only set this to true if you are sure the dropdown won't contain its own dropdowns; otherwise disallowing overflow will cause submenus to not be visible
  bool disabled;
}

mixin MenuDropdownRightState on UiState {
  num top;
  Ref<DivElement> HTML_element;
}

class MenuDropdownRightComponent extends UiStatefulComponent2<
    MenuDropdownRightProps, MenuDropdownRightState> {
  @override
  Map get initialState => (newState()
    ..HTML_element = createRef()
    ..top = null);

  @override
  get defaultProps => (newProps()..disabled = false);

  // once component mounts and HTML_element has a reference assigned, save top coord to set proper css styling
  @override
  void componentDidMount() {
    setState(
        state..top = state.HTML_element.current.getBoundingClientRect().top);
  }

  @override
  render() {
    var menu_dropdown_right = DropdownButton({
      'title': props.title,
      'drop': 'right',
      'id': props.id,
      'variant': 'none',
      'disabled': props.disabled,
      'ref': state.HTML_element,
      /* set some custom CSS props so dropright divs know how much to shift themselves upwards */
      'style': state.top != null
          ? {
              '--offset-top': '${state.top}px',
              '--overflow-y':
                  props.disallow_overflow == true ? 'auto' : 'visible'
            }
          : {}
    }, props.children);

    if (props.tooltip == null) {
      return menu_dropdown_right;
    } else {
      return (Dom
          .span() // had to put outside of DropdownItem to make tooltip show up when disabled
        ..title = props.tooltip)(menu_dropdown_right);
    }
  }
}