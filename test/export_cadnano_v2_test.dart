import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/position3d.dart';
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
  });
}