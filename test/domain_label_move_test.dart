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
import 'package:scadnano/src/state/app_state.dart';
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
    test('self_complementary_strand__no_loopouts', () {
      /* 0       8
       |-------|
         ABC        
    0  [------\
              |
              |
              |
    1         |
       <------/
         XYZ      
    */
      var helices = [
        Helix(idx: 0, max_offset: 100, grid: Grid.square),
        Helix(idx: 1, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(1)
          .move(-8)
          .with_domain_name("XYZ")
          .commit();

      AppState state = app_state_from_design(design);
      StrandsMove strandsMove = null;
      //Select Strands
      BuiltList<Selectable> selectables = [design.strands[0]].toBuiltList();
      int offset = 4;
      int helix_idx = 0;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //Adjust Address
      offset = 4;
      helix_idx = 0;
      forward = false;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));
      strandsMove = state.ui_state.strands_move;

      //Stop Moving
      state = app_state_reducer(state, StrandsMoveStop());

      //Commit the Move
      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strandsMove, autopaste: false));
      /* 0       8
       |-------| 
       
    0
       <------\
         ABC  |
         XYZ  |
    1  [------/

 
    */
      expect(state.design.all_domains[0].name, "XYZ");
      expect(state.design.all_domains[0].helix, 1);

      expect(state.design.all_domains[1].name, "ABC");
      expect(state.design.all_domains[1].helix, 0);
    });

    test('self_complementary_strand__with_loopouts', () {
      /* 0       8
       |-------|
         ABC        
    0  [------\
                )
                 )
                 )
    1           )
       <------/
         XYZ      
    */
      var helices = [
        Helix(idx: 0, max_offset: 100, grid: Grid.square),
        Helix(idx: 1, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .loopout(1, 2)
          .move(-8)
          .with_domain_name("XYZ")
          .commit();

      AppState state = app_state_from_design(design);
      StrandsMove strandsMove = null;
      //Select Strands
      BuiltList<Selectable> selectables = [design.strands[0]].toBuiltList();
      int offset = 4;
      int helix_idx = 0;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //Adjust Address
      offset = 4;
      helix_idx = 0;
      forward = false;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));
      strandsMove = state.ui_state.strands_move;

      //Stop Moving
      state = app_state_reducer(state, StrandsMoveStop());

      //Commit the Move
      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strandsMove, autopaste: false));
      /* 0       8
       |-------|
       
    0  
       <------\
          ABC   )
          XYZ   )
    1  [------/

 
    */
      expect(state.design.all_domains[0].name, "XYZ");
      expect(state.design.all_domains[0].helix, 1);

      expect(state.design.all_domains[1].name, "ABC");
      expect(state.design.all_domains[1].helix, 0);
    });
    test('circular_strand__no_loopouts', () {
      /* 0       8
       |-------|
         ABC        
    0  /------\
       |      |
       |      |
       |      |
    1  |      |
       \------/
         XYZ      
    */
      var helices = [
        Helix(idx: 0, max_offset: 100, grid: Grid.square),
        Helix(idx: 1, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(1)
          .move(-8)
          .with_domain_name("XYZ")
          .as_circular()
          .commit();
      AppState state = app_state_from_design(design);
      StrandsMove strandsMove = null;
      //Select Strands
      BuiltList<Selectable> selectables = [design.strands[0]].toBuiltList();
      int offset = 4;
      int helix_idx = 0;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //Adjust Address
      offset = 4;
      helix_idx = 0;
      forward = false;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));
      strandsMove = state.ui_state.strands_move;

      //Stop Moving
      state = app_state_reducer(state, StrandsMoveStop());

      //Commit the Move
      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strandsMove, autopaste: false));
      /* 0       8
       |-------|

    0   
       /------\
       | ABC  |
       | XYZ  |
    1  \------/
    
    
    */
      expect(state.design.all_domains[0].name, "XYZ");
      expect(state.design.all_domains[0].helix, 1);

      expect(state.design.all_domains[1].name, "ABC");
      expect(state.design.all_domains[1].helix, 0);
    });

    test('circular_strand__with_loopouts', () {
      /* 0       8
       |-------|
         ABC        
    0  /------\
       |        )
       |         )
       |         )
    1  |        )
       \------/
         XYZ      
    */
      var helices = [
        Helix(idx: 0, max_offset: 100, grid: Grid.square),
        Helix(idx: 1, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .loopout(1, 2)
          .move(-8)
          .with_domain_name("XYZ")
          .as_circular()
          .commit();
      AppState state = app_state_from_design(design);
      StrandsMove strandsMove = null;
      //Select Strands
      BuiltList<Selectable> selectables = [design.strands[0]].toBuiltList();
      int offset = 4;
      int helix_idx = 0;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //Adjust Address
      offset = 4;
      helix_idx = 0;
      forward = false;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));
      strandsMove = state.ui_state.strands_move;

      //Stop Moving
      state = app_state_reducer(state, StrandsMoveStop());

      //Commit the Move
      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strandsMove, autopaste: false));
      /* 0       8
       |-------|

    0     
       /------\
       | ABC    )
       | XYZ    )
       \------/
    1

    */
      expect(state.design.all_domains[0].name, "XYZ");
      expect(state.design.all_domains[0].helix, 1);

      expect(state.design.all_domains[1].name, "ABC");
      expect(state.design.all_domains[1].helix, 0);
    });

    test('self_complementary_strand__no_loopouts__move_right', () {
      /* 0       8
       |-------|
         ABC        
    0  [------\
    1  <------/
         XYZ      
    */
      var helices = [
        Helix(idx: 0, max_offset: 100, grid: Grid.square),
        Helix(idx: 1, max_offset: 100, grid: Grid.square)
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name("ABC")
          .cross(1)
          .move(-8)
          .with_domain_name("XYZ")
          .commit();

      AppState state = app_state_from_design(design);
      StrandsMove strandsMove = null;
      //Select Strands
      BuiltList<Selectable> selectables = [design.strands[0]].toBuiltList();
      int offset = 4;
      int helix_idx = 0;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //Adjust Address
      offset = 6;
      helix_idx = 0;
      forward = true;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));
      strandsMove = state.ui_state.strands_move;

      //Stop Moving
      state = app_state_reducer(state, StrandsMoveStop());

      //Commit the Move
      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strandsMove, autopaste: false));
     /* 0       8 
       |-------|--|
           ABC        
    0    [------\
    1    <------/
           XYZ      
    */
      expect(state.design.all_domains[0].name, "ABC");
      expect(state.design.all_domains[0].helix, 0);

      expect(state.design.all_domains[1].name, "XYZ");
      expect(state.design.all_domains[1].helix, 1);
    });
  });
}
