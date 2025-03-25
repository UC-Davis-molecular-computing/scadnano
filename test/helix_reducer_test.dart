import 'dart:convert';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/reducers/helices_reducer.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/extension.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/reducers/design_reducer.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/extension_methods.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/constants.dart' as constants;
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  group('helix_reducer', () {
    test('change_helix_idx', () {
      var helices = [Helix(idx: 0, grid: Grid.square, grid_position: GridPosition(0, 0))];
      var design = Design(helices: helices, grid: Grid.square);
      design = design.draw_strand(0, 0).extension_5p(5).to(8).commit();
      var state = app_state_from_design(design);

      var strand = state.design.strands[0];
      var ext = strand.substrands[0] as Extension;
      var dom = strand.substrands[1] as Domain;
      expect(ext.adjacent_domain, dom);
      expect(ext.adjacent_domain.helix, 0);
      expect(dom.helix, 0);

      var action = actions.HelixIdxsChange(idx_replacements: {0: 1});
      state = app_state_reducer(state, action);

      strand = state.design.strands[0];
      ext = strand.substrands[0] as Extension;
      dom = strand.substrands[1] as Domain;
      expect(ext.adjacent_domain, dom);
      expect(ext.adjacent_domain.helix, 1);
      expect(dom.helix, 1);
    });

    test('change_helix_idx_with_nondefault_helices_view_order', () {
      var helices = [
        for (int i = 0; i < 3; i++) Helix(idx: i, grid: Grid.square, grid_position: GridPosition(0, i))
      ];
      var groups = {
        "default_group": HelixGroup(helices_view_order: [2, 1, 0], grid: Grid.square),
      };
      var design = Design(helices: helices, grid: Grid.square, groups: groups);
      var state = app_state_from_design(design);

      var action = actions.HelixIdxsChange(idx_replacements: {2: 3});
      state = app_state_reducer(state, action);

      expect(state.design.default_group().helices_view_order.toList(), [3, 1, 0]);
    });
  });
}
