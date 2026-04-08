import 'dart:html';

import 'package:redux/redux.dart';

import 'package:scadnano_state/src/actions/actions.dart' as actions;
import 'package:scadnano_state/src/state/app_state.dart';

stroke_width_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);
  if (action is actions.StrokeWidthSet) {
    set_strand_stroke_width(action.stroke_width);
  } else if (action is actions.CrossoverOpacitySet) {
    set_crossover_opacity(action.opacity);
  } else if (action is actions.CrossoverOpacitySameHelixSet) {
    set_crossover_opacity_same_helix(action.opacity);
  }
}

set_strand_stroke_width(double stroke_width) {
  document.documentElement?.style.setProperty('--strand-stroke-width', '$stroke_width');
}

set_crossover_opacity(double opacity) {
  document.documentElement?.style.setProperty('--crossover-opacity', '$opacity');
}

set_crossover_opacity_same_helix(double opacity) {
  document.documentElement?.style.setProperty('--crossover-opacity-same-helix', '$opacity');
}
