// @dart=2.9
import 'dart:html';

import 'package:over_react/over_react.dart';
import '../view/react_bootstrap.dart';

part 'menu_dropdown_right.over_react.g.dart';

UiFactory<MenuDropdownRightProps> MenuDropdownRight = _$MenuDropdownRight;

mixin MenuDropdownRightProps on UiProps {
  String tooltip;
  String title;
  String id;
  bool
      disallow_overflow; // IMPORTANT: only set this to true if you are sure the dropdown won't contain its own dropdowns; otherwise disallowing overflow will cause submenus to not be visible
  bool disabled;
  String keyboard_shortcut;
}

mixin MenuDropdownRightState on UiState {
  num top;
  Ref<DivElement> HTML_element;
}

class MenuDropdownRightComponent
    extends UiStatefulComponent2<MenuDropdownRightProps, MenuDropdownRightState> {
  @override
  Map get initialState => (newState()
    ..HTML_element = createRef()
    ..top = null);

  @override
  get defaultProps => (newProps()..disabled = false);

  // once component mounts and HTML_element has a reference assigned, save top coord to set proper css styling
  @override
  void componentDidMount() {
    setState(state..top = state.HTML_element.current.getBoundingClientRect().top);
  }

  @override
  render() {
    // This ugliness of making title either a String (normal case) or a list of React components
    // (if there's a keyboard shortcut) allows us to have a keyboard shortcut in the dropdown title
    // justified to the right, while the rest of the title is justified to the left.
    // React Bootstrap only seems to pass along the components properly when they are HTML elements,
    // in this case a <span> and a <text> element. We can pass a list of Strings as the value to associate
    // to the 'title' key, but then the keyboard shortcut will be left-justified with the rest of the title.
    bool has_shortcut = props.keyboard_shortcut != null;
    var title_and_shortcut = [Dom.span()(props.title)];
    if (has_shortcut) {
      title_and_shortcut.add(Dom.text()(props.keyboard_shortcut));
    }
    var menu_dropdown_right = DropdownButton({
      'title': has_shortcut ? title_and_shortcut : props.title,
      'drop': 'right',
      'id': props.id,
      'variant': 'none',
      'disabled': props.disabled,
      'ref': state.HTML_element,
      'key': props.id,
      /* set some custom CSS props so dropright divs know how much to shift themselves upwards */
      'style': state.top != null
          ? {
              '--offset-top': '${state.top}px',
              '--overflow-y': props.disallow_overflow == true ? 'auto' : 'visible',
            }
          : {}
    }, props.children);

    if (props.tooltip == null) {
      return menu_dropdown_right;
    } else {
      return (Dom.span() // had to put outside of DropdownItem to make tooltip show up when disabled
        ..title = props.tooltip)(menu_dropdown_right);
    }
  }
}
