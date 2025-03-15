import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:quiver/iterables.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/reducers/design_reducer.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/grid_position.dart';

import 'package:scadnano/src/middleware/helices_positions_set_based_on_crossovers.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/constants.dart' as constants;
import 'package:scadnano/src/util.dart' as util;
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  num eps = 0.0001;

  group('unstrain_backbone_vert_design', () {
    Design design_vert = Design(helices: [], grid: Grid.square);
    AppState state_vert = app_state_from_design(design_vert);

    // grid positions:
    //  0,0
    //  0,1
    //  0,2
    //
    //     0    5
    //  0  +----]
    //     |
    //  1  +----+
    //          |
    //  2  <----+
    setUp(() async {
      var pre_design_vert = Design(grid: Grid.square, num_helices: 3);
      design_vert = pre_design_vert.draw_strand(0, 5).to(0).cross(1).to(5).cross(2).to(0).commit();
      state_vert = app_state_from_design(design_vert);
    });

    test('rotations_vert_before_setting', () {
      var helix0 = design_vert.helices[0]!;
      var helix1 = design_vert.helices[1]!;
      var helix2 = design_vert.helices[2]!;

      expect(helix0.roll, 0);
      expect(helix1.roll, 0);
      expect(helix2.roll, 0);

      expect(helix0.grid_position, GridPosition(0, 0));
      expect(helix1.grid_position, GridPosition(0, 1));
      expect(helix2.grid_position, GridPosition(0, 2));

      expect(util.rotation_between_helices(helix0, helix1, true, design_vert.geometry), 180);
      expect(util.rotation_between_helices(helix1, helix2, true, design_vert.geometry), 180);

      for (int i in Iterable<int>.generate(5)) {
        expect(design_vert.helix_rotation_forward(0, i), closeTo(i * 360 / 10.5, eps));
        expect(design_vert.helix_rotation_forward(1, i), closeTo(i * 360 / 10.5, eps));
        expect(design_vert.helix_rotation_forward(2, i), closeTo(i * 360 / 10.5, eps));
      }
    });

    // grid positions:
    //  0,0
    //  0,1
    //  0,2
    //
    //     0    5
    //  0  +----]
    // --> |
    //  1  +----+
    //          |
    //  2  <----+
    test('unstrain_backbone_h0_h1_offset0', () {
      int anchor = 0;
      var roll_action_h0 = actions.HelixRollSetAtOther(0, 1, false, anchor);
      var roll_action_h1 = actions.HelixRollSetAtOther(1, 0, true, anchor);
      var batch_action = actions.BatchAction([
        roll_action_h0,
        roll_action_h1,
      ], "unstrain backbone at crossover");
      var state_after = app_state_reducer(state_vert, batch_action);

      expect(state_after.design.helix_rotation_reverse(0, 0), closeTo(180, eps));
      expect(state_after.design.helix_rotation_forward(1, 0), closeTo(0, eps));
    });

    // grid positions:
    //  0,0
    //  0,1
    //  0,2
    //
    //     0    5
    //  0  +----]
    //     |
    //  1  +----+
    //          | <--
    //  2  <----+
    test('unstrain_backbone_h1_h2_offset5', () {
      int anchor = 5;
      var roll_action_h1 = actions.HelixRollSetAtOther(1, 2, true, anchor);
      var roll_action_h2 = actions.HelixRollSetAtOther(2, 1, false, anchor);
      var batch_action = actions.BatchAction([
        roll_action_h1,
        roll_action_h2,
      ], "unstrain backbone at crossover");
      var state_after = app_state_reducer(state_vert, batch_action);

      expect(state_after.design.helix_rotation_forward(1, 5), closeTo(180, eps));
      expect(state_after.design.helix_rotation_reverse(2, 5), closeTo(0, eps));
    });
  });

  group('unstrain_backbone_horz_design', () {
    Design design_horz = Design(helices: [], grid: Grid.square);
    AppState state_horz = app_state_from_design(design_horz);

    // design_horz:
    // grid positions:
    //    0,0 1,0 2,0
    //
    //     0    5
    //  0  +----]
    //     |
    //  1  +----+
    //          |
    //  2  <----+
    setUp(() async {
      var helices = [
        Helix(idx: 0, grid: Grid.square, grid_position: GridPosition(0, 0)),
        Helix(idx: 1, grid: Grid.square, grid_position: GridPosition(1, 0)),
        Helix(idx: 2, grid: Grid.square, grid_position: GridPosition(2, 0)),
      ];
      var pre_design_horz = Design(grid: Grid.square, helices: helices);
      design_horz = pre_design_horz.draw_strand(0, 5).to(0).cross(1).to(5).cross(2).to(0).commit();
      state_horz = app_state_from_design(design_horz);
    });

    test('rotations_horz_before_setting', () {
      var helix0 = design_horz.helices[0]!;
      var helix1 = design_horz.helices[1]!;
      var helix2 = design_horz.helices[2]!;

      expect(helix0.roll, 0);
      expect(helix1.roll, 0);
      expect(helix2.roll, 0);

      expect(helix0.grid_position, GridPosition(0, 0));
      expect(helix1.grid_position, GridPosition(1, 0));
      expect(helix2.grid_position, GridPosition(2, 0));

      expect(util.rotation_between_helices(helix0, helix1, true, design_horz.geometry), 90);
      expect(util.rotation_between_helices(helix1, helix2, true, design_horz.geometry), 90);

      for (int i in Iterable<int>.generate(5)) {
        expect(design_horz.helix_rotation_forward(0, i), closeTo(i * 360 / 10.5, eps));
        expect(design_horz.helix_rotation_forward(1, i), closeTo(i * 360 / 10.5, eps));
        expect(design_horz.helix_rotation_forward(2, i), closeTo(i * 360 / 10.5, eps));
      }
    });

    // grid positions:
    //   0,0  1,0  2,0
    //
    //     0    5
    //  0  +----]
    // --> |
    //  1  +----+
    //          |
    //  2  <----+
    test('unstrain_backbone_h0_h1_offset5_horz', () {
      int anchor = 0;
      var roll_action_h0 = actions.HelixRollSetAtOther(0, 1, false, anchor);
      var roll_action_h1 = actions.HelixRollSetAtOther(1, 0, true, anchor);
      var batch_action = actions.BatchAction([
        roll_action_h0,
        roll_action_h1,
      ], "unstrain backbone at crossover");
      var state_after = app_state_reducer(state_horz, batch_action);

      expect(state_after.design.helix_rotation_reverse(0, 0), closeTo(90, eps));
      expect(state_after.design.helix_rotation_forward(1, 0), closeTo(270, eps));
    });

    // grid positions:
    //  0,0  1,0  2,0
    //
    //     0    5
    //  0  +----]
    //     |
    //  1  +----+
    //          | <--
    //  2  <----+
    test('unstrain_backbone_h1_h2_offset5_horz', () {
      int anchor = 5;
      var roll_action_h1 = actions.HelixRollSetAtOther(1, 2, true, anchor);
      var roll_action_h2 = actions.HelixRollSetAtOther(2, 1, false, anchor);
      var batch_action = actions.BatchAction([
        roll_action_h1,
        roll_action_h2,
      ], "unstrain backbone at crossover");
      var state_after = app_state_reducer(state_horz, batch_action);

      expect(state_after.design.helix_rotation_forward(1, 5), closeTo(90, eps));
      expect(state_after.design.helix_rotation_reverse(2, 5), closeTo(270, eps));
    });
  });

  group('helix_rotation_set_based_on_crossovers', () {
    Design design = Design(helices: [], grid: Grid.none);
    AppState state = app_state_from_design(design);
    Geometry geometry = Geometry();

    // design:
    // positions:
    //    0,0
    //    0,2.5
    //    0,5
    //
    //    0    5    10   15
    // 0  +---->
    //    |
    // 1  +----]
    //    +---->
    //    |
    // 2  +----]
    setUp(() async {
      geometry = Geometry(helix_radius: 1.0, inter_helix_gap: 0.5, bases_per_turn: 10.5);
      double helix_dist = geometry.distance_between_helices_nm;
      var helices = [
        Helix(idx: 0, grid: Grid.none, position: Position3D(x: 0, z: 0, y: 0), roll: 0),
        Helix(idx: 1, grid: Grid.none, position: Position3D(x: helix_dist, z: 0, y: helix_dist), roll: 0),
        Helix(
          idx: 2,
          grid: Grid.none,
          position: Position3D(x: 2 * helix_dist, z: 0, y: 2 * helix_dist),
          roll: 0,
        ),
      ];
      design = Design(grid: Grid.none, helices: helices, geometry: geometry);
      design = design.draw_strand(1, 5).to(0).cross(0).to(5).commit();
      design = design.draw_strand(2, 5).to(0).cross(1).to(5).commit();
      state = app_state_from_design(design);
    });

    test('rotations_gridless_design_before_setting', () {
      var helix0 = design.helices[0]!;
      var helix1 = design.helices[1]!;
      var helix2 = design.helices[2]!;

      expect(helix0.roll, 0);
      expect(helix1.roll, 0);
      expect(helix2.roll, 0);

      double helix_dist = design.geometry.distance_between_helices_nm;
      expect(helix0.position(design.geometry), Position3D(x: 0, z: 0, y: 0));
      expect(helix1.position(design.geometry), Position3D(x: helix_dist, z: 0, y: helix_dist));
      expect(helix2.position(design.geometry), Position3D(x: 2 * helix_dist, z: 0, y: 2 * helix_dist));

      expect(util.rotation_between_helices(helix0, helix1, true, design.geometry), 90 + 45);
      expect(util.rotation_between_helices(helix1, helix2, true, design.geometry), 90 + 45);

      expect(design.groups.length, 1);
      expect(design.groups.keys, contains(constants.default_group_name));
      var group = design.default_group();
      expect(group.helices_view_order, orderedEquals([0, 1, 2]));
      expect(group.grid, Grid.none);
    });

    test('h0_h1_crossover_0_h1_h2_crossover_10', () {
      // with helix0.roll = 0, the forward backbone points up, so helix1 should be directly above
      // x = 0, y = -2.5
      // On helix1, the reverse backbone will point down, so the forward backbone will point 30 degrees
      // clockwise from straight up, which is 60 degrees counterclockwise from the x-axis in Cartesian.
      // So helix2 will be at
      // x = cos(60), y = -sin(60)
      List<actions.UndoableAction> all_actions = get_helix_position_and_roll_actions(state);

      expect(all_actions.length, 6);

      var batch_action = actions.BatchAction(all_actions, "set helix coordinates based on crossovers");
      var state_after = app_state_reducer(state, batch_action);
      var design_after = state_after.design;

      var helix0 = design_after.helices[0]!;
      var helix1 = design_after.helices[1]!;
      var helix2 = design_after.helices[2]!;

      expect(helix0.position(geometry).x, closeTo(0, eps));
      expect(helix0.position(geometry).y, closeTo(0, eps));
      expect(helix0.position(geometry).z, closeTo(0, eps));

      num x1 = 0;
      num y1 = -design.geometry.distance_between_helices_nm;
      expect(helix1.position(geometry).x, closeTo(x1, eps));
      expect(helix1.position(geometry).y, closeTo(y1, eps));
      expect(helix1.position(geometry).z, closeTo(0, eps));

      num radians_60_deg = util.to_radians(60);
      num x2 = cos(radians_60_deg) * design.geometry.distance_between_helices_nm;
      num y2 = -sin(radians_60_deg) * design.geometry.distance_between_helices_nm;
      expect(helix2.position(geometry).x, closeTo(x1 + x2, eps));
      expect(helix2.position(geometry).y, closeTo(y1 + y2, eps));
      expect(helix2.position(geometry).z, closeTo(0, eps));
    });
  });
}
