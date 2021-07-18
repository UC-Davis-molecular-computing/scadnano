import 'dart:html';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';

import '../state/app_state.dart';
import '../state/context_menu.dart';
import '../app.dart';
import 'pure_component.dart';
import '../actions/actions.dart' as actions;

part 'design_context_menu.over_react.g.dart';

UiFactory<DesignContextMenuProps> ConnectedDesignContextMenu =
    connect<AppState, DesignContextMenuProps>(mapStateToProps: (state) {
  return DesignContextMenu()..context_menu = state.ui_state.context_menu;
})(DesignContextMenu);

UiFactory<DesignContextMenuProps> DesignContextMenu = _$DesignContextMenu;

mixin DesignContextMenuProps on UiProps {
  ContextMenu context_menu;
}

mixin DesignContextMenuState on UiState {
  int width;
  int height;
  Ref<DivElement> container;
}

class DesignContextMenuComponent extends UiStatefulComponent2<DesignContextMenuProps, DesignContextMenuState> with PureComponent {

  @override
  Map get initialState => (newState()
    ..width = 0
    ..height = 0
    ..container = createRef()
  );

  @override
  void componentDidUpdate(Map prevProps, Map prevState, [dynamic snapshot]) {
    var tPrevState = typedStateFactory(prevState);

    if (state.container.current != null && state.container.current.offsetWidth != tPrevState.width) {
      setState(newState()
        ..width = state.container.current.offsetWidth
        ..height = state.container.current.offsetHeight
      );
    }
  }

  @override
  render() {
    if (props.context_menu == null) {
      return null;
    }

    int left = props.context_menu.position.x, top = props.context_menu.position.y;
    if (left + state.width > window.innerWidth) left -= state.width;
    if (top + state.height > window.innerHeight) top -= state.height;

    return (Dom.div()
      ..ref = state.container
      ..className = 'context-menu'
      ..id = 'context-menu'
      ..style = {
        'left': left,
        'top': top,
      })(contextMenuToUl(props.context_menu));
  }
}

UiFactory<DesignContextSubmenuProps> DesignContextSubmenu = _$DesignContextSubmenu;

mixin DesignContextSubmenuProps on UiProps {
  ContextMenu context_menu;
}

mixin DesignContextSubmenuState on UiState {
  num width;
  num height;
  num left;
  num top;
  Ref<DivElement> container;
}

class DesignContextSubmenuComponent extends UiStatefulComponent2<DesignContextSubmenuProps, DesignContextSubmenuState> with PureComponent {

  @override
  Map get initialState => (newState()
    ..width = 0
    ..height = 0
    ..left = 0
    ..top = 0
    ..container = createRef()
  );

  @override
  void componentDidMount() {
      setState(newState()
        ..width = state.container.current.offsetWidth
        ..height = state.container.current.offsetHeight
        ..left = state.container.current.getBoundingClientRect().left
        ..top = state.container.current.getBoundingClientRect().top
      );
  }

  @override
  void componentDidUpdate(Map prevProps, _, [__]) {
    var tPrevProps = typedPropsFactory(prevProps);

    // if main context menu has been moved (e.g. by immediately right clicking another strand)
    // then trigger a state change, which will then be picked up in the else if block
    if (tPrevProps.context_menu.position != props.context_menu.position) {
      setState(newState()
        ..width = 0
        ..height = 0
      );
    }
    else if (state.width == 0) {
      setState(newState()
        ..width = state.container.current.offsetWidth
        ..height = state.container.current.offsetHeight
        ..left = state.container.current.getBoundingClientRect().left
        ..top = state.container.current.getBoundingClientRect().top
      );
    }
  }

  @override
  render() {
    // this shouldn't fire, submenus should never have null ContextMenus
    if (props.context_menu == null) {
      return null;
    }

    var classList = [
      'context-menu',
      state.left + state.width > window.innerWidth ? 'left' : 'right',
      state.top + state.height > window.innerHeight ? 'top' : 'bottom',
    ];

    return (Dom.div()
      ..ref = state.container
      ..className = classList.join(' ')
      ..id = 'context-menu'
      )(contextMenuToUl(props.context_menu));
  }
}

ReactElement contextMenuToUl(ContextMenu menu) {
  return (Dom.ul()
        ..className = 'context-menu-list'
        )([
          for (var item in menu.items)
            (Dom.li()
              ..key = item.title
              ..className = item.nested != null ? 'has-submenu' : ''
              )(
                (Dom.span()
                  ..title = item.tooltip ?? ""
                  ..onClick = item.on_click != null ? (_) {
                    app.dispatch(actions.ContextMenuHide());
                    item.on_click();
                  } : null
                  ..className = 'context-menu-item'
                  )(item.title),
                item.nested != null ? (DesignContextSubmenu()..context_menu = ContextMenu(items: item.nested, position: menu.position))() : null
              )
        ]);
}