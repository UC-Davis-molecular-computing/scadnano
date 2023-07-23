// @dart=2.9

import 'dart:convert';

import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/change_loopout_ext_properties.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/inline_insertions_deletions_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/reducers/assign_domain_names_reducer.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

void helix0_strand0_inlined_test(Design design, {int max_offset, List<int> major_ticks, int start, int end}) {
  expect(design.helices.length, 1);
  expect(design.strands.length, 1);
  var helix = design.helices[0];
  var strand = design.strands[0];
  expect(helix.max_offset, max_offset);
  expect(helix.major_ticks, major_ticks);
  expect(strand.domains[0].start, start);
  expect(strand.domains[0].end, end);
  expect(strand.domains[0].deletions, []);
  expect(strand.domains[0].insertions, []);
}

main() {
  group('InlineInsertionsDeletions', () {
    Design design;
    actions.InlineInsertionsDeletions action = actions.InlineInsertionsDeletions();

    setUp(() async {
      design = Design(helices: [
        Helix(max_offset: 24, grid_position: GridPosition(0, 0), major_tick_periodic_distances: [8], idx: 0)
      ], strands: [], grid: Grid.square);
    });

    test('no_deletion_after_loopout', () {
      expect(() => design.draw_strand(0, 0).move(8).loopout(0, 10, 5).with_deletion(4), throwsArgumentError);
    });

    test('no_insertion_after_loopout', () {
      expect(
          () => design.draw_strand(0, 0).move(8).loopout(0, 10, 5).with_insertion(4, 2), throwsArgumentError);
    });

    test('deletion_below_range', () {
      expect(() => design.draw_strand(0, 4).move(4).with_deletion(2), throwsA(IllegalDesignError('')));
    });

    test('deletion_above_range', () {
      expect(() => design.draw_strand(0, 0).move(4).with_deletion(6), throwsA(IllegalDesignError('')));
    });

    test('insertion_below_range', () {
      expect(() => design.draw_strand(0, 4).move(4).with_insertion(2, 2), throwsA(IllegalDesignError('')));
    });

    test('insertion_above_range', () {
      expect(() => design.draw_strand(0, 0).move(4).with_insertion(6, 2), throwsA(IllegalDesignError('')));
    });

    test('inline_deletions_insertions__one_deletion', () {
      /*
        before
        0   4   8       16      24
        |       |       |       |
    0   [---X-->

        after
        0   4  7       15      23
        |      |       |       |
    0   [----->
        */
      design = design.draw_strand(0, 0).move(8).with_deletion(4).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 23, major_ticks: [0, 7, 15, 23], start: 0, end: 7);
    });

    test('inline_deletions_insertions__two_deletions', () {
      /*
        before
        0 2 4   8       16      24
        |       |       |       |
    0   [-X-X-->

        after
        0     6       14      22
        |     |       |       |
    0   [---->
        */
      design = design.draw_strand(0, 0).move(8).with_deletions([2, 4]).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 22, major_ticks: [0, 6, 14, 22], start: 0, end: 6);
    });

    test('inline_deletions_insertions__one_insertion', () {
      /*
        before
        0   4   8       16      24
        |       |       |       |
    0   [---1-->

        after
        0        9       17      25
        |        |       |       |
    0   [------->
        */
      design = design.draw_strand(0, 0).move(8).with_insertion(4, 1).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 25, major_ticks: [0, 9, 17, 25], start: 0, end: 9);
    });

    test('inline_deletions_insertions__two_insertions', () {
      /*
        before
        0 2 4   8       16      24
        |       |       |       |
    0   [-3-1-->

        after
        0           12      20      28
        |           |       |       |
    0   [---------->
        */
      design = design.draw_strand(0, 0).move(8).with_insertions([Insertion(2, 3), Insertion(4, 1)]).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 28, major_ticks: [0, 12, 20, 28], start: 0, end: 12);
    });

    test('inline_deletions_insertions__one_deletion_one_insertion', () {
      /*
        before
        0 2 4   8       16      24
        |       |       |       |
    0   [-3-X-->

        after
        0         10      18      26
        |         |       |       |
    0   [-------->
        */
      design = design.draw_strand(0, 0).move(8).with_deletion(4).with_insertion(2, 3).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 26, major_ticks: [0, 10, 18, 26], start: 0, end: 10);
    });

    test('inline_deletions_insertions__one_deletion_right_of_major_tick', () {
      /*
        before
        0       89      16      24
        |       |       |       |
    0   [--------X->

        after
        0       8      15      23
        |       |      |       |
    0   [--------->
        */
      design = design.draw_strand(0, 0).move(12).with_deletion(9).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 23, major_ticks: [0, 8, 15, 23], start: 0, end: 11);
    });

    test('inline_deletions_insertions__one_deletion_on_major_tick', () {
      /*
        | is major tick, and . is minor tick
        before
         0               8               16              24
        | . . . . . . . | . . . . . . . | . . . . . . . |
         [ - - - - - - - X - - >

        after
         0               8             15              23
        | . . . . . . . | . . . . . . | . . . . . . . |
         [ - - - - - - - - - >
        */
      design = design.draw_strand(0, 0).move(12).with_deletion(8).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 23, major_ticks: [0, 8, 15, 23], start: 0, end: 11);
    });

    test('inline_deletions_insertions__one_deletion_left_of_major_tick', () {
      /*
        before
        0      78       16      24
        |       |       |       |
    0   [------X--->

        after
        0       8      15      23
        |       |      |       |
    0   [--------->
        */
      design = design.draw_strand(0, 0).move(12).with_deletion(7).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 23, major_ticks: [0, 7, 15, 23], start: 0, end: 11);
    });

    test('inline_deletions_insertions__one_insertion_right_of_major_tick', () {
      /*
        before
        0       89      16      24
        |       |       |       |
    0   [--------1->

        after
        0       8        17      25
        |       |        |       |
    0   [----------->
        */
      design = design.draw_strand(0, 0).move(12).with_insertion(9, 1).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 25, major_ticks: [0, 8, 17, 25], start: 0, end: 13);
    });

    test('inline_deletions_insertions__one_insertion_on_major_tick', () {
      /*
        before
        0       8       16      24
        |       |       |       |
    0   [-------1-->

        after
        0       8        17      25
        |       |        |       |
    0   [----------->
        */
      design = design.draw_strand(0, 0).move(12).with_insertion(8, 1).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 25, major_ticks: [0, 8, 17, 25], start: 0, end: 13);
    });

    test('inline_deletions_insertions__one_insertion_left_of_major_tick', () {
      /*
        before
        0      78       16      24
        |       |       |       |
    0   [------1--->

        after
        0        9       17      25
        |        |       |       |
    0   [----------->
        */
      design = design.draw_strand(0, 0).move(12).with_insertion(7, 1).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 25, major_ticks: [0, 9, 17, 25], start: 0, end: 13);
    });

    test('inline_deletions_insertions__deletions_insertions_in_multiple_domains', () {
      /*
        before
        0    5  8  11   16 19   24
        |       |       |       |
    0   [----2-----1-------X---->

        after
        0         10      19      26
        |         |       |       |
    0   [------------------------->
        */
      design = design
          .draw_strand(0, 0)
          .move(24)
          .with_deletion(19)
          .with_insertions([Insertion(5, 2), Insertion(11, 1)]).commit();
      design = inline_insertions_deletions_reducer(design, action);
      helix0_strand0_inlined_test(design, max_offset: 26, major_ticks: [0, 10, 19, 26], start: 0, end: 26);
    });

    test('inline_deletions_insertions__deletions_insertions_in_multiple_domains_two_strands', () {
      /*
        | is major tick, . is minor tick
        before
         0   2     5     8   10          16    19        24
        | . . . . . . . | . . . . . . . | . . . . . . . |
         [ - X - - 2 - - - - 1 - - > [ - - - - X - - - >

        after
         0   2     5       9             16  18            25
        | . . . . . . . . | . . . . . . . . | . . . . . . |
         [ - - - - - - - - - - - - - - > [ - - - - - - - >
        */
      design = design
          .draw_strand(0, 0)
          .move(14)
          .with_deletion(2)
          .with_insertions([Insertion(5, 2), Insertion(10, 1)]).commit();
      design = design.draw_strand(0, 14).to(24).with_deletion(19).commit();
      design = inline_insertions_deletions_reducer(design, action);
      expect(design.helices.length, 1);
      expect(design.strands.length, 2);
      var helix = design.helices[0];
      var strand0 = design.strands[0];
      var strand1 = design.strands[1];
      expect(helix.max_offset, 25);
      expect(helix.calculate_major_ticks, [0, 9, 18, 25]);
      expect(strand0.domains[0].start, 0);
      expect(strand0.domains[0].end, 16);
      expect(strand1.domains[0].start, 16);
      expect(strand1.domains[0].end, 25);
      expect(strand0.domains[0].deletions, []);
      expect(strand0.domains[0].insertions, []);
      expect(strand1.domains[0].deletions, []);
      expect(strand1.domains[0].insertions, []);
    });
  });
}
