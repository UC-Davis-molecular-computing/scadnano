import 'package:redux/redux.dart';
import 'package:scadnano/src/state/dialog.dart';
import 'package:scadnano/src/state/export_dna_format.dart';
import 'package:scadnano/src/state/export_dna_format_strand_order.dart';

import '../app.dart';
import '../state/strand.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../util.dart' as util;
import '../util.dart';

String get_cause(Object e) {
  if (e is Exception) {
    return e.toString();
  } else if (e is Error) {
    return e.toString();
  } else {
    return e.toString();
  }
}

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
      String content = result;
      util.save_file(filename, content, blob_type: blob_type);
    } catch (e, stackTrace) {
      var cause = get_cause(e);
      String msg = '$cause\n\n$stackTrace';
      store.dispatch(actions.ErrorMessageSet(msg));
      app.view.design_view.render(store.state);
    }
  }

  // Export DNA for other platforms.
  if (action is actions.ExportDNA) {
    List<Strand> strands;
    if (action.include_only_selected_strands) {
      strands = state.ui_state.selectables_store.selected_strands.toList();
    } else if (action.exclude_selected_strands) {
      strands = state.design.strands.toList();
      for (var strand in state.ui_state.selectables_store.selected_strands) {
        strands.remove(strand);
      }
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
        delimiter: action.delimiter,
        domain_delimiter: action.domain_delimiter,
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
      var cause = get_cause(e);
      String msg = '$cause\n\n$stackTrace';
      store.dispatch(actions.ErrorMessageSet(msg));
      app.view.design_view.render(store.state);
    }
  }
}

// called from view/menu.dart but makes more sense to keep the code here
Future<void> export_dna() async {
  List<String> export_options = ExportDNAFormat.values.map((v) => v.toString()).toList();
  List<String> sort_options = StrandOrder.values.map((v) => v.toString()).toList();

  int idx_include_scaffold = 0;
  int idx_include_only_selected_strands = 1;
  int idx_exclude_selected_strands = 2;
  int idx_format_str = 3;
  int idx_delimiter = 4;
  int idx_domain_delimiter = 5;
  int idx_column_major_plate = 6;
  int idx_sort = 7;
  int idx_column_major_strand = 8;
  int idx_strand_order_str = 9;

  FixedList<DialogItem> items = FixedList<DialogItem>(idx_strand_order_str + 1);

  items[idx_delimiter] = DialogText(label: 'delimiter between IDT fields', value: ',', tooltip: '''\
Delimiter to separate IDT fields in a "bulk input" text file, for instance if set to ";", then a line 
of the file could be
  strand_name;AAAAACCCCCGGGGG;25nm;STD''');

  items[idx_domain_delimiter] =
      DialogText(label: 'delimiter between DNA sequences of domains', value: '', tooltip: '''\
Delimiter to separate DNA sequences from different domains/loopouts/extensions, for instance if set to " ", 
then the exported DNA sequence could be
  AAAAA CCCCC GGGGG
if it had three domains each of length 5.''');

  items[idx_include_scaffold] = DialogCheckbox(label: 'include scaffold', value: false);
  items[idx_include_only_selected_strands] =
      DialogCheckbox(label: 'include only selected strands', value: false);
  items[idx_exclude_selected_strands] = DialogCheckbox(label: 'exclude selected strands', value: false);
  items[idx_format_str] = DialogRadio(
    label: 'export format',
    options: export_options,
    radio: false,
    option_tooltips: ExportDNAFormat.tooltips,
  );
  items[idx_column_major_plate] = DialogCheckbox(
      label: 'column-major well order (uncheck for row-major order)', value: true, tooltip: """\
For exporting to plates, this customizes the order in which wells are enumerated.
Column-major order is A1, B1, C1, ... Row-major order is A1, A2, A3, ... 
Note that this is distinct from the notion of "sort strands", which helps specify the 
order in which strands are processed (as opposed to order of wells in a plate).
""");
  items[idx_sort] = DialogCheckbox(label: 'sort strands', value: false, tooltip: """\
By default strands are exported in the order they are stored in the .sc file.
Checking this box allows some customization of the order in which strands are processed.
(See "column-major" box below for description.) Note that for exporting plates, 
this is distinct from the order in which wells are enumerated when putting strands 
into the plate. That can be customized by selecting "column-major well order" below.
""");
  items[idx_column_major_strand] = DialogCheckbox(
      label: 'column-major strand order (uncheck for row-major order)', value: true, tooltip: """\
When checked, strands are processed in column-major "visual order" by their 5' ends. 
Column-major means sort first by offset, then by helix index. For example, if
the 5' addresses are (0,5), meaning helix 0 at offset 5, 
then (0,10), (0,15), (1,5), (1,10), (1,15), (2,5), (2,10), (2,15),
then that is row-major order. Column-major order would be
(0,5), (1,5), (2,5), (0,10), (1,10), (2,10), (0,15), (1,15), (2,15).
Finally, instead of using the addresses of 5' ends, other strand "parts" can be
used to sort; see options under "strand part to sort by".
""");
  items[idx_strand_order_str] = DialogRadio(
    label: 'strand part to sort by',
    options: sort_options,
    tooltip: """\
When sorting strands by their "address" (helix index and offset), this indicates
which part of the strand to use as the address.
""",
    option_tooltips: StrandOrder.sort_option_tooltips,
    radio: false,
  );

  var dialog = Dialog(
      title: 'export DNA sequences',
      type: DialogType.export_dna_sequences,
      items: items,
      disable_when_any_checkboxes_on: {
        idx_include_only_selected_strands: [idx_exclude_selected_strands],
        idx_exclude_selected_strands: [idx_include_only_selected_strands],
      },
      disable_when_any_checkboxes_off: {
        idx_column_major_strand: [idx_sort],
        idx_strand_order_str: [idx_sort],
      },
      disable_when_any_radio_button_selected: {
        idx_column_major_plate: {
          idx_format_str: [
            // need to use toString() to get the exact string value displayed for later comparison
            // using ExportDNAFormat.name instead will return a different string (e.g. 'csv' vs
            // 'CSV (.csv)') than displayed in the radio button
            ExportDNAFormat.csv.toString(),
            ExportDNAFormat.idt_bulk.toString(),
          ]
        },
      });

  List<DialogItem>? results = await util.dialog(dialog);
  if (results == null) return;

  bool include_scaffold = (results[idx_include_scaffold] as DialogCheckbox).value;
  bool include_only_selected_strands = (results[idx_include_only_selected_strands] as DialogCheckbox).value;
  bool exclude_selected_strands = (results[idx_exclude_selected_strands] as DialogCheckbox).value;
  String format_str = (results[idx_format_str] as DialogRadio).value;
  bool sort = (results[idx_sort] as DialogCheckbox).value;
  StrandOrder? strand_order = null;
  bool column_major_strand = true;
  if (sort) {
    column_major_strand = (results[idx_column_major_strand] as DialogCheckbox).value;
    String strand_order_str = (results[idx_strand_order_str] as DialogRadio).value;
    strand_order = StrandOrder.fromString(strand_order_str);
  }
  bool column_major_plate = (results[idx_column_major_plate] as DialogCheckbox).value;
  ExportDNAFormat format = ExportDNAFormat.fromString(format_str);
  String delimiter = (results[idx_delimiter] as DialogText).value;
  String domain_delimiter = (results[idx_domain_delimiter] as DialogText).value;

  assert(!(include_only_selected_strands && exclude_selected_strands));

  app.dispatch(actions.ExportDNA(
    include_scaffold: include_scaffold,
    include_only_selected_strands: include_only_selected_strands,
    exclude_selected_strands: exclude_selected_strands,
    export_dna_format: format,
    delimiter: delimiter,
    domain_delimiter: domain_delimiter,
    strand_order: strand_order,
    column_major_strand: column_major_strand,
    column_major_plate: column_major_plate,
  ));
}

String cando_compatible_csv_export(Iterable<Strand> strands) {
  StringBuffer buf = StringBuffer();
  // Write the CSV header
  buf.writeln('Start,End,Sequence,Length,Color');
  for (var strand in strands) {
    // If the export name contains 'SCAF', then it's a scaffold strand, so we do not export it for cando.
    if (strand.vendor_export_name().contains('SCAF')) {
      continue;
    }
    // Remove the characters 'ST' from the start of the export name as cando doesn't understand them.
    var cando_strand = strand.vendor_export_name().replaceAll(RegExp(r'^ST'), '');
    // Split the export name into the start and end positions.
    RegExp cando_split_regex = RegExp(r'\d+\[\d+\]');
    List<String?> cando_split_name =
        cando_split_regex.allMatches(cando_strand).map((match) => match.group(0)).toList();
    if (cando_split_name.length != 2) {
      throw ExportDNAException('Invalid strand name: ${strand.vendor_export_name()}');
    }
    String cando_strand_end = cando_split_name[1]!;
    String cando_strand_start = cando_split_name[0]!;
    // Write the strand to the CSV file.
    buf.writeln('${cando_strand_start},${cando_strand_end}'
        ',${vendor_sequence_null_aware(strand, "")}'
        ',${vendor_sequence_null_aware(strand, "").length}'
        ',${strand.color.toHexColor().toCssString().toUpperCase()}');
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
