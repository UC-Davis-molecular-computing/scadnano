import 'package:redux/redux.dart';
import 'package:scadnano/src/state/export_dna_format.dart';
import 'package:scadnano/src/state/export_dna_format_strand_order.dart';

import '../app.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../util.dart' as util;

export_dna_sequences_middleware(Store<AppState> store, action, NextDispatcher next) {
  next(action);

  AppState state = store.state;

  // Export CSV DNA for CanDo.
  if (action is actions.ExportCanDoDNA) {
    List<Strand> strands;
    strands = state.design.strands.toList();
    strands.removeWhere((strand) => strand.is_scaffold);

    String filename = 'cando_sequences.csv';
    util.BlobType blob_type = util.BlobType.text;

    try {
      String result = cando_compatible_csv_export(strands);

      // See export comments for why we have this stupid special case
      // if (result is Future<List<int>>) {
      //   result.then((response) {
      //     List<int> content = response;
      //     util.save_file(filename, content, blob_type: blob_type);
      //   }).catchError((e, stackTrace) {
      //     var cause = "";
      //     if (has_cause(e)) {
      //       cause = e.cause;
      //     } else if (has_message(e)) {
      //       cause = e.message;
      //     }
      //     var msg = cause + '\n\n' + stackTrace.toString();
      //     store.dispatch(actions.ErrorMessageSet(msg));
      //     app.view.design_view.render(store.state);
      //   });
      // } else {
      String content = result;
      util.save_file(filename, content, blob_type: blob_type);
      // }
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

// Export DNA for other platforms.
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
      var result = action.export_dna_format.export(
        strands,
        strand_order: action.strand_order,
        column_major_strand: action.column_major_strand,
        column_major_plate: action.column_major_plate,
      );
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

String cando_compatible_csv_export(Iterable<Strand> strands) {
  StringBuffer buf = StringBuffer();
// Write the CSV header
  buf.writeln('Start,End,Sequence,Length,Color');
  for (var strand in strands) {
// If the export name contains 'SCAF', then it's a scaffold strand, so we do not export it for cando.
    if (strand.idt_export_name().contains('SCAF')) {
      continue;
    }
// Remove the characters 'ST' from the start of the export name as cando doesn't understand them.
    var cando_strand = strand.idt_export_name().replaceAll(RegExp(r'^ST'), '');
// Split the export name into the start and end positions.
    RegExp cando_split_regex = RegExp(r'\d+\[\d+\]');
    List<String> cando_split_name =
        cando_split_regex.allMatches(cando_strand).map((match) => match.group(0)).toList();
    if (cando_split_name.length != 2) {
      throw ExportDNAException('Invalid strand name: ${strand.idt_export_name()}');
    }
    var cando_strand_end = cando_split_name[1];
    var cando_strand_start = cando_split_name[0];
// Write the strand to the CSV file.
    buf.writeln(
        '${cando_strand_start},${cando_strand_end},${idt_sequence_null_aware(strand)},${idt_sequence_null_aware(strand).length},${strand.color.toHexColor().toCssString().toUpperCase()}');
  }
  return buf.toString();
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
