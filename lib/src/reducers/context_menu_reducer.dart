// @dart=2.9
import 'package:redux/redux.dart';
import '../state/context_menu.dart';
import '../actions/actions.dart' as actions;

Reducer<ContextMenu> context_menu_reducer = combineReducers([
  TypedReducer<ContextMenu, actions.ContextMenuShow>(context_menu_show_reducer),
  TypedReducer<ContextMenu, actions.ContextMenuHide>(context_menu_hide_reducer),
]);

ContextMenu context_menu_show_reducer(ContextMenu _, actions.ContextMenuShow action) => action.context_menu;

ContextMenu context_menu_hide_reducer(ContextMenu _, actions.ContextMenuHide action) => null;
