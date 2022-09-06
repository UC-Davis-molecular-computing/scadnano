// @dart=2.9

import 'package:scadnano/src/reducers/change_loopout_ext_properties.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  // group('CircularStrandsLegalMods', () {
  //   var helices;
  //   var design;
  //   Strand strand;
  //
  //   setUp(() {
  //     helices = [for (int i = 0; i < 2; i++) Helix(idx: i, max_offset: 100, grid: Grid.square)];
  //     design = Design(helices: helices, grid: Grid.square);
  //     design = design.strand(0, 0).move(10).cross(1).move(-10).commit();
  //     strand = design.strands[0];
  //   });
  //
  //   test('can_add_internal_mod_to_circular_strand', () {
  //     // strand = strand.set_circular();
  //     // expect(strand.circular, true);
  //     // strand.set_modification_internal(2, Modification5Prime(display_text: 'B', id: "5' biotin", idt_text: '/5Biosg/'));
  //     // expect(strand.modifications_int.length, 1);
  //     throw UnimplementedError();
  //   });
  //
  //   /*
  //   def test_can_add_internal_mod_to_circular_strand(self) -> None:
  //       self.strand.set_circular()
  //       self.assertTrue(self.strand.circular)
  //       self.strand.set_modification_internal(2, mod.biotin_int)
  //       self.assertEqual(1, len(self.strand.modifications_int))
  //
  //   def test_cannot_make_strand_circular_if_5p_mod(self) -> None:
  //       self.strand.set_modification_5p(mod.biotin_5p)
  //       with self.assertRaises(sc.StrandError):
  //           self.strand.set_circular(True)
  //
  //   def test_cannot_make_strand_circular_if_3p_mod(self) -> None:
  //       self.strand.set_modification_3p(mod.biotin_3p)
  //       with self.assertRaises(sc.StrandError):
  //           self.strand.set_circular(True)
  //
  //   def test_add_5p_mod_to_circular_strand(self) -> None:
  //       self.strand.set_circular(True)
  //       with self.assertRaises(sc.StrandError):
  //           self.strand.set_modification_5p(mod.biotin_5p)
  //
  //   def test_add_3p_mod_to_circular_strand(self) -> None:
  //       self.strand.set_circular(True)
  //       with self.assertRaises(sc.StrandError):
  //           self.strand.set_modification_3p(mod.biotin_3p)
  //    */
  // });

  group('CircularStrandEdits', () {
    List<Helix> helices;
    Design design;
    int num_strands;

    setUp(() {
      helices = [for (int i = 0; i < 3; i++) Helix(idx: i, max_offset: 100, grid: Grid.square)];
      design = Design(helices: helices, grid: Grid.square);
      design = design.draw_strand(0, 0).move(10).cross(1).move(-10).commit();
      design = design.draw_strand(0, 15).move(5).cross(1).move(-10).cross(0).move(5).commit();
      design = design.draw_strand(0, 20).move(10).commit();
      design = design.draw_strand(1, 30).move(-10).commit();
      design = design.draw_strand(0, 30).move(10).loopout(1, 5).move(-10).cross(2).move(10).as_circular().commit();
      design = design.draw_strand(0, 40).move(10).cross(1).move(-10).as_circular().commit();
      num_strands = design.strands.length;
    });
    /*
       0          10         20         30         40
        strand 0   strand 1   strand 2   strand 4   strand 5
    0  [--------\ /--->[---\ [--------> [--------\ /--------\
                | |        |                     ) |        |
    1  <--------/ \--------/ <--------] /--------/ \--------/
                              strand 3  |
    2                                   \-------->cross to 5' end on helix 0
    */

    test('add_crossover_from_linear_strand_to_itself_makes_it_circular', () {
      /*
         0
          strand 0
      0  [--------\
                  |
      1  <--------/
      to
         0
          strand 0
      0  /--------\
         |        |
      1  \--------/
      */
      expect(design.strands[0].circular, false);
      expect(design.strands[0].substrands.length, 2);

      var dna_end1 = design.strands[0].dnaend_5p;
      var dna_end2 = design.strands[0].dnaend_3p;
      var action =
          actions.JoinStrandsByCrossover(dna_end_first_click: dna_end1, dna_end_second_click: dna_end2);
      var state = app_state_from_design(design);
      var strands = join_strands_by_crossover_reducer(design.strands, state, action);

      expect(strands[0].circular, true);
      expect(strands.length, num_strands);
    });

    test('convert_crossover_to_loopout_on_circular_strand_right_crossover', () {
      /*
         40
          strand 5
      0  /--------\
         |        |
      1  \--------/
      to
         40
          strand 5
      0  /--------\
         |         ) loopout length 5
      1  \--------/
      */
      var strand = design.strands[5];
      expect(strand.circular, true);
      expect(strand.substrands.length, 2);

      var crossover = strand.crossovers[0];
      var action = actions.ConvertCrossoverToLoopout(crossover, 5);
      strand = convert_crossover_to_loopout_reducer(strand, action);

      expect(strand.circular, true);
      expect(strand.substrands.length, 3);
      expect(strand.domains.length, 2);

      Domain d0 = strand.substrands[0] as Domain;
      Loopout loopout = strand.substrands[1] as Loopout;
      Domain d1 = strand.substrands[2] as Domain;

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 40);
      expect(d0.end, 50);

      expect(d1.helix, 1);
      expect(d1.forward, false);
      expect(d1.start, 40);
      expect(d1.end, 50);
    });

    test('convert_crossover_to_loopout_on_circular_strand_left_crossover', () {
      /*
         40
          strand 5
      0  /--------\
         |        |
      1  \--------/
      to
         40
          strand 5
      0  /--------\
        (len 5    |
      1  \--------/  <-- this is now the "5' end" of the circular strand
                         (i.e., where first domain in list of substrands is)
      */
      var strand = design.strands[5];
      expect(strand.circular, true);
      expect(strand.substrands.length, 2);

      var crossover = strand.crossovers[1];
      var action = actions.ConvertCrossoverToLoopout(crossover, 5);
      strand = convert_crossover_to_loopout_reducer(strand, action);

      expect(strand.circular, true);
      expect(strand.substrands.length, 3);
      expect(strand.domains.length, 2);

      // implementation detail: the domains will be rotated to ensure that the strand doesn't begin
      // with a loopout; so domain 0 is now the BOTTOM one
      Domain d0 = strand.substrands[0] as Domain;
      Loopout loopout = strand.substrands[1] as Loopout;
      Domain d1 = strand.substrands[2] as Domain;

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 1);
      expect(d0.forward, false);
      expect(d0.start, 40);
      expect(d0.end, 50);

      expect(d1.helix, 0);
      expect(d1.forward, true);
      expect(d1.start, 40);
      expect(d1.end, 50);
    });

    test('convert_loopout_to_crossover_on_circular_strand', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0  [--------\
                    |
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
      */
      var strand = design.strands[4];
      expect(strand.circular, true);
      expect(strand.substrands.length, 4);

      var loopout = strand.loopouts[0];
      var action = actions.LoopoutLengthChange(loopout, 0);
      strand = loopout_length_change_reducer(strand, action);

      expect(strand.circular, true);
      expect(strand.substrands.length, 3);
      expect(strand.domains.length, 3);

      Domain d0 = strand.substrands[0] as Domain;
      Domain d1 = strand.substrands[1] as Domain;
      Domain d2 = strand.substrands[2] as Domain;

      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 30);
      expect(d0.end, 40);

      expect(d1.helix, 1);
      expect(d1.forward, false);
      expect(d1.start, 30);
      expect(d1.end, 40);

      expect(d2.helix, 2);
      expect(d2.forward, true);
      expect(d2.start, 30);
      expect(d2.end, 40);
    });

    test('remove_crossover_from_circular_strand_makes_it_linear_left_crossover', () {
      /*
         40
          strand 5
      0  /--------\
         |        |
      1  \--------/
      to
         40
          strand 5
      0  [--------\
                  |
      1  <--------/
      */
      var strand = design.strands[5];
      expect(strand.circular, true);
      expect(strand.substrands.length, 2);

      var crossover = strand.crossovers[1];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.crossover])
          ..selectables_store.selected_items.replace([crossover])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[5];
      expect(strand.circular, false);
      expect(strand.substrands.length, 2);
      expect(strand.domains.length, 2);

      expect(strand.domains[0].helix, 0);
      expect(strand.domains[0].forward, true);
      expect(strand.domains[0].start, 40);
      expect(strand.domains[0].end, 50);

      expect(strand.domains[1].helix, 1);
      expect(strand.domains[1].forward, false);
      expect(strand.domains[1].start, 40);
      expect(strand.domains[1].end, 50);
    });

    test('remove_crossover_from_circular_strand_makes_it_linear_right_crossover', () {
      /*
         40
          strand 5
      0  /--------\
         |        |
      1  \--------/
      to
         0
          strand 5
      0  /-------->
         |
      1  \--------]
      */
      var strand = design.strands[5];
      expect(strand.circular, true);
      expect(strand.substrands.length, 2);

      var crossover = strand.crossovers[0];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.crossover])
          ..selectables_store.selected_items.replace([crossover])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[5];
      expect(strand.circular, false);
      expect(strand.substrands.length, 2);
      expect(strand.domains.length, 2);

      expect(strand.domains[0].helix, 1);
      expect(strand.domains[0].forward, false);
      expect(strand.domains[0].start, 40);
      expect(strand.domains[0].end, 50);

      expect(strand.domains[1].helix, 0);
      expect(strand.domains[1].forward, true);
      expect(strand.domains[1].start, 40);
      expect(strand.domains[1].end, 50);
    });

    test('remove_domain_from_circular_strand_makes_it_linear_first_domain', () {
      /*
         40
          strand 5
      0  /--------\
         |        |
      1  \--------/
      to
         0
          strand 5
      0

      1  <--------]
      */
      var strand = design.strands[5];
      expect(strand.circular, true);
      expect(strand.substrands.length, 2);

      var domain = strand.domains[0];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.domain])
          ..selectables_store.selected_items.replace([domain])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[5];
      expect(strand.circular, false);
      expect(strand.substrands.length, 1);
      expect(strand.domains.length, 1);

      var d0 = strand.domains[0];
      expect(d0.helix, 1);
      expect(d0.forward, false);
      expect(d0.start, 40);
      expect(d0.end, 50);
    });

    test('remove_domain_from_circular_strand_makes_it_linear_last_domain', () {
      /*
         40
          strand 5
      0  /--------\
         |        |
      1  \--------/
      to
         0
          strand 5
      0  [-------->

      1
      */
      var strand = design.strands[5];
      expect(strand.circular, true);
      expect(strand.substrands.length, 2);

      var domain = strand.domains[1];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.domain])
          ..selectables_store.selected_items.replace([domain])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[5];
      expect(strand.circular, false);
      expect(strand.substrands.length, 1);
      expect(strand.domains.length, 1);

      var d0 = strand.domains[0];
      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 40);
      expect(d0.end, 50);
    });

    test('remove_domain_from_circular_strand_with_loopout_adjacent_to_domain_makes_it_linear', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0

        1  /--------]
           |
        2  \-------->
       */
      var strand = design.strands[4];
      expect(strand.circular, true);
      expect(strand.substrands.length, 4);
      expect(strand.domains.length, 3);

      var domain = strand.domains[0];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.domain])
          ..selectables_store.selected_items.replace([domain])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[4];
      expect(strand.circular, false);
      expect(strand.substrands.length, 2);
      expect(strand.domains.length, 2);

      var d0 = strand.substrands[0] as Domain;
      var d1 = strand.substrands[1] as Domain;

      expect(d0.helix, 1);
      expect(d0.forward, false);
      expect(d0.start, 30);
      expect(d0.end, 40);

      expect(d1.helix, 2);
      expect(d1.forward, true);
      expect(d1.start, 30);
      expect(d1.end, 40);
    });

    test('remove_domain_from_circular_strand_with_loopout_adjacent_prior_to_domain_makes_it_linear', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0  [-------->

        1

        2  [-------->cross to 5' end on helix 0 here
       */
      var strand = design.strands[4];
      expect(strand.circular, true);
      expect(strand.substrands.length, 4);
      expect(strand.domains.length, 3);

      var domain = strand.domains[1];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.domain])
          ..selectables_store.selected_items.replace([domain])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[4];
      expect(strand.circular, false);
      expect(strand.substrands.length, 2);
      expect(strand.domains.length, 2);

      var d0 = strand.substrands[0] as Domain;
      var d1 = strand.substrands[1] as Domain;

      expect(d0.helix, 2);
      expect(d0.forward, true);
      expect(d0.start, 30);
      expect(d0.end, 40);

      expect(d1.helix, 0);
      expect(d1.forward, true);
      expect(d1.start, 30);
      expect(d1.end, 40);
    });

    test('remove_domain_from_circular_strand_with_loopout_nonadjacent_to_domain_makes_it_linear', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  <--------/

        2
       */
      var strand = design.strands[4];
      expect(strand.circular, true);
      expect(strand.substrands.length, 4);
      expect(strand.domains.length, 3);

      var domain = strand.domains[2];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.domain])
          ..selectables_store.selected_items.replace([domain])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[4];
      expect(strand.circular, false);
      expect(strand.substrands.length, 3);
      expect(strand.domains.length, 2);

      var d0 = strand.substrands[0] as Domain;
      var loopout = strand.substrands[1] as Loopout;
      var d1 = strand.substrands[2] as Domain;

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 30);
      expect(d0.end, 40);

      expect(d1.helix, 1);
      expect(d1.forward, false);
      expect(d1.start, 30);
      expect(d1.end, 40);
    });

    test('remove_loopout_from_circular_strand_makes_it_linear', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0  [-------->

        1  /--------]
           |
        2  \-------->cross to 5' end on helix 0 here
       */
      var strand = design.strands[4];
      expect(strand.circular, true);
      expect(strand.substrands.length, 4);
      expect(strand.domains.length, 3);

      var loopout = strand.loopouts[0];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.loopout])
          ..selectables_store.selected_items.replace([loopout])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[4];
      expect(strand.circular, false);
      expect(strand.substrands.length, 3);
      expect(strand.domains.length, 3);

      var d0 = strand.substrands[0] as Domain;
      var d1 = strand.substrands[1] as Domain;
      var d2 = strand.substrands[2] as Domain;

      expect(d0.helix, 1);
      expect(d0.forward, false);
      expect(d0.start, 30);
      expect(d0.end, 40);

      expect(d1.helix, 2);
      expect(d1.forward, true);
      expect(d1.start, 30);
      expect(d1.end, 40);

      expect(d2.helix, 0);
      expect(d2.forward, true);
      expect(d2.start, 30);
      expect(d2.end, 40);
    });

    test('remove_crossover_from_circular_strand_with_loopout_makes_it_linear', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0  [-------->
                     ) loopout length 5
        1  <--------]

        2  [-------->cross to 5' end on helix 0 here
       */
      var strand = design.strands[4];
      expect(strand.circular, true);
      expect(strand.substrands.length, 4);
      expect(strand.domains.length, 3);

      var crossover = strand.crossovers[0];
      var action = actions.DeleteAllSelected();
      var state = app_state_from_design(design);
      state = state.rebuild((b) => b
        ..ui_state.update((u) => u
          ..storables.select_mode_state.modes.replace([SelectModeChoice.crossover])
          ..selectables_store.selected_items.replace([crossover])));
      var strands = delete_all_reducer(design.strands, state, action);

      expect(strands.length, num_strands);
      strand = strands[4];
      expect(strand.circular, false);
      expect(strand.substrands.length, 4);
      expect(strand.domains.length, 3);

      var d0 = strand.substrands[0] as Domain;
      var d1 = strand.substrands[1] as Domain;
      var loopout = strand.substrands[2] as Loopout;
      var d2 = strand.substrands[3] as Domain;

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 2);
      expect(d0.forward, true);
      expect(d0.start, 30);
      expect(d0.end, 40);

      expect(d1.helix, 0);
      expect(d1.forward, true);
      expect(d1.start, 30);
      expect(d1.end, 40);

      expect(d2.helix, 1);
      expect(d2.forward, false);
      expect(d2.start, 30);
      expect(d2.end, 40);
    });

    test('add_nick_to_2_domain_circular_strand_makes_it_linear_nick_first_domain', () {
      /*
         40
          strand 5
      0  /--------\
         |        |
      1  \--------/
      to
         40
          strand 5
      0  /--->[---\
         |        |
      1  \--------/
       */
      expect(design.strands[5].circular, true);
      expect(design.strands[5].substrands.length, 2);

      var action = actions.Nick(domain: design.strands[5].substrands[0], offset: 45);
      var state = app_state_from_design(design);
      var strands = nick_reducer(design.strands, state, action);

      var strand = strands[5];
      expect(strand.circular, false);
      expect(strands.length, num_strands);

      expect(strand.substrands.length, 3);
      expect(strand.domains.length, 3);

      Domain d0 = strand.substrands[0];
      Domain d1 = strand.substrands[1];
      Domain d2 = strand.substrands[2];
      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 45);
      expect(d0.end, 50);

      expect(d1.helix, 1);
      expect(d1.forward, false);
      expect(d1.start, 40);
      expect(d1.end, 50);

      expect(d2.helix, 0);
      expect(d2.forward, true);
      expect(d2.start, 40);
      expect(d2.end, 45);
    });

    test('add_nick_to_2_domain_circular_strand_makes_it_linear_nick_second_domain', () {
      /*
         40
          strand 5
      0  /--------\
         |        |
      1  \--------/
      to
          40
           strand 5
       0  /--------\
          |        |
       1  \---]<---/
       */
      expect(design.strands[5].circular, true);
      expect(design.strands[5].substrands.length, 2);

      var action = actions.Nick(domain: design.strands[5].substrands[1], offset: 45);
      var state = app_state_from_design(design);
      var strands = nick_reducer(design.strands, state, action);

      var strand = strands[5];
      expect(strand.circular, false);
      expect(strands.length, num_strands);

      expect(strand.substrands.length, 3);
      expect(strand.domains.length, 3);

      Domain d0 = strand.substrands[0];
      Domain d1 = strand.substrands[1];
      Domain d2 = strand.substrands[2];
      expect(d0.helix, 1);
      expect(d0.forward, false);
      expect(d0.start, 40);
      expect(d0.end, 45);

      expect(d1.helix, 0);
      expect(d1.forward, true);
      expect(d1.start, 40);
      expect(d1.end, 50);

      expect(d2.helix, 1);
      expect(d2.forward, false);
      expect(d2.start, 45);
      expect(d2.end, 50);
    });

    test('add_nick_to_3_domain_circular_strand_makes_it_linear_nick_first_domain', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0  [--->[---\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end here
       */
      expect(design.strands[4].circular, true);
      expect(design.strands[4].substrands.length, 4);
      expect(design.strands[4].domains.length, 3);

      var action = actions.Nick(domain: design.strands[4].domains[0], offset: 35);
      var state = app_state_from_design(design);
      var strands = nick_reducer(design.strands, state, action);

      var strand = strands[4];
      expect(strand.circular, false);
      expect(strands.length, num_strands);

      expect(strand.substrands.length, 5);
      expect(strand.domains.length, 4);

      Domain d0 = strand.substrands[0];
      Loopout loopout = strand.substrands[1];
      Domain d1 = strand.substrands[2];
      Domain d2 = strand.substrands[3];
      Domain d3 = strand.substrands[4];

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 35);
      expect(d0.end, 40);

      expect(d1.helix, 1);
      expect(d1.forward, false);
      expect(d1.start, 30);
      expect(d1.end, 40);

      expect(d2.helix, 2);
      expect(d2.forward, true);
      expect(d2.start, 30);
      expect(d2.end, 40);

      expect(d3.helix, 0);
      expect(d3.forward, true);
      expect(d3.start, 30);
      expect(d3.end, 35);
    });

    test('add_nick_to_3_domain_circular_strand_makes_it_linear_nick_middle_domain', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /---]<---/
           |
        2  \-------->cross to 5' end here
       */
      expect(design.strands[4].circular, true);
      expect(design.strands[4].substrands.length, 4);
      expect(design.strands[4].domains.length, 3);

      var action = actions.Nick(domain: design.strands[4].domains[1], offset: 35);
      var state = app_state_from_design(design);
      var strands = nick_reducer(design.strands, state, action);

      var strand = strands[4];
      expect(strand.circular, false);
      expect(strands.length, num_strands);

      expect(strand.substrands.length, 5);
      expect(strand.domains.length, 4);

      Domain d0 = strand.substrands[0];
      Domain d1 = strand.substrands[1];
      Domain d2 = strand.substrands[2];
      Loopout loopout = strand.substrands[3];
      Domain d3 = strand.substrands[4];

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 1);
      expect(d0.forward, false);
      expect(d0.start, 30);
      expect(d0.end, 35);

      expect(d1.helix, 2);
      expect(d1.forward, true);
      expect(d1.start, 30);
      expect(d1.end, 40);

      expect(d2.helix, 0);
      expect(d2.forward, true);
      expect(d2.start, 30);
      expect(d2.end, 40);

      expect(d3.helix, 1);
      expect(d3.forward, false);
      expect(d3.start, 35);
      expect(d3.end, 40);
    });

    test('add_nick_to_3_domain_circular_strand_makes_it_linear_nick_last_domain', () {
      /*
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \-------->cross to 5' end on helix 0 here
        to
           30         40
            strand 4
        0  [--------\
                     ) loopout length 5
        1  /--------/
           |
        2  \--->[--->cross to 5' end here
       */
      expect(design.strands[4].circular, true);
      expect(design.strands[4].substrands.length, 4);
      expect(design.strands[4].domains.length, 3);

      var action = actions.Nick(domain: design.strands[4].domains[2], offset: 35);
      var state = app_state_from_design(design);
      var strands = nick_reducer(design.strands, state, action);

      var strand = strands[4];
      expect(strand.circular, false);
      expect(strands.length, num_strands);

      expect(strand.substrands.length, 5);
      expect(strand.domains.length, 4);

      Domain d0 = strand.substrands[0];
      Domain d1 = strand.substrands[1];
      Loopout loopout = strand.substrands[2];
      Domain d2 = strand.substrands[3];
      Domain d3 = strand.substrands[4];

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 2);
      expect(d0.forward, true);
      expect(d0.start, 35);
      expect(d0.end, 40);

      expect(d1.helix, 0);
      expect(d1.forward, true);
      expect(d1.start, 30);
      expect(d1.end, 40);

      expect(d2.helix, 1);
      expect(d2.forward, false);
      expect(d2.start, 30);
      expect(d2.end, 40);

      expect(d3.helix, 2);
      expect(d3.forward, true);
      expect(d3.start, 30);
      expect(d3.end, 35);
    });

    test('ligate_linear_strand_to_itself_makes_it_circular', () {
      /*
         10
          strand 1
      0  /--->[---\
         |        |
      1  \--------/
      to
         10
          strand 1
      0  /--------\
         |        |
      1  \--------/
      */
      expect(design.strands[1].substrands.length, 3);
      var action = actions.Ligate(dna_end: design.strands[1].first_domain.dnaend_5p);
      var state = app_state_from_design(design);
      var strands = ligate_reducer(design.strands, state, action);
      expect(strands.length, num_strands);
      expect(strands[1].circular, true);
      expect(strands[1].substrands.length, 2);

      var d0 = strands[1].domains[0];
      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 10);
      expect(d0.end, 20);

      var d1 = strands[1].domains[1];
      expect(d1.helix, 1);
      expect(d1.forward, false);
      expect(d1.start, 10);
      expect(d1.end, 20);
    });

    test('ligate_linear_strand_with_3_domains_loopout_makes_it_circular_loopout_bt_domains_0_and_1', () {
      /*
         0
          strand 1
      0  /--->[---\
         |         ) loopout length 5
      1  \--------/
      to
         0
          strand 1
      0  /--------\  <-- starting domain after to ensure strand doesn't have loopout on start or end
         |         ) loopout length 5
      1  \--------/
      */
      helices = [for (int i = 0; i < 2; i++) Helix(idx: i, max_offset: 100, grid: Grid.square)];
      design = Design(helices: helices, grid: Grid.square);
      design = design.draw_strand(0, 5).move(5).loopout(1, 5).move(-10).cross(0).move(5).commit();
      num_strands = design.strands.length;

      // expectations before change
      expect(design.strands.length, 1);
      expect(design.strands[0].circular, false);
      expect(design.strands[0].substrands.length, 4);
      expect(design.strands[0].domains.length, 3);

      // change
      var action = actions.Ligate(dna_end: design.strands[0].first_domain.dnaend_5p);
      var state = app_state_from_design(design);
      var strands = ligate_reducer(design.strands, state, action);
      expect(strands.length, num_strands);

      // expectations after change
      var strand = strands.first;
      expect(strand.circular, true);
      expect(strand.substrands.length, 3);

      Domain d0 = strand.substrands[0] as Domain;
      Loopout loopout = strand.substrands[1] as Loopout;
      Domain d1 = strand.substrands[2] as Domain;

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 0);
      expect(d0.end, 10);

      expect(d1.helix, 1);
      expect(d1.forward, false);
      expect(d1.start, 0);
      expect(d1.end, 10);
    });

    test('ligate_linear_strand_with_3_domains_loopout_makes_it_circular_loopout_bt_domains_1_and_2', () {
      /*
         0
          strand 1
      0  /--------\
         |         ) loopout length 5
      1  \---]<---/
      to
         0
          strand 1
      0  /--------\  <-- starting domain after to ensure strand doesn't have loopout on start or end
         |         ) loopout length 5
      1  \--------/
      */
      helices = [for (int i = 0; i < 2; i++) Helix(idx: i, max_offset: 100, grid: Grid.square)];
      design = Design(helices: helices, grid: Grid.square);
      design = design.draw_strand(1, 5).move(-5).cross(0).move(10).loopout(1, 5).move(-5).commit();
      num_strands = design.strands.length;

      // expectations before change
      expect(design.strands.length, 1);
      expect(design.strands[0].circular, false);
      expect(design.strands[0].substrands.length, 4);
      expect(design.strands[0].domains.length, 3);

      // change
      var action = actions.Ligate(dna_end: design.strands[0].first_domain.dnaend_5p);
      var state = app_state_from_design(design);
      var strands = ligate_reducer(design.strands, state, action);
      expect(strands.length, num_strands);

      // expectations after change
      var strand = strands.first;
      expect(strand.circular, true);
      expect(strand.substrands.length, 3);

      // NOTE: to ensure loopout doesn't start or end strand,
      // domains will be rotated to keep it in the middle
      Domain d0 = strand.substrands[0] as Domain;
      Loopout loopout = strand.substrands[1] as Loopout;
      Domain d1 = strand.substrands[2] as Domain;

      expect(loopout.loopout_num_bases, 5);

      expect(d0.helix, 0);
      expect(d0.forward, true);
      expect(d0.start, 0);
      expect(d0.end, 10);

      expect(d1.helix, 1);
      expect(d1.forward, false);
      expect(d1.start, 0);
      expect(d1.end, 10);
    });
  });
}
