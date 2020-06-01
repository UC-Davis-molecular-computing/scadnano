import 'package:test/test.dart';

import 'package:scadnano/src/util.dart' as util;

main() {
  test('util.deltas starting 0', () {
    List<int> nums = [0, 2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [0, 2, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });

  test('util.deltas starting positive', () {
    List<int> nums = [2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [2, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });

  test('util.deltas starting negative', () {
    List<int> nums = [-5, 2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [-5, 7, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });
}
