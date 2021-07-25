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

main() {
  group('DomainLabelMove', () {
    /* 0       8
       |-------|
         ABC        
    0  [------\
    1  <------/
         XYZ      
    */
    test('self_complementary_strand__no_insertions', () {
      var helices = [Helix(idx: 0, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .strand(0, 0)
          .move(8)
          .with_domain_name("A")
          .cross(1)
          .move(-8)
          .with_domain_name("B")
          .commit();
      

      var action = actions.StrandsMoveCommit(design);
      var state = app_state_from_design(design);
      var all_strands =
          strands_move_commit_reducer(design.strands, state, action);
      expect(all_strands.length, 1);

      var names = [all_strands[0].domains[0].name, all_strands[0].domains[1].name];
      expect(
          names,
          anyOf([
            equals(["ABC", "ABC*"]),
            equals(["XYZ*", "XYZ"])
          ]));
    });


  });
}

