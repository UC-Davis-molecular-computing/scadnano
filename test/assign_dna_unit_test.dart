// @dart=2.9

import 'dart:convert';

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
  group('Assign/remove dna test: ', () {
    test('AssignDNA', () {
      //     0               16
      // 0   [--------------->
      //     <---------------]
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(16).commit();
      design = design.draw_strand(0, 16).move(-16).commit();
      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AACGTACGATGCATCC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      //     0               16
      //     AACGTACGATGCATCC
      // 0   [-------------->
      //     <--------------]
      //     TTGCATGCTACGTAGG
      expect(state.design.strands[0].dna_sequence, "AACGTACGATGCATCC");
      expect(state.design.strands[1].dna_sequence, "GGATGCATCGTACGTT");

      // // Assigning on strands that already have dna sequence (not sure if this is allowed yet)
      Strand strand_last = state.design.strands[1];
      dna_sequence = 'ATCCAACAGCCCCTCG';
      state = app_state_reducer(
        state,
        AssignDNA(
          strand: strand_last,
          dna_assign_options: DNAAssignOptions(
            assign_complements: false,
            dna_sequence: dna_sequence,
            disable_change_sequence_bound_strand: false,
          ),
        ),
      );
      //     0               16
      //     AACGTACGATGCATCC
      // 0   [-------------->
      //     <--------------]
      //     GCTCCCCGACAACCTA
      expect(state.design.strands[0].dna_sequence, "AACGTACGATGCATCC");
      expect(state.design.strands[1].dna_sequence, "ATCCAACAGCCCCTCG");
    });
    test('AssignDNA__hairpin', () {
      //     0   4
      //
      // 0   [---\
      //         )
      //         )
      //         )
      //         )
      //         )
      //     <---/
      //
      var helices = [Helix(idx: 0, max_offset: 5, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(5).loopout(0, 5).move(-5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAACCTGCAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));

      //     0   4
      //     AAACC
      // 0   [---\
      //         ) T
      //         ) G
      //         ) C
      //         ) A
      //         ) C
      //     <---/
      //     TTTGG
      expect(state.design.strands.length, 1);
      expect(state.design.strands[0].dna_sequence, "AAACCTGCACGGTTT");
    });
    test('AssignDNA__from_strand_with_loopout', () {
      //     0   4
      //
      //     [---\
      // 0   <---]
      //           )
      //           )
      //           )
      //           )
      //           )
      //     [--->
      // 1   <---/
      //

      var helices = [
        Helix(idx: 0, max_offset: 5, grid: Grid.square),
        Helix(idx: 1, max_offset: 5, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(5).loopout(1, 5).move(-5).commit();
      design = design.draw_strand(0, 5).move(-5).commit();
      design = design.draw_strand(1, 0).move(5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAACCTGCACATTCG';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));

      //     0   4
      //     AAACC
      //     [---\
      // 0   <---]
      //     TTTGG ) T
      //           ) G
      //           ) C
      //           ) A
      //     CGAAT ) C
      //     [--->
      // 1   <---/
      //     GCTTA

      expect(state.design.strands.length, 3);
      expect(state.design.strands[0].dna_sequence, "AAACCTGCACATTCG");
      expect(state.design.strands[1].dna_sequence, "GGTTT");
      expect(state.design.strands[2].dna_sequence, "CGAAT");
    });

    test('AssignDNA__to_strand_with_loopout', () {
      //     0   4
      //
      //     [---\
      // 0   <---]
      //           )
      //           )
      //           )
      //           )
      //           )
      //     [--->
      // 1   <---/
      //

      var helices = [
        Helix(idx: 0, max_offset: 5, grid: Grid.square),
        Helix(idx: 1, max_offset: 5, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(5).loopout(1, 5).move(-5).commit();
      design = design.draw_strand(0, 5).move(-5).commit();
      design = design.draw_strand(1, 0).move(5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands[1];
      String dna_sequence = 'GGTTT';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));

      //     0   4
      //     AAACC
      //     [---\
      // 0   <---]
      //     TTTGG ) ?
      //           ) ?
      //           ) ?
      //           ) ?
      //           ) ?
      //     [--->
      // 1   <---/
      //     ?????
      expect(state.design.strands.length, 3);
      expect(state.design.strands[0].dna_sequence, "AAACC??????????");
      expect(state.design.strands[1].dna_sequence, "GGTTT");
      expect(state.design.strands[2].dna_sequence, null);
      strand = state.design.strands[2];
      dna_sequence = 'CGAAT';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      //     0   4
      //     AAACC
      //     [---\
      // 0   <---]
      //     TTTGG ) ?
      //           ) ?
      //           ) ?
      //           ) ?
      //     ATTCG ) ?
      //     [--->
      // 1   <---/
      //     TAAGC

      expect(state.design.strands.length, 3);
      expect(state.design.strands[0].dna_sequence, "AAACC?????ATTCG");
      expect(state.design.strands[1].dna_sequence, "GGTTT");
      expect(state.design.strands[2].dna_sequence, "CGAAT");
    });

    test('AssignDNA__test_assign_dna__assign_from_strand_multi_other_single', () {
      //     0       8
      //
      //     /-->[--\
      // 0   <------]
      //
      //
      // 1   \------/
      //

      var helices = [
        Helix(idx: 0, max_offset: 8, grid: Grid.square),
        Helix(idx: 1, max_offset: 8, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 4).move(4).cross(1).move(-8).cross(0).move(4).commit();
      design = design.draw_strand(0, 8).move(-8).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands[0];
      String dna_sequence = 'CTGTATGATTCGAAAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));

      //     0       8
      //     AAACCTGT
      //     /-->[--\
      // 0   <------]
      //     TTTGGACA
      //
      // 1   \------/
      //     GCTTAGTA

      expect(state.design.strands.length, 2);
      expect(state.design.strands[0].dna_sequence, "CTGTATGATTCGAAAC");
      expect(state.design.strands[1].dna_sequence, "ACAGGTTT");
    });

    test('AssignDNA__test_assign_dna__assign_to_strand_multi_other_single', () {
      //     0       8
      //     AAACCTGT
      //     /-->[--\
      // 0   <------]
      //     TTTGGACA
      //
      // 1   \------/
      //     ????????

      var helices = [
        Helix(idx: 0, max_offset: 8, grid: Grid.square),
        Helix(idx: 1, max_offset: 8, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 4).move(4).cross(1).move(-8).cross(0).move(4).commit();
      design = design.draw_strand(0, 8).move(-8).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands[1];
      String dna_sequence = 'ACAGGTTT';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));

      //     0       8
      //     AAACCTGT
      //     /-->[--\
      // 0   <------]
      //     TTTGGACA
      //
      // 1   \------/
      //     GCTTAGTA

      expect(state.design.strands.length, 2);
      expect(state.design.strands[0].dna_sequence, "CTGT????????AAAC");
      expect(state.design.strands[1].dna_sequence, "ACAGGTTT");
    });

    test('test_assign_dna__other_strand_fully_defined_already', () {
      /*
        0      7
        [------>


        <--]
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 4).move(-4).commit();

      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[0];
      Strand strand2 = design.strands[1];
      String dna_sequence1 = 'CAAAGTCG';
      String dna_sequence2 = 'TTTG';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand1,
            dna_assign_options: DNAAssignOptions(
              assign_complements: false,
              dna_sequence: dna_sequence1,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            dna_assign_options: DNAAssignOptions(
              assign_complements: false,
              dna_sequence: dna_sequence2,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      /*
        0      7
        CAAAGTCG
        [------>


        <--]
        GTTT
      */
      // should not have an error by this point
      expect('CAAAGTCG', state.design.strands[0].dna_sequence);
      expect('TTTG', state.design.strands[1].dna_sequence);
    });

    test('AssignDNA__other_strand_fully_defined_already_and_self_extends_beyond', () {
      /*
        0      7
        [------>
        CAAAGTCG
          TTCA
          <--]
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 6).move(-4).commit();

      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[0];
      Strand strand2 = design.strands[1];
      String dna_sequence1 = 'CAAAGTCG';
      String dna_sequence2 = 'ACTT';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            dna_assign_options: DNAAssignOptions(
              assign_complements: false,
              dna_sequence: dna_sequence2,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand1,
            dna_assign_options: DNAAssignOptions(
              assign_complements: false,
              dna_sequence: dna_sequence1,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      // should not have an error by this point
    });

    test('AssignDNA__two_equal_length_strands_on_one_helix', () {
      /*
        0   4
        GTTTT
        [--->
        CAAAA
        <---]
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(5).commit();
      design = design.draw_strand(0, 5).move(-5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.last;
      String dna_sequence = 'AAAAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[0].dna_sequence, 'GTTTT');
    });

    test('AssignDNA__assign_seq_with_wildcards', () {
      /*
        0   4
        G??TT
        [--->
        C??AA
        <---]
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(5).commit();
      design = design.draw_strand(0, 5).move(-5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.last;
      String dna_sequence = 'AA??C';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[0].dna_sequence, 'G??TT');
    });

    test('AssignDNA__one_strand_assigned_by_complement_from_two_other_strands', () {
      /*
        0      8
        TTTGCCCT
        [------>
        CAAAAGGG
        <--]<--]
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 4).move(-4).commit();
      design = design.draw_strand(0, 8).move(-4).commit();

      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[1];
      Strand strand2 = design.strands.last;
      String dna_sequence1 = 'CAAA';
      String dna_sequence2 = 'AGGG';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand1,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence1,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[0].dna_sequence, 'TTTG????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence2,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[0].dna_sequence, 'TTTGCCCT');
    });

    test('AssignDNA__adapter_assigned_from_scaffold_and_tiles', () {
      /*
          01 2345     6789  01
           [-TTTC-----CATT-------+
        <-GT-AAAG-+ <-GTAA--AA-] |
                       |         |
        [-AA-TTTG-+ [-TGCC--GG-> |
           <-AAAC-----ACGG-------+
      */

      var helices = [
        Helix(idx: 0, max_offset: 15, grid: Grid.square),
        Helix(idx: 1, max_offset: 15, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(1, 0).move(6).cross(0).move(-6).commit();
      design = design.draw_strand(0, 2).move(8).cross(1).move(-8).commit();
      design = design.draw_strand(0, 12).move(-6).commit();
      design = design.draw_strand(1, 6).move(6).commit();

      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[2];
      Strand strand2 = design.strands.last;
      Strand strand3 = design.strands.first;
      String dna_sequence1 = 'AAAATG';
      String dna_sequence2 = 'TGCCGG';
      String dna_sequence3 = 'AATTTGGAAATG';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand1,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence1,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, '????CATT????????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence2,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, '????CATTGGCA????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand3,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence3,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, 'TTTCCATTGGCACAAA');
    });

    test('AssignDNA__adapter_assigned_from_scaffold_and_tiles_with_deletions', () {
      /*
          01 2345     6789  01
              X         X           deletions
           [-T TC-----CA T-------+
        <-GT-A AG-+ <-GT A--AA-] |
                       |         |
        [-AA-TTTG-+ [-TG C--GG-> |
           <-AAAC-----AC G-------+
                        X           deletions
      */

      var helices = [
        Helix(idx: 0, max_offset: 15, grid: Grid.square),
        Helix(idx: 1, max_offset: 15, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(1, 0).move(6).cross(0).move(-6).add_deletion(0, 3).commit();
      design = design
          .draw_strand(0, 2)
          .move(8)
          .add_deletion(0, 3)
          .add_deletion(0, 8)
          .cross(1)
          .move(-8)
          .add_deletion(1, 8)
          .commit();
      design = design.draw_strand(0, 12).move(-6).add_deletion(0, 8).commit();
      design = design.draw_strand(1, 6).move(6).add_deletion(1, 8).commit();

      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[2];
      Strand strand2 = design.strands.last;
      Strand strand3 = design.strands.first;
      String dna_sequence1 = 'AAATG';
      String dna_sequence2 = 'TGCGG';
      String dna_sequence3 = 'AATTTGGAATG';
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand1,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence1,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, '???CAT???????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence2,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, '???CATGCA????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand3,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence3,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, 'TTCCATGCACAAA');
    });

    test('AssignDNA__adapter_assigned_from_scaffold_and_tiles_with_insertions', () {
      /*
          01 2345     6789  01
                         I          insertions
           [-TTTC-----CATTT-------+
        <-GT-AAAG-+ <-GTAA--AA-]  |
                       |          |
        [-AA-TTTG-+ [-TG C--GG->  |
           <-AAAC-----ACGGG-------+
                         I           insertions
      */

      var helices = [
        Helix(idx: 0, max_offset: 15, grid: Grid.square),
        Helix(idx: 1, max_offset: 15, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(1, 0).move(6).cross(0).move(-6).commit();
      design = design
          .draw_strand(0, 2)
          .move(8)
          .add_insertion(0, 8, 1)
          .cross(1)
          .move(-8)
          .add_insertion(1, 8, 1)
          .commit();
      design = design.draw_strand(0, 12).move(-6).add_insertion(0, 8, 1).commit();
      design = design.draw_strand(1, 6).move(6).add_insertion(1, 8, 1).commit();

      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[2];
      Strand strand2 = design.strands.last;
      Strand strand3 = design.strands.first;
      String dna_sequence1 = 'AAAAATG';
      String dna_sequence2 = 'TGCCCGG';
      String dna_sequence3 = 'AATTTGGAAATG';
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand1,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence1,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, '????CATTT?????????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence2,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, '????CATTTGGGCA????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand3,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence3,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, 'TTTCCATTTGGGCACAAA');
    });

    test('AssignDNA__dna_sequence_shorter_than_complementary_strand_right_strand_longer', () {
      /*
        0        10
        [-------->
        GTTTT?????
        AAAAC
        <---]
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(10).commit();
      design = design.draw_strand(0, 5).move(-5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.last;
      String dna_sequence = 'AAAAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands.first.dna_sequence, 'GTTTT?????');
    });

    test('AssignDNA__dna_sequence_shorter_than_complementary_strand_left_strand_longer', () {
      /*
        0        10
        [--->
        AAAAC
        TTTTG?????
        <--------]
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(5).commit();
      design = design.draw_strand(0, 10).move(-10).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAAAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands.last.dna_sequence, '?????GTTTT');
    });

    test('AssignDNA__dna_sequence_with_uncomplemented_domain_on_different_helix', () {
      /*
        0        10
        <---]
        CAAAA
        GTTTT?????
        [--------+
                 |
               <-+
               ???
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 5).move(-5).commit();
      design = design.draw_strand(0, 0).move(10).move(-3).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAAAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands.last.dna_sequence, 'GTTTT????????');
    });

    test('AssignDNA__dna_sequence_with_uncomplemented_domain_on_different_helix_wildcards_both_ends', () {
      /*
        0        10
             <---]
             CAAAA
        ?????GTTTT
        [--------+
                 |
               <-+
               ???
      */

      var helices = [
        Helix(idx: 0, max_offset: 10, grid: Grid.square),
        Helix(idx: 1, max_offset: 10, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 10).move(-5).commit();
      design = design.draw_strand(0, 0).move(10).cross(1).move(-3).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAAAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands.last.dna_sequence, '?????GTTTT???');
    });

    test('AssignDNA__one_helix_with_one_bottom_strand_and_three_top_strands', () {
      /*
        0        10
         012   345   678
        -CCC> -GGG> -TTT>
        <GGG---CCC---AAA-
         876   543   210
      */

      var helices = [Helix(idx: 0, max_offset: 10, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 9).move(-9).commit();
      design = design.draw_strand(0, 0).move(3).commit();
      design = design.draw_strand(0, 3).move(3).commit();
      design = design.draw_strand(0, 6).move(3).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAACCCGGG';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, 'CCC');
      expect(state.design.strands[2].dna_sequence, 'GGG');
      expect(state.design.strands[3].dna_sequence, 'TTT');
    });

    test('AssignDNA__two_helices_with_multiple_domain_intersections', () {
      /*
                012    345   678    901
        M13   [-ACC----TAA---GAA----AAC---+
              +-TGG-]<-ATT-+ CTT----TTG-+ |
              |            | |          | |
              +-GAT----TTC-+ ATG->[-AGT-+ |
              <-CTA----AAG---TAC----TCA---+
      */

      var helices = [
        Helix(idx: 0, max_offset: 12, grid: Grid.square),
        Helix(idx: 1, max_offset: 12, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(12).cross(1).move(-12).commit();
      design = design.draw_strand(0, 3).move(-3).cross(1).move(6).cross(0).move(-3).commit();
      design = design.draw_strand(1, 9).move(3).cross(0).move(-6).cross(1).move(3).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'ACC TAA GAA AAC ACT CAT GAA ATC'.replaceAll(' ', '');

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[1].dna_sequence, 'GGT GAT TTC TTA'.replaceAll(' ', ''));
      expect(state.design.strands[2].dna_sequence, 'AGT GTT TTC ATG'.replaceAll(' ', ''));
    });

    test('AssignDNA__upper_left_edge_staple_of_16H_origami_rectangle', () {
      /*
        staple <ACATAAGAAAACGGAG--+
        M13   +-TGTATTCTTTTGCCTC> |
              |                   |
              +-GATTTTGTGAGTAGAA- |
               -CTAAAACACTCATCTT--+
      */

      var helices = [
        Helix(idx: 0, max_offset: 16, grid: Grid.square),
        Helix(idx: 1, max_offset: 16, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(1, 16).move(-16).cross(0).move(16).commit();
      design = design.draw_strand(1, 0).move(16).cross(0).move(-16).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAGATGAGTGTTTTAGTGTATTCTTTTGCCTC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands.last.dna_sequence, 'CTAAAACACTCATCTTGAGGCAAAAGAATACA');
    });

    test('AssignDNA__2helix_with_deletions', () {
      /*
        scaf index: 2     3  4     5
        offset:     0 D1  2  3 D4  5
                    +     -  -     +
                   /C     A  T     C\
                  | G     T  A     G |
        helix 0   | <     +  +     ] |
                  |       |  |       |
        helix 1   | [     +  +     > |
                  | T     T  A     C |
                   \A     A  T     G/
                    +     ]  <     +
        offset:     0 D1  2  3 D4  5
        scaf index: 1     0  7     6
      */

      var helices = [
        Helix(idx: 0, max_offset: 6, grid: Grid.square),
        Helix(idx: 1, max_offset: 6, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(1, 3)
          .move(-3)
          .add_deletion(1, 1)
          .cross(0)
          .move(6)
          .add_deletion(0, 1)
          .add_deletion(0, 4)
          .cross(1)
          .move(-3)
          .add_deletion(1, 4)
          .commit();
      design = design.draw_strand(1, 0).move(3).add_deletion(1, 1).cross(0).move(-3).add_deletion(0, 1).commit();
      design = design.draw_strand(0, 6).move(-3).add_deletion(0, 4).cross(1).move(3).add_deletion(1, 4).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AACATCGT';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: dna_sequence,
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands[0].dna_sequence, 'AACATCGT');
      expect(state.design.strands[1].dna_sequence, 'TTTG');
      expect(state.design.strands[2].dna_sequence, 'GAAC');
    });

    test('AssignDNA__wildcards_simple', () {
      /*
         012   345   678
        -TTC> -GGA> -CCT>
        <AAG---CCT---GGA-
         876   543   210
      */

      var helices = [Helix(idx: 0, max_offset: 9, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(3).commit();
      design = design.draw_strand(0, 3).move(3).commit();
      design = design.draw_strand(0, 6).move(3).commit();
      design = design.draw_strand(0, 9).move(-9).commit();

      AppState state = app_state_from_design(design);

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: design.strands[0],
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: 'TTC',
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands.last.dna_sequence, '??????GAA');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: design.strands[2],
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: 'CCT',
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands.last.dna_sequence, 'AGG???GAA');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: design.strands[1],
            dna_assign_options: DNAAssignOptions(
              assign_complements: true,
              dna_sequence: 'GGA',
              disable_change_sequence_bound_strand: true,
            ),
          ));
      expect(state.design.strands.last.dna_sequence, 'AGGTCCGAA');
    });

    test('RemoveDNA (see issue #109)', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(16).with_sequence("AACGTACGATGCATCC").commit();
      design = design.draw_strand(0, 16).move(-16).with_sequence("GGATGCATCGTACGTT").commit();
      AppState state = app_state_from_design(design);
      Strand strand = design.strands.last;
      state =
          app_state_reducer(state, RemoveDNA(strand: strand, remove_all: false, remove_complements: true));

      expect(state.design.strands[0].dna_sequence, null);
      expect(state.design.strands[1].dna_sequence, null);
    });
    test('AssignDNAComplementFromBoundStrands__no_insertions_or_deletions', () {
      //     0               16
      //     AACGTACGATGCATCC
      // 0   [--------------->
      //     <---------------]
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(16).with_sequence('AACGTACGATGCATCC').commit();
      design = design.draw_strand(0, 16).move(-16).commit();

      var action = actions.AssignDNAComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_dna_reducer_complement_from_bound_strands(design.strands, state, action);

      //     0               16
      //     AACGTACGATGCATCC
      // 0   [-------------->
      //     <--------------]
      //     TTGCATGCTACGTAGG
      expect(all_strands[0].dna_sequence, "AACGTACGATGCATCC");
      expect(all_strands[1].dna_sequence, "GGATGCATCGTACGTT");
    });
    test('AssignDNAComplementFromBoundStrands__insertions__one_bound_strand', () {
      //     0                  16
      //     AACGTATCGCGATGCATCC
      // 0   [-------I: 3------->
      //     <-------I: 3-------]
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design =
          design.draw_strand(0, 0).move(16).add_insertion(0, 8, 3).with_sequence('AACGTATCGCGATGCATCC').commit();
      design = design.draw_strand(0, 16).move(-16).add_insertion(0, 8, 3).commit();

      var action = actions.AssignDNAComplementFromBoundStrands([design.strands[1]]);
      var state = app_state_from_design(design);
      var all_strands = assign_dna_reducer_complement_from_bound_strands(design.strands, state, action);

      //     0                  16
      //     AACGTATCGCGATGCATCC
      // 0   [-------I: 3------->
      //     <-------I: 3-------]
      //     TTGCATAGCGCTACGTAGG
      expect(all_strands[0].dna_sequence, "AACGTATCGCGATGCATCC");
      expect(all_strands[1].dna_sequence, "GGATGCATCGCGATACGTT");
    });

    test('AssignDNAComplementFromBoundStrands__insertions__two_bound_strands', () {
      //     0                  16
      //
      // 0   [-------I: 3------>
      //     <---]<--I: 3------]
      //     TTGCATAGCGCTACGTAGG
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(16).add_insertion(0, 8, 3).commit();
      design = design.draw_strand(0, 5).move(-5).with_sequence("ACGTT").commit();
      design = design.draw_strand(0, 16).move(-11).add_insertion(0, 8, 3).with_sequence('GGATGCATCGCGAT').commit();

      var action = actions.AssignDNAComplementFromBoundStrands([design.strands[0]]);
      var state = app_state_from_design(design);
      var all_strands = assign_dna_reducer_complement_from_bound_strands(design.strands, state, action);

      //     0                  16
      //     AACGTATCGCGATGCATCC
      // 0   [-------I: 3------>
      //     <---]<--I: 3------]
      //     TTGCATAGCGCTACGTAGG
      expect(all_strands[0].dna_sequence, "AACGTATCGCGATGCATCC");
      expect(all_strands[1].dna_sequence, "ACGTT");
      expect(all_strands[2].dna_sequence, "GGATGCATCGCGAT");
    });
    test('AssignDNAComplementFromBoundStrands__deletions__one_bound_strand', () {
      //     0               16
      //     AACGTACG TGCATCC
      // 0   [-------X------>
      //     <-------X------]

      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(16).add_deletion(0, 8).with_sequence('AACGTACGTGCATCC').commit();
      design = design.draw_strand(0, 16).move(-16).add_deletion(0, 8).commit();

      var action = actions.AssignDNAComplementFromBoundStrands([design.strands[1]]);
      var state = app_state_from_design(design);
      var all_strands = assign_dna_reducer_complement_from_bound_strands(design.strands, state, action);

      //     0               16
      //     AACGTACG TGCATCC
      // 0   [-------X------>
      //     <-------X------]
      //     TTGCATGC ACGTAGG
      expect(all_strands[0].dna_sequence, "AACGTACGTGCATCC");
      expect(all_strands[1].dna_sequence, "GGATGCACGTACGTT");
    });
    test('AssignDNAComplementFromBoundStrands__deletions__two_bound_strands', () {
      //     0               16
      // 0   [-------X------>
      //     <---]<--X------]
      //     TTGCATAG GCTACGT
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(16).add_deletion(0, 8).commit();
      design = design.draw_strand(0, 5).move(-5).with_sequence("ACGTT").commit();
      design = design.draw_strand(0, 16).move(-11).add_deletion(0, 8).with_sequence('TGCATCGGAT').commit();

      var action = actions.AssignDNAComplementFromBoundStrands([design.strands[0]]);
      var state = app_state_from_design(design);
      var all_strands = assign_dna_reducer_complement_from_bound_strands(design.strands, state, action);

      //     0               16
      //     AACGTATC CGATGCA
      // 0   [-------X------>
      //     <---]<--X------]
      //     TTGCATAG GCTACGT
      expect(all_strands[0].dna_sequence, "AACGTATCCGATGCA");
      expect(all_strands[1].dna_sequence, "ACGTT");
      expect(all_strands[2].dna_sequence, "TGCATCGGAT");
    });
  });
}
