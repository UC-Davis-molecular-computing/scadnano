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

  // @override
  // void componentDidMount() {
  //   print(state.container);
  //     setState(newState()
  //       ..width = state.container.current.offsetWidth
  //       ..height = state.container.current.offsetHeight
  //     );
  //   }

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
      })((Dom.ul()
        ..className = 'context-menu-list'
        )(props.context_menu.items.map(menuItemToLi)));
  }

  ReactElement menuItemToLi(ContextMenuItem item)
  {
    List<ReactElement> children = [];

    for (var nested in item.nested ?? [])
      children.add(menuItemToLi(nested));
    
    return (Dom.li()
        ..key = item.title
        ..className = children.isEmpty ? '' : 'has-submenu'
        )(
          (Dom.span()
            ..title = item.tooltip ?? ""
            ..onClick = item.on_click != null ? (_) {
              app.dispatch(actions.ContextMenuHide());
              item.on_click();
            } : null
            ..className = 'context-menu-item'
            )(item.title),
          children.isEmpty ? null : (Dom.div()
            ..className = 'context-menu'
            )((Dom.ul()
              ..className = 'context-menu-list'
              )(children)),
        );
  }
}
