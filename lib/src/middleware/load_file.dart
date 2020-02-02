import 'dart:html';

import 'package:redux/redux.dart';

import '../actions/actions.dart' as actions;
import '../app.dart';
import '../state/app_state.dart';
import '../util.dart' as util;

load_file_middleware(Store<AppState> store, action, NextDispatcher next) {
  next(action);

  if (action is actions.LoadDNAFile) {
    document.title = action.filename;
    app?.view?.design_view?.render(store.state);

    // re-center if necessary
    if (store.state.ui_state.autofit && store.state.dna_design != null) {
      Point<num> pan_side = Point<num>(50, 50);
      Point<num> pan_main = Point<num>(100, 50);
      if (store.state.dna_design.helices.length > 0) {
        // center at smallest-index helix
        var helices = store.state.dna_design.helices.values.toList();
        var first_helix = helices.first;
        for (var helix in helices) {
          if (first_helix.idx > helix.idx) {
            first_helix = helix;
          }
        }
        pan_main += first_helix.svg_position;
        pan_side += util.position3d_to_side_view_svg(first_helix.position3d());
      }
      util.set_pan_side(pan_side);
      util.set_pan_main(pan_main);
    }
  }
}
