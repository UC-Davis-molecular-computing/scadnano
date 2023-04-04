import 'package:redux/redux.dart';
import 'package:scadnano/src/state/export_dna_format_strand_order.dart';

import '../app.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../util.dart' as util;

export_dna_sequences_middleware(Store<AppState> store, action, NextDispatcher next) {
  next(action);

  AppState state = store.state;


if (action is actions.ExportCanDoDNA) {
    List<Strand> strands;
      strands = state.design.strands.toList();
      strands.removeWhere((strand) => strand.is_scaffold);

    String filename = 'cando_sequences.csv';
    util.BlobType blob_type = util.BlobType.text;

    try {
      var result = action.export_dna_format
        .export(strands, strand_order: StrandOrder.fromString("5'"), column_major: true);
      // See export comments for why we have this stupid special case
      if (result is Future<List<int>>) {
        result.then((response) {
          List<int> content = response;
          util.save_file(filename, content, blob_type: blob_type);
        }).catchError((e, stackTrace) {
          var cause = "";
          if (has_cause(e)) {
            cause = e.cause;
          } else if (has_message(e)) {
            cause = e.message;
          }
          var msg = cause + '\n\n' + stackTrace.toString();
          store.dispatch(actions.ErrorMessageSet(msg));
          app.view.design_view.render(store.state);
        });
      } else {
        String content = result;
        util.save_file(filename, content, blob_type: blob_type);
      }
      // .then((content) => util.save_file(filename, content, blob_type: blob_type))
    } catch (e, stackTrace) {
      var cause = "";
      if (has_cause(e)) {
        cause = e.cause;
      } else if (has_message(e)) {
        cause = e.message;
      }
      var msg = cause + '\n\n' + stackTrace.toString();
      store.dispatch(actions.ErrorMessageSet(msg));
      app.view.design_view.render(store.state);
    }
  }
  if (action is actions.ExportDNA) {
    List<Strand> strands;
    if (action.include_only_selected_strands) {
      strands = state.ui_state.selectables_store.selected_strands.toList();
    } else {
      strands = state.design.strands.toList();
    }


    if (!action.include_scaffold) {
      strands.removeWhere((strand) => strand.is_scaffold);
    }

    String filename = 'sequences.' + action.export_dna_format.extension();
    util.BlobType blob_type = action.export_dna_format.blob_type();

    try {
      var result = action.export_dna_format
          .export(strands, strand_order: action.strand_order, column_major: action.column_major);
      // See export comments for why we have this stupid special case
      if (result is Future<List<int>>) {
        result.then((response) {
          List<int> content = response;
          util.save_file(filename, content, blob_type: blob_type);
        }).catchError((e, stackTrace) {
          var cause = "";
          if (has_cause(e)) {
            cause = e.cause;
          } else if (has_message(e)) {
            cause = e.message;
          }
          var msg = cause + '\n\n' + stackTrace.toString();
          store.dispatch(actions.ErrorMessageSet(msg));
          app.view.design_view.render(store.state);
        });
      } else {
        String content = result;
        util.save_file(filename, content, blob_type: blob_type);
      }
      // .then((content) => util.save_file(filename, content, blob_type: blob_type))
    } catch (e, stackTrace) {
      var cause = "";
      if (has_cause(e)) {
        cause = e.cause;
      } else if (has_message(e)) {
        cause = e.message;
      }
      var msg = cause + '\n\n' + stackTrace.toString();
      store.dispatch(actions.ErrorMessageSet(msg));
      app.view.design_view.render(store.state);
    }
  }
}

/// Check if a Dart object has cause field.
bool has_cause(obj) {
  var has_it = false;
  try {
    (obj as dynamic).cause;
    has_it = true;
  } on NoSuchMethodError {}
  return has_it;
}

/// Check if a Dart object has message field.
bool has_message(obj) {
  var has_it = false;
  try {
    (obj as dynamic).message;
    has_it = true;
  } on NoSuchMethodError {}
  return has_it;
}
