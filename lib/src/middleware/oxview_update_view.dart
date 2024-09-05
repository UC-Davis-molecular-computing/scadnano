import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js';
import 'dart:math';
import 'package:path/path.dart' as path;
import 'package:quiver/iterables.dart' as quiver;
import 'package:react/react.dart';
import 'package:built_collection/built_collection.dart';

import 'package:redux/redux.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/extension.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:tuple/tuple.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../state/helix.dart';
import '../util.dart' as util;
import '../util.dart';
import 'export_cadnano_or_codenano_file.dart' as export_cadnano;
import '../constants.dart' as constants;
import 'oxdna_export.dart';
import '../app.dart';

// This middleware handles sending the new design to the oxview viewer,
// as well as updating whether it is shown, since it is wired to the
// view outside of React.
oxview_update_view_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);

  if (action is actions.OxviewShowSet) {
    app.view.update_showing_oxview();
  }

  if (store.state.ui_state.show_oxview && action is actions.DesignChangingAction) {
    Design design = store.state.design;
    if (design != null) {
      update_oxview_view(design);
    }
  }
}

// frame is optional because usually we get it from app.view.oxview_view.frame,
// but on startup app.view is not yet allocated (we're in the View constructor
// the first time), so we send the frame just after creating it.
void update_oxview_view(Design design, {IFrameElement frame = null}) {
  assert(design != null);
  assert(design.strands != null);
  if (frame == null) {
    frame = app.view?.oxview_view?.frame;
  }
  assert(frame != null);

  List<Strand> strands_to_export = design.strands.toList();

  // String content = to_oxview_format(design, strands_to_export);
  Tuple2<String, String> dat_top = to_oxdna_format(design, strands_to_export);
  String dat = dat_top.item1;
  String top = dat_top.item2;

  String blob_type_string = blob_type_to_string(BlobType.text);
  Blob blob_dat = new Blob([dat], blob_type_string);
  Blob blob_top = new Blob([top], blob_type_string);

  Map<String, dynamic> message = {
    'message': 'iframe_drop',
    'files': [blob_top, blob_dat],
    'ext': ['top', 'dat'],
    'inbox_settings': ["Monomer", "Origin"],
  };

  print("sending message to iframe");
  frame.contentWindow?.postMessage(message, 'https://sulcgroup.github.io/oxdna-viewer/');

  // frame.src = frame.src;
}
