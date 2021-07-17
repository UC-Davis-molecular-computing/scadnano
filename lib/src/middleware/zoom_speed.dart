import 'dart:html';

import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../util.dart' as util;
import '../state/app_state.dart';

// check to ensure when switching from Grid.none to a real grid, that each grid_position will get
// at most one helix (i.e., function mapping real-coordinates to grid-coordinates is 1-1)
zoom_speed_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.ZoomSpeedSet) {
    util.set_zoom_speed(action.speed);
  }
  next(action);
}
