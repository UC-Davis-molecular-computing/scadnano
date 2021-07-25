// @dart=2.9

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/reducers/change_loopout_length.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/reducers/assign_domain_names_reducer.dart';
import 'package:scadnano/src/reducers/strands_reducer.dart';
import 'package:scadnano/src/state/address.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/strands_move.dart';
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

      design =
          design.strand(0, 0).move(8).with_domain_name("A").cross(1).move(-8).with_domain_name("B").commit();
      var state = app_state_from_design(design);
      print(state.design.default_group().helices_view_order);
      var new_strand = move_strand(strand: design.strands[0], original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse, current_group: state.design.groups["default_group"], delta_view_order: state.design.default_group().helices_view_order[0], delta_offset: 10, delta_forward: true);
      
      print(design.strands[0]);
      print(new_strand);
      // var state = app_state_from_design(design);
      // StrandsMove strands_move = StrandsMove(
      //   strands_moving:  design.strands,
      //   all_strands: design.strands,
      //   original_address: Address(forward: true, helix_idx: 0, offset: 4),
      //   helices: state.design.helices,
      //   groups: state.design.groups,
      //   original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
      //   copy: false,
      // ).rebuild((b) => b..current_address = Address(forward: false, helix_idx: 0, offset: 8).toBuilder());
      // state = app_state_reducer(state, StrandsMoveCommit(strands_move: strands_move, autopaste: false));
    });
  });
}
