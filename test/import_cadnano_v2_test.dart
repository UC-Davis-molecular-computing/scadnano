import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/util.dart';
import 'package:test/test.dart';

import 'utils.dart';

main() {
  group('ImportCadnanoV2', () {
    test('test_32_helix_rectangle', () async {
      String filename = 'cadnano_v2_import/test_32_helix_rectangle.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 35);
    });

    test('test_helices_order', () async {
      String filename = 'cadnano_v2_import/test_helices_order.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 11);
    });

    test('test_huge_hex', () async {
      String filename = 'cadnano_v2_import/test_huge_hex.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 26);
    });
    test('test_Science09_prot120_98_v3', () async {
      String filename = 'cadnano_v2_import/test_Science09_prot120_98_v3.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 19);
    });
    test('test_Nature09_monolith', () async {
      String filename = 'cadnano_v2_import/test_Nature09_monolith.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 60);
    });
    test('test_circular_auto_staple', () async {
      String filename = 'cadnano_v2_import/test_circular_auto_staple.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 8);
    });
    test('test_circular_auto_staple_hex', () async {
      String filename = 'cadnano_v2_import/test_circular_auto_staple_hex.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 6);
    });
    test('test_paranemic_crossover', () async {
      String filename = 'cadnano_v2_import/test_paranemic_crossover.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 4);
    });
    test('test_2_stape_2_helix_origami_deletions_insertions', () async {
      String filename = 'cadnano_v2_import/test_2_stape_2_helix_origami_deletions_insertions.json';
      Design design =
          Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));

      // Recolor for testing purposes
      design = design.rebuild((b) => b..strands.replace(recolor_strands(design.strands)));
      expect(design.helices.length, 2);
      expect(design.grid, Grid.square);
      expect(design.helices[0]?.grid_position, GridPosition(0, 0));
      expect(design.helices[1]?.grid_position, GridPosition(0, 1));
      expect(design.strands.length, 3);

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
      expect(design.strands.contains(stap_left), true);

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
      expect(design.strands.contains(stap_right), true);

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
      expect(design.strands.contains(scaf), true);
    });
  });
}
