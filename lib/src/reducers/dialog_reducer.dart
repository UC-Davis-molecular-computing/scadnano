import 'package:redux/redux.dart';

import '../state/dialog.dart';
import '../actions/actions.dart' as actions;

Reducer<Dialog?> dialog_reducer = combineReducers([
  TypedReducer<Dialog?, actions.DialogShow>(dialog_show_reducer),
  TypedReducer<Dialog?, actions.DialogHide>(dialog_hide_reducer),
]);

Dialog? dialog_show_reducer(Dialog? _, actions.DialogShow action) => action.dialog;

Dialog? dialog_hide_reducer(Dialog? _, actions.DialogHide action) => null;
