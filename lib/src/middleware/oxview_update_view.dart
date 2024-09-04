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

oxdna_export_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.DesignChangingAction) {
    AppState state = store.state;

    List<Strand> strands_to_export = state.design.strands.toList();
    String content = to_oxview_format(state.design, strands_to_export);
    String blob_type_string = blob_type_to_string(BlobType.text);
    Blob blob = new Blob([content], blob_type_string);

    IFrameElement frame = querySelector('#oxview-frame-1') as IFrameElement;

    Map<String, dynamic> message = {
      'message': 'iframe_drop',
      'files': [blob],
      'ext': 'oxview',
      'inbox_settings': ["Monomer", "Origin"],
    };

    frame.contentWindow?.postMessage(message, 'https://sulcgroup.github.io/oxdna-viewer/');
  }
  next(action);
}
