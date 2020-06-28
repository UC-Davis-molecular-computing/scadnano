import 'dart:convert';

import 'package:scadnano/src/state/dna_design.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/util.dart' as util;

main() {
  test('util_deltas_starting_0', () {
    List<int> nums = [0, 2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [0, 2, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });

  test('util_deltas_starting_positive', () {
    List<int> nums = [2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [2, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });

  test('util_deltas_starting_negative', () {
    List<int> nums = [-5, 2, 3, 5, 7, 11, 13];
    List<int> expected_deltas = [-5, 7, 1, 2, 2, 4, 2];
    List<int> actual_deltas = util.deltas(nums);
    expect(actual_deltas, expected_deltas);
  });

  test('read_old_version_position_x_z_swapped', () {
    String no_grid_two_helices_json = r"""
          {
            "version": "0.8.0",
            "grid": "none",
            "helices": [
              {
                "position": {"x": 10, "y": 60, "z": 30}
              },
              {
                "position": {"x": 20, "y": 80, "z": 50}
              }
            ],
            "strands": [
              {
                "domains": [
                  {"helix": 0, "forward": true , "start": 0, "end": 16}
                ]
              },
              {
                "domains": [
                  {"helix": 0, "forward": false , "start": 0, "end": 16}
                ]
              },
              {
                "domains": [
                  {"helix": 1, "forward": true , "start": 0, "end": 16}
                ]
              },
              {
                "domains": [
                  {"helix": 1, "forward": false , "start": 0, "end": 16}
                ]
              }
            ]
          }
      """;
    DNADesign design = DNADesign.from_json(jsonDecode(no_grid_two_helices_json), false);
    // ensure x and z are swapped after reading in
    //TODO: test for swapping x and z positions in versions < 0.9.0 temporarily disabled until
    // codenano/scadnano versions are aligned
//    expect(design.helices[0].position3d().x, 30);
//    expect(design.helices[0].position3d().y, 60);
//    expect(design.helices[0].position3d().z, 10);
//    expect(design.helices[1].position3d().x, 50);
//    expect(design.helices[1].position3d().y, 80);
//    expect(design.helices[1].position3d().z, 20);
  });


}
