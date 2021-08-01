// @dart=2.9

import 'dart:convert';

import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/reducers/assign_or_remove_dna_reducer.dart';
import 'package:scadnano/src/reducers/change_loopout_length.dart';
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

      design = design.strand(0, 0).move(16).commit();
      design = design.strand(0, 16).move(-16).commit();
      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AACGTACGATGCATCC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            assign_complements: true,
            dna_sequence: dna_sequence,
            warn_on_change: true,
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
          assign_complements: false,
          dna_sequence: dna_sequence,
          warn_on_change: false,
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

      design = design.strand(0, 0).move(5).loopout(0, 5).move(-5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAACCTGCAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            assign_complements: true,
            dna_sequence: dna_sequence,
            warn_on_change: true,
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

      design = design.strand(0, 0).move(5).loopout(1, 5).move(-5).commit();
      design = design.strand(0, 5).move(-5).commit();
      design = design.strand(1, 0).move(5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.first;
      String dna_sequence = 'AAACCTGCACATTCG';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            assign_complements: true,
            dna_sequence: dna_sequence,
            warn_on_change: true,
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

      design = design.strand(0, 0).move(8).commit();
      design = design.strand(0, 6).move(-4).commit();

      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[0];
      Strand strand2 = design.strands[1];
      String dna_sequence1 = 'CAAAGTCG';
      String dna_sequence2 = 'ACTT';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            assign_complements: false,
            dna_sequence: dna_sequence2,
            warn_on_change: true,
          ));
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand1,
            assign_complements: false,
            dna_sequence: dna_sequence1,
            warn_on_change: true,
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

      design = design.strand(0, 0).move(5).commit();
      design = design.strand(0, 5).move(-5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.last;
      String dna_sequence = 'AAAAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            assign_complements: true,
            dna_sequence: dna_sequence,
            warn_on_change: true,
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

      design = design.strand(0, 0).move(5).commit();
      design = design.strand(0, 5).move(-5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.last;
      String dna_sequence = 'AA??C';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            assign_complements: true,
            dna_sequence: dna_sequence,
            warn_on_change: true,
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

      design = design.strand(0, 0).move(8).commit();
      design = design.strand(0, 4).move(-4).commit();
      design = design.strand(0, 8).move(-4).commit();

      AppState state = app_state_from_design(design);
      Strand strand1 = design.strands[1];
      Strand strand2 = design.strands.last;
      String dna_sequence1 = 'CAAA';
      String dna_sequence2 = 'AGGG';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand1,
            assign_complements: true,
            dna_sequence: dna_sequence1,
            warn_on_change: true,
          ));
      expect(state.design.strands[0].dna_sequence, 'TTTG????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            assign_complements: true,
            dna_sequence: dna_sequence2,
            warn_on_change: true,
          ));
      expect(state.design.strands[0].dna_sequence, 'TTTGCCCT');
    });

    test('AssignDNA__adapter_assigned_from_scaffold_and_tiles', () {
      /*
          0    5    10    
            TTTCCATT 
      0     [------\
                    |
          GAAATGAAAATG   
          <----\<---+]  
                |   |
                |   |
          AATTTG|TGCCGG  
      1   [----/[---+>    
            GGCACAAA|
            <------/
      */

      var helices = [
        Helix(idx: 0, max_offset: 15, grid: Grid.square),
        Helix(idx: 1, max_offset: 15, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.strand(1, 0).move(6).cross(0).move(-6).commit();
      design = design.strand(0, 2).move(8).cross(1).move(-8).commit();
      design = design.strand(0, 12).move(-6).commit();
      design = design.strand(1, 6).move(6).commit();

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
            assign_complements: true,
            dna_sequence: dna_sequence1,
            warn_on_change: true,
          ));
      expect(state.design.strands[1].dna_sequence, '????CATT????????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            assign_complements: true,
            dna_sequence: dna_sequence2,
            warn_on_change: true,
          ));
      expect(state.design.strands[1].dna_sequence, '????CATTGGCA????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand3,
            assign_complements: true,
            dna_sequence: dna_sequence3,
            warn_on_change: true,
          ));
      expect(state.design.strands[1].dna_sequence, 'TTTCCATTGGCACAAA');
    });

    test('AssignDNA__adapter_assigned_from_scaffold_and_tiles_with_deletions', () {
      /*
          0    5    10    
            T TCCA T 
      0     [x----x\
                    |
          GA ATGAAA TG   
          <-x--\<--x+]  
                |   |
                |   |
          AATTTG|TG CGG  
      1   [----/[--x+>    
            G CACAAA|
            <x-----/
      */

      var helices = [
        Helix(idx: 0, max_offset: 15, grid: Grid.square),
        Helix(idx: 1, max_offset: 15, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.strand(1, 0).move(6).cross(0).move(-6).add_deletion(0, 3).commit();
      design = design
          .strand(0, 2)
          .move(8)
          .add_deletion(0, 3)
          .add_deletion(0, 8)
          .cross(1)
          .move(-8)
          .add_deletion(1, 8)
          .commit();
      design = design.strand(0, 12).move(-6).add_deletion(0, 8).commit();
      design = design.strand(1, 6).move(6).add_deletion(1, 8).commit();

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
            assign_complements: true,
            dna_sequence: dna_sequence1,
            warn_on_change: true,
          ));
      expect(state.design.strands[1].dna_sequence, '???CAT???????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            assign_complements: true,
            dna_sequence: dna_sequence2,
            warn_on_change: true,
          ));
      expect(state.design.strands[1].dna_sequence, '???CATGCA????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand3,
            assign_complements: true,
            dna_sequence: dna_sequence3,
            warn_on_change: true,
          ));
      expect(state.design.strands[1].dna_sequence, 'TTCCATGCACAAA');
    });

    test('AssignDNA__adapter_assigned_from_scaffold_and_tiles_with_insertions', () {
      /*
          0    5    10    
            T TCCA T 
      0     [x----x\
                    |
          GA ATGAAA TG   
          <-x--\<--x+]  
                |   |
                |   |
          AATTTG|TG CGG  
      1   [----/[--x+>    
            G CACAAA|
            <x-----/
      */

      var helices = [
        Helix(idx: 0, max_offset: 15, grid: Grid.square),
        Helix(idx: 1, max_offset: 15, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.strand(1, 0).move(6).cross(0).move(-6).commit();
      design = design
          .strand(0, 2)
          .move(8)
          .add_insertion(0, 8, 1)
          .cross(1)
          .move(-8)
          .add_insertion(1, 8, 1)
          .commit();
      design = design.strand(0, 12).move(-6).add_insertion(0, 8, 1).commit();
      design = design.strand(1, 6).move(6).add_insertion(1, 8, 1).commit();

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
            assign_complements: true,
            dna_sequence: dna_sequence1,
            warn_on_change: true,
          ));
      expect(state.design.strands[1].dna_sequence, '????CATTT?????????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand2,
            assign_complements: true,
            dna_sequence: dna_sequence2,
            warn_on_change: true,
          ));
      expect(state.design.strands[1].dna_sequence, '????CATTTGGGCA????');
      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand3,
            assign_complements: true,
            dna_sequence: dna_sequence3,
            warn_on_change: true,
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

      design = design.strand(0, 0).move(10).commit();
      design = design.strand(0, 5).move(-5).commit();

      AppState state = app_state_from_design(design);
      Strand strand = design.strands.last;
      String dna_sequence = 'AAAAC';

      state = app_state_reducer(
          state,
          AssignDNA(
            strand: strand,
            assign_complements: true,
            dna_sequence: dna_sequence,
            warn_on_change: true,
          ));
      expect(state.design.strands.first.dna_sequence, 'GTTTT?????');
    });

    test('RemoveDNA (see issue #109)', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.strand(0, 0).move(16).with_sequence("AACGTACGATGCATCC").commit();
      design = design.strand(0, 16).move(-16).with_sequence("GGATGCATCGTACGTT").commit();
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

      design = design.strand(0, 0).move(16).with_sequence('AACGTACGATGCATCC').commit();
      design = design.strand(0, 16).move(-16).commit();

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
          design.strand(0, 0).move(16).add_insertion(0, 8, 3).with_sequence('AACGTATCGCGATGCATCC').commit();
      design = design.strand(0, 16).move(-16).add_insertion(0, 8, 3).commit();

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

      design = design.strand(0, 0).move(16).add_insertion(0, 8, 3).commit();
      design = design.strand(0, 5).move(-5).with_sequence("ACGTT").commit();
      design = design.strand(0, 16).move(-11).add_insertion(0, 8, 3).with_sequence('GGATGCATCGCGAT').commit();

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

      design = design.strand(0, 0).move(16).add_deletion(0, 8).with_sequence('AACGTACGTGCATCC').commit();
      design = design.strand(0, 16).move(-16).add_deletion(0, 8).commit();

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

      design = design.strand(0, 0).move(16).add_deletion(0, 8).commit();
      design = design.strand(0, 5).move(-5).with_sequence("ACGTT").commit();
      design = design.strand(0, 16).move(-11).add_deletion(0, 8).with_sequence('TGCATCGGAT').commit();

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
