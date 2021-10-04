import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:test/test.dart';

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
        ..grid = Grid.square);
      HelixGroup group_east = HelixGroup.from((b) => b
        ..position.replace(Position3D(x: 10, y: 0, z: 0))
        ..grid = Grid.square);

      Map<String, HelixGroup> groups = {
        e: group_east,
        s: group_south
      };

      Design design = Design(helices: helices, groups: groups);
      design.to_cadnano_v2_json();
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
        ..grid = Grid.square);
      HelixGroup group_east = HelixGroup.from((b) => b
        ..position.replace(Position3D(x: 10, y: 0, z: 0))
        ..grid = Grid.honeycomb);

      Map<String, HelixGroup> groups = {
        e: group_east,
        s: group_south
      };

      Design design = Design(helices: helices, groups: groups);

      try {
        design.to_cadnano_v2_json();
      } on IllegalCadnanoDesignError catch(e) {
        expect(e.cause.contains('helix groups'), true);
      }
    });

    test('test_2_staple_2_helix_origami_extremely_simple', () {
      List<Helix> helices = [Helix(idx: 0, max_offset: 32, grid: Grid.square), Helix(idx: 1, max_offset: 32, grid: Grid.square)];
      Design design = Design(helices:helices, grid:Grid.square);
      design = design.strand(0, 0).move(32).as_scaffold().commit();

      design.to_cadnano_v2_json();
    });

    test('test_2_staple_2_helix_origami_extremely_simple_2', () {
      List<Helix> helices = [Helix(idx: 0, max_offset: 32, grid: Grid.square), Helix(idx: 1, max_offset: 32, grid: Grid.square)];
      Design design = Design(helices:helices, grid:Grid.square);
      design = design.strand(0, 0).move(32).cross(1).move(-32).as_scaffold().commit();

      design.to_cadnano_v2_json();
    });

    test('test_2_staple_2_helix_origami_deletions_insertions', () {
      List<Helix> helices = [
        Helix(idx: 0, max_offset: 24, grid: Grid.square),
        Helix(idx: 1, max_offset: 25, grid: Grid.square),
      ];
      Design design = Design(helices: helices, grid: Grid.square);

      // left staple
      design = design
        .strand(1, 0)
        .move(16)
        .cross(0)
        .move(-16)
        .commit();

      // right staple
      design = design.strand(0, 32).move(-16).cross(1).move(16).commit();

      // scaffold
      design = design.strand(1, 16)
        .move(-16)
        .cross(0)
        .move(32)
        .cross(1)
        .move(-16)
        .as_scaffold()
        // also assigns complement to strands other than scaf bound to it
        // deletions and insertions added to design so they can be added to both strands on a helix
        .with_sequence('AACGT' * 18)
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

      design.to_cadnano_v2_json();
    });
  });
}