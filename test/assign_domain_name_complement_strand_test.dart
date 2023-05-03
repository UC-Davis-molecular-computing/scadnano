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
  group('DomainNameBoundComplements_LinearStrands', () {
    List<Helix> helices;
    Design design;

    /* 0              16               32      40       50  
       |---------------|---------------|-------|---------|

    0  /------------------------------\        [-------->
      |<--------------++--------------])       <--------]
      |               ||       GHI      )          JKL
      |               ||                )
      |       ABC     ||                )
    1 |[--------------++-------------->)
       \--------------]<--------------/  
                              DEF*
    */
    setUp(() {
      int num_helices = 2;
      helices = [
        for (int i = 0; i < num_helices; i++)
          Helix(idx: i, max_offset: 100, grid: Grid.square)
      ];
      design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(1, 16).move(-16).cross(0).move(32).loopout(1, 3).move(-16).with_domain_name("DEF*").as_scaffold().commit();
      design = design.draw_strand(1, 0).move(16).with_domain_name("ABC").cross(0).move(-16).commit();
      design = design.draw_strand(0, 32).move(-16).with_domain_name("GHI").cross(1).move(16).commit();
      design = design.draw_strand(0, 40).move(10).commit();
      design = design.draw_strand(0, 50).move(-10).with_domain_name("JKL").commit();
    });

    /* 0              16               32      40       50  
       |---------------|---------------|-------|---------|

                                                  JKL*
    0  /------------------------------\        [-------->
      |<--------------++--------------])       <--------]
      |               ||      GHI       )         JKL
      |               ||                )
      |      ABC      ||      DEF       )
    1 |[--------------++-------------->)
       \--------------]<--------------/  
             ABC*            DEF*
    */

    test('assign_domain_name_complement_on_all_strands', () {
      var action =
          actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_strands_reducer(
              design.strands, state, action);

      expect(all_strands.length, 5);

      expect(all_strands[0].substrands[0].name, "ABC*");
      expect(all_strands[0].substrands[1].name, null);
      expect(all_strands[0].substrands[2].name, null);
      expect(all_strands[0].substrands[3].name, "DEF*");

      expect(all_strands[1].substrands[0].name, "ABC");
      expect(all_strands[1].substrands[1].name, null);

      expect(all_strands[2].substrands[0].name, "GHI");
      expect(all_strands[2].substrands[1].name, "DEF");

      expect(all_strands[3].substrands[0].name, "JKL*");

      expect(all_strands[4].substrands[0].name, "JKL");
    });

    /* 0              16               32      40       50  
       |---------------|---------------|-------|---------|
                                                  JKL*
    0  /------------------------------\        [-------->
      |<--------------++--------------])       <--------]
      |               ||       GHI      )          JKL
      |               ||                )
      |       ABC     ||                )
    1 |[--------------++-------------->)
       \--------------]<--------------/  
                              DEF*
    */

    test('assign_domain_name_complement_on_complement_of_JKL_strand', () {
      var action = actions.AssignDomainNameComplementFromBoundStrands(
          [design.strands[3]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_strands_reducer(
              design.strands, state, action);

      expect(all_strands.length, 5);

      expect(all_strands[0].substrands[0].name, null);
      expect(all_strands[0].substrands[1].name, null);
      expect(all_strands[0].substrands[2].name, null);
      expect(all_strands[0].substrands[3].name, "DEF*");

      expect(all_strands[1].substrands[0].name, "ABC");
      expect(all_strands[1].substrands[1].name, null);

      expect(all_strands[2].substrands[0].name, "GHI");
      expect(all_strands[2].substrands[1].name, null);

      expect(all_strands[3].substrands[0].name, "JKL*");

      expect(all_strands[4].substrands[0].name, "JKL");
    });

    /* 0              16               32      40       50  
       |---------------|---------------|-------|---------|
                                                  JKL*
    0  /------------------------------\        [-------->
      |<--------------++--------------])       <--------]
      |               ||       GHI      )          JKL
      |               ||                )
      |       ABC     ||                )
    1 |[--------------++-------------->)
       \--------------]<--------------/  
              ABC*            DEF*
    */

    test('assign_domain_name_complement_on_complement_of_ABC_and_JKL', () {
      // assign complements for ABC and JKL
      var action = actions.AssignDomainNameComplementFromBoundStrands(
          [design.strands[0], design.strands[3]]);
      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_strands_reducer(
              design.strands, state, action);

      expect(all_strands.length, 5);

      expect(all_strands[0].substrands[0].name, "ABC*");
      expect(all_strands[0].substrands[1].name, null);
      expect(all_strands[0].substrands[2].name, null);
      expect(all_strands[0].substrands[3].name, "DEF*");

      expect(all_strands[1].substrands[0].name, "ABC");
      expect(all_strands[1].substrands[1].name, null);

      expect(all_strands[2].substrands[0].name, "GHI");
      expect(all_strands[2].substrands[1].name, null);

      expect(all_strands[3].substrands[0].name, "JKL*");

      expect(all_strands[4].substrands[0].name, "JKL");
    });

    /* 0              16               32      40       50  
       |---------------|---------------|-------|---------|

    0  /------------------------------\        [-------->
      |<--------------++--------------])       <--------]
      |               ||       GHI      )          JKL
      |               ||                )
      |       ABC     ||      DEF       )
    1 |[--------------++-------------->)
       \--------------]<--------------/  
                              DEF*
    */
    test('assign_domain_name_complement_on_complement_of_ABC_and_DEF', () {
      // assign complements for ABC and JKL
      var action = actions.AssignDomainNameComplementFromBoundStrands(
          [design.strands[0], design.strands[2]]);

      var state = app_state_from_design(design);
      var all_strands =
          assign_domain_name_complement_from_bound_strands_reducer(
              design.strands, state, action);

      expect(all_strands.length, 5);

      expect(all_strands[0].substrands[0].name, "ABC*");
      expect(all_strands[0].substrands[1].name, null);
      expect(all_strands[0].substrands[2].name, null);
      expect(all_strands[0].substrands[3].name, "DEF*");

      expect(all_strands[1].substrands[0].name, "ABC");
      expect(all_strands[1].substrands[1].name, null);

      expect(all_strands[2].substrands[0].name, "GHI");
      expect(all_strands[2].substrands[1].name, "DEF");

      expect(all_strands[3].substrands[0].name, null);

      expect(all_strands[4].substrands[0].name, "JKL");
    });
  });

  group('DomainNameBoundComplements_CircularStrands', () {
    List<Helix> helices;
    Design design;

    /* 0       8       16      24      32
       |-------|-------|-------|-------|
         ABC
    0  /------\[------\/------> /------\
       \------/<------/\------] \---/
                 DEF     GHI     JKL*
    */
    setUp(() {
      helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(8).with_domain_name("ABC").cross(0).move(-8).cross(0).as_circular().commit();
      design = design.draw_strand(0, 8).move(8).cross(0).move(-8).with_domain_name("DEF").commit();
      design = design.draw_strand(0, 24).move(-8).with_domain_name("GHI").cross(0).move(8).commit();
      design = design.draw_strand(0, 25).move(8).cross(0, 29).move(-3).with_domain_name("JKL*").cross(0,25).as_circular().commit();
    });

    /* 0       8       16      24      32
       |-------|-------|-------|-------|
         ABC     DEF*    GHI*
    0  /------\[------\/------> /------\
       \------/<------/\------] \---/
         ABC*     DEF     GHI    JKL*
    */
    test('assign_domain_name_complement_on_all_strands_circular', () {

      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands[0].substrands[0].name, "ABC");
      expect(all_strands[0].substrands[1].name, "ABC*");

      expect(all_strands[1].substrands[0].name, "DEF*");
      expect(all_strands[1].substrands[1].name, "DEF");

      expect(all_strands[2].substrands[0].name, "GHI");
      expect(all_strands[2].substrands[1].name, "GHI*");

      expect(all_strands[3].substrands[0].name, null);
      expect(all_strands[3].substrands[1].name, "JKL*");
    });

    /* 0       8       16      24      32
       |-------|-------|-------|-------|
         ABC        
    0  /------\[------\/------> /------\
       \------/<------/\------] \---/
         ABC*     DEF     GHI    JKL*
    */
    test('assign_domain_name_complement_on_ABC_circular', () {

      var action = actions.AssignDomainNameComplementFromBoundStrands([design.strands[0]]);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands[0].substrands[0].name, "ABC");
      expect(all_strands[0].substrands[1].name, "ABC*");

      expect(all_strands[1].substrands[0].name, null);
      expect(all_strands[1].substrands[1].name, "DEF");

      expect(all_strands[2].substrands[0].name, "GHI");
      expect(all_strands[2].substrands[1].name, null);

      expect(all_strands[3].substrands[0].name, null);
      expect(all_strands[3].substrands[1].name, "JKL*");
    });

    test('assign_domain_name_complement_on_ABC_and_GHI_circular', () {

      var action = actions.AssignDomainNameComplementFromBoundStrands([design.strands[0], design.strands[2]]);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands[0].substrands[0].name, "ABC");
      expect(all_strands[0].substrands[1].name, "ABC*");

      expect(all_strands[1].substrands[0].name, null);
      expect(all_strands[1].substrands[1].name, "DEF");

      expect(all_strands[2].substrands[0].name, "GHI");
      expect(all_strands[2].substrands[1].name, "GHI*");

      expect(all_strands[3].substrands[0].name, null);
      expect(all_strands[3].substrands[1].name, "JKL*");
    });
  });
  
  group('DomainNameBoundComplements_DifferentCombinationOfExistingDomainNames', () {
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
      
      design = design.draw_strand(0, 0).move(8).with_domain_name("ABC").cross(0).move(-8).with_domain_name("XYZ").commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands.length, 1);

      var names = [all_strands[0].domains[0].name, all_strands[0].domains[1].name];
      expect(names, anyOf([equals(["ABC", "ABC*"]), equals(["XYZ*", "XYZ"])]));
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
      
      design = design.draw_strand(0, 0).move(9).with_domain_name("ABC").cross(0).move(-8).with_domain_name("XYZ").commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

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
      
      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

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
    test('separate_strands__both_domains_named__complementary__both_strands_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(8).with_domain_name("ABC").commit();
      design = design.draw_strand(0, 8).move(-8).with_domain_name("XYZ").commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      var names = [all_strands[0].domains[0].name, all_strands[1].domains[0].name];
      expect(names, anyOf([equals(["ABC", "ABC*"]), equals(["XYZ*", "XYZ"])]));
    });

    /* 0       8
       |-------|-
         ABC        
    0  [------->
       <------]
          XYZ      
    */
    test('separate_strands__both_domains_named__noncomplementary__both_strands_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(9).with_domain_name("ABC").commit();
      design = design.draw_strand(0, 8).move(-8).with_domain_name("XYZ").commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, 'ABC');
      expect(all_strands[1].domains[0].name, 'XYZ');
    });

    /* 0       8
       |-------|

    0  [------>
       <------]
    */
    test('separate_strands__both_domains_not_named__complementary__both_strands_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 8).move(-8).commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[1].domains[0].name, null);
    });

    /* 0       8
       |-------|

    0  [------>
       <------]
    */
    test('separate_strands__both_domains_not_named__complementary__both_strands_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 8).move(-8).commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[1].domains[0].name, null);
    });

    /////////////////////////
    // Only 1 strand Selected

      /* 0       8
       |-------|
          ABC        
    0  [------>
       <------]
          XYZ      
    */
    test('separate_strands__both_domains_named__complementary__one_strand_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(8).with_domain_name("ABC").commit();
      design = design.draw_strand(0, 8).move(-8).with_domain_name("XYZ").commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands([design.strands[0]]);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

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
    test('separate_strands__both_domains_named__noncomplementary__one_strand_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(9).with_domain_name("ABC").commit();
      design = design.draw_strand(0, 8).move(-8).with_domain_name("XYZ").commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands([design.strands[0]]);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, "ABC");
      expect(all_strands[1].domains[0].name, "XYZ");
    });

      /* 0       8
       |-------|
                  
    0  [------>
       <------]
                
    */
    test('separate_strands__both_domains_not_named__complementary__one_strand_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(8).commit();
      design = design.draw_strand(0, 8).move(-8).commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands([design.strands[0]]);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[1].domains[0].name, null);
    });

      /* 0      8
       |-------|-
                  
    0  [------->
       <------]
                
    */
    test('separate_strands__both_domains_not_named__noncomplementary__one_strand_selected', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(9).commit();
      design = design.draw_strand(0, 8).move(-8).commit();
      
      var action = actions.AssignDomainNameComplementFromBoundStrands([design.strands[0]]);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_complement_from_bound_strands_reducer(design.strands, state, action);

      expect(all_strands.length, 2);

      expect(all_strands[0].domains[0].name, null);
      expect(all_strands[1].domains[0].name, null);
    });
  });

  group('strands_overlapping_unit_test', () {
    List<Helix> helices;
    Design design;
    /* 0              16               32      40       50  
       |---------------|---------------|-------|---------|

    0  /------------------------------\        [--------\
      |<--------------++--------------])       <--------/
      |               ||       GHI      )          JKL
      |               ||                )
      |       ABC     ||                )
    1 |[--------------++-------------->)
       \--------------]<--------------/  
                              DEF*
    */
    test('strands_overlapping__multiple_not_perfect_overlap__linear_and_self_complementary', () {
      int num_helices = 2;
      helices = [
        for (int i = 0; i < num_helices; i++)
          Helix(idx: i, max_offset: 100, grid: Grid.square)
      ];
      design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(1, 16).move(-16).cross(0).move(32).loopout(1, 3).move(-16).with_domain_name("DEF*").as_scaffold().commit();
      design = design.draw_strand(1, 0).move(16).with_domain_name("ABC").cross(0).move(-16).commit();
      design = design.draw_strand(0, 32).move(-16).with_domain_name("GHI").cross(1).move(16).commit();
      design = design.draw_strand(0, 40).move(10).cross(0).move(-10).with_domain_name("JKL").as_circular().commit();

      var all_overlapping_strands = design.strands_overlapping;
      
      expect(all_overlapping_strands[design.strands[0]].length, 2);
      expect(all_overlapping_strands[design.strands[0]], allOf([contains(design.strands[1]), contains(design.strands[2])]));


      expect(all_overlapping_strands[design.strands[1]].length, 1);
      expect(all_overlapping_strands[design.strands[1]], [design.strands[0]]);

      expect(all_overlapping_strands[design.strands[2]].length, 1);
      expect(all_overlapping_strands[design.strands[2]], [design.strands[0]]);  

      expect(all_overlapping_strands[design.strands[3]].length, 1);
      expect(all_overlapping_strands[design.strands[3]], [design.strands[3]]);  
    });

    /* 0       8
       |-------|
    0  [-------->
       <------]
    */
    test('strands_overlapping__not_perfect_overlap__linear', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(9).commit();
      design = design.draw_strand(0, 8).move(-8).commit();

      var all_overlapping_strands = design.strands_overlapping;
      
      expect(all_overlapping_strands[design.strands[0]].length, 1);
      expect(all_overlapping_strands[design.strands[0]], allOf([contains(design.strands[1])]));

      expect(all_overlapping_strands[design.strands[1]].length, 1);
      expect(all_overlapping_strands[design.strands[1]], allOf([contains(design.strands[0])]));
    });

    /* 0       8
       |-------|
    0  /-------\
       \-----/
    */
    test('strands_overlapping__not_perfect_overlap__circular', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(8).cross(0, 6).move(-6).as_circular().commit();

      var all_overlapping_strands = design.strands_overlapping;
      
      expect(all_overlapping_strands[design.strands[0]].length, 1);
      expect(all_overlapping_strands[design.strands[0]], allOf([contains(design.strands[0])]));
    });

    /* 0       8
       |-------|
    0  /------/
       \-/<---]
    */
    test('strands_overlapping__multiple_not_perfect_overlap__circular', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);
      
      design = design.draw_strand(0, 0).move(8).cross(0, 3).move(-3).as_circular().commit();
      design = design.draw_strand(0,8).move(-5).commit();

      var all_overlapping_strands = design.strands_overlapping;
      
      expect(all_overlapping_strands[design.strands[0]].length, 2);
      expect(all_overlapping_strands[design.strands[0]], allOf([contains(design.strands[0]), contains(design.strands[1])]));

      expect(all_overlapping_strands[design.strands[1]].length, 1);
      expect(all_overlapping_strands[design.strands[1]], allOf([contains(design.strands[0])]));  
    });
  });

}
