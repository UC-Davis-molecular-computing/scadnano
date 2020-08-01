import 'dart:convert';
import 'package:scadnano/src/state/strand_maker.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/modification.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/util.dart' as util;

main() {
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
//    expect(design.helices[0].position3d().x, 30);
//    expect(design.helices[0].position3d().y, 60);
//    expect(design.helices[0].position3d().z, 10);
//    expect(design.helices[1].position3d().x, 50);
//    expect(design.helices[1].position3d().y, 80);
//    expect(design.helices[1].position3d().z, 20);
  });

  group('strand_maker_tests', () {
    test('test_strand__0_0_to_10_cross_1_to_5', () {
      Design actual_design = new Design();
      StrandMaker maker = new StrandMaker(0, 0);
      maker.to(10);
      maker.cross(1);
      maker.to(5);
      Strand new_strand = maker.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 5, end: 10, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
    test('test_strand__0_0_to_10_cross_1_to_5__reverse', () {
      Design actual_design = new Design();
      StrandMaker maker = new StrandMaker(1, 5);
      maker.to(10);
      maker.cross(0);
      maker.to(0);
      Strand new_strand = maker.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 1, forward: true, start: 5, end: 10, is_scaffold: false),
          Domain(helix: 0, forward: false, start: 0, end: 10, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
    test('test_strand__h0_off0_to_off10_cross_h1_to_off5_loopout_length3_h2_to_off15', () {
      Design actual_design = new Design();
      StrandMaker maker = new StrandMaker(0, 0);
      maker.to(10);
      maker.cross(1);
      maker.to(5);
      maker.loopout(2, 3);
      maker.to(15);
      Strand new_strand = maker.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 5, end: 10, is_scaffold: false),
          Loopout(3, 1, 3, false),
          Domain(helix: 2, forward: true, start: 5, end: 15, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
    test('test_strand__two_forward_paranemic_crossovers', () {
      Design actual_design = new Design();
      StrandMaker maker = new StrandMaker(0, 0);
      maker.to(10);
      maker.cross(1);
      maker.to(15);
      maker.cross(2);
      maker.to(20);
      Strand new_strand = maker.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
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
      Design actual_design = new Design();
      StrandMaker maker = new StrandMaker(0, 20);
      maker.to(10);
      maker.cross(1);
      maker.to(5);
      maker.cross(2);
      maker.to(0);
      Strand new_strand = maker.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: false, start: 10, end: 20, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 5, end: 10, is_scaffold: false),
          Domain(helix: 2, forward: false, start: 0, end: 5, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
    test('test_strand__multiple_strands', () {
      Design actual_design = new Design();
      StrandMaker maker1 = new StrandMaker(0, 0);
      maker1.to(10);
      maker1.cross(1);
      maker1.to(0);
      Strand new_strand = maker1.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      StrandMaker maker2 = new StrandMaker(0, 20);
      maker2.to(10);
      maker2.cross(1);
      maker2.to(20);
      new_strand = maker2.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
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
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
    test('test_strand__multiple_strands_other_order', () {
      Design actual_design = new Design();
      StrandMaker maker1 = new StrandMaker(0, 20);
      maker1.to(10);
      maker1.cross(1);
      maker1.to(20);
      Strand new_strand = maker1.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      StrandMaker maker2 = new StrandMaker(0, 0);
      maker2.to(10);
      maker2.cross(1);
      maker2.to(0);
      new_strand = maker2.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
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
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
    test('test_strand__multiple_strands_overlap_no_error', () {
      Design actual_design = new Design();
      StrandMaker maker1 = new StrandMaker(0, 0);
      maker1.to(10);
      maker1.cross(1);
      maker1.to(0);
      maker1.as_scaffold();
      maker1.with_modification_internal(
          5,
          ModificationInternal(
              display_text: 'Cy3',
              id: '/iCy3/',
              idt_text: '/iCy3/',
              allowed_bases: null,
              unused_fields: BuiltMap<String, Object>()));
      Strand new_strand = maker1.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      StrandMaker maker2 = new StrandMaker(0, 10);
      maker2.to(0);
      maker2.cross(1);
      maker2.to(10);
      maker2.with_modification_5p(Modification5Prime(
          display_text: 'B',
          id: '/5Biosg/',
          idt_text: '/5Biosg/',
          unused_fields: BuiltMap<String, Object>()));
      new_strand = maker2.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
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
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
    test('test_strand__call_to_twice_legally', () {
      Design actual_design = new Design();
      StrandMaker maker = new StrandMaker(0, 0);
      maker.to(10);
      maker.cross(1);
      maker.to(5);
      maker.to(0);
      Strand new_strand = maker.commit();
      actual_design = actual_design.rebuild((s) => s..strands.add(new_strand));

      Design expected_design = new Design();
      expected_design = expected_design.rebuild((s) => s
        ..strands.add(Strand([
          Domain(helix: 0, forward: true, start: 0, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 5, end: 10, is_scaffold: false),
          Domain(helix: 1, forward: false, start: 0, end: 5, is_scaffold: false),
        ], color: Color.rgb(247, 67, 8))));
      expect(actual_design.strands, expected_design.strands);
      expected_design = expected_design.rebuild((s) => s..strands.clear());
    });
  });
}
