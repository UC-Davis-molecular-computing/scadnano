// @dart=2.9
import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
import 'package:scadnano/src/state/domain.dart';

import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

// Stops strands from being copied or moved unless they are all on the same helix group
move_ensure_all_in_same_helix_group_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.StrandsMoveStart) {
    if (action.original_helices_view_order_inverse == null) {
      var msg = 'Cannot move or copy strands unless they are all on the same helix group.\n'
          'original_helices_view_order_inverse is null';
      window.alert(msg);
      return;
    }
  }
  next(action);
}
