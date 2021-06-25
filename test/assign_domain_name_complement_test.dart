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

      design = design.strand(1, 16).move(-16).cross(0).move(32).loopout(1, 3).move(-16).with_domain_name("DEF*").as_scaffold().commit();
      design = design.strand(1, 0).move(16).with_domain_name("ABC").cross(0).move(-16).commit();
      design = design.strand(0, 32).move(-16).with_domain_name("GHI").cross(1).move(16).commit();
      design = design.strand(0, 40).move(10).commit();
      design = design.strand(0, 50).move(-10).with_domain_name("JKL").commit();
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
          assign_domain_name_reducer_complement_from_bound_strands(
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
          assign_domain_name_reducer_complement_from_bound_strands(
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
          assign_domain_name_reducer_complement_from_bound_strands(
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
          assign_domain_name_reducer_complement_from_bound_strands(
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

    /* 0       8       16      24     
       |-------|-------|-------|
         ABC
    0  /------\[------\/------>
       \------/<------/\------]
                 DEF     GHI
    */
    setUp(() {
      helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      design = Design(helices: helices, grid: Grid.square);

      design = design.strand(0, 0).move(8).with_domain_name("ABC").cross(0).move(-8).cross(0).as_circular().commit();
      design = design.strand(0, 8).move(8).cross(0).move(-8).with_domain_name("DEF").commit();
      design = design.strand(0, 24).move(-8).with_domain_name("GHI").cross(0).move(8).commit();
      
    });

    /* 0       8       16      24     
       |-------|-------|-------|
         ABC     DEF*    GHI*
    0  /------\[------\/------>
       \------/<------/\------]
         ABC*     DEF     GHI
    */
    test('assign_domain_name_complement_on_all_strands_with_circular', () {

      var action = actions.AssignDomainNameComplementFromBoundStrands(design.strands);
      var state = app_state_from_design(design);
      var all_strands = assign_domain_name_reducer_complement_from_bound_strands(design.strands, state, action);

      expect(all_strands[0].substrands[0].name, "ABC");
      expect(all_strands[0].substrands[1].name, "ABC*");

      expect(all_strands[1].substrands[0].name, "DEF*");
      expect(all_strands[1].substrands[1].name, "DEF");

      expect(all_strands[2].substrands[0].name, "GHI");
      expect(all_strands[2].substrands[1].name, "GHI*");
    });
  });
}