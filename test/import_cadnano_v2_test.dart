import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/util.dart';
import 'package:test/test.dart';


main() {
  group('ImportCadnanoV2', () {
    test('test_32_helix_rectangle', () async {
      String filename = 'cadnano_v2_import/test_32_helix_rectangle.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 35);
    });

    test('test_helices_order', () async {
      String filename = 'cadnano_v2_import/test_helices_order.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 11);
    });

    test('test_huge_hex', () async {
      String filename = 'cadnano_v2_import/test_huge_hex.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 26);
    });
    test('test_Science09_prot120_98_v3', () async {
      String filename = 'cadnano_v2_import/test_Science09_prot120_98_v3.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 19);
    });
    test('test_Nature09_monolith', () async {
      String filename = 'cadnano_v2_import/test_Nature09_monolith.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 60);
    });
    test('test_circular_auto_staple', () async {
      String filename = 'cadnano_v2_import/test_circular_auto_staple.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 8);
    });
    test('test_circular_auto_staple_hex', () async {
      String filename = 'cadnano_v2_import/test_circular_auto_staple_hex.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 6);
    });
    test('test_paranemic_crossover', () async {
      String filename = 'cadnano_v2_import/test_paranemic_crossover.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 4);
    });
    test('test_2_stape_2_helix_origami_deletions_insertions', () async {
      String filename = 'cadnano_v2_import/test_2_stape_2_helix_origami_deletions_insertions.json';
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/${filename}'));
      expect(design.helices.length, 2);
    });
  });
}