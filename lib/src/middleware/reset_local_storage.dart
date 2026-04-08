import 'dart:convert';
import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:redux/redux.dart';
import 'package:scadnano_state/src/state/design.dart';
import 'package:scadnano_state/src/state/app_ui_state_storables.dart';
import 'package:scadnano_state/src/serializers.dart';
import 'package:scadnano_state/src/state/local_storage_design_choice.dart';

import 'package:scadnano_state/src/json_serializable.dart';
import 'package:scadnano_state/src/state/app_state.dart';
import 'package:scadnano_state/src/actions/actions.dart' as actions;
import 'package:scadnano_state/src/state/storable.dart';
import '../util.dart' as util;
import 'local_storage.dart';

reset_local_storage_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);
  if (action is actions.ResetLocalStorage) {
    window.localStorage.remove(Storable.design.key_name);
    window.localStorage.remove(Storable.app_ui_state_storables.key_name);
    window.location.reload();
  }
}
