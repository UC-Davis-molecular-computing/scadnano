// @dart=2.9

import 'dart:convert';

import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/change_loopout_ext_properties.dart';
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

main() {
  group('DomainNameBoundComplements_LinearDesigns', () {
    /* 0       8
       |-------|
         ABC        
    0  [------\
       <------/
         XYZ      
    */
    test('self_complementary_strand__both_domains_named__complementary', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(0)
          .move(-8)
          .with_domain_name("XYZ")
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 1);

      var names = [all_strands[0].domains[0].name, all_strands[0].domains[1].name];
      expect(
          names,
          anyOf([
            equals(["ABC", "ABC*"]),
            equals(["XYZ*", "XYZ"])
          ]));
    });

    /* 0       8
       |-------|
          ABC        
    0  [-------\
        <------/
          XYZ      
    */
    test('self_complementary_strand__both_domains_named__noncomplementary', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(9)
          .with_domain_name("ABC")
          .cross(0)
          .move(-8)
          .with_domain_name("XYZ")
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 1);

      var names = [all_strands[0].domains[0].name, all_strands[0].domains[1].name];
      expect(names, equals(["ABC", "XYZ"]));
    });

    /* 0       8
       |-------|
                  
    0  [-------\
       <-------/
                
    */
    test('self_complementary_strand__both_domains_not_named__complementary', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).cross(0).move(-8).commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 1);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[0].domains[1].name, null);
    });

    /* 0       8
       |-------|
         ABC        
    0  [------>
       <------]
          XYZ      
    */
    test('separate_strands__both_domains_named__complementary__both_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).with_domain_name("ABC").commit();
      design = design.draw_strand(0, 8).move(-8).with_domain_name("XYZ").commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      var names = [all_strands[0].domains[0].name, all_strands[1].domains[0].name];
      expect(
          names,
          anyOf([
            equals(["ABC", "ABC*"]),
            equals(["XYZ*", "XYZ"])
          ]));
    });

    /* 0       8
       |-------|-
         ABC        
    0  [------->
       <------]
          XYZ      
    */
    test('separate_strands__both_domains_named__noncomplementary__both_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(9).with_domain_name("ABC").commit();
      design = design.draw_strand(0, 8).move(-8).with_domain_name("XYZ").commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, 'ABC');
      expect(all_strands[1].domains[0].name, 'XYZ');
    });

    /* 0       8
       |-------|

    0  [------>
       <------]
    */
    test('separate_strands__both_domains_not_named__complementary__both_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 8).move(-8).commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[1].domains[0].name, null);
    });

    /* 0       8
       |-------|

    0  [------>
       <------]
    */
    test('separate_strands__both_domains_not_named__complementary__both_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 8).move(-8).commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[1].domains[0].name, null);
    });

    /////////////////////////
    // Only 1 domain Selected

    /* 0       8
       |-------|
          ABC        
    0  [------>
       <------]
          XYZ      
    */
    test('separate_strands__both_domains_named__complementary__one_domain_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).with_domain_name("ABC").commit();
      design = design.draw_strand(0, 8).move(-8).with_domain_name("XYZ").commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[0]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, "XYZ*");
      expect(all_strands[1].domains[0].name, "XYZ");
    });

    /* 0     8
       |-------|-
          ABC        
    0  [------->
       <------]
          XYZ      
    */
    test('separate_strands__both_domains_named__noncomplementary__one_domain_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(9).with_domain_name("ABC").commit();
      design = design.draw_strand(0, 8).move(-8).with_domain_name("XYZ").commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[0]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, "ABC");
      expect(all_strands[1].domains[0].name, "XYZ");
    });

    /* 0       8
       |-------|
                  
    0  [------>
       <------]
                
    */
    test('separate_strands__both_domains_not_named__complementary__one_domain_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 8).move(-8).commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[0]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[1].domains[0].name, null);
    });

    /* 0      8
       |-------|-
                  
    0  [------->
       <------]
                
    */
    test('separate_strands__both_domains_not_named__noncomplementary__one_domain_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(9).commit();
      design = design.draw_strand(0, 8).move(-8).commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[0]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[1].domains[0].name, null);
    });
  });

  group('DomainNameBoundComplements_CircularDesigns', () {
    /* 0       8       
       |-------|
         ABC
    0  /------\
       \------/
    */
    test('circular_strands__both_domains_not_named__complementary__both_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(0)
          .move(-8)
          .cross(0)
          .as_circular()
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands[0].domains[0].name, "ABC");
      expect(all_strands[0].domains[1].name, "ABC*");
    });

    /* 0       8       
       |-------|
    0  [------\
       <------/
          DEF
    */
    test('self_complementary_strands__both_domains_not_named__complementary__both_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).cross(0).move(-8).with_domain_name("DEF").commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands[0].domains[0].name, "DEF*");
      expect(all_strands[0].domains[1].name, "DEF");
    });

    /* 0       8       
       |-------|
         JKL
    0  /------\
       \---/
        JKL*
    */
    test('circular_strands__both_domains_named__non_complementary__both_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("JKL")
          .cross(0, 4)
          .move(-3)
          .with_domain_name("JKL*")
          .cross(0, 0)
          .as_circular()
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands[0].domains[0].name, "JKL");
      expect(all_strands[0].domains[1].name, "JKL*");
    });

    /* 0       8       
       |-------|
         ABC
    0  /------\
       \------/
         JKL*
    */
    test('circular_strands__both_domains_named__complementary__both_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(0)
          .move(-8)
          .with_domain_name("JKL*")
          .cross(0)
          .as_circular()
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains(design.all_domains);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      var names = [all_strands[0].domains[0].name, all_strands[0].domains[1].name];
      expect(
          names,
          anyOf([
            equals(["ABC", "ABC*"]),
            equals(["JKL", "JKL*"])
          ]));
    });

    /////////////////////////
    // Only 1 domain Selected

    /* 0       8       
       |-------|
         ABC
    0  /------\
       \------/
         JKL*
    */
    test('circular_strands__both_domains_named__complementary__ABC_domain_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(0)
          .move(-8)
          .with_domain_name("JKL*")
          .cross(0)
          .as_circular()
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[0]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands[0].domains[0].name, "JKL");
      expect(all_strands[0].domains[1].name, "JKL*");
    });

    /* 0       8       
       |-------|
         ABC
    0  /------\
       \------/
    */
    test('circular_strands__one_domain_named__complementary__ABC_domain_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(0)
          .move(-8)
          .cross(0)
          .as_circular()
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[0]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands[0].domains[0].name, "ABC");
      expect(all_strands[0].domains[1].name, null);
    });

    /* 0       8       
       |-------|
         ABC
    0  /------\
       \------/
    */
    test('circular_strands__one_domain_named__complementary__empty_domain_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(0)
          .move(-8)
          .cross(0)
          .as_circular()
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[1]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands[0].domains[0].name, "ABC");
      expect(all_strands[0].domains[1].name, "ABC*");
    });

    /* 0       8       
       |-------|
          JKL
    0  [------\
       <------/
          DEF
    */
    test('self_complementary_strands__both_domains_named__complementary__one_domains_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("JKL")
          .cross(0)
          .move(-8)
          .with_domain_name("DEF")
          .commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[1]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands[0].domains[0].name, "JKL");
      expect(all_strands[0].domains[1].name, "JKL*");
    });

    /* 0       8       
       |-------|
          JKL
    0  [------\
         <----/
    */
    test('self_complementary_strands__one_domains_named__non_complementary__one_domain_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).with_domain_name("JKL").cross(0).move(-6).commit();

      var action = actions.AssignDomainNameComplementFromBoundDomains([design.all_domains[1]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_domains_reducer(design.strands, state, action);

      expect(all_strands[0].domains[0].name, "JKL");
      expect(all_strands[0].domains[1].name, null);
    });
  });
}
