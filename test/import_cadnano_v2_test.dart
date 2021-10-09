import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/util.dart';
import 'package:test/test.dart';


main() {
  group('ImportCadnanoV2', () {
    test('test_32_helix_rectangle', () async {
      Design design = Design.from_cadnano_v2_json_str(await get_text_file_content('../test/tests_inputs/cadnano_v2_import/test_32_helix_rectangle.json'));
      expect(design.helices.length, 35);
    });
  });
}