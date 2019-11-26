import 'dart:html';

import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../model/model.dart';

Model load_file_middleware(Store<Model> store, dynamic action, NextDispatcher next) {
  next(action);
  if (action is actions.LoadDNAFile) {
    document.title = action.filename;
  }
}