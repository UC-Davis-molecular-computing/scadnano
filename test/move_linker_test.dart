// @dart=2.9

import 'dart:convert';
import 'dart:math';

import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/reducers/assign_or_remove_dna_reducer.dart';
import 'package:scadnano/src/reducers/change_loopout_length.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/reducers/assign_domain_names_reducer.dart';
import 'package:scadnano/src/state/address.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/potential_crossover.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/dna_assign_options.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  group('move crossover: ', () {
    test('move-2nd-crossover-in-2-crossover-strand-3p-end-fixed', () {
      /*
          0   4     0   4
          AAAA      AAAA
      0   [--+      [--+
             |         |
          CCCC      CCCC
      1   +--+      +--+
          |        /
          GGGG    / GGGG
      2   +-->    | [-->
                  \
          TTTT     \TTTT
      3   [-->      +-->
       */
      var helices = [
        for (int idx in [0, 1, 2, 3]) Helix(idx: idx, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .strand(0, 0)
          .move(4)
          .cross(1)
          .move(-4)
          .cross(2)
          .move(4)
          .with_sequence('AAAACCCCGGGG')
          .commit();
      design = design.strand(3, 0).move(4).with_sequence('TTTT').commit();
      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[0];
      Strand strand2 = design.strands[1];

      expect(state.design.strands[0].dna_sequence, "AAAACCCCGGGG");
      expect(state.design.strands[1].dna_sequence, "TTTT");

      Crossover orig_crossover = strand1.crossovers[1];
      DNAEnd end_click1 = strand1.domains[1].dnaend_start;
      DNAEnd end_click2 = strand2.domains[0].dnaend_start;
      PotentialCrossover potential_crossover = PotentialCrossover(
          address: Address(helix_idx: 2, forward: true, offset: 0),
          color: '000000',
          dna_end_first_click: end_click1,
          start_point: Point<num>(0, 0),
          current_point: Point<num>(0, 0),
          linker: orig_crossover);
      state = app_state_reducer(
          state, MoveLinker(potential_crossover: potential_crossover, dna_end_second_click: end_click2));

      expect(state.design.strands.length, 2);
      expect(state.design.strands[0].substrands.length, 3);
      expect(state.design.strands[1].substrands.length, 1);

      expect(state.design.strands[0].domains[0].helix, 0);
      expect(state.design.strands[0].domains[0].start, 0);
      expect(state.design.strands[0].domains[0].end, 4);
      expect(state.design.strands[0].domains[0].forward, true);

      expect(state.design.strands[0].domains[1].helix, 1);
      expect(state.design.strands[0].domains[1].start, 0);
      expect(state.design.strands[0].domains[1].end, 4);
      expect(state.design.strands[0].domains[1].forward, false);

      expect(state.design.strands[0].domains[2].helix, 3);
      expect(state.design.strands[0].domains[2].start, 0);
      expect(state.design.strands[0].domains[2].end, 4);
      expect(state.design.strands[0].domains[2].forward, true);

      expect(state.design.strands[1].domains[0].helix, 2);
      expect(state.design.strands[1].domains[0].start, 0);
      expect(state.design.strands[1].domains[0].end, 4);
      expect(state.design.strands[1].domains[0].forward, true);

      expect(state.design.strands[0].dna_sequence, "AAAACCCCTTTT");
      expect(state.design.strands[1].dna_sequence, "GGGG");
    });


    test('move-2nd-crossover-in-2-crossover-strand-5p-end-fixed', () {
      /*
          0   4     0   4
          AAAA      AAAA
      0   [--+      [--+
             |         |
          CCCC      CCCC
      1   +--+      <--+
          |
          GGGG      GGGG
      2   +-->      +-->
                     \
                      \
                       \
                        \
          TTTT      TTTT/
      3   [-->      [--+
       */
      var helices = [
        for (int idx in [0, 1, 2, 3]) Helix(idx: idx, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .strand(0, 0)
          .move(4)
          .cross(1)
          .move(-4)
          .cross(2)
          .move(4)
          .with_sequence('AAAACCCCGGGG')
          .commit();
      design = design.strand(3, 0).move(4).with_sequence('TTTT').commit();
      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[0];
      Strand strand2 = design.strands[1];

      expect(state.design.strands[0].dna_sequence, "AAAACCCCGGGG");
      expect(state.design.strands[1].dna_sequence, "TTTT");

      Crossover orig_crossover = strand1.crossovers[1];
      DNAEnd end_click1 = strand1.domains[2].dnaend_start;
      DNAEnd end_click2 = strand2.domains[0].dnaend_end;
      PotentialCrossover potential_crossover = PotentialCrossover(
          address: Address(helix_idx: 1, forward: false, offset: 0),
          color: '000000',
          dna_end_first_click: end_click1,
          start_point: Point<num>(0, 0),
          current_point: Point<num>(0, 0),
          linker: orig_crossover);
      state = app_state_reducer(
          state, MoveLinker(potential_crossover: potential_crossover, dna_end_second_click: end_click2));

      expect(state.design.strands.length, 2);
      expect(state.design.strands[0].substrands.length, 2);
      expect(state.design.strands[1].substrands.length, 2);

      expect(state.design.strands[1].domains[0].helix, 0);
      expect(state.design.strands[1].domains[0].start, 0);
      expect(state.design.strands[1].domains[0].end, 4);
      expect(state.design.strands[1].domains[0].forward, true);

      expect(state.design.strands[1].domains[1].helix, 1);
      expect(state.design.strands[1].domains[1].start, 0);
      expect(state.design.strands[1].domains[1].end, 4);
      expect(state.design.strands[1].domains[1].forward, false);

      expect(state.design.strands[0].domains[0].helix, 3);
      expect(state.design.strands[0].domains[0].start, 0);
      expect(state.design.strands[0].domains[0].end, 4);
      expect(state.design.strands[0].domains[0].forward, true);

      expect(state.design.strands[0].domains[1].helix, 2);
      expect(state.design.strands[0].domains[1].start, 0);
      expect(state.design.strands[0].domains[1].end, 4);
      expect(state.design.strands[0].domains[1].forward, true);

      expect(state.design.strands[1].dna_sequence, "AAAACCCC");
      expect(state.design.strands[0].dna_sequence, "TTTTGGGG");
    });
  });


  group('move loopout: ', () {
    test('move-2nd-loopout-in-2-loopout-strand', () {
      /*
          0   4     0   4
          AAAA      AAAA
      0   [--+      [--+
             |G        |G
          CCCC      CCCC
      1   +--+      +--+
         T|        /
          GGGG    / GGGG
      2   +-->  T|  [-->
                  \
          TTTT     \TTTT
      3   [-->      +-->
      */
      var helices = [
        for (int idx in [0, 1, 2, 3]) Helix(idx: idx, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .strand(0, 0)
          .move(4)
          .loopout(1, 1)
          .move(-4)
          .loopout(2, 1)
          .move(4)
          .with_sequence('AAAAGCCCCTGGGG')
          .commit();
      design = design.strand(3, 0).move(4).with_sequence('TTTT').commit();
      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[0];
      Strand strand2 = design.strands[1];

      expect(state.design.strands[0].dna_sequence, "AAAAGCCCCTGGGG");
      expect(state.design.strands[1].dna_sequence, "TTTT");

      Loopout orig_loopout = strand1.loopouts[1];
      DNAEnd end_click1 = strand1.domains[1].dnaend_start;
      DNAEnd end_click2 = strand2.domains[0].dnaend_start;
      PotentialCrossover potential_crossover = PotentialCrossover(
          address: Address(helix_idx: 2, forward: true, offset: 0),
          color: '000000',
          dna_end_first_click: end_click1,
          start_point: Point<num>(0, 0),
          current_point: Point<num>(0, 0),
          linker: orig_loopout);
      state = app_state_reducer(
          state, MoveLinker(potential_crossover: potential_crossover, dna_end_second_click: end_click2));

      expect(state.design.strands.length, 2);
      expect(state.design.strands[0].substrands.length, 5);
      expect(state.design.strands[1].substrands.length, 1);

      expect(state.design.strands[0].domains[0].helix, 0);
      expect(state.design.strands[0].domains[0].start, 0);
      expect(state.design.strands[0].domains[0].end, 4);
      expect(state.design.strands[0].domains[0].forward, true);

      expect(state.design.strands[0].domains[1].helix, 1);
      expect(state.design.strands[0].domains[1].start, 0);
      expect(state.design.strands[0].domains[1].end, 4);
      expect(state.design.strands[0].domains[1].forward, false);

      expect(state.design.strands[0].domains[2].helix, 3);
      expect(state.design.strands[0].domains[2].start, 0);
      expect(state.design.strands[0].domains[2].end, 4);
      expect(state.design.strands[0].domains[2].forward, true);

      expect(state.design.strands[0].loopouts[0].dna_sequence, 'G');
      expect(state.design.strands[0].loopouts[1].dna_sequence, 'T');

      expect(state.design.strands[1].domains[0].helix, 2);
      expect(state.design.strands[1].domains[0].start, 0);
      expect(state.design.strands[1].domains[0].end, 4);
      expect(state.design.strands[1].domains[0].forward, true);

      expect(state.design.strands[0].dna_sequence, "AAAAGCCCCTTTTT");
      expect(state.design.strands[1].dna_sequence, "GGGG");
    });

    test('move-2nd-loopout-in-2-loopout-strand', () {
      /*
          0   4     0   4
          AAAA      AAAA
      0   [--+      [--+
             |G        |G
          CCCC      CCCC
      1   +--+      <--+
         T|
          GGGG      GGGG
      2   +-->      +-->
                     \
                      \
                       \
                        \T
          TTTT      TTTT/
      3   [-->      [--+
       */
      var helices = [
        for (int idx in [0, 1, 2, 3]) Helix(idx: idx, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .strand(0, 0)
          .move(4)
          .loopout(1, 1)
          .move(-4)
          .loopout(2, 1)
          .move(4)
          .with_sequence('AAAAGCCCCTGGGG')
          .commit();
      design = design.strand(3, 0).move(4).with_sequence('TTTT').commit();
      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[0];
      Strand strand2 = design.strands[1];

      expect(state.design.strands[0].dna_sequence, "AAAAGCCCCTGGGG");
      expect(state.design.strands[1].dna_sequence, "TTTT");

      Loopout orig_loopout = strand1.loopouts[1];
      DNAEnd end_click1 = strand1.domains[2].dnaend_start;
      DNAEnd end_click2 = strand2.domains[0].dnaend_end;
      PotentialCrossover potential_crossover = PotentialCrossover(
          address: Address(helix_idx: 1, forward: false, offset: 0),
          color: '000000',
          dna_end_first_click: end_click1,
          start_point: Point<num>(0, 0),
          current_point: Point<num>(0, 0),
          linker: orig_loopout);
      state = app_state_reducer(
          state, MoveLinker(potential_crossover: potential_crossover, dna_end_second_click: end_click2));

      expect(state.design.strands.length, 2);
      expect(state.design.strands[0].substrands.length, 3);
      expect(state.design.strands[1].substrands.length, 3);

      expect(state.design.strands[1].domains[0].helix, 0);
      expect(state.design.strands[1].domains[0].start, 0);
      expect(state.design.strands[1].domains[0].end, 4);
      expect(state.design.strands[1].domains[0].forward, true);

      expect(state.design.strands[1].loopouts[0].dna_sequence, 'G');

      expect(state.design.strands[1].domains[1].helix, 1);
      expect(state.design.strands[1].domains[1].start, 0);
      expect(state.design.strands[1].domains[1].end, 4);
      expect(state.design.strands[1].domains[1].forward, false);

      expect(state.design.strands[0].domains[0].helix, 3);
      expect(state.design.strands[0].domains[0].start, 0);
      expect(state.design.strands[0].domains[0].end, 4);
      expect(state.design.strands[0].domains[0].forward, true);

      expect(state.design.strands[0].loopouts[0].dna_sequence, 'T');

      expect(state.design.strands[0].domains[1].helix, 2);
      expect(state.design.strands[0].domains[1].start, 0);
      expect(state.design.strands[0].domains[1].end, 4);
      expect(state.design.strands[0].domains[1].forward, true);

      expect(state.design.strands[1].dna_sequence, "AAAAGCCCC");
      expect(state.design.strands[0].dna_sequence, "TTTTTGGGG");
    });

  });

}
