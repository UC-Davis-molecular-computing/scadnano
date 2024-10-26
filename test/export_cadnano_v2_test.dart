import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/middleware/export_cadnano_file.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/util.dart';
import 'package:test/test.dart';

import 'utils.dart';

main() {
  group('ExportCadnanoV2', () {
    test('test_export_design_with_helix_group', () {
      String e = 'east';
      String s = 'south';
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 24, group: s, grid: Grid.square),
        Helix(idx: 1, max_offset: 25, group: s, grid: Grid.square),
      ];
      helices.addAll([
        Helix(idx: 2, max_offset: 22, group: e, grid: Grid.square),
        Helix(idx: 3, max_offset: 23, group: e, grid: Grid.square),
      ]);

      HelixGroup group_south = HelixGroup.from((b) => b
        ..position.replace(Position3D(x: 0, y: 10, z: 0))
        ..grid = Grid.square
        ..helices_view_order = ListBuilder([0, 1]));
      HelixGroup group_east = HelixGroup.from((b) => b
        ..position.replace(Position3D(x: 10, y: 0, z: 0))
        ..grid = Grid.square
        ..helices_view_order = ListBuilder([2, 3]));

      Map<String, HelixGroup> groups = {e: group_east, s: group_south};

      Design design = Design(helices: helices, groups: groups);
      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 4);
    });

    test('test_export_design_with_helix_group_not_same_grid', () {
      String e = 'east';
      String s = 'south';
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 24, group: s, grid: Grid.square),
        Helix(idx: 1, max_offset: 25, group: s, grid: Grid.square),
      ];
      helices.addAll([
        Helix(idx: 2, max_offset: 22, group: e, grid: Grid.honeycomb),
        Helix(idx: 3, max_offset: 23, group: e, grid: Grid.honeycomb),
      ]);

      HelixGroup group_south = HelixGroup.from((b) => b
        ..position.replace(Position3D(x: 0, y: 10, z: 0))
        ..grid = Grid.square
        ..helices_view_order = ListBuilder([0, 1]));
      HelixGroup group_east = HelixGroup.from((b) => b
        ..position.replace(Position3D(x: 10, y: 0, z: 0))
        ..grid = Grid.honeycomb
        ..helices_view_order = ListBuilder([2, 3]));

      Map<String, HelixGroup> groups = {e: group_east, s: group_south};

      Design design = Design(helices: helices, groups: groups);

      try {
        to_cadnano_v2_json(design);
      } on IllegalCadnanoDesignError catch (e) {
        expect(e.cause.contains('helix groups'), true);
        return;
      }

      throw new Exception("Expected IllegalCadnanoDesignError");
    });

    test('test_2_staple_2_helix_origami_extremely_simple', () {
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 32, grid: Grid.square),
        Helix(idx: 1, max_offset: 32, grid: Grid.square)
      ];
      Design design = Design(helices: helices, grid: Grid.square);
      design = design.draw_strand(0, 0).move(32).as_scaffold().commit();

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 2);
    });

    test('test_2_staple_2_helix_origami_extremely_simple_2', () {
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 32, grid: Grid.square),
        Helix(idx: 1, max_offset: 32, grid: Grid.square)
      ];
      Design design = Design(helices: helices, grid: Grid.square);
      design = design.draw_strand(0, 0).move(32).cross(1).move(-32).as_scaffold().commit();

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 2);
    });

    test('test_2_staple_2_helix_origami_deletions_insertions', () {
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 24, grid: Grid.square),
        Helix(idx: 1, max_offset: 25, grid: Grid.square),
      ];
      Design design = Design(helices: helices, grid: Grid.square);

      // left staple
      design = design.draw_strand(1, 0).move(16).cross(0).move(-16).commit();

      // right staple
      design = design.draw_strand(0, 32).move(-16).cross(1).move(16).commit();

      // scaffold
      design = design
          .draw_strand(1, 16)
          .move(-16)
          .cross(0)
          .move(32)
          .cross(1)
          .move(-16)
          .as_scaffold()
          // also assigns complement to strands other than scaf bound to it
          .with_sequence('AACGT' * 18)
          // deletions and insertions added to design so they can be added to both strands on a helix
          .add_deletion(0, 11)
          .add_deletion(0, 12)
          .add_deletion(0, 24)
          .add_deletion(1, 12)
          .add_deletion(1, 24)
          .add_insertion(0, 6, 1)
          .add_insertion(0, 18, 2)
          .add_insertion(1, 6, 3)
          .add_insertion(1, 18, 4)
          .commit();

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      // Recolor for testing purposes
      output_design = output_design.rebuild((b) => b.strands.replace(recolor_strands(output_design.strands)));

      expect(output_design.helices.length, 2);
      expect(output_design.grid, Grid.square);
      expect(output_design.helices[0]?.grid_position, GridPosition(0, 0));
      expect(output_design.helices[1]?.grid_position, GridPosition(0, 1));
      expect(output_design.strands.length, 3);

      //left staple
      Domain stap_left_ss1 = Domain(
          helix: 1,
          forward: true,
          start: 0,
          end: 16,
          deletions: [12],
          insertions: [Insertion(6, 3)],
          is_scaffold: false);
      Domain stap_left_ss0 = Domain(
          helix: 0,
          forward: false,
          start: 0,
          end: 16,
          deletions: [11, 12],
          insertions: [Insertion(6, 1)],
          is_scaffold: false);
      Strand stap_left = recolor_strand(Strand([stap_left_ss1, stap_left_ss0]));
      expect(output_design.strands.contains(stap_left), true);

      // # right staple
      Domain stap_right_ss0 = Domain(
          helix: 0,
          forward: false,
          start: 16,
          end: 32,
          deletions: [24],
          insertions: [Insertion(18, 2)],
          is_scaffold: false);
      Domain stap_right_ss1 = Domain(
          helix: 1,
          forward: true,
          start: 16,
          end: 32,
          deletions: [24],
          insertions: [Insertion(18, 4)],
          is_scaffold: false);
      Strand stap_right = recolor_strand(Strand([stap_right_ss0, stap_right_ss1]));
      expect(output_design.strands.contains(stap_right), true);

      // # scaffold
      Domain scaf_ss1_left = Domain(
          helix: 1,
          forward: false,
          start: 0,
          end: 16,
          deletions: [12],
          insertions: [Insertion(6, 3)],
          is_scaffold: true);
      Domain scaf_ss0 = Domain(
          helix: 0,
          forward: true,
          start: 0,
          end: 32,
          deletions: [11, 12, 24],
          insertions: [Insertion(6, 1), Insertion(18, 2)],
          is_scaffold: true);
      Domain scaf_ss1_right = Domain(
          helix: 1,
          forward: false,
          start: 16,
          end: 32,
          deletions: [24],
          insertions: [Insertion(18, 4)],
          is_scaffold: true);
      Strand scaf = recolor_strand(Strand([scaf_ss1_left, scaf_ss0, scaf_ss1_right], is_scaffold: true));
      expect(output_design.strands.contains(scaf), true);
    });

    test('test_6_helix_origami_rectangle', () async {
      String filename = 'test_6_helix_origami_rectangle.sc';
      Design design = Design.from_json_str(
          await get_text_file_content('../test/tests_inputs/cadnano_v2_export/${filename}'))!;

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 6);
    });

    test('test_6_helix_bundle_honeycomb', () async {
      String filename = 'test_6_helix_bundle_honeycomb.sc';
      Design design = Design.from_json_str(
          await get_text_file_content('../test/tests_inputs/cadnano_v2_export/${filename}'))!;

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 6);
    });

    test('test_16_helix_origami_rectangle_no_twist', () async {
      String filename = 'test_16_helix_origami_rectangle_no_twist.sc';
      Design design = Design.from_json_str(
          await get_text_file_content('../test/tests_inputs/cadnano_v2_export/${filename}'))!;

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 16);
    });

    test('test_circular_strand', () {
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 24, grid: Grid.square),
        Helix(idx: 1, max_offset: 24, grid: Grid.square),
      ];
      Design design = Design(helices: helices, grid: Grid.square);

      design.draw_strand(1, 0).move(8).cross(0).move(-8).as_circular().commit();
      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 2);
    });

    test('test_big_circular_staples_hex', () async {
      String filename = 'test_big_circular_staples_hex.sc';
      Design design = Design.from_json_str(
          await get_text_file_content('../test/tests_inputs/cadnano_v2_export/${filename}'))!;

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 6);
    });

    test('test_big_circular_staples', () async {
      String filename = 'test_big_circular_staples.sc';
      Design design = Design.from_json_str(
          await get_text_file_content('../test/tests_inputs/cadnano_v2_export/${filename}'))!;

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 8);
    });

    test('test_paranemic_crossover', () async {
      String filename = 'test_paranemic_crossover.sc';
      Design design = Design.from_json_str(
          await get_text_file_content('../test/tests_inputs/cadnano_v2_export/${filename}'))!;

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 4);
    });

    test('test_paranemic_crossover_other_direction', () async {
      var helices = [
        Helix(idx: 1, max_offset: 64, grid_position: GridPosition(19, 14), grid: Grid.square),
        Helix(idx: 0, max_offset: 64, grid_position: GridPosition(19, 15), grid: Grid.square),
        Helix(idx: 3, max_offset: 64, grid_position: GridPosition(19, 16), grid: Grid.square),
        Helix(idx: 2, max_offset: 64, grid_position: GridPosition(19, 17), grid: Grid.square),
      ];
      var design = Design(helices: helices);
      design = design.draw_strand(3, 24).to(8).cross(1, 24).to(8).commit();
      design = design.draw_strand(2, 50).to(24).cross(0, 50).to(24).commit();

      String output_json = to_cadnano_v2_json(design);
      Design output_design = Design.from_cadnano_v2_json_str(output_json);
      expect(output_design.helices.length, 4);
    });

    // We do not handle Loopouts and design where the parity of the helix
    // does not correspond to the direction.
    test('test_parity_issue', () {
      // Bad case one: parity issue in design (see cadnano v2 format spec, v2.txt)
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 32, grid: Grid.square),
        Helix(idx: 1, max_offset: 32, grid: Grid.square),
      ];
      Design design = Design(helices: helices, grid: Grid.square);
      design = design.draw_strand(1, 0).move(32).as_scaffold().commit();

      try {
        to_cadnano_v2_json(design);
      } on IllegalCadnanoDesignError catch (e) {
        expect(e.cause.contains('forward'), true);
        return;
      }
      throw new Exception("Expected IllegalCadnanoDesignError");
    });

    test('test_loopout', () {
      // Bad case one: loopout
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 48, grid: Grid.square),
        Helix(idx: 1, max_offset: 48, grid: Grid.square),
      ];
      Design design = Design(helices: helices, grid: Grid.square);

      // left staple
      design = design.draw_strand(1, 8).move(16).cross(0).move(-16).commit();

      // right staple
      design = design.draw_strand(0, 40).move(-16).cross(1).move(16).commit();

      // scaffold
      design = design
          .draw_strand(1, 24)
          .move(-16)
          .cross(0)
          .move(32)
          .loopout(1, 3)
          .move(-16)
          .as_scaffold()
          // also assigns complement to strands other than scaf bound to it
          .with_sequence('AACGT' * 18)
          // deletions and insertions added to design so they can be added to both strands on a helix
          .add_deletion(1, 20)
          .add_insertion(0, 14, 1)
          .add_insertion(0, 26, 2)
          .commit();

      try {
        to_cadnano_v2_json(design);
      } on IllegalCadnanoDesignError catch (e) {
        expect(e.cause.contains('Loopouts'), true);
        return;
      }
      throw new Exception("Expected IllegalCadnanoDesignError");
    });
  });
}
