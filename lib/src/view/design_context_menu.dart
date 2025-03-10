import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';

import '../state/app_state.dart';
import '../state/context_menu.dart';
import '../app.dart';
import 'pure_component.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_context_menu.over_react.g.dart';

UiFactory<DesignContextMenuProps> ConnectedDesignContextMenu = connect<AppState, DesignContextMenuProps>(
  mapStateToProps: (state) {
    return DesignContextMenu()..context_menu = state.ui_state.context_menu;
  },
)(DesignContextMenu);

UiFactory<DesignContextMenuProps> DesignContextMenu = _$DesignContextMenu;

mixin DesignContextMenuProps on UiProps {
  ContextMenu? context_menu;
}

mixin DesignContextMenuState on UiState {
  late int width;
  late int height;
  late Ref<DivElement?> menu_HTML_element_ref;
}

class DesignContextMenuComponent extends UiStatefulComponent2<DesignContextMenuProps, DesignContextMenuState>
    with PureComponent {
  final num MENU_PADDING = 20;

  @override
  Map get initialState =>
      (newState()
        ..width = 0
        ..height = 0
        ..menu_HTML_element_ref = createRef<DivElement>());

  // how to find width and height of a React element:
  // https://stackoverflow.com/a/43824598
  // https://stackoverflow.com/a/49059117

  // Order in which DesignContextMenu repositions itself according to its size in window:
  // 0. Width and height are 0 when DesignContextMenu is first initialized.
  // 1. Somewhere in State, right-click is activated and ContextMenu becomes non-null. This triggers a component update and a render() call.
  // 2. Inside render(), calculate_menu_position() sees that menu dimensions are 0 x 0 and places menu exactly where
  //    mouse cursor is
  // 3. render() returns a component and assigns menu_HTML_element_ref to the newly created HTML element,
  //    thus triggering a component update
  // 4. componentDidUpdate() sees that menu_HTML_element_ref.current is not null and that the width of the created
  //    HTML element is not 0 (or at least it shouldn't be. ContextMenus with anything in them should have a non-zero width)
  // 5. componentDidUpdate() sets width and height to the width and height of the HTML Element (given by menu_HTML_element_ref.current)
  // 6. updated state triggers a new render() call. render() calls calculate_menu_position() with correct width/height and positions
  //    menu accordingly
  // 7. Context menu is positioned correctly within the window

  // context menu and therefore React element can be null, so instead of using componentDidMount
  // as the SO answers suggest, use componentDidUpdate and do a quick check if the HTML Element ref
  // is not null and if its width is not the same as previous width before updating width and height values
  // (check width change, otherwise state changes would be triggered everytime the context menu is moved
  // which would be undesirable)
  @override
  void componentDidUpdate(_, Map prev_state, [__]) {
    var t_prev_state = typedStateFactory(prev_state);

    if (state.menu_HTML_element_ref.current != null &&
        state.menu_HTML_element_ref.current!.offsetWidth != 0 &&
        state.menu_HTML_element_ref.current!.offsetWidth != t_prev_state.width) {
      setState(
        newState()
          ..width = state.menu_HTML_element_ref.current!.offsetWidth
          ..height = state.menu_HTML_element_ref.current!.offsetHeight,
      );
    }
    // if (state.menu_HTML_element_ref.current.offsetWidth != t_prev_state.width) {
    //   setState(newState()
    //     ..width = state.menu_HTML_element_ref.current!.offsetWidth
    //     ..height = state.menu_HTML_element_ref.current!.offsetHeight);
    // }
  }

  Point<double> calculate_menu_position() {
    double left = props.context_menu!.position.x, top = props.context_menu!.position.y;

    if (left + state.width > window.innerWidth!)
      left -= left + state.width - window.innerWidth! + MENU_PADDING;
    if (top + state.height > window.innerHeight!)
      top -= top + state.height - window.innerHeight! + MENU_PADDING;

    return Point(left, top);
  }

  @override
  render() {
    if (props.context_menu == null) {
      return null;
    }

    var pos = calculate_menu_position();

    return (Dom.div()
      ..ref = state.menu_HTML_element_ref
      ..className = 'context-menu'
      ..id = 'context-menu'
      ..style = {'left': pos.x, 'top': pos.y})(context_menu_to_ul(props.context_menu!));
  }
}

UiFactory<DesignContextSubmenuProps> DesignContextSubmenu = _$DesignContextSubmenu;

mixin DesignContextSubmenuProps on UiProps {
  late ContextMenu context_menu;
}

mixin DesignContextSubmenuState on UiState {
  late int width; // width of submenu as it appears on screen
  late int height; // height of submenu as it appears on screen
  late num left; // position of left edge of submenu RELATIVE TO ENTIRE SCREEN
  late num top; // position of top edge of submenu RELATIVE TO ENTIRE SCREEN
  late Ref<DivElement?> submenu_HTML_element_ref;
}

class DesignContextSubmenuComponent
    extends UiStatefulComponent2<DesignContextSubmenuProps, DesignContextSubmenuState>
    with PureComponent {
  @override
  Map get initialState =>
      (newState()
        ..width = 0
        ..height = 0
        ..left = 0
        ..top = 0
        ..submenu_HTML_element_ref = createRef<DivElement>());

  // how to find width and height of a React element (same links as DesignContextMenuComponent):
  // https://stackoverflow.com/a/43824598
  // https://stackoverflow.com/a/49059117

  // slightly different steps in which submenu repositions itself:
  // 0. Somewhere in State, right-click is activated and ContextMenu becomes non-null and creates a DesignContextMenu component,
  //    and any recursive ContextMenus create DesignContextSubmenus
  // 1. Width, height, left, and top are set to 0 when DesignContextSubmenuComponent is first initialized
  // 2. On first render() call, width, height, left, and top are 0. get_classnames_from_bounding_box() assumes submenu fits
  //    in window in this position, so it applies a right/bottom classes to submenu div, causing it to act like a default right/dropping submenu
  // 3. render() returns a component and assigns submenu_HTML_element_ref to created HTML element.
  // 4. Since this is the first call of render(), we are allowed to use componentDidMount as per the SO answer to get the created HTML
  //    Element's width and height (and top and left)
  // 5. componentDidMount() calls reset_submenu_bounding_box() which simply sets the top/left/width/height to the correct values of its submenu.
  //    This triggers a component update.
  // 6. (I'm not sure if componentDidUpdate() is then called right after, but even if it did, nothing will run inside it according to the if/else if blocks)
  // 7. render() is called again, this time get_classnames_from_bounding_box() will see that the submenu might or might not fit in the window
  //    according to the actual bounding box values, so it adjusts class values accordingly. CSS absolute positioning is our friend,
  //    and will automatically position a submenu to the right/top/left/bottom of its parent Menu/Submenu li element.
  //
  //    NOW, what does componentDidUpdate do?
  // 0. Somewhere in State, a user right clicks a strand immediately after right clicking a previous strand. This causes
  //    DesignContextMenu to update its component since it has a prop referencing the ContextMenu's x/y position. At first
  //    glance, it might seem enough to plop a reset_submenu_bounding_box() inside a componentDidUpdate() listener, BUT we must
  //    remember that Submenu still has its left/top/right/bottom classes from before. However, reset_submenu_bounding_box()
  //    doesn't know that and thus will treat that left/top/right/bottom orientation as the (possibly) incorrect default position.
  //    (For example, Submenu has been aligned to the left/top of its parent menu/submenu. The main menu is then moved to
  //    somwhere in the far bottom/right corner of the screen. However, reset_submenu_bounding_box() will update bounding boxes
  //    and then get_classnames_from_bounding_box() will see that Submenu still fits happily in its "default" position and sets its
  //    classes to right/bottom, which will then cause Submenu to appear out of bounds of the window screen)
  // 1. Therefore, when we detect that the main menu's position has changed, reset the width and height to 0 to mimic the initial
  //    state of the component.
  // 2. render() does its shebang, and the updated width/height triggers a state change and calls componentDidUpdate() AGAIN
  // 3. else if block picks up that width is 0, and similar to DesignContextMenu, we use componentDidUpdate() to set width/height
  //    (and left/top) of the component if we see that the state's width has changed (or in this case, it's 0)
  // 4. render() again blah blah, now left/top/width/height has the correct default values, and get_classnames returns correct classes

  @override
  void componentDidMount() {
    reset_submenu_bounding_box();
  }

  @override
  void componentDidUpdate(Map prev_props, _, [__]) {
    var t_prev_props = typedPropsFactory(prev_props);

    if (t_prev_props.context_menu.position != props.context_menu.position) {
      setState(
        newState()
          ..width = 0
          ..height = 0,
      );
    } else if (state.width == 0) {
      reset_submenu_bounding_box();
    }
  }

  void reset_submenu_bounding_box() {
    if (state.submenu_HTML_element_ref.current == null) {
      return;
    }
    setState(
      newState()
        ..width = state.submenu_HTML_element_ref.current!.offsetWidth
        ..height = state.submenu_HTML_element_ref.current!.offsetHeight
        ..left = state.submenu_HTML_element_ref.current!.getBoundingClientRect().left
        ..top = state.submenu_HTML_element_ref.current!.getBoundingClientRect().top,
    );
  }

  // apply correct css absolute positioning classes depending on if submenus fit in its default
  // right/bottom orientation to its parent Submenu (most specifically, its parent li element)
  // NOTE: this will ONLY work if when this is called the first time, state.left and state.top
  // are set to as if the Submenu is positioned to the bottom right of its parent menu/submenu li element
  List<String> get_classnames_from_bounding_box() {
    return [
      state.left + state.width > window.innerWidth! ? 'left' : 'right',
      state.top + state.height > window.innerHeight! ? 'top' : 'bottom',
    ];
  }

  @override
  render() {
    // no need for this check like in DesignContextMenu; submenus should never have null ContextMenus
    // if (props.context_menu == null) {
    //   return null;
    // }

    var class_list = ['context-menu', ...get_classnames_from_bounding_box()];

    return (Dom.div()
      ..ref = state.submenu_HTML_element_ref
      ..className = class_list.join(' ')
      ..id = 'context-menu')(context_menu_to_ul(props.context_menu));
  }
}

ReactElement context_menu_to_ul(ContextMenu menu) {
  return (Dom.ul()..className = 'context-menu-list')([
    for (ContextMenuItem item in menu.items)
      (Dom.li()
        ..key = item.title
        ..className = (item.nested != null ? 'has-submenu' : ''))(
        (Dom.span()
          ..title = item.tooltip
          ..onClick =
              item.on_click != null
                  ? (_) {
                    app.dispatch(actions.ContextMenuHide());
                    item.on_click!();
                  }
                  : null
          ..className =
              'context-menu-item' +
              (item.disabled ? " " + constants.css_selector_context_menu_item_disabled : ""))(item.title),
        item.nested != null
            ? (DesignContextSubmenu()
              ..context_menu = ContextMenu(items: item.nested!, position: menu.position))()
            : null,
      ),
  ]);
}
