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
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../state/helix.dart';
import '../util.dart' as util;
import '../util.dart';
import 'export_cadnano_file.dart' as export_cadnano;
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

    // Show warning when user opens oxView (not when closing it)
    if (action.show && store.state.ui_state.warn_about_unassigned_dna_and_oxview_open) {
      if (store.state.maybe_design != null) {
        _check_and_show_unassigned_dna_warning(store.state.design.strands.toList());
      }
    }
  }

  if (store.state.ui_state.show_oxview && action is actions.DesignChangingAction) {
    update_oxview_view(
      store.state.design,
      null,
      store.state.ui_state.warn_about_unassigned_dna_and_oxview_open,
    );
  }
}

// `frame` argument is optional because usually we get it from app.view.oxview_view.frame,
// but on startup, `app.view` is not yet initialized (we're in the View constructor
// the first time we call `update_oxview_view`), so from that constructor, we send the frame explicitly
// to this function just after creating it, but before it can be accessed via `app.view.oxview_view?.frame`.
void update_oxview_view(Design design, IFrameElement? frame, bool warn_enabled) {
  if (frame == null) {
    frame = app.view.oxview_view.frame;
  }

  // reset oxview in case it has nucleotides already
  Blob blob_js_reset_commands = new Blob([
    'resetScene(resetCamera = false);',
  ], blob_type_to_string(BlobType.text));
  Map<String, dynamic> message = {
    'message': 'iframe_drop',
    'files': [blob_js_reset_commands],
    'ext': ['js'],
  };
  frame.contentWindow?.postMessage(message, constants.OXVIEW_URL);

  // send current exported design
  List<Strand> strands_to_export = design.strands.toList();

  // Warning handled in middleware, not here

  //////////////////////////////////////////
  // oxDNA

  // // String content = to_oxview_format(design, strands_to_export);
  // var (dat, top) = to_oxdna_format(design, strands_to_export); // (String, String)
  //
  // Blob blob_dat = new Blob([dat], blob_type_to_string(BlobType.text));
  // Blob blob_top = new Blob([top], blob_type_to_string(BlobType.text));
  //
  // message = {
  //   'message': 'iframe_drop',
  //   'files': [blob_top, blob_dat],
  //   'ext': ['top', 'dat'],
  //   'inbox_settings': ["Monomer", "Origin"],
  // };

  /////////////////////////////////////////
  // oxView

  String oxview_content = to_oxview_format(design, strands_to_export);

  Blob blob_oxview_content = new Blob([oxview_content], blob_type_to_string(BlobType.text));

  message = {
    'message': 'iframe_drop',
    'files': [blob_oxview_content],
    'ext': ['oxview'],
    'inbox_settings': ["Monomer", "Origin"],
  };

  frame.contentWindow?.postMessage(message, constants.OXVIEW_URL);
}

// Helper function to check for unassigned DNA and show warning
void _check_and_show_unassigned_dna_warning(List<Strand> strands_to_export) {
  List<String> strand_names_without_dna = [];
  for (var strand in strands_to_export) {
    if (strand.dna_sequence == null || strand.dna_sequence!.contains(constants.DNA_BASE_WILDCARD)) {
      if (strand.name != null) {
        strand_names_without_dna.add(strand.name!);
      } else {
        strand_names_without_dna.add(strand.id);
      }
    }
  }

  if (strand_names_without_dna.isNotEmpty) {
    var msg =
        'The following strands do not have complete DNA sequences assigned: '
        '${strand_names_without_dna.join(", ")}. '
        'These strands will be exported with a default sequence of "T" '
        'for each nucleotide whose base is not specified. '
        'This can lead to unexpected behavior in oxView. For best results, '
        'assign a DNA sequence to each strand before exporting.'
        '\n\nTo silence this warning, uncheck View→Warnings→Unassigned DNA if oxView open.';
    window.alert(msg);
  }
}
