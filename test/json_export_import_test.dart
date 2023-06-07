// @dart=2.9

import 'dart:convert';

import 'package:color/color.dart';
import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/reducers/assign_or_remove_dna_reducer.dart';
import 'package:scadnano/src/reducers/change_loopout_ext_properties.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/reducers/assign_domain_names_reducer.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/dna_assign_options.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  group('JSON export/import', () {
    test('simple_design_domain_and_strand_colors', () {
      var helices = [for (int idx = 0; idx < 4; idx++) Helix(idx: idx, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      var ext_5p_color = Color.rgb(0, 0, 0);
      var dom1_color = Color.rgb(1, 0, 0);
      var dom2_color = Color.rgb(2, 0, 0);
      var loop_color = Color.rgb(3, 0, 0);
      Color dom3_color = null;
      var ext_3p_color = Color.rgb(4, 0, 0);
      var strand_color = Color.rgb(5, 0, 0);
      design = design
          .draw_strand(0, 0)
          .extension_5p(5)
          .with_domain_color(ext_5p_color)
          .move(8)
          .with_domain_color(dom1_color)
          .cross(1)
          .move(-8)
          .with_domain_color(dom2_color)
          .loopout(2, 5)
          .with_domain_color(loop_color)
          .move(8)
          .extension_3p(5)
          .with_domain_color(ext_3p_color)
          .with_color(strand_color)
          .commit();

      var design_json = design.to_json_serializable();
      // print(design_json);
      design = Design.from_json(design_json);
      expect(design.strands.length, 1);
      var strand = design.strands[0];
      expect(strand.substrands.length, 6);
      var ext_5p = strand.substrands[0];
      var dom1 = strand.substrands[1];
      var dom2 = strand.substrands[2];
      var loop = strand.substrands[3];
      var dom3 = strand.substrands[4];
      var ext_3p = strand.substrands[5];

      expect(ext_5p.color, ext_5p_color);
      expect(dom1.color, dom1_color);
      expect(dom2.color, dom2_color);
      expect(loop.color, loop_color);
      expect(dom3.color, dom3_color);
      expect(ext_3p.color, ext_3p_color);
      expect(strand.color, strand_color);
    });

    test('loopout_name', () {
      var helices = [for (int idx = 0; idx < 4; idx++) Helix(idx: idx, max_offset: 100, grid: Grid.square)];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(8)
          .with_domain_name('dom1')
          .loopout(1, 5)
          .with_domain_name('loop')
          .with_domain_label('loop label')
          .move(-8)
          .with_domain_name('dom2')
          .commit();

      var design_json = design.to_json_serializable();
      // print(design_json);
      design = Design.from_json(design_json);
      expect(design.strands.length, 1);
      var strand = design.strands[0];
      expect(strand.substrands.length, 3);
      var dom1 = strand.substrands[0];
      var loop = strand.substrands[1];
      var dom2 = strand.substrands[2];

      expect(dom1.name, 'dom1');
      expect(loop.name, 'loop');
      expect(loop.label, 'loop label');
      expect(dom2.name, 'dom2');
    });
  });
}
