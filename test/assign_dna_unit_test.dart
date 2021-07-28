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
    test('AssignDNA_test_FILE', () {
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
      // //     0               16
      // //     AACGTACGATGCATCC
      // // 0   [-------------->
      // //     <--------------]
      // //     GCTCCCCGACAACCTA
      expect(state.design.strands[0].dna_sequence, "AACGTACGATGCATCC");
      expect(state.design.strands[1].dna_sequence, "ATCCAACAGCCCCTCG");
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
    test('AssignDNAComplementFromBoundStrands__insertions', () {
      //TODO: Add insertion art to the ASCII art 
      //     0               16
      //     AACGTACGATGCATCC
      // 0   [--------------->
      //     <---------------]
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.strand(0, 0).move(16).add_insertion(0, 8, 3).with_sequence('AACGTATCGCGATGCATCC').commit();
      design = design.strand(0, 16).move(-16).add_insertion(0, 8, 3).commit();
      print(json_encode(design));

      var action = actions.AssignDNAComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_dna_reducer_complement_from_bound_strands(design.strands, state, action);

      //     0               16
      //     AACGTACGATGCATCC
      //             
      // 0   [-------------->
      //     <--------------]
      //     TTGCATGCTACGTAGG
      expect(all_strands[0].dna_sequence, "AACGTATCGCGATGCATCC");
      expect(all_strands[1].dna_sequence, "GGATGCATCGCGATACGTT");
    });
  });
  
}
