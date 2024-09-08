// @dart=2.9

import 'package:color/color.dart';
import 'package:scadnano/src/reducers/change_loopout_ext_properties.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/state/address.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/extension.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:tuple/tuple.dart';

import 'package:scadnano/src/util.dart' as util;
import 'package:scadnano/src/constants.dart' as constants;

main() {
  group('HelixRollRelax', () {
    Design design2h;
    Design design3helix3strand;
    double epsilon = 0.000000001;

    setUp(() {
      /*
        0123456789012345678901234567890123456789
      0 [---+[--------+[----------+
            |         |           |
      1 [---+<--------+<----------+

      angle (fraction of 360)
           4/10.5
                   (14-10.5)/10.5 = 3.5/10.5
                             (26-21)/10.5 = 5/10.5
      */
      design2h = Design(helices: [
        for (int i = 0; i < 2; i++) Helix(max_offset: 50, idx: i, grid_position: GridPosition(0, i))
      ], grid: Grid.square);
      // helix 0 forward
      design2h = design2h.draw_strand(0, 0).move(5).cross(1).move(-5).commit();
      design2h = design2h.draw_strand(0, 5).move(10).cross(1).move(-10).commit();
      design2h = design2h.draw_strand(0, 15).move(12).cross(1).move(-12).commit();

      /*
        0123456789012345678901234567890123456789
      0 [---+[--------+[----------+
            |         |           |
      1 [---+         |<----------+
                      |
      2      <--------+
      */
      design3helix3strand = Design(helices: [
        for (int i = 0; i < 3; i++) Helix(max_offset: 50, idx: i, grid_position: GridPosition(0, i))
      ], grid: Grid.square);
      // helix 0 forward
      design3helix3strand = design3helix3strand.draw_strand(0, 0).move(5).cross(1).move(-5).commit();
      design3helix3strand = design3helix3strand.draw_strand(0, 5).move(10).cross(2).move(-10).commit();
      design3helix3strand = design3helix3strand.draw_strand(0, 15).move(12).cross(1).move(-12).commit();
    });

    test('3_helix_2_crossovers', () {
      /*
        0         1
        012345678901234
      0 [---+[------+
            |       |
      1 [---+       |
                    |
      2      <------+
      */
      List<Helix> helices = [];
      [];
      for (int i = 0; i < 3; i++) {
        var helix = Helix(max_offset: 60, grid: Grid.square, idx: i, grid_position: GridPosition(0, i));
        if (i == 2) {
          helix = helix.rebuild((b) => b..grid_position.replace(GridPosition(1, 0)));
        }
        helices.add(helix);
      }
      var design3h = Design(helices: helices, grid: Grid.square);

      design3h = design3h.draw_strand(0, 0).move(5).cross(1).move(-5).commit();
      design3h = design3h.draw_strand(0, 5).move(8).cross(2).move(-8).commit();

      var crossover_addresses_h0 = design3h.helix_to_crossover_addresses[0].toList();
      var crossover_addresses_h1 = design3h.helix_to_crossover_addresses[1].toList();
      var crossover_addresses_h2 = design3h.helix_to_crossover_addresses[2].toList();
      expect(crossover_addresses_h0.length, 2);
      expect(crossover_addresses_h1.length, 1);
      expect(crossover_addresses_h2.length, 1);

      var f1 = 4 / 10.5;
      var f2 = 12 / 10.5;
      var a1 = f1 * 360 % 360;
      var a2 = f2 * 360 % 360;

      // rules for angles:
      // - add 150 if on reverse strand to account of minor groove
      // - subtract angle of helix crossover is connecting to

      var ave_h0 = (a1 - 180 + a2 - 90) / 2; // helix 1 at 180 degrees, helix 2 at 90 degrees
      var exp_h0_roll = (-ave_h0) % 360;

      var ave_h1 = a1 + 150; // helix 0 at 0 degrees relative to helix 1
      var exp_h1_roll = (-ave_h1) % 360;

      var ave_h2 = a2 + 150 - (-90); // helix 0 at -90 degrees relative to helix 2
      var exp_h2_roll = (-ave_h2) % 360;

      design3h = design3h.relax_helix_rolls();

      expect(design3h.helices[0].roll, closeTo(exp_h0_roll, epsilon));
      expect(design3h.helices[1].roll, closeTo(exp_h1_roll, epsilon));
      expect(design3h.helices[2].roll, closeTo(exp_h2_roll, epsilon));
    });

    test('3_helix_2_crossovers_1_loopout_crossovers_method', () {
      /*
          0         1          2
          012345678901234567890
        0 [---+[------+[------+
              |       |        \
        1 [---+       |        |
                      |        /
        2      <------+<------+
      */
      List<Helix> helices = [];
      [];
      for (int i = 0; i < 3; i++) {
        var helix = Helix(max_offset: 60, grid: Grid.square, idx: i, grid_position: GridPosition(0, i));
        if (i == 2) {
          helix = helix.rebuild((b) => b..grid_position.replace(GridPosition(1, 0)));
        }
        helices.add(helix);
      }
      var design3h = Design(helices: helices, grid: Grid.square);

      design3h = design3h.draw_strand(0, 0).move(5).cross(1).move(-5).commit();
      design3h = design3h.draw_strand(0, 5).move(8).cross(2).move(-8).commit();
      design3h = design3h.draw_strand(0, 13).move(8).loopout(2, 3).move(-8).commit();

      var crossover_addresses = design3h.helix_to_crossover_addresses;
      var crossover_addresses_h0 = crossover_addresses[0];
      var crossover_addresses_h1 = crossover_addresses[1];
      var crossover_addresses_h2 = crossover_addresses[2];

      expect(crossover_addresses_h0.length, 2);
      expect(crossover_addresses_h1.length, 1);
      expect(crossover_addresses_h2.length, 1);

      expect(crossover_addresses_h0[0], Address(helix_idx: 1, offset: 4, forward: true));
      expect(crossover_addresses_h0[1], Address(helix_idx: 2, offset: 12, forward: true));

      expect(crossover_addresses_h1[0], Address(helix_idx: 0, offset: 4, forward: false));

      expect(crossover_addresses_h2[0], Address(helix_idx: 0, offset: 12, forward: false));
    });

    test('3_helix_2_crossovers_1_loopout', () {
      /*
          0         1          2
          012345678901234567890
        0 [---+[------+[------+
              |       |        \
        1 [---+       |        |
                      |        /
        2      <------+<------+
      */
      List<Helix> helices = [];
      [];
      for (int i = 0; i < 3; i++) {
        var helix = Helix(max_offset: 60, grid: Grid.square, idx: i, grid_position: GridPosition(0, i));
        if (i == 2) {
          helix = helix.rebuild((b) => b..grid_position.replace(GridPosition(1, 0)));
        }
        helices.add(helix);
      }
      var design3h = Design(helices: helices, grid: Grid.square);

      design3h = design3h.draw_strand(0, 0).move(5).cross(1).move(-5).commit();
      design3h = design3h.draw_strand(0, 5).move(8).cross(2).move(-8).commit();
      design3h = design3h.draw_strand(0, 13).move(8).loopout(2, 3).move(-8).commit();

      var crossover_addresses_h0 = design3h.helix_to_crossover_addresses[0].toList();
      var crossover_addresses_h1 = design3h.helix_to_crossover_addresses[1].toList();
      var crossover_addresses_h2 = design3h.helix_to_crossover_addresses[2].toList();
      expect(crossover_addresses_h0.length, 2);
      expect(crossover_addresses_h1.length, 1);
      expect(crossover_addresses_h2.length, 1);

      var f1 = 4 / 10.5;
      var f2 = 12 / 10.5;
      var a1 = f1 * 360 % 360;
      var a2 = f2 * 360 % 360;

      // rules for angles:
      // - add 150 if on reverse strand to account of minor groove
      // - subtract angle of helix crossover is connecting to

      var ave_h0 = (a1 - 180 + a2 - 90) / 2; // helix 1 at 180 degrees, helix 2 at 90 degrees
      var exp_h0_roll = (-ave_h0) % 360;

      var ave_h1 = a1 + 150; // helix 0 at 0 degrees relative to helix 1
      var exp_h1_roll = (-ave_h1) % 360;

      var ave_h2 = a2 + 150 - (-90); // helix 0 at -90 degrees relative to helix 2
      var exp_h2_roll = (-ave_h2) % 360;

      design3h = design3h.relax_helix_rolls();

      expect(design3h.helices[0].roll, closeTo(exp_h0_roll, epsilon));
      expect(design3h.helices[1].roll, closeTo(exp_h1_roll, epsilon));
      expect(design3h.helices[2].roll, closeTo(exp_h2_roll, epsilon));
    });

    test('2_helix_no_crossovers', () {
      /*
          0         1         2
          012345678901234567890
        0 [--->[-------->

        1 <---]<--------]
      */
      List<Helix> helices = [];
      double initial_roll = 30.0;
      for (int i = 0; i < 2; i++) {
        var helix = Helix(
            max_offset: 60, grid: Grid.square, idx: i, grid_position: GridPosition(0, i), roll: initial_roll);
        helices.add(helix);
      }
      var design2h = Design(helices: helices, grid: Grid.square);

      design2h = design2h.draw_strand(0, 0).move(5).commit();
      design2h = design2h.draw_strand(0, 5).move(10).commit();
      design2h = design2h.draw_strand(1, 5).move(-5).commit();
      design2h = design2h.draw_strand(1, 15).move(-10).commit();

      var crossover_addresses_h0 = design2h.helix_to_crossover_addresses[0].toList();
      var crossover_addresses_h1 = design2h.helix_to_crossover_addresses[1].toList();
      expect(crossover_addresses_h0.length, 0);
      expect(crossover_addresses_h1.length, 0);

      design2h = design2h.relax_helix_rolls();

      expect(design2h.helices[0].roll, closeTo(initial_roll, epsilon));
      expect(design2h.helices[1].roll, closeTo(initial_roll, epsilon));
    });

    test('3_helix_6_crossovers', () {
      /*
          0         1         2         3         4         5         6
          012345678901234567890123456789012345678901234567890123456789
        0 [---+[--------+[----------+[------+[--------+[--------+
              |         |           |       |         |         |
        1 [---+<--------+<----------+       |         |         |
                                            |         |         |
        2                            <------+<--------+<--------+
      */
      List<Helix> helices = [];
      for (int i = 0; i < 3; i++) {
        var helix = Helix(max_offset: 60, grid: Grid.square, idx: i, grid_position: GridPosition(0, i));
        if (i == 2) {
          helix = helix.rebuild((b) => b..grid_position.replace(GridPosition(1, 0)));
        }
        helices.add(helix);
      }
      var design3h = Design(helices: helices, grid: Grid.square);
      design3h = design3h.draw_strand(0, 0).move(5).cross(1).move(-5).commit();
      design3h = design3h.draw_strand(0, 5).move(10).cross(1).move(-10).commit();
      design3h = design3h.draw_strand(0, 15).move(12).cross(1).move(-12).commit();
      design3h = design3h.draw_strand(0, 27).move(7).cross(2).move(-7).commit();
      design3h = design3h.draw_strand(0, 34).move(10).cross(2).move(-10).commit();
      design3h = design3h.draw_strand(0, 44).move(10).cross(2).move(-10).commit();

      var f1 = 4 / 10.5;
      var f2 = 14 / 10.5;
      var f3 = 26 / 10.5;
      var f4 = 33 / 10.5;
      var f5 = 43 / 10.5;
      var f6 = 53 / 10.5;
      var a1 = f1 * 360 % 360;
      var a2 = f2 * 360 % 360;
      var a3 = f3 * 360 % 360;
      var a4 = f4 * 360 % 360;
      var a5 = f5 * 360 % 360;
      var a6 = f6 * 360 % 360;

      // rules for angles:
      // - add 150 if on reverse strand to account of minor groove
      // - subtract angle of helix crossover is connecting to

      var ave_h0 = (a1 - 180 + a2 - 180 + a3 - 180 + a4 - 90 + a5 - 90 + a6 - 90) / 6;
      var exp_h0_roll = (-ave_h0) % 360;

      var ave_h1 = (a1 + 150 + a2 + 150 + a3 + 150) / 3;
      var exp_h1_roll = (-ave_h1) % 360;

      var ave_h2 = (a4 + 150 - (-90) + a5 + 150 - (-90) + a6 + 150 - (-90)) / 3;
      var exp_h2_roll = (-ave_h2) % 360;

      design3h = design3h.relax_helix_rolls();

      expect(design3h.helices[0].roll, closeTo(exp_h0_roll, epsilon));
      expect(design3h.helices[1].roll, closeTo(exp_h1_roll, epsilon));
      expect(design3h.helices[2].roll, closeTo(exp_h2_roll, epsilon));
    });

    test('2_helix_3_crossover', () {
      var f1 = 4 / 10.5;
      var f2 = 14 / 10.5;
      var f3 = 26 / 10.5;
      var a1 = f1 * 360 % 360;
      var a2 = f2 * 360 % 360;
      var a3 = f3 * 360 % 360;

      // rules for angles:
      // - add 150 if on reverse strand to account of minor groove
      // - subtract angle of helix crossover is connecting to

      var ave_h0 = (a1 - 180 + a2 - 180 + a3 - 180) / 3;
      var exp_h0_roll = (-ave_h0) % 360;

      var ave_h1 = (a1 + 150 + a2 + 150 + a3 + 150) / 3;
      var exp_h1_roll = (-ave_h1) % 360;

      design2h = design2h.relax_helix_rolls();

      expect(design2h.helices[0].roll, closeTo(exp_h0_roll, epsilon));
      expect(design2h.helices[1].roll, closeTo(exp_h1_roll, epsilon));
    });

    test('2_helix_3_crossover_and_intrahelix_crossovers', () {
      /*                  1         2         3
          0123456789012345678901234567890123456789
        0 [---+[--------+[----------+[--+c+-->
              |         |           |
        1 [---+<--------+<----------+<--+c+--]
       */
      design2h = design2h.draw_strand(0, 27).move(4).cross(0, 32).move(4).commit();
      design2h = design2h.draw_strand(1, 36).move(-4).cross(1, 31).move(-4).commit();

      var f1 = 4 / 10.5;
      var f2 = 14 / 10.5;
      var f3 = 26 / 10.5;
      var a1 = f1 * 360 % 360;
      var a2 = f2 * 360 % 360;
      var a3 = f3 * 360 % 360;

      // rules for angles:
      // - add 150 if on reverse strand to account of minor groove
      // - subtract angle of helix crossover is connecting to

      var ave_h0 = (a1 - 180 + a2 - 180 + a3 - 180) / 3;
      var exp_h0_roll = (-ave_h0) % 360;

      var ave_h1 = (a1 + 150 + a2 + 150 + a3 + 150) / 3;
      var exp_h1_roll = (-ave_h1) % 360;

      design2h = design2h.relax_helix_rolls();

      expect(design2h.helices[0].roll, closeTo(exp_h0_roll, epsilon));
      expect(design2h.helices[1].roll, closeTo(exp_h1_roll, epsilon));
    });

    test('2_helix_2_crossover_call_relax_twice', () {
      /*
          0         1
          012345678901234
        0 [---+[-----+
              |      |
        1 [---+<-----+
    */
      List<Helix> helices = [];
      for (int i = 0; i < 2; i++) {
        var helix = Helix(max_offset: 60, grid: Grid.square, idx: i, grid_position: GridPosition(0, i));
        helices.add(helix);
      }
      var design2h = Design(helices: helices, grid: Grid.square);
      design2h = design2h.draw_strand(0, 0).move(5).cross(1).move(-5).commit();
      design2h = design2h.draw_strand(0, 5).move(6).cross(1).move(-6).commit();

      var exp_h0_roll = 120.0;
      var exp_h1_roll = 150.0;

      design2h = design2h.relax_helix_rolls();

      expect(exp_h0_roll, design2h.helices[0].roll);
      expect(exp_h1_roll, design2h.helices[1].roll);

      // test for bug that reset roll; if called twice in a row it should have no effect the second time
      design2h = design2h.relax_helix_rolls();

      expect(exp_h0_roll, design2h.helices[0].roll);
      expect(exp_h1_roll, design2h.helices[1].roll);
    });

    test('helix_crossover_addresses_3_helix_3_strand', () {
      var xs0 = design3helix3strand.helix_to_crossover_addresses[0];
      expect(xs0.length, 3);
      Address a0 = xs0[0];
      Address a1 = xs0[1];
      Address a2 = xs0[2];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a0.helix_idx, 1);
      expect(a1.helix_idx, 2);
      expect(a2.helix_idx, 1);
      expect(a0.forward, true);
      expect(a1.forward, true);
      expect(a2.forward, true);

      var xs1 = design3helix3strand.helix_to_crossover_addresses[1];
      expect(xs1.length, 2);
      a0 = xs1[0];
      a1 = xs1[1];
      expect(a0.offset, 4);
      expect(a1.offset, 26);
      expect(a0.helix_idx, 0);
      expect(a1.helix_idx, 0);
      expect(a0.forward, false);
      expect(a1.forward, false);

      var xs2 = design3helix3strand.helix_to_crossover_addresses[2];
      expect(xs2.length, 1);
      a0 = xs2[0];
      expect(a0.offset, 14);
      expect(a0.helix_idx, 0);
      expect(a0.forward, false);
    });

    test('helix_crossover_addresses_2_helix_3_strand', () {
      var xs0 = design2h.helix_to_crossover_addresses[0];
      expect(xs0.length, 3);
      var a0 = xs0[0];
      var a1 = xs0[1];
      var a2 = xs0[2];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a0.helix_idx, 1);
      expect(a1.helix_idx, 1);
      expect(a2.helix_idx, 1);
      expect(a0.forward, true);
      expect(a1.forward, true);
      expect(a2.forward, true);

      var xs1 = design2h.helix_to_crossover_addresses[1];
      expect(xs1.length, 3);
      a0 = xs1[0];
      a1 = xs1[1];
      a2 = xs1[2];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a0.helix_idx, 0);
      expect(a1.helix_idx, 0);
      expect(a2.helix_idx, 0);
      expect(a0.forward, false);
      expect(a1.forward, false);
      expect(a2.forward, false);
    });

    test('helix_crossover_addresses_2_helix_disallow_intrahelix_crossovers', () {
      /*                  1         2         3
          0123456789012345678901234567890123456789
        0 [---+[--------+[----------+[--+c+-->
              |         |           |
        1 [---+<--------+<----------+<--+c+--]
       */
      design2h = design2h.draw_strand(0, 27).move(4).cross(0, 32).move(4).commit();
      design2h = design2h.draw_strand(1, 36).move(-4).cross(1, 31).move(-4).commit();

      var xs0 = design2h.helix_to_crossover_addresses_disallow_intrahelix[0];
      expect(xs0.length, 3);
      var a0 = xs0[0];
      var a1 = xs0[1];
      var a2 = xs0[2];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a0.helix_idx, 1);
      expect(a1.helix_idx, 1);
      expect(a2.helix_idx, 1);
      expect(a0.forward, true);
      expect(a1.forward, true);
      expect(a2.forward, true);

      var xs1 = design2h.helix_to_crossover_addresses_disallow_intrahelix[1];
      expect(xs1.length, 3);
      a0 = xs1[0];
      a1 = xs1[1];
      a2 = xs1[2];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a0.helix_idx, 0);
      expect(a1.helix_idx, 0);
      expect(a2.helix_idx, 0);
      expect(a0.forward, false);
      expect(a1.forward, false);
      expect(a2.forward, false);
    });

    test('helix_crossover_addresses_2_helix_allow_intrahelix_crossovers', () {
      /*                  1         2         3
          0123456789012345678901234567890123456789
        0 [---+[--------+[----------+[--+c+-->
              |         |           |
        1 [---+<--------+<----------+<--+c+--]
       */
      design2h = design2h.draw_strand(0, 27).move(4).cross(0, 32).move(4).commit();
      design2h = design2h.draw_strand(1, 36).move(-4).cross(1, 31).move(-4).commit();

      var xs0 = design2h.helix_to_crossover_addresses[0];
      expect(xs0.length, 5);
      var a0 = xs0[0];
      var a1 = xs0[1];
      var a2 = xs0[2];
      var a3 = xs0[3];
      var a4 = xs0[4];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a3.offset, 30);
      expect(a4.offset, 32);
      expect(a0.helix_idx, 1);
      expect(a1.helix_idx, 1);
      expect(a2.helix_idx, 1);
      expect(a3.helix_idx, 0);
      expect(a4.helix_idx, 0);
      expect(a0.forward, true);
      expect(a1.forward, true);
      expect(a2.forward, true);
      expect(a3.forward, true);
      expect(a4.forward, true);

      var xs1 = design2h.helix_to_crossover_addresses[1];
      expect(xs1.length, 5);
      a0 = xs1[0];
      a1 = xs1[1];
      a2 = xs1[2];
      a3 = xs1[3];
      a4 = xs1[4];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a3.offset, 30);
      expect(a4.offset, 32);
      expect(a0.helix_idx, 0);
      expect(a1.helix_idx, 0);
      expect(a2.helix_idx, 0);
      expect(a3.helix_idx, 1);
      expect(a4.helix_idx, 1);
      expect(a0.forward, false);
      expect(a1.forward, false);
      expect(a2.forward, false);
      expect(a3.forward, false);
      expect(a4.forward, false);
    });

    test('helix_crossover_addresses_2_helix_disallow_intergroup_crossovers', () {
      /*            1         2         3
          0123456789012345678901234567890123456789
        0 [---+[--------+[----------+[--+
              |         |           |   |
        1 <---+<--------+<----------+   |
                                        |
        group 2                         |
        2                            <--+
       */
      var group2name = 'group 2';

      var helices = [
        for (int i = 0; i < 3; i++) Helix(max_offset: 50, idx: i, grid_position: GridPosition(0, i))
      ];
      helices[2] = helices[2].rebuild((b) => b..group = group2name);
      var design = Design(helices: helices, grid: Grid.square);
      design = design.draw_strand(0, 0).move(5).cross(1).move(-5).commit();
      design = design.draw_strand(0, 5).move(10).cross(1).move(-10).commit();
      design = design.draw_strand(0, 15).move(12).cross(1).move(-12).commit();
      design = design.draw_strand(0, 27).move(4).cross(2).move(-4).commit();

      expect(design.groups.length, 2);

      var exp_group_names = List<String>.from(design.groups.keys);
      expect(exp_group_names, [constants.default_group_name, group2name]);

      var xs0 = design.helix_to_crossover_addresses_disallow_intrahelix_disallow_intergroup[0];
      expect(xs0.length, 3);
      var a0 = xs0[0];
      var a1 = xs0[1];
      var a2 = xs0[2];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a0.helix_idx, 1);
      expect(a1.helix_idx, 1);
      expect(a2.helix_idx, 1);
      expect(a0.forward, true);
      expect(a1.forward, true);
      expect(a2.forward, true);

      var xs1 = design.helix_to_crossover_addresses_disallow_intrahelix_disallow_intergroup[1];
      expect(xs1.length, 3);
      a0 = xs1[0];
      a1 = xs1[1];
      a2 = xs1[2];
      expect(a0.offset, 4);
      expect(a1.offset, 14);
      expect(a2.offset, 26);
      expect(a0.helix_idx, 0);
      expect(a1.helix_idx, 0);
      expect(a2.helix_idx, 0);
      expect(a0.forward, false);
      expect(a1.forward, false);
      expect(a2.forward, false);

      var xs2 = design.helix_to_crossover_addresses_disallow_intrahelix_disallow_intergroup[2];
      expect(xs2.length, 0);
    });

    test('minimum_strain_angle_0_10_20_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(0, 0),
        Tuple2<double, double>(10, 0),
        Tuple2<double, double>(20, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 350.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_0_10_50_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(0, 0),
        Tuple2<double, double>(10, 0),
        Tuple2<double, double>(50, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 340.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_0_10_80_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(0, 0),
        Tuple2<double, double>(10, 0),
        Tuple2<double, double>(80, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 330.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_350_0_10_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(350, 0),
        Tuple2<double, double>(0, 0),
        Tuple2<double, double>(10, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 0.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_350_0_40_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(350, 0),
        Tuple2<double, double>(0, 0),
        Tuple2<double, double>(40, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 350.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_350_10_60_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(350, 0),
        Tuple2<double, double>(10, 0),
        Tuple2<double, double>(60, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 340.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_350_10_60_relative_to_0_and_20_0_310_relative_to_10', () {
      var relative_angles = [
        Tuple2<double, double>(350, 0), // -10
        Tuple2<double, double>(10, 0), // 10
        Tuple2<double, double>(60, 0), // 60
        ///////////////////////////////// ave to 20
        Tuple2<double, double>(20, 10), // 10
        Tuple2<double, double>(0, 10), // -10
        Tuple2<double, double>(340, 10), // -30
        ///////////////////////////////// ave to -10
        ///////////////////////////////// total average is (20-10)/2 = 5, so 355 (-5) to correct it
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 355.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_179_181_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(179, 0),
        Tuple2<double, double>(181, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 180.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_181_183_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(181, 0),
        Tuple2<double, double>(183, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 178.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('minimum_strain_angle_174_179_184_relative_to_0', () {
      var relative_angles = [
        Tuple2<double, double>(174, 0),
        Tuple2<double, double>(179, 0),
        Tuple2<double, double>(184, 0),
      ];
      var act_min_strain_angle = util.minimum_strain_angle(relative_angles);
      var exp_min_strain_angle = 181.0;
      expect(act_min_strain_angle, closeTo(exp_min_strain_angle, epsilon));
    });

    test('average_angle_1_359', () {
      var angles = [1.0, 359.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 0.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_10_350', () {
      var angles = [10.0, 350.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 0.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_30_350', () {
      var angles = [30.0, 350.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 10.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_0_10_20', () {
      var angles = [0.0, 10.0, 20.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 10.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_0_0_90', () {
      var angles = [0.0, 0.0, 90.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 30.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_0_45_90', () {
      var angles = [0.0, 45.0, 90.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 45.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_0_10_50', () {
      var angles = [0.0, 10.0, 50.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 20.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_0_10_80', () {
      var angles = [0.0, 10.0, 80.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 30.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_350_0_40', () {
      var angles = [350.0, 0.0, 40.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 10.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_330_40_50', () {
      var angles = [330.0, 40.0, 50.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 20.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });

    test('average_angle_330_40_80', () {
      var angles = [330.0, 40.0, 80.0];
      var act_ave_angle = util.average_angle(angles);
      var exp_ave_angle = 30.0;
      expect(act_ave_angle, closeTo(exp_ave_angle, epsilon));
    });
  });
}
