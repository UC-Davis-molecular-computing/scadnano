import 'package:web/web.dart';

import 'package:over_react/over_react.dart';
import '../view/react_bootstrap.dart';

part 'menu_dropdown_right.over_react.g.dart';

UiFactory<MenuDropdownRightProps> MenuDropdownRight = _$MenuDropdownRight;

mixin MenuDropdownRightProps on UiProps {
  // I think title and id are inherited from UiProps; got some error about invalid override without the `_`.
  late String title_;
  late String id_;

  // optional
  String? keyboard_shortcut;

  // optional to specify, but non-nullable since they have default values
  // https://github.com/Workiva/over_react/blob/master/doc/null_safety_and_required_props.md#defaulting-props-class-components
  late String tooltip;
  late bool disabled;

  // IMPORTANT: only set this to true if you are sure the dropdown won't contain its own dropdowns;
  // otherwise disallowing overflow will cause submenus to not be visible
  late bool disallow_overflow;
}

mixin MenuDropdownRightState on UiState {
  num? top;
  late Ref<HTMLDivElement?> HTML_element;
}

class MenuDropdownRightComponent
    extends UiStatefulComponent2<MenuDropdownRightProps, MenuDropdownRightState> {
  @override
  Map get initialState => (newState()
    ..HTML_element = createRef<HTMLDivElement>()
    ..top = null);

  @override
  get defaultProps => (newProps()
    ..tooltip = ''
    ..disabled = false
    ..disallow_overflow = false);

  // once component mounts and HTML_element has a reference assigned, save top coord to set proper css styling
  @override
  void componentDidMount() {
    setState(state..top = state.HTML_element.current!.getBoundingClientRect().top);
  }

  @override
  render() {
    // This ugliness of making title either a String (normal case) or a list of React components
    // (if there's a keyboard shortcut) allows us to have a keyboard shortcut in the dropdown title
    // justified to the right, while the rest of the title is justified to the left.
    // React Bootstrap only seems to pass along the components properly when they are HTML elements,
    // in this case two <span> elements. We can pass a list of Strings as the value to associate
    // to the 'title' key, but then the keyboard shortcut will be left-justified with the rest of the title.
    bool has_shortcut = props.keyboard_shortcut != null;
    var title_and_shortcut = [(Dom.span()..key = 'title')(props.title_)];
    if (has_shortcut) {
      title_and_shortcut.add((Dom.span()..key = 'shortcut')(props.keyboard_shortcut!));
    }
    var menu_dropdown_right = DropdownButton({
      'title': has_shortcut ? title_and_shortcut : props.title_,
      'drop': 'right',
      'id': props.id_,
      'variant': 'none',
      'disabled': props.disabled,
      'ref': state.HTML_element,
      'key': props.id_,
      /* set some custom CSS props so dropright divs know how much to shift themselves upwards */
      'style': state.top != null
          ? {
              '--offset-top': '${state.top}px',
              '--overflow-y': props.disallow_overflow == true ? 'auto' : 'visible',
            }
          : {}
    }, props.children);

    return (Dom.span() // had to put outside of DropdownItem to make tooltip show up when disabled
      ..title = props.tooltip)(menu_dropdown_right);
  }
}
