// @dart=2.9

import 'dart:convert';

import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/change_loopout_length.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/reducers/assign_domain_names_reducer.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';


//TODO: Add Unit Tests for different cases of strand names
main() {
  group('StrandName', () {
    /* 0       8   12
       |-------|---|
         ABC        
    0  [------>[--->

    */
    test('ligate__one_scaffold__both_named', () {
      var helices = [Helix(idx: 0, max_offset: 16, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("Scaf").as_scaffold().commit();
      design = design.draw_strand(0,8).move(4).with_name("NotScaf").commit();

            
      expect(design.strands[0].name, "Scaf");
      expect(design.strands[1].name, "NotScaf");
      expect(design.strands.length, 2);

      var action = actions.Ligate(dna_end: design.strands[1].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = ligate_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "Scaf");
      expect(all_strands.length, 1);
    });
    test('ligate__one_scaffold__one_named', () {
      var helices = [Helix(idx: 0, max_offset: 16, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("Scaf").as_scaffold().commit();
      design = design.draw_strand(0,8).move(4).commit();

            
      expect(design.strands[0].name, "Scaf");
      expect(design.strands[1].name, null);
      expect(design.strands.length, 2);

      var action = actions.Ligate(dna_end: design.strands[1].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = ligate_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "Scaf");
      expect(all_strands.length, 1);
    });

    
    test('ligate__both_named__both_staple__first_strand_clicked', () {
      var helices = [Helix(idx: 0, max_offset: 20, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").commit();
      design = design.draw_strand(0,8).move(8).with_name("XYZ").commit();

      var action = actions.Ligate(dna_end: design.strands[0].dnaend_3p);
      var state = app_state_from_design(design);
      var all_strands = ligate_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "ABC");
      expect(all_strands.length, 1);
    });
    test('ligate__both_named__both_staple__second_strand_clicked', () {
      var helices = [Helix(idx: 0, max_offset: 20, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").commit();
      design = design.draw_strand(0,8).move(8).with_name("XYZ").commit();

      var action = actions.Ligate(dna_end: design.strands[1].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = ligate_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "XYZ");
      expect(all_strands.length, 1);
    });
    test('crossover__both_named__both_staple__first_strand_clicked', () {
      var helices = [Helix(idx: 0, max_offset: 20, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").commit();
      design = design.draw_strand(0,8).move(-8).with_name("XYZ").commit();

      var action = 
          actions.JoinStrandsByCrossover(dna_end_first_click: design.strands[0].dnaend_3p, dna_end_second_click: design.strands[1].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = join_strands_by_crossover_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "ABC");
      expect(all_strands.length, 1);
    });
    test('crossover__both_named__both_staple__second_strand_clicked', () {
      var helices = [Helix(idx: 0, max_offset: 20, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").commit();
      design = design.draw_strand(0,8).move(-8).with_name("XYZ").commit();

      var action = 
          actions.JoinStrandsByCrossover(dna_end_first_click: design.strands[1].dnaend_3p, dna_end_second_click: design.strands[0].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = join_strands_by_crossover_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "XYZ");
      expect(all_strands.length, 1);
    });
    test('ligate__both_named__both_scaffold__first_strand_clicked', () {
      var helices = [Helix(idx: 0, max_offset: 20, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").as_scaffold().commit();
      design = design.draw_strand(0,8).move(8).with_name("XYZ").as_scaffold().commit();

      var action = actions.Ligate(dna_end: design.strands[0].dnaend_3p);
      var state = app_state_from_design(design);
      var all_strands = ligate_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "ABC");
      expect(all_strands.length, 1);
    });
    test('ligate__both_named__both_scaffold__second_strand_clicked', () {
      var helices = [Helix(idx: 0, max_offset: 20, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").as_scaffold().commit();
      design = design.draw_strand(0,8).move(8).with_name("XYZ").as_scaffold().commit();

      var action = actions.Ligate(dna_end: design.strands[1].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = ligate_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "XYZ");
      expect(all_strands.length, 1);
    });
    test('crossover__both_named__both_scaffold__first_strand_clicked', () {
      var helices = [Helix(idx: 0, max_offset: 20, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").as_scaffold().commit();
      design = design.draw_strand(0,8).move(-8).with_name("XYZ").as_scaffold().commit();

      var action = 
          actions.JoinStrandsByCrossover(dna_end_first_click: design.strands[0].dnaend_3p, dna_end_second_click: design.strands[1].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = join_strands_by_crossover_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "ABC");
      expect(all_strands.length, 1);
    });
    test('crossover__both_named__both_scaffold__second_strand_clicked', () {
      var helices = [Helix(idx: 0, max_offset: 20, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").as_scaffold().commit();
      design = design.draw_strand(0,8).move(-8).with_name("XYZ").as_scaffold().commit();

      var action = 
          actions.JoinStrandsByCrossover(dna_end_first_click: design.strands[1].dnaend_3p, dna_end_second_click: design.strands[0].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = join_strands_by_crossover_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "XYZ");
      expect(all_strands.length, 1);
    });

    test('ligate__two_strands__one_named', () {
      var helices = [Helix(idx: 0, max_offset: 16, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("ABC").commit();
      design = design.draw_strand(0,8).move(4).commit();

            
      expect(design.strands[0].name, "ABC");
      expect(design.strands[1].name, null);
      expect(design.strands.length, 2);

      var action = actions.Ligate(dna_end: design.strands[1].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = ligate_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "ABC");
      expect(all_strands.length, 1);
    });

     test('crossover__two_strands__one_named', () {
      var helices = [Helix(idx: 0, max_offset: 16, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0,0).move(8).with_name("XYZ").commit();
      design = design.draw_strand(0,8).move(-8).commit();

      expect(design.strands[0].name, "XYZ");
      expect(design.strands[1].name, null);
      expect(design.strands.length, 2);

      var action = 
          actions.JoinStrandsByCrossover(dna_end_first_click: design.strands[1].dnaend_3p, dna_end_second_click: design.strands[0].dnaend_5p);
      var state = app_state_from_design(design);
      var all_strands = join_strands_by_crossover_reducer(design.strands, state, action);
      
      expect(all_strands[0].name, "XYZ");
      expect(all_strands.length, 1);
    });

  });
}