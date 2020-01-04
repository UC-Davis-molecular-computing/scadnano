import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';

import 'package:scadnano/src/state/context_menu.dart';
import 'package:scadnano/src/view/pure_component.dart';
import '../app.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;

part 'design_context_menu.over_react.g.dart';

UiFactory<DesignContextMenuProps> ConnectedDesignContextMenu =
    connect<AppState, DesignContextMenuProps>(mapStateToProps: (state) {
  return DesignContextMenu()..context_menu = state.ui_state.context_menu;
})(DesignContextMenu);

@Factory()
UiFactory<DesignContextMenuProps> DesignContextMenu = _$DesignContextMenu;

@Props()
class _$DesignContextMenuProps extends UiProps {
  ContextMenu context_menu;
}

@Component2()
class DesignContextMenuComponent extends UiComponent2<DesignContextMenuProps> with PureComponent {
  @override
  render() {
    if (props.context_menu == null) {
      return null;
    }
    num x = props.context_menu.position.x;
    num y = props.context_menu.position.y;
    return (Dom.div()
      ..className = 'context-menu-div'
      ..style = {
        'left': x,
        'top': y,
        'display': 'block',
      })((Dom.ul()..className = 'context-menu')([
      for (var item in props.context_menu.items)
        (Dom.li()
          ..onClick = ((_) {
            app.dispatch(actions.ContextMenuHide());
            item.on_click();
          })
          ..className = 'context-menu-item'
          ..key = item.title)(item.title)
    ]));
  }
}
