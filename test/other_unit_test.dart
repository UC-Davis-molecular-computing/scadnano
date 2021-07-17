// @dart=2.9

import 'dart:convert';
import 'dart:html';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:scadnano/src/state/domain.dart';
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

  test('util.position3d_to_grid_position', () {
    var grid = Grid.square;
    var geometry = Geometry(helix_radius: 2.0, inter_helix_gap: 1.0);

    var position11 = Position3D(x: 0.0, y: 3.0, z: 3.0);
    var grid_position11_actual = util.position3d_to_grid_position(position11, grid, geometry);
    var grid_position11_expected = GridPosition(1, 1);
    expect(grid_position11_expected, grid_position11_actual);

    var position00 = Position3D(x: 0.0, y: 0.0, z: 0.0);
    var grid_position00_actual = util.position3d_to_grid_position(position00, grid, geometry);
    var grid_position00_expected = GridPosition(0, 0);
    expect(grid_position00_expected, grid_position00_actual);

    var position21 = Position3D(x: 0.0, y: 2.5, z: 5.0);
    var grid_position21_actual = util.position3d_to_grid_position(position21, grid, geometry);
    var grid_position21_expected = GridPosition(1, 1);
    expect(grid_position21_expected, grid_position21_actual);
  });

  test('duplicate_deletions_in_JSON_removed', () {
    var json_str = '''
{
  "grid": "square",
  "helices": [
    {
      "max_offset": 100,
      "grid_position": [0, 0]
    }
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8, "deletions": [5, 5, 7]}
      ]
    }
  ]
}    
''';
    var json_map = jsonDecode(json_str);
    var design = Design.from_json(json_map);
    var deletions = design.strands[0].domains[0].deletions;
    expect(2, deletions.length);
    expect(5, deletions[0]);
    expect(7, deletions[1]);
  });

  test('duplicate_insertions_in_JSON_removed', () {
    var json_str = '''
{
  "grid": "square",
  "helices": [
    {
      "max_offset": 100,
      "grid_position": [0, 0]
    }
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8, "insertions": [[5,2], [5,2], [7,3]]}
      ]
    }
  ]
}    
''';
    var json_map = jsonDecode(json_str);
    var design = Design.from_json(json_map);
    var insertions = design.strands[0].domains[0].insertions;
    expect(2, insertions.length);
    expect(5, insertions[0].offset);
    expect(2, insertions[0].length);
    expect(7, insertions[1].offset);
    expect(3, insertions[1].length);
  });

  test('duplicate_insertions_with_contradictory_length_in_JSON_throws_exception', () {
    var json_str = '''
{
  "grid": "square",
  "helices": [
    {
      "max_offset": 100,
      "grid_position": [0, 0]
    }
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8, "insertions": [[5,2], [5,3], [7,3]]}
      ]
    }
  ]
}    
''';
    var json_map = jsonDecode(json_str);
    expect(() => Design.from_json(json_map), throwsException);
  });

  test('util_deltas_starting_0', () {
    List<int> nums = [0, 2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [0, 2, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });

  test('util_deltas_starting_positive', () {
    List<int> nums = [2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [2, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });

  test('util_deltas_starting_negative', () {
    List<int> nums = [-5, 2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [-5, 7, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });

  test('read_old_version_position_x_z_swapped', () {
    String no_grid_two_helices_json = r"""
          {
            "version": "0.8.0",
            "grid": "none",
            "helices": [
              {
                "position": {"x": 10, "y": 60, "z": 30}
              },
              {
                "position": {"x": 20, "y": 80, "z": 50}
              }
            ],
            "strands": [
              {
                "domains": [
                  {"helix": 0, "forward": true , "start": 0, "end": 16}
                ]
              },
              {
                "domains": [
                  {"helix": 0, "forward": false , "start": 0, "end": 16}
                ]
              },
              {
                "domains": [
                  {"helix": 1, "forward": true , "start": 0, "end": 16}
                ]
              },
              {
                "domains": [
                  {"helix": 1, "forward": false , "start": 0, "end": 16}
                ]
              }
            ]
          }
      """;
    Design design = Design.from_json(jsonDecode(no_grid_two_helices_json), false);
    // ensure x and z are swapped after reading in
    //TODO: test for swapping x and z positions in versions < 0.9.0 temporarily disabled until
    // codenano/scadnano versions are aligned
   expect(design.helices[0].position3d().x, 30);
   expect(design.helices[0].position3d().y, 60);
   expect(design.helices[0].position3d().z, 10);
   expect(design.helices[1].position3d().x, 50);
   expect(design.helices[1].position3d().y, 80);
   expect(design.helices[1].position3d().z, 20);
  });

  group('strand_maker_tests', () {
    List<Helix> helices = [
      Helix(idx: 0, geometry: Geometry(), grid_position: GridPosition(0, 0), grid: Grid.square),
      Helix(idx: 1, geometry: Geometry(), grid_position: GridPosition(0, 1), grid: Grid.square),
      Helix(idx: 2, geometry: Geometry(), grid_position: GridPosition(0, 2), grid: Grid.square),
      Helix(idx: 3, geometry: Geometry(), grid_position: GridPosition(0, 3), grid: Grid.square),
      Helix(idx: 4, geometry: Geometry(), grid_position: GridPosition(0, 4), grid: Grid.square),
      Helix(idx: 5, geometry: Geometry(), grid_position: GridPosition(0, 5), grid: Grid.square),
    ];
    test('test_strand__0_0_to_10_cross_1_to_5', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design.strand(0, 0).to(10).cross(1).to(5).commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 5, end: 10, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
    });
    test('test_strand__0_0_to_10_cross_1_to_5__reverse', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design.strand(1, 5).to(10).cross(0).to(0).commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 1, forward: true, start: 5, end: 10, is_scaffold: false),
          Domain(helix: 0, forward: false, start: 0, end: 10, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
    });
    test('test_strand__h0_off0_to_off10_cross_h1_to_off5_loopout_length3_h2_to_off15', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design.strand(0, 0).to(10).cross(1).to(5).loopout(2, 3).to(15).commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 5, end: 10, is_scaffold: false),
          Loopout(loopout_length: 3, prev_domain_idx: 0, next_domain_idx: 2, is_scaffold: false),
          Domain(helix: 2, forward: true, start: 5, end: 15, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
    });
    test('test_strand__two_forward_paranemic_crossovers', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design.strand(0, 0).to(10).cross(1).to(15).cross(2).to(20).commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: true, start: 10, end: 15, is_scaffold: false),
          Domain(helix: 2, forward: true, start: 15, end: 20, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
    test('test_strand__two_reverse_paranemic_crossovers', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design.strand(0, 20).to(10).cross(1).to(5).cross(2).to(0).commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: false, start: 10, end: 20, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 5, end: 10, is_scaffold: false),
          Domain(helix: 2, forward: false, start: 0, end: 5, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
    });
    test('test_strand__multiple_strands', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design.strand(0, 0).to(10).cross(1).to(0).commit();
      actual_design = actual_design.strand(0, 20).to(10).cross(1).to(20).commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand(
          [
            Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
            Domain(helix: 1, forward: false, start: 0, end: 10, is_scaffold: false),
          ],
          color: Color.rgb(247, 67, 8),
        )));
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand(
          [
            Domain(helix: 0, forward: false, start: 10, end: 20, is_scaffold: false),
            Domain(helix: 1, forward: true, start: 10, end: 20, is_scaffold: false),
          ],
          color: Color.rgb(247, 67, 8),
        )));
      expect(actual_design.strands, expected_design.strands);
    });
    test('test_strand__multiple_strands_other_order', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design.strand(0, 20).to(10).cross(1).to(20).commit();
      actual_design = actual_design.strand(0, 0).to(10).cross(1).to(0).commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand(
          [
            Domain(helix: 0, forward: false, start: 10, end: 20, is_scaffold: false),
            Domain(helix: 1, forward: true, start: 10, end: 20, is_scaffold: false),
          ],
          color: Color.rgb(247, 67, 8),
        )));
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand(
          [
            Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
            Domain(helix: 1, forward: false, start: 0, end: 10, is_scaffold: false),
          ],
          color: Color.rgb(247, 67, 8),
        )));
      expect(actual_design.strands, expected_design.strands);
    });
    test('test_strand__multiple_strands_overlap_no_error', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design
          .strand(0, 0)
          .to(10)
          .cross(1)
          .to(0)
          .as_scaffold()
          .with_modification_internal(
              5,
              ModificationInternal(
                  display_text: 'Cy3',
                  id: '/iCy3/',
                  idt_text: '/iCy3/',
                  allowed_bases: null,
                  unused_fields: BuiltMap<String, Object>()))
          .commit();
      actual_design = actual_design
          .strand(0, 10)
          .to(0)
          .cross(1)
          .to(10)
          .with_modification_5p(Modification5Prime(
              display_text: 'B',
              id: '/5Biosg/',
              idt_text: '/5Biosg/',
              unused_fields: BuiltMap<String, Object>()))
          .commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand(
          [
            Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
            Domain(helix: 1, forward: false, start: 0, end: 10, is_scaffold: false),
          ],
          color: Color.rgb(247, 67, 8),
          modifications_int: {
            5: ModificationInternal(
                display_text: 'Cy3',
                id: '/iCy3/',
                idt_text: '/iCy3/',
                allowed_bases: null,
                unused_fields: BuiltMap<String, Object>())
          },
          is_scaffold: true,
        )));
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: false, start: 0, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: true, start: 0, end: 10, is_scaffold: false),
        ],
            color: Color.rgb(247, 67, 8),
            modification_5p: Modification5Prime(
                display_text: 'B',
                id: '/5Biosg/',
                idt_text: '/5Biosg/',
                unused_fields: BuiltMap<String, Object>()))));
      expect(actual_design.strands, expected_design.strands);
    });
    test('test_strand__call_to_twice_legally', () {
      Design actual_design = new Design(grid: Grid.square, helices: helices);
      actual_design = actual_design.strand(0, 0).to(10).cross(1).to(5).to(0).commit();

      Design expected_design = new Design(grid: Grid.square, helices: helices);
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 5, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 0, end: 5, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
    });
  });

  // Issue: https://github.com/UC-Davis-molecular-computing/scadnano/issues/497
  test('design with min_offset should set major_tick_distance values', () {
    String four_helix_min_offsets_nonzero_design = """
    {
      "grid": "square",
      "helices": [
        {"max_offset": 30, "grid_position": [0, 0]},
        {"min_offset": 1, "max_offset": 30, "grid_position": [0, 1]},
        {"min_offset": 2, "max_offset": 30, "grid_position": [0, 2]},
        {"min_offset": 3, "max_offset": 30, "grid_position": [0, 3]}
      ],
      "strands": []
    }
    """;
    Design design = Design.from_json(jsonDecode(four_helix_min_offsets_nonzero_design), false);

    expect(design.helices[0].major_tick_start, 0);
    expect(design.helices[1].major_tick_start, 1);
    expect(design.helices[2].major_tick_start, 2);
    expect(design.helices[3].major_tick_start, 3);
  });

  // See issue #551: https://github.com/UC-Davis-molecular-computing/scadnano/issues/551
  //
  //
  // (1,2)    (11,2)   (21,2)
  //  |       |        |
  //  v       v        v
  //  [------][-------][--------] ...
  //     -5     -4        -3
  test('helix.svg_x_to_offset_when_min_offset_is_non-zero', () {
    // Tweak rise per base pair so that svg base width will be exactly 10
    var rise_per_base_pair = 10 / 30.12;
    var helix = Helix(idx: 0, grid: Grid.square, svg_position: Point(1, 2), min_offset: -5, max_offset: 8, geometry: Geometry(rise_per_base_pair: rise_per_base_pair));

    expect(helix.svg_x_to_offset(1), -5);
    expect(helix.svg_x_to_offset(3), -5); // base interior
    expect(helix.svg_x_to_offset(11), -4);
    expect(helix.svg_x_to_offset(15), -4); // base interior
    expect(helix.svg_x_to_offset(21), -3);
  });
}
