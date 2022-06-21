// @dart=2.9

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';
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
  
  group('StrandReflectInvalid', () {
    List<Helix> helices;
    Design orig_design;

    setUp(() {
      /*

      * initial design

        0    5    10
        |----|----|
        
      0 [---------\
                  |
                  |
                  |
      1           |
             <----/   

      */

      helices = [
        Helix(idx: 0, min_offset: 0, max_offset: 10, grid: Grid.square),
        Helix(idx: 1, min_offset: 5, max_offset: 10, grid: Grid.square)
      ];
      orig_design = Design(helices: helices, grid: Grid.square);

      orig_design = orig_design
          .strand(0, 0)
          .move(10)
          .cross(1)
          .move(-5)
          .commit();
    });

    test('strand_reflect_horizontally_no_polarity_reverse', () {

      Store<AppState> store = store_from_design(orig_design, initialize_app_instance: false);
      store.dispatch(
          actions.StrandsReflect(
        strands: orig_design.strands, horizontal: true, reverse_polarity: false));
        
      /* 

      * hypothetical reflect --- but notice domain on helix 1 is out of bounds! (min_offset is 5)
      * therefore, reflect action should be cancelled

        0    5    10
        |----|----|
        
      0  
        /---------]
        |
        |
      1 \---->
        
      */
      expect_design_equal(store.state.design, orig_design);
    });

    test('strand_reflect_vertically_no_polarity_reverse', () {

      Store<AppState> store = store_from_design(orig_design, initialize_app_instance: false);
      store.dispatch(
          actions.StrandsReflect(
        strands: orig_design.strands, horizontal: false, reverse_polarity: false));
        
      /* 

      * hypothetical reflect --- but notice domain on helix 1 is out of bounds! (min_offset is 5)
      * therefore, reflect action should be cancelled

        0    5    10
        |----|----|
        
      0      [----\
                  |
                  |
                  |
      1           |
        <---------/   
        
      */
      expect_design_equal(store.state.design, orig_design);
    });

    test('strand_reflect_horizontally_polarity_reverse', () {

      Store<AppState> store = store_from_design(orig_design, initialize_app_instance: false);
      store.dispatch(
          actions.StrandsReflect(
        strands: orig_design.strands, horizontal: true, reverse_polarity: true));
        
      /* 

      * hypothetical reflect --- but notice domain on helix 1 is out of bounds! (min_offset is 5)
      * therefore, reflect action should be cancelled

        0    5    10
        |----|----|
        
      0 /--------->
        |
        |
        |
      1 |
        \----]
        
      */
      expect_design_equal(store.state.design, orig_design);
    });

    test('strand_reflect_vertically_polarity_reverse', () {

      Store<AppState> store = store_from_design(orig_design, initialize_app_instance: false);
      store.dispatch(
          actions.StrandsReflect(
        strands: orig_design.strands, horizontal: false, reverse_polarity: true));
        
      /* 

      * hypothetical reflect --- but notice domain on helix 1 is out of bounds! (min_offset is 5)
      * therefore, reflect action should be cancelled

        0    5    10
        |----|----|
        
      0
             <----\
                  |
                  |
      1 [---------/   
        
      */
      expect_design_equal(store.state.design, orig_design);
    });
  });
  
  group('StrandReflectValid', () {
    List<Helix> helices;
    Design orig_design;

    setUp(() {
      /*

      * initial design

        0    5    10
        |----|----|
        
      0 [---------\
                  |
                  |
                  |
      1           |
             <----/   

      */

      helices = [
        Helix(idx: 0, min_offset: 0, max_offset: 10, grid: Grid.square),
        Helix(idx: 1, min_offset: 0, max_offset: 10, grid: Grid.square)
      ];
      orig_design = Design(helices: helices, grid: Grid.square);

      orig_design = orig_design
          .strand(0, 0)
          .move(10)
          .cross(1)
          .move(-5)
          .commit();
    });

    test('strand_reflect_horizontally_no_polarity_reverse', () {

      Store<AppState> store = store_from_design(orig_design, initialize_app_instance: false);
      store.dispatch(
          actions.StrandsReflect(
        strands: orig_design.strands, horizontal: true, reverse_polarity: false));
        
      /* 

      * resulting design

        0    5    10
        |----|----|
        
      0  
        /---------]
        |
        |
      1 \---->
        
      */

      var expected_design = Design(helices: helices, grid: Grid.square);

      expected_design = expected_design
          .strand(0, 10)
          .move(-10)
          .cross(1)
          .move(5)
          .commit();
      expect_design_equal(store.state.design, expected_design);
    });

    test('strand_reflect_vertically_no_polarity_reverse', () {

      Store<AppState> store = store_from_design(orig_design, initialize_app_instance: false);
      store.dispatch(
          actions.StrandsReflect(
        strands: orig_design.strands, horizontal: false, reverse_polarity: false));
        
      /* 

      * resulting design

        0    5    10
        |----|----|
        
      0      [----\
                  |
                  |
                  |
      1           |
        <---------/   
        
      */

      var expected_design = Design(helices: helices, grid: Grid.square);

      expected_design = expected_design
          .strand(0, 5)
          .move(5)
          .cross(1)
          .move(-10)
          .commit();
      expect_design_equal(store.state.design, expected_design);
    });

    test('strand_reflect_horizontally_polarity_reverse', () {

      Store<AppState> store = store_from_design(orig_design, initialize_app_instance: false);
      store.dispatch(
          actions.StrandsReflect(
        strands: orig_design.strands, horizontal: true, reverse_polarity: true));
        
      /* 

      * resulting design

        0    5    10
        |----|----|
        
      0 /--------->
        |
        |
        |
      1 |
        \----]
        
      */

      var expected_design = Design(helices: helices, grid: Grid.square);

      expected_design = expected_design
          .strand(1, 5)
          .move(-5)
          .cross(0)
          .move(10)
          .commit();
      expect_design_equal(store.state.design, expected_design);
    });

    test('strand_reflect_vertically_polarity_reverse', () {

      Store<AppState> store = store_from_design(orig_design, initialize_app_instance: false);
      store.dispatch(
          actions.StrandsReflect(
        strands: orig_design.strands, horizontal: false, reverse_polarity: true));
        
      /* 

      * resulting design

        0    5    10
        |----|----|
        
      0
             <----\
                  |
                  |
      1 [---------/   
        
      */

      var expected_design = Design(helices: helices, grid: Grid.square);

      expected_design = expected_design
          .strand(1, 0)
          .move(10)
          .cross(0)
          .move(-5)
          .commit();
      expect_design_equal(store.state.design, expected_design);
    });
  });
}
