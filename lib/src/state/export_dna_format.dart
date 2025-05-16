import 'dart:typed_data';
import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/view/menu_form_file.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../util.dart' as util;
import 'strand.dart';
import 'export_dna_format_strand_order.dart';

part 'export_dna_format.g.dart';

typedef StrandComparison = int Function(Strand s1, Strand s2);

(int, int) strand_helix_offset_key(Strand strand, StrandOrder strand_order, bool column_major) {
  int helix_idx;
  int offset;
  if (strand_order == StrandOrder.five_prime) {
    helix_idx = strand.first_domain.helix;
    offset = strand.first_domain.offset_5p;
  } else if (strand_order == StrandOrder.three_prime) {
    helix_idx = strand.last_domain.helix;
    offset = strand.last_domain.offset_3p;
  } else if (strand_order == StrandOrder.five_or_three_prime) {
    int helix_idx_5p = strand.first_domain.helix;
    int offset_5p = strand.first_domain.offset_5p;
    int helix_idx_3p = strand.last_domain.helix;
    int offset_3p = strand.last_domain.offset_3p;
    if (column_major) {
      if (offset_5p < offset_3p || (offset_5p == offset_3p && helix_idx_5p <= helix_idx_3p)) {
        offset = offset_5p;
        helix_idx = helix_idx_5p;
      } else {
        offset = offset_3p;
        helix_idx = helix_idx_3p;
      }
    } else {
      if (helix_idx_5p < helix_idx_3p || (helix_idx_5p == helix_idx_3p && offset_5p <= offset_3p)) {
        helix_idx = helix_idx_5p;
        offset = offset_5p;
      } else {
        helix_idx = helix_idx_3p;
        offset = offset_3p;
      }
    }
  } else if (strand_order == StrandOrder.top_left_domain_start) {
    helix_idx = strand.first_domain.helix;
    offset = strand.first_domain.start;
    for (var domain in strand.domains) {
      if (helix_idx > domain.helix || (helix_idx == domain.helix && offset > domain.start)) {
        helix_idx = domain.helix;
        offset = domain.start;
      }
    }
  } else {
    throw ArgumentError('${strand_order} is not a valid StrandOrder');
  }
  return (helix_idx, offset);
}

/// Returns comparison function that can be used to sort Strands
StrandComparison strands_comparison_function(StrandOrder strand_order, bool column_major) {
  int compare(Strand strand1, Strand strand2) {
    var (helix_idx1, offset1) = strand_helix_offset_key(strand1, strand_order, column_major); // (int, int)
    var (helix_idx2, offset2) = strand_helix_offset_key(strand2, strand_order, column_major); // (int, int)

    (int, int) tuple1;
    (int, int) tuple2;
    if (column_major) {
      tuple1 = (offset1, helix_idx1);
      tuple2 = (offset2, helix_idx2);
    } else {
      tuple1 = (helix_idx1, offset1);
      tuple2 = (helix_idx2, offset2);
    }

    if (tuple1.$1 != tuple2.$1) {
      return tuple1.$1 - tuple2.$1;
    } else {
      return tuple1.$2 - tuple2.$2;
    }
  }

  return compare;
}

/// Format of exported DNA sequences
class ExportDNAFormat extends EnumClass {
  static const tooltips = [
    """\
Format for IDT's "bulk input" webpage when specifying strands
in individual test tubes.
""",
    """\
Excel file formatted for IDT's plate upload webpage for 96-well plates.
""",
    """\
Excel file formatted for IDT's plate upload webpage for 384-well plates.
""",
    """\
Simple CSV (comma-separated value) format. Not a format used by any biotech company.""",
  ];

  const ExportDNAFormat._(String name) : super(name);

  static Serializer<ExportDNAFormat> get serializer => _$exportDNAFormatSerializer;

  static const ExportDNAFormat idt_bulk = _$idt_bulk;
  static const ExportDNAFormat idt_plates96 = _$idt_plates96;
  static const ExportDNAFormat idt_plates384 = _$idt_plates384;
  static const ExportDNAFormat csv = _$csv;

  static BuiltSet<ExportDNAFormat> get values => _$values;

  static ExportDNAFormat valueOf(String name) => _$valueOf(name);

  String extension() {
    switch (this) {
      case csv:
        return 'csv';
      case idt_bulk:
        return 'txt';
      case idt_plates96:
      case idt_plates384:
        return 'xlsx';
    }
    throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }

  static const Map<ExportDNAFormat, String> _toString_map = {
    csv: 'CSV (.csv)',
    idt_bulk: 'IDT Bulk (.txt)',
    idt_plates96: 'IDT 96-well plate(s) (.xlsx)',
    idt_plates384: 'IDT 384-well plate(s) (.xlsx)',
  };

  String toString() => _toString_map[this]!;

  /// Inverse of toString()
  static ExportDNAFormat fromString(String str) {
    for (var format in _toString_map.keys) {
      String val_str = _toString_map[format]!;
      if (val_str == str) {
        return format;
      }
    }
    throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }

  bool text_file() {
    switch (this) {
      case csv:
        return true;
      case idt_bulk:
        return true;
      case idt_plates96:
      case idt_plates384:
        return false;
    }
    throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }

  util.BlobType blob_type() {
    switch (this) {
      case csv:
        return util.BlobType.text;
      case idt_bulk:
        return util.BlobType.text;
      case idt_plates96:
      case idt_plates384:
        return util.BlobType.excel;
    }
    throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }

  /// Output object (String if text file; Future<List<int>> if binary) representing list of Strands
  /// I couldn't see a way to export Excel files synchronously, since they require loading an
  /// existing Excel file from a local resource using an HttpRequest, which is asynchronous.
  /// So export returns a Future<List<int>> if calling idt_plates_export and a String (with text file
  /// contents) otherwise. The caller needs to check the return type, or the type of this,
  /// to determine whether to use the return value directly or to wait for it asynchronously.
  export(
    Iterable<Strand> strands, {
    String delimiter = ',',
    String domain_delimiter = '',
    StrandOrder? strand_order = null,
    bool column_major_strand = true,
    bool column_major_plate = true,
  }) {
    List<Strand> strands_sorted = strands.toList();
    if (strand_order != null) {
      StrandComparison compare = strands_comparison_function(strand_order, column_major_strand);
      strands_sorted.sort(compare);
    }

    try {
      switch (this) {
        case csv:
          return csv_export(strands_sorted, domain_delimiter);
        case idt_bulk:
          return idt_bulk_export(strands_sorted, delimiter: delimiter, domain_delimiter: domain_delimiter);
        case idt_plates96:
          return idt_plates_export(
            strands_sorted,
            PlateType.wells96,
            column_major_plate,
            domain_delimiter: domain_delimiter,
          );
        case idt_plates384:
          return idt_plates_export(
            strands_sorted,
            PlateType.wells384,
            column_major_plate,
            domain_delimiter: domain_delimiter,
          );
      }
    } on ExportDNAException catch (e) {
      throw e;
    } on Error {
      //FIXME: this isn't catching the error when the Excel file isn't found
      throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
    } on Exception {
      //FIXME: this isn't catching the error when the Excel file isn't found
      throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
    }
    throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }
}

class ExportDNAException implements Exception {
  String cause;

  ExportDNAException(this.cause);
}

String csv_export(Iterable<Strand> strands, String domain_delimiter) {
  var lines = strands.map(
    (strand) => '${strand.vendor_export_name()},${vendor_sequence_null_aware(strand, domain_delimiter)}',
  );
  return lines.join('\n');
}

String vendor_sequence_null_aware(Strand strand, String domain_delimiter) =>
    strand.vendor_dna_sequence(domain_delimiter: domain_delimiter) ?? '*****NONE*****';

String idt_bulk_export(
  Iterable<Strand> strands, {
  String delimiter = ',',
  String domain_delimiter = '',
  String scale = '25nm',
  String purification = 'STD',
}) {
  var lines = strands.map(
    (strand) =>
        '${strand.vendor_export_name()}'
        '${delimiter}'
        '${vendor_sequence_null_aware(strand, domain_delimiter)}'
        '${delimiter}'
        '${scale}'
        '${delimiter}'
        '${purification}',
  );
  return lines.join('\n');
}

Future<List<int>> idt_plates_export(
  Iterable<Strand> strands,
  PlateType plate_type,
  bool column_major_plate, {
  required String domain_delimiter,
}) async {
  var plate_coord = _PlateCoordinate(plate_type);
  int plate = 1;
  int excel_row = 1;
  String plate_name = 'plate${plate}';

  int num_strands_per_plate = num_wells_per_plate(plate_type);
  int num_plates_needed = strands.length ~/ num_strands_per_plate;
  if (strands.length % num_strands_per_plate != 0) {
    num_plates_needed++;
  }
  int min_strands_per_plate = min_wells_per_plate(plate_type);

  int num_strands_plates_except_final = max(0, (num_plates_needed - 1) * num_strands_per_plate);
  int num_strands_final_plate = strands.length - num_strands_plates_except_final;
  bool final_plate_less_than_min_required = num_strands_final_plate < min_strands_per_plate;

  if (num_plates_needed > 10) {
    throw ExportDNAException(
      'To put ${strands.length} strands into ${plate_type == PlateType.wells96 ? 96 : 384}-well plates '
      'requires ${num_plates_needed} plates.\n'
      'It is currently unsupported to create more than 10 plates in a single design.\n'
      'Please file an issue requesting this feature here: '
      'https://github.com/UC-Davis-molecular-computing/scadnano/issues',
    );
  }

  String filename = 'excel-spreadsheets/idt-plates-empty-${num_plates_needed}plate.xlsx';
  ByteBuffer data = await util.get_binary_file_content(filename);
  List<int> bytes = Uint8List.view(data);
  var decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true, verify: true);

  int num_strands_remaining = strands.length;
  bool on_final_plate = num_plates_needed == 1;
  for (var strand in strands) {
    var well = plate_coord.well();
    decoder.insertRow(plate_name, excel_row);
    decoder.updateCell(plate_name, 0, excel_row, well);
    decoder.updateCell(plate_name, 1, excel_row, strand.vendor_export_name());
    decoder.updateCell(plate_name, 2, excel_row, vendor_sequence_null_aware(strand, domain_delimiter));
    num_strands_remaining--;

    // IDT charges extra for a plate with < 24 strands for 96-well plate
    // or < 96 strands for 384-well plate.
    // So if we would have fewer than that many on the last plate,
    // shift some from the penultimate plate.
    if (!on_final_plate &&
        final_plate_less_than_min_required &&
        num_strands_remaining == min_strands_per_plate) {
      plate_coord.advance_to_next_plate();
    } else {
      plate_coord.increment(column_major_plate);
    }

    if (plate != plate_coord.plate) {
      plate = plate_coord.plate;
      plate_name = 'plate${plate}';
      excel_row = 1;
      on_final_plate = true;
      //TODO: add a new table with name plate_name; for now we hardcode the number of plates in advance
      // https://github.com/sestegra/spreadsheet_decoder/issues/20
      //      worksheet = self._add_new_excel_plate_sheet(plate_name, workbook);
    } else {
      excel_row++;
    }
  }

  var bytes_out = decoder.encode();
  return bytes_out;
}

enum PlateType { wells96, wells384, none }

int num_wells_per_plate(PlateType plate_type) {
  switch (plate_type) {
    case PlateType.wells96:
      return 96;
    case PlateType.wells384:
      return 384;
    case PlateType.none:
      throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }
}

int min_wells_per_plate(PlateType plate_type) {
  switch (plate_type) {
    case PlateType.wells96:
      return 24;
    case PlateType.wells384:
      return 96;
    case PlateType.none:
      throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }
}

List<String> rows_of(PlateType plate_type) {
  switch (plate_type) {
    case PlateType.wells96:
      return ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    case PlateType.wells384:
      return ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P'];
    case PlateType.none:
      throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }
}

List<int> cols_of(PlateType plate_type) {
  switch (plate_type) {
    case PlateType.wells96:
      return [for (int i = 1; i <= 12; i++) i];
    case PlateType.wells384:
      return [for (int i = 1; i <= 24; i++) i];
    case PlateType.none:
      throw ExportDNAException(util.ASSERTION_ERROR_MESSAGE);
  }
}

class _PlateCoordinate {
  PlateType plate_type;
  int plate = 1;
  int row_idx = 0;
  int col_idx = 0;

  _PlateCoordinate(this.plate_type);

  increment(bool column_major) {
    if (column_major) {
      row_idx++;
      if (row_idx == rows_of(plate_type).length) {
        row_idx = 0;
        col_idx++;
        if (col_idx == cols_of(plate_type).length) {
          col_idx = 0;
          plate++;
        }
      }
    } else {
      col_idx++;
      if (col_idx == cols_of(plate_type).length) {
        col_idx = 0;
        row_idx++;
        if (row_idx == rows_of(plate_type).length) {
          row_idx = 0;
          plate++;
        }
      }
    }
  }

  advance_to_next_plate() {
    row_idx = 0;
    col_idx = 0;
    plate++;
  }

  String row() => rows_of(plate_type)[row_idx];

  int col() => cols_of(plate_type)[col_idx];

  String well() => '${row()}${col()}';
}
