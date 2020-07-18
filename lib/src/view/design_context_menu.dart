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

class DesignContextMenuComponent extends UiComponent2<DesignContextMenuProps> with PureComponent {
  @override
  render() {
    if (props.context_menu == null) {
      return null;
    }

    return (Dom.div()
      ..className = 'context-menu'
      ..id = 'context-menu'
      ..style = {
        'left': props.context_menu.position.x,
        'top': props.context_menu.position.y,
      })((Dom.ul()..className = 'context-menu-list')([
      for (var item in props.context_menu.items)
        (Dom.li()
          ..title = item.tooltip ?? ""
          ..onClick = ((_) {
            app.dispatch(actions.ContextMenuHide());
            item.on_click();
          })
          ..className = 'context-menu-item'
          ..key = item.title)(item.title)
    ]));
  }
}
