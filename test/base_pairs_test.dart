import 'dart:convert';

import 'package:tuple/tuple.dart';

import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/reducers/assign_or_remove_dna_reducer.dart';
import 'package:scadnano/src/reducers/change_loopout_ext_properties.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/reducers/assign_domain_names_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/dna_assign_options.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  group('Base pairs: ', () {
    Design design = Design(helices: []); // mock to make dart compiler happy; gets set in setUp

    setUp(() {
      /*
      X shows position of mismatches
                  111111111122222222223333333333
        0123456789012345678901234567890123456789
      0 [-->[-->    [-->    [-->    [-->
         <] <--------]   <-]      <-]     <] <]
             X
                  111111111122222222223333333333
        0123456789012345678901234567890123456789
      1     [----------->   [-->
                <--] <-----------]
                  X
      */
      var helices = [for (int i = 0; i < 2; i++) Helix(idx: i, max_offset: 40, grid: Grid.square)];
      design = Design(helices: helices);
      // helix 0 forward
      design = design.draw_strand(0, 0).move(4).with_sequence('AAAA').commit();
      design = design.draw_strand(0, 4).move(4).with_sequence('AAAA').commit();
      design = design.draw_strand(0, 12).move(4).with_sequence('AAAA').commit();
      design = design.draw_strand(0, 20).move(4).with_sequence('AAAA').commit();
      design = design.draw_strand(0, 28).move(4).with_sequence('AAAA').commit();
      // helix 0 reverse
      design = design.draw_strand(0, 3).move(-2).with_sequence('TT').commit();
      design = design.draw_strand(0, 14).to(4).with_sequence('TTTTTTTTCT').commit();
      design = design.draw_strand(0, 20).to(17).with_sequence('TTT').commit();
      design = design.draw_strand(0, 29).to(26).with_sequence('TTT').commit();
      design = design.draw_strand(0, 36).to(34).with_sequence('TT').commit();
      design = design.draw_strand(0, 39).to(37).with_sequence('TT').commit();
      // helix 1 forward
      design = design.draw_strand(1, 4).to(17).with_sequence('A' * 13).commit();
      design = design.draw_strand(1, 20).to(24).with_sequence('A' * 4).commit();
      // helix 1 reverse
      design = design.draw_strand(1, 12).to(8).with_sequence('TGTT').commit();
      design = design.draw_strand(1, 26).to(13).with_sequence('T' * 13).commit();
    });

    test('extended_forward_strand', () {
      var helices = [for (int i = 0; i < 1; i++) Helix(idx: i, max_offset: 40, grid: Grid.square)];
      var test_design = Design(helices: helices);

      /*
        0123456789012345678901234567890123456789
      1 
      0 [-------->[-------->
        <--------]
      */

      test_design = test_design.draw_strand(0, 0).to(10).with_sequence('A' * 10).commit();
      test_design = test_design.draw_strand(0, 10).to(20).with_sequence('A' * 10).commit();
      test_design = test_design.draw_strand(0, 10).to(0).with_sequence('A' * 10).commit();

      var d01f = test_design.strands[0].domains[0];
      var d01r = test_design.strands[2].domains[0];

      var overlapping_domains_h0 = test_design.find_overlapping_domains_on_helix(0);

      expect(overlapping_domains_h0.length, 1);
      expect(overlapping_domains_h0, contains(Tuple2<Domain, Domain>(d01f, d01r)));
    });
    test('find_overlapping_domains', () {
      var d01f = design.strands[0].domains[0];
      var d02f = design.strands[1].domains[0];
      var d03f = design.strands[2].domains[0];
      // var d04f = design.strands[3].domains[0];
      var d05f = design.strands[4].domains[0];

      var d01r = design.strands[5].domains[0];
      var d02r = design.strands[6].domains[0];
      // var d03r = design.strands[7].domains[0];
      var d04r = design.strands[8].domains[0];
      // var d05r = design.strands[9].domains[0];
      // var d06r = design.strands[10].domains[0];

      var d11f = design.strands[11].domains[0];
      var d12f = design.strands[12].domains[0];

      var d11r = design.strands[13].domains[0];
      var d12r = design.strands[14].domains[0];

      var overlapping_domains_h0 = design.find_overlapping_domains_on_helix(0);
      var overlapping_domains_h1 = design.find_overlapping_domains_on_helix(1);

      expect(overlapping_domains_h0.length, 4);
      expect(overlapping_domains_h1.length, 3);

      expect(overlapping_domains_h0, contains(Tuple2<Domain, Domain>(d01f, d01r)));
      expect(overlapping_domains_h0, contains(Tuple2<Domain, Domain>(d02f, d02r)));
      expect(overlapping_domains_h0, contains(Tuple2<Domain, Domain>(d03f, d02r)));
      expect(overlapping_domains_h0, contains(Tuple2<Domain, Domain>(d05f, d04r)));

      expect(overlapping_domains_h1, contains(Tuple2<Domain, Domain>(d11f, d11r)));
      expect(overlapping_domains_h1, contains(Tuple2<Domain, Domain>(d11f, d12r)));
      expect(overlapping_domains_h1, contains(Tuple2<Domain, Domain>(d12f, d12r)));
    });

    test('design_base_pairs_mismatches', () {
      var base_pairs = design.base_pairs_with_mismatches;
      expect(base_pairs.length, 2);
      expect(base_pairs[0]!.length, 9);
      expect(base_pairs[1]!.length, 12);

      // d01f, d01r
      expect(base_pairs[0], contains(1));
      expect(base_pairs[0], contains(2));

      // d02f, d02r
      expect(base_pairs[0], contains(4));
      expect(base_pairs[0], contains(5));
      expect(base_pairs[0], contains(6));
      expect(base_pairs[0], contains(7));

      // d03f, d02r
      expect(base_pairs[0], contains(12));
      expect(base_pairs[0], contains(13));

      // d05f, d04r
      expect(base_pairs[0], contains(28));

      // d11f, d11r
      expect(base_pairs[1], contains(8));
      expect(base_pairs[1], contains(9));
      expect(base_pairs[1], contains(10));
      expect(base_pairs[1], contains(11));

      // d11f, d12r
      expect(base_pairs[1], contains(13));
      expect(base_pairs[1], contains(14));
      expect(base_pairs[1], contains(15));
      expect(base_pairs[1], contains(16));

      // d11f, d12r
      expect(base_pairs[1], contains(20));
      expect(base_pairs[1], contains(21));
      expect(base_pairs[1], contains(22));
      expect(base_pairs[1], contains(23));
    });

    test('design_base_pairs_no_mismatches', () {
      var base_pairs = design.base_pairs;
      expect(base_pairs.length, 2);
      expect(base_pairs[0]!.length, 8);
      expect(base_pairs[1]!.length, 11);

      // d01f, d01r
      expect(base_pairs[0], contains(1));
      expect(base_pairs[0], contains(2));

      // d02f, d02r
      expect(base_pairs[0], contains(4));
      // expect(base_pairs[0], contains(5)); // mismatch
      expect(base_pairs[0], contains(6));
      expect(base_pairs[0], contains(7));

      // d03f, d02r
      expect(base_pairs[0], contains(12));
      expect(base_pairs[0], contains(13));

      // d05f, d04r
      expect(base_pairs[0], contains(28));

      // d11f, d11r
      expect(base_pairs[1], contains(8));
      expect(base_pairs[1], contains(9));
      // expect(base_pairs[1], contains(10)); // mismatch
      expect(base_pairs[1], contains(11));

      // d11f, d12r
      expect(base_pairs[1], contains(13));
      expect(base_pairs[1], contains(14));
      expect(base_pairs[1], contains(15));
      expect(base_pairs[1], contains(16));

      // d11f, d12r
      expect(base_pairs[1], contains(20));
      expect(base_pairs[1], contains(21));
      expect(base_pairs[1], contains(22));
      expect(base_pairs[1], contains(23));

      /*
        X shows position of mismatches
                    111111111122222222223333333333
          0123456789012345678901234567890123456789
        0 [-->[-->    [-->    [-->    [-->
           <] <--------]   <-]      <-]     <] <]
               X
                    111111111122222222223333333333
          0123456789012345678901234567890123456789
        1     [----------->   [-->
                  <--] <-----------]
                    X
        */
    });

    test('design_base_pairs_no_dna', () {
      /*
          0123456789
        0 [-------->
          <---]<---]
       */
      var design = Design(helices: [Helix(idx: 0, max_offset: 40, grid: Grid.square)]);
      design = design.draw_strand(0, 0).move(10).commit();
      design = design.draw_strand(0, 5).move(-5).commit();
      design = design.draw_strand(0, 10).move(-5).commit();

      var base_pairs = design.base_pairs;
      expect(base_pairs.length, 1);
      expect(base_pairs[0]!.length, 10);

      for (int offset = 0; offset < 10; offset++) {
        expect(base_pairs[0], contains(offset));
      }
    });

    test('design_base_pairs_dna_on_some_strands_and_mismatches', () {
      /*
          0123456789
          AAAAAAAAAA
        0 [-------->
          <---]<---]
          TTCTT
       */
      var design = Design(helices: [Helix(idx: 0, max_offset: 40, grid: Grid.square)]);
      design = design.draw_strand(0, 0).move(10).with_sequence('A' * 10).commit();
      design = design.draw_strand(0, 5).move(-5).with_sequence('TTCTT').commit();
      design = design.draw_strand(0, 10).move(-5).commit();

      var base_pairs = design.base_pairs;
      expect(base_pairs.length, 1);
      expect(base_pairs[0]!.length, 9);

      for (int offset = 0; offset < 10; offset++) {
        if (offset != 2) {
          expect(base_pairs[0], contains(offset));
        }
      }
    });

    test('design_base_pairs_deletions_insertions', () {
      /*
          0123456789
                AA
          A  AAAAAAA
        0 [XX---II->
          <-XX]<-II]
          TT  TTTTTT
                 TT
       */
      var design = Design(helices: [Helix(idx: 0, max_offset: 40, grid: Grid.square)]);
      design = design
          .draw_strand(0, 0)
          .move(10)
          .with_deletions([1, 2])
          .with_insertions([Insertion(6, 1), Insertion(7, 1)])
          .with_sequence('A' * 10)
          .commit();
      design = design.draw_strand(0, 5).move(-5).with_deletions([2, 3]).with_sequence('TTT').commit();
      design = design
          .draw_strand(0, 10)
          .move(-5)
          .with_insertions([Insertion(7, 1), Insertion(8, 1)])
          .with_sequence('T' * 7)
          .commit();

      var base_pairs = design.base_pairs;
      expect(base_pairs.length, 1);
      expect(base_pairs[0]!.length, 5);

      for (var offset in [0, 4, 5, 7, 9]) {
        expect(base_pairs[0], contains(offset));
      }
    });

    test('design_base_pairs_deletions_insertions_mismatch_in_insertion', () {
      /*
          0123456789
                AA
          A  AAAAAAA
        0 [XX---II->
          <-XX]<-II]
          TT  TTTTTT
                 CT
       */
      var design = Design(helices: [Helix(idx: 0, max_offset: 40, grid: Grid.square)]);
      design = design
          .draw_strand(0, 0)
          .move(10)
          .with_deletions([1, 2])
          .with_insertions([Insertion(6, 1), Insertion(7, 1)])
          .with_sequence('A' * 10)
          .commit();
      design = design.draw_strand(0, 5).move(-5).with_deletions([2, 3]).with_sequence('TTT').commit();
      design = design
          .draw_strand(0, 10)
          .move(-5)
          .with_insertions([Insertion(7, 1), Insertion(8, 1)])
          .with_sequence('TTTCTTT')
          .commit();

      var base_pairs = design.base_pairs;
      expect(base_pairs.length, 1);
      expect(base_pairs[0]!.length, 4);

      for (var offset in [0, 4, 5, 9]) {
        expect(base_pairs[0], contains(offset));
      }
    });

    test('no_base_pairs', () {
      /*
          0123456789
          [-->
               <--]
       */
      var design = Design(helices: [Helix(idx: 0, max_offset: 40, grid: Grid.square)]);
      design = design.draw_strand(0, 0).move(4).commit();
      design = design.draw_strand(0, 9).move(-4).commit();

      var base_pairs = design.base_pairs;
      expect(base_pairs.length, 0);
    });

    test('no_base_pairs_only_forward_strand', () {
      /*
          0123456789
          [-->
       */
      var design = Design(helices: [Helix(idx: 0, max_offset: 40, grid: Grid.square)]);
      design = design.draw_strand(0, 0).move(4).commit();

      var base_pairs = design.base_pairs;
      expect(base_pairs.length, 0);
    });
  });
}
