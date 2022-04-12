// @dart=2.9

import 'dart:convert';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/export_dna_format.dart';
import 'package:scadnano/src/state/export_dna_format_strand_order.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/util.dart' as util;

import 'utils.dart';

main() {
  /*
  Removing scaffold from this design:
    0        8        16       24       32       40       48       56       64       72       80       88      96
0   +------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------+
   /<------- -------+ +------- -------- -------] <------- -------- -------- -------] <------+ +------- -------]\
  (                 | |                                                                     | |                 )
1  \[------- -------+ +------> [------+ +------- -------- -------> [------+ +------- -------+ +------- ------->/
    +------- -------- -------- -------- -------- -------+ +------- -------- -------- -------- -------- -------+
                                      | |               | |               | |
2   +------- -------- -------- -------- -------- -------+ +------- -------- -------- -------- -------- -------+
   /<------- -------+ +------- -------+ +------] <------- -------- -------+ +------] <------+ +------- -------]\
  (                 | |                                                                     | |                 )
3  \[------- -------+ +------> [------+ +------- -------- -------> [------+ +------- -------+ +------- ------->/
    +------- -------- -------- -------- -------- -------+ +------- -------- -------- -------- -------- -------+
                                      | |               | |               | |
4   +------- -------- -------- -------- -------- -------+ +------- -------- -------- -------- -------- -------+
   /<------- -------+ +------- -------+ +------] <------- -------- -------+ +------] <------+ +------- -------]\
  (                 | |                                                                     | |                 )
5  \[------- -------+ +------> [------- -------- -------- -------> [------- -------- -------+ +------- ------->/
    +------- -------- -------- -------- -------- -------] <------- -------- -------- -------- -------- -------+

gives this (removed scaffold to make it easier for me to visually track the strands)

    0        8        16       24       32       40       48       56       64       72       80       88      96
0   <-------A-------+ +-------D--------D-------] <-------G--------G--------G-------] <------+ +-------P-------]
                    | |                                                                     | |
1   [-------A-------+ +------> [------+ +-------H--------H-------> [------+ +-------M-------+ +-------P------->
                                      | |                                 | |
2   <-------B-------+ +-------E-------+ +------] <-------I--------I-------+ +------] <------+ +-------Q-------]
                    | |                                                                     | |
3   [-------B-------+ +------> [------+ +-------J--------J-------> [------+ +-------N-------+ +-------Q------->
                                      | |                                 | |
4   <-------C-------+ +-------F-------+ +------] <-------K--------K-------+ +------] <------+ +-------R-------]
                    | |                                                                     | |
5   [-------C-------+ +------> [-------L--------L--------L-------> [-------O--------O-------+ +-------R------->

We give the strands simple single-letter names to help test they appear in the correct order in the output.

row major 5':                    DGPAEIHMQBFKJNRCLO
col major 5':                    ABCEFLDHJIKOGMNPQR
row major 3':                    AGMDHPBINEJQCKOFLR
col major 3':                    ABCDEFGIKHJLMNOPQR
row major 5' or 3':              ADGMPEHIBNQFJKCORL
col major 5' or 3':              ABCDEFLHJGIKOMNPQR
row major top-left domain start: ADGMPEHIBNQFJKCORL
col major top-left domain start: ABCDEFLHJGIKMNOPQR
   */

  var helices = [for (int i = 0; i < 6; i++) Helix(idx: i, max_offset: 100, grid: Grid.square)];
  var d = Design(helices: helices, grid: Grid.square);

  d = d.draw_strand(1, 0).move(16).cross(0).move(-16).with_name('A').commit();
  d = d.draw_strand(3, 0).move(16).cross(2).move(-16).with_name('B').commit();
  d = d.draw_strand(5, 0).move(16).cross(4).move(-16).with_name('C').commit();

  d = d.draw_strand(0, 40).move(-24).cross(1).move(8).with_name('D').commit();

  d = d.draw_strand(1, 24).move(8).cross(2).move(-16).cross(3).move(8).with_name('E').commit();
  d = d.draw_strand(3, 24).move(8).cross(4).move(-16).cross(5).move(8).with_name('F').commit();

  d = d.draw_strand(0, 72).move(-32).with_name('G').commit();

  d = d.draw_strand(2, 40).move(-8).cross(1).move(24).with_name('H').commit();
  d = d.draw_strand(1, 56).move(8).cross(2).move(-24).with_name('I').commit();

  d = d.draw_strand(4, 40).move(-8).cross(3).move(24).with_name('J').commit();
  d = d.draw_strand(3, 56).move(8).cross(4).move(-24).with_name('K').commit();

  d = d.draw_strand(5, 24).move(32).with_name('L').commit();

  d = d.draw_strand(2, 72).move(-8).cross(1).move(16).cross(0).move(-8).with_name('M').commit();
  d = d.draw_strand(4, 72).move(-8).cross(3).move(16).cross(2).move(-8).with_name('N').commit();

  d = d.draw_strand(5, 56).move(24).cross(4).move(-8).with_name('O').commit();

  d = d.draw_strand(0, 96).move(-16).cross(1).move(16).with_name('P').commit();
  d = d.draw_strand(2, 96).move(-16).cross(3).move(16).with_name('Q').commit();
  d = d.draw_strand(4, 96).move(-16).cross(5).move(16).with_name('R').commit();

  // assign DNA to strands so we can export IDT
  var strands = d.strands.toList();
  for (int i = 0; i < strands.length; i++) {
    var strand = strands[i];
    strand = strand.set_dna_sequence('A' * 32);
    strand = strand.initialize();
    strands[i] = strand;
  }
  d = d.rebuild((b) => b..strands.replace(strands));

  // use friendlier name in tests below
  var design_6h = d;

  String get_names_idt(Design design, StrandOrder strand_order, bool column_major) {
    // get IDT names of strands exported, and return them joined into a single string
    ExportDNAFormat format = ExportDNAFormat.idt_bulk;
    //XXX: export can return a Future<List<int>>, but only when exporting to Excel files.
    String idt_str = format.export(strands, strand_order: strand_order, column_major: column_major);

    List<String> idt_lines = idt_str.split('\n');
    List<String> names = [];
    for (var line in idt_lines) {
      var name = line.split(',')[0];
      names.add(name);
    }
    var names_joined = names.join('');
    return names_joined;
  }

  test('to_idt_bulk_input_format__row_major_5p', () {
    var names_joined = get_names_idt(design_6h, StrandOrder.five_prime, false);
    expect(names_joined, 'DGPAEIHMQBFKJNRCLO');
  });

  test('to_idt_bulk_input_format__col_major_5p', () {
    var names_joined = get_names_idt(design_6h, StrandOrder.five_prime, true);
    expect(names_joined, 'ABCEFLDHJIKOGMNPQR');
  });

  test('to_idt_bulk_input_format__row_major_3p', () {
    var names_joined = get_names_idt(design_6h, StrandOrder.three_prime, false);
    expect(names_joined, 'AGMDHPBINEJQCKOFLR');
  });

  test('to_idt_bulk_input_format__col_major_3p', () {
    var names_joined = get_names_idt(design_6h, StrandOrder.three_prime, true);
    expect(names_joined, 'ABCDEFGIKHJLMNOPQR');
  });

  test('to_idt_bulk_input_format__row_major_5p_or_3p', () {
    var names_joined = get_names_idt(design_6h, StrandOrder.five_or_three_prime, false);
    expect(names_joined, 'ADGMPEHIBNQFJKCORL');
  });

  test('to_idt_bulk_input_format__col_major_5p_or_3p', () {
    var names_joined = get_names_idt(design_6h, StrandOrder.five_or_three_prime, true);
    expect(names_joined, 'ABCDEFLHJGIKOMNPQR');
  });

  test('to_idt_bulk_input_format__row_major_top_left_domain_start', () {
    var names_joined = get_names_idt(design_6h, StrandOrder.top_left_domain_start, false);
    expect(names_joined, 'ADGMPEHIBNQFJKCORL');
  });

  test('to_idt_bulk_input_format__col_major_top_left_domain_start', () {
    var names_joined = get_names_idt(design_6h, StrandOrder.top_left_domain_start, true);
    expect(names_joined, 'ABCDEFLHJGIKMNOPQR');
  });

  test('from_json__legacy_idt_name__no_strand_name', () {
    // tests proper importing of old format when name was a subfield of idt;
    // ensures if that exists and no Strand.name field exists, the idt.name is used as Strand.name
    var json_str = '''
    {
      "version": "0.14.0",
      "grid": "square",
      "helices": [
        {"grid_position": [0, 0]},
        {"grid_position": [0, 1]}
      ],
      "strands": [
        {
          "color": "#f74308",
          "sequence": "TATTATAGTCTTACCCTGAC",
          "idt": {"name": "staple1", "scale": "100nm", "purification": "HPLC", "plate": "plate1", "well": "A1"},
          "domains": [
            {"helix": 0, "forward": true, "start": 0, "end": 10},
            {"helix": 1, "forward": false, "start": 0, "end": 10}
          ]
        }
      ]
    }
    ''';

    var design = Design.from_json_str(json_str);
    expect(design.strands.length, 1);
    var strand = design.strands[0];
    expect(strand.name, 'staple1');
    expect(strand.idt.scale, '100nm');
    expect(strand.idt.purification, 'HPLC');
    expect(strand.idt.plate, 'plate1');
    expect(strand.idt.well, 'A1');
  });

  test('from_json__legacy_idt_name__strand_name_exists', () {
    // tests proper importing of old format when name was a subfield of idt;
    // ensures if that exists and no Strand.name field exists, the idt.name is used as Strand.name
    var json_str = '''
    {
      "version": "0.14.0",
      "grid": "square",
      "helices": [
        {"grid_position": [0, 0]},
        {"grid_position": [0, 1]}
      ],
      "strands": [
        {
          "name": "staple1 strand level",
          "color": "#f74308",
          "sequence": "TATTATAGTCTTACCCTGAC",
          "idt": {"name": "staple1", "scale": "100nm", "purification": "HPLC", "plate": "plate1", "well": "A1"},
          "domains": [
            {"helix": 0, "forward": true, "start": 0, "end": 10},
            {"helix": 1, "forward": false, "start": 0, "end": 10}
          ]
        }
      ]
    }
    ''';

    var design = Design.from_json_str(json_str);
    expect(design.strands.length, 1);
    var strand = design.strands[0];
    expect(strand.name, 'staple1 strand level');
  });

}
