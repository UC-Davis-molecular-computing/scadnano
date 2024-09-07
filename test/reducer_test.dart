// @dart=2.9
// import 'dart:convert';
// import 'dart:io';

import 'dart:math';
import 'dart:convert';
import 'dart:html';

import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:test/test.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';

import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/reducers/potential_crossover_reducer.dart';
import 'package:scadnano/src/reducers/selection_reducer.dart';
import 'package:scadnano/src/state/address.dart';
import 'package:scadnano/src/state/crossover.dart';
import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/dna_ends_move.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:scadnano/src/state/potential_crossover.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:scadnano/src/state/select_mode_state.dart';
import 'package:scadnano/src/state/selectable.dart';
import 'package:scadnano/src/state/selection_box.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/strands_move.dart';
import 'package:scadnano/src/state/undo_redo.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/mouseover_data.dart';
import 'package:scadnano/src/extension_methods.dart';
import 'package:scadnano/src/util.dart' as util;
import 'package:scadnano/src/constants.dart' as constants;

import 'utils.dart';

main() {
  test('read in color specified as decimal', () {
    // addresses https://github.com/UC-Davis-molecular-computing/scadnano/issues/271
    // 0066cc hex is 26316 decimal
    String json_str = r'''
    { 
      "grid": "square",
      "helices": [{"grid_position": [0,0]}],
      "strands": [ 
        { 
          "color": 26316, 
          "substrands": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
        } 
      ] 
    }
    ''';
    Design design = Design.from_json(jsonDecode(json_str));
    Strand strand = design.strands.first;
    Color color = strand.color;
    String color_str = color.toHexColor().toCssString();
    expect(color_str, "#0066cc");
  });

  test('position_specified_with_origin_keyword', () {
    // addresses https://github.com/UC-Davis-molecular-computing/scadnano/issues/271
    // 0066cc hex is 26316 decimal
    String json_str = r'''
    { 
      "grid": "none",
      "helices": [{
        "position": { 
          "origin": { "x": 1, "y": 2, "z": 3}, 
          "pitch": 4, 
          "roll": 5, 
          "yaw": 6
        } 
      }],
      "strands": [ 
        { 
          "color": "#0066cc", 
          "substrands": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
        } 
      ] 
    }
    ''';
    /*
    d = sc.DNADesign.from_scadnano_json_str(json_str)
    expected_position = sc.Position3D(1,2,3,4,5,6)
    actual_position = d.helices[0].position3d
    self.assertEqual(expected_position, actual_position)
     */
    Design design = Design.from_json(jsonDecode(json_str), false);
    var expected_position = Position3D(x: 1, y: 2, z: 3);
    var actual_position = design.helices[0].position3d;
    expect(actual_position, expected_position);
  });

  test('position specified no origin keyword', () {
    // addresses https://github.com/UC-Davis-molecular-computing/scadnano/issues/271
    // 0066cc hex is 26316 decimal
    String json_str = r'''
    { 
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
      "grid": "none",
      "helices": [{
        "position": { 
          "x": 1, 
          "y": 2, 
          "z": 3, 
          "pitch": 4, 
          "roll": 5, 
          "yaw": 6
        } 
      }],
      "strands": [ 
        { 
          "color": "#0066cc", 
          "substrands": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
        } 
      ] 
    }
    ''';
    /*
    d = sc.DNADesign.from_scadnano_json_str(json_str)
    expected_position = sc.Position3D(1,2,3,4,5,6)
    actual_position = d.helices[0].position3d
    self.assertEqual(expected_position, actual_position)
     */
    Design design = Design.from_json(jsonDecode(json_str), false);
    var expected_position = Position3D(x: 1, y: 2, z: 3);
    var actual_position = design.helices[0].position3d;
    expect(actual_position, expected_position);
  });

  test('position specified with origin keyword directly in Helix', () {
    // addresses https://github.com/UC-Davis-molecular-computing/scadnano/issues/271
    // 0066cc hex is 26316 decimal
    String json_str = r'''
    { 
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
      "grid": "none",
      "helices": [{ 
          "origin": { "x": 1, "y": 2, "z": 3}, 
          "pitch": 4, 
          "roll": 5, 
          "yaw": 6 
      }],
      "strands": [ 
        { 
          "color": "#0066cc", 
          "substrands": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
        } 
      ] 
    }
    ''';
    /*
    d = sc.DNADesign.from_scadnano_json_str(json_str)
    expected_position = sc.Position3D(1,2,3,4,5,6)
    actual_position = d.helices[0].position3d
    self.assertEqual(expected_position, actual_position)
     */
    Design design = Design.from_json(jsonDecode(json_str), false);
    var expected_position = Position3D(x: 1, y: 2, z: 3);
    var actual_position = design.helices[0].position3d;
    expect(actual_position, expected_position);
  });

  test('position specified without origin keyword directly in Helix', () {
    // addresses https://github.com/UC-Davis-molecular-computing/scadnano/issues/271
    // 0066cc hex is 26316 decimal
    String json_str = r'''
    { 
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
      "grid": "none",
      "helices": [{ 
          "x": 1, 
          "y": 2, 
          "z": 3, 
          "pitch": 4, 
          "roll": 5, 
          "yaw": 6 
      }],
      "strands": [ 
        { 
          "color": "#0066cc", 
          "substrands": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
        } 
      ] 
    }
    ''';
    /*
    d = sc.DNADesign.from_scadnano_json_str(json_str)
    expected_position = sc.Position3D(1,2,3,4,5,6)
    actual_position = d.helices[0].position3d
    self.assertEqual(expected_position, actual_position)
     */
    Design design = Design.from_json(jsonDecode(json_str), false);
    var expected_position = Position3D(x: 1, y: 2, z: 3);
    var actual_position = design.helices[0].position3d;
    expect(actual_position, expected_position);
  });

  test('should_add_helix_in_response_to_HelixAdd', () {
    var state = util.default_state(grid: Grid.square);
    final grid_position = new GridPosition(5, 10);

    state = app_state_reducer(state, new HelixAdd(grid_position: grid_position));

    var geometry = state.design.geometry;
    final correct_helix =
        new Helix(grid_position: grid_position, idx: 0, grid: Grid.square, geometry: geometry);
    expect(state.design.helices, BuiltMap<int, Helix>({correct_helix.idx: correct_helix}));
  });

  test('should_remove_helix_in_response_to_HelixRemove', () {
    var state = util.default_state(grid: Grid.square);
    final grid_position = new GridPosition(5, 10);

    state = app_state_reducer(state, new HelixAdd(grid_position: grid_position));
    state = app_state_reducer(state, new HelixRemove(0));

    var correct_helices = BuiltMap<int, Helix>();
    expect(state.design.helices, correct_helices);
  });

  String simple_strand = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 24}
      ]
    }
  ]
} 
  ''';
  Design design_simple_strand = Design.from_json(jsonDecode(simple_strand));

  //     before
  //     0        8              24
  // 0   [------------------------>

  //     after
  //     0        8              24
  // 0   [------> [--------------->
  test('test add nick on substrand', () {
    String content_after = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 8, "end": 24}
      ]
    }
  ]
} 
  ''';
    var state = app_state_from_design(design_simple_strand);

    Domain substrand = design_simple_strand.strands[0].substrands[0] as Domain;
    state = app_state_reducer(state, Nick(domain: substrand, offset: 8));

    Design expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);
  });

  //     before
  //     0        8       16     24
  // 0   [------------------------>

  //     after
  //     0        8        16      24
  // 0   [------> [------> [------->
  test('test add two nicks on substrand', () {
    String content_after = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 8, "end": 16}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 16, "end": 24}
      ]
    }
  ]
} 
  ''';
    AppState state = app_state_from_design(design_simple_strand);

    Domain nicked_substrand1 = design_simple_strand.strands[0].substrands[0] as Domain;
    state = app_state_reducer(state, Nick(domain: nicked_substrand1, offset: 8));
    Domain nicked_substrand2 = state.design.strands[1].substrands[0] as Domain;
    state = app_state_reducer(state, Nick(domain: nicked_substrand2, offset: 16));

    Design expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);
  });

  //     ACGTACGA AACCGGTA
  // 0   [------- ------->
  //     <------- -------]
  //     TTTGGGCC AAACCCGG
  String smaller_design_h0_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "sequence": "ACGTACGAAACCGGTA",
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "GGCCCAAACCGGGTTT",
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
} 
  ''';
  Design small_design_h0 = Design.from_json(jsonDecode(smaller_design_h0_json));

  //     ACGTACGA AACCGGTA
  // 0   [------> [------>
  //     <------- -------]
  //     TTTGGGCC AAACCCGG
  test('test add nick small_design_h0 forward', () {
    String content_after = '''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "sequence": "ACGTACGA",
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "sequence": "AACCGGTA",
      "domains": [
        {"helix": 0, "forward": true, "start": 8, "end": 16}
      ]
    },
    {
      "sequence": "GGCCCAAACCGGGTTT",
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
} 
    ''';

    AppState state = app_state_from_design(small_design_h0);

    Domain nicked_substrand = small_design_h0.strands[0].substrands[0] as Domain;
    state = app_state_reducer(state, Nick(domain: nicked_substrand, offset: 8));

    Design expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);
  });

  //     0        8        16
  //     ACGTACGA AACCGGTA
  // 0   [------- ------->
  //     <------] <------]
  //     TTTGGGCC AAACCCGG
  test('test add nick small_design_h0 reverse', () {
    String content_after = '''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "sequence": "ACGTACGAAACCGGTA",
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "CCGGGTTT",
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "sequence": "GGCCCAAA",
      "domains": [
        {"helix": 0, "forward": false, "start": 8, "end": 16}
      ]
    }
  ]
} 
    ''';
    AppState state = app_state_from_design(small_design_h0);

    Domain nicked_substrand = small_design_h0.strands[1].substrands[0] as Domain;
    state = app_state_reducer(state, Nick(domain: nicked_substrand, offset: 8));

    Design expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);
  });

// 6_helix_rectangle
//     0        8        16       24       32       40       48       56       64       72       80       88       96
// 0   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------]

// 1   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------]

// 2   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------]

// 3   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------]

// 4   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------]

// 5   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------]
  String six_helix_rectangle_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]},
    {"grid_position": [0, 1]},
    {"grid_position": [0, 2]},
    {"grid_position": [0, 3]},
    {"grid_position": [0, 4]},
    {"grid_position": [0, 5]}
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 3, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 3, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": false, "start": 0, "end": 96}
      ]
    }
  ]
 }
  ''';
  Design six_helix_rectangle = Design.from_json(jsonDecode(six_helix_rectangle_json));

//     0        8        16       24       32       40       48       56       64       72       80       88       96
// 0   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------] <------- -------- -------- -------] <------- -------- -------]

// 1   [------- -------- -------> [------- -------- -------- -------> [------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------]

// 2   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------] <------- -------- -------- -------] <------- -------- -------]

// 3   [------- -------- -------> [------- -------- -------- -------> [------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------]

// 4   [------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------] <------- -------- -------- -------] <------- -------- -------]

// 5   [------- -------- -------> [------- -------- -------- -------> [------- -------- -------- -------- ------->
//     <------- -------- -------- -------- -------- -------] <------- -------- -------- -------- -------- -------]
  test("test add nick on six_helix_rectangle", () {
    AppState state = app_state_from_design(six_helix_rectangle);

    // design.add_nick(helix=5, offset=48, forward=False)
    Domain h5_reverse = six_helix_rectangle.strands[11].substrands[0];
    state = app_state_reducer(state, Nick(domain: h5_reverse, offset: 48));

    String h5_after_nick_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0], "max_offset": 100},
    {"grid_position": [0, 1], "max_offset": 100},
    {"grid_position": [0, 2], "max_offset": 100},
    {"grid_position": [0, 3], "max_offset": 100},
    {"grid_position": [0, 4], "max_offset": 100},
    {"grid_position": [0, 5], "max_offset": 100}
  ],
  "strands": [
    {
      "domains": [
        {"helix": 5, "forward": false, "start": 48, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": false, "start": 0, "end": 48}
      ]
    }
  ]
 }
  ''';
    Design h5_after_nick1 = Design.from_json(jsonDecode(h5_after_nick_json));
    Strand h5_96_reverse = h5_after_nick1.strands[0];
    Strand h5_48_reverse = h5_after_nick1.strands[1];

    expect(recolor_strands(state.design.strands).contains(h5_96_reverse), true);
    expect(recolor_strands(state.design.strands).contains(h5_48_reverse), true);

    // design.add_nick(helix=0, offset=40, forward=False)
    Domain h0_reverse = six_helix_rectangle.strands[1].substrands[0];
    state = app_state_reducer(state, Nick(domain: h0_reverse, offset: 40));
    String h0_after_nick_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
  "grid": "square", 
  "helices": [ 
    {"grid_position": [0, 0]}, 
    {"grid_position": [0, 1]}, 
    {"grid_position": [0, 2]}, 
    {"grid_position": [0, 3]}, 
    {"grid_position": [0, 4]}, 
    {"grid_position": [0, 5]} 
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 40, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 40}
      ]
    }
  ]
 }
  ''';
    Design h0_after_nick2 = Design.from_json(jsonDecode(h0_after_nick_json));
    Strand h0_96_reverse = h0_after_nick2.strands[0];
    Strand h0_40_reverse = h0_after_nick2.strands[1];
    expect(recolor_strands(state.design.strands).contains(h0_96_reverse), true);
    expect(recolor_strands(state.design.strands).contains(h0_40_reverse), true);

    // design.add_nick(helix=0, offset=72, forward=False)
    Domain h0_reverse_for_nick3 = h0_96_reverse.substrands[0];
    state = app_state_reducer(state, Nick(domain: h0_reverse_for_nick3, offset: 72));
    String h0_after_nick3_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 72, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h0_after_nick3 = Design.from_json(jsonDecode(h0_after_nick3_json));
    Strand h0_40_72_reverse = h0_after_nick3.strands[0];
    Strand h0_72_96_reverse = h0_after_nick3.strands[1];
    expect(recolor_strands(state.design.strands).contains(h0_40_72_reverse), true);
    expect(recolor_strands(state.design.strands).contains(h0_72_96_reverse), true);
    // design.add_nick(helix=2, offset=40, forward=False)
    Domain h2_reverse_for_nick4 = six_helix_rectangle.strands[5].substrands[0];
    state = app_state_reducer(state, Nick(domain: h2_reverse_for_nick4, offset: 40));
    String h2_after_nick4_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 2, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": false, "start": 40, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h2_after_nick4 = Design.from_json(jsonDecode(h2_after_nick4_json));
    Strand h2_00_40_reverse = h2_after_nick4.strands[0];
    Strand h2_40_96_reverse = h2_after_nick4.strands[1];
    expect(recolor_strands(state.design.strands).contains(h2_00_40_reverse), true);
    expect(recolor_strands(state.design.strands).contains(h2_40_96_reverse), true);
    // design.add_nick(helix=2, offset=72, forward=False)
    Domain h2_reverse_for_nick5 = h2_40_96_reverse.substrands[0];
    state = app_state_reducer(state, Nick(domain: h2_reverse_for_nick5, offset: 72));
    String h2_after_nick5_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 2, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": false, "start": 72, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h2_after_nick5 = Design.from_json(jsonDecode(h2_after_nick5_json));
    Strand h2_40_72_reverse = h2_after_nick5.strands[0];
    Strand h2_72_96_reverse = h2_after_nick5.strands[1];
    expect(recolor_strands(state.design.strands).contains(h2_40_72_reverse), true);
    expect(recolor_strands(state.design.strands).contains(h2_72_96_reverse), true);
    // design.add_nick(helix=4, offset=40, forward=False)
    Domain h4_reverse_for_nick6 = six_helix_rectangle.strands[9].substrands[0];
    state = app_state_reducer(state, Nick(domain: h4_reverse_for_nick6, offset: 40));
    String h4_after_nick6_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 4, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": false, "start": 40, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h4_after_nick6 = Design.from_json(jsonDecode(h4_after_nick6_json));
    Strand h4_00_40_reverse = h4_after_nick6.strands[0];
    Strand h4_40_96_reverse = h4_after_nick6.strands[1];
    expect(recolor_strands(state.design.strands).contains(h4_00_40_reverse), true);
    expect(recolor_strands(state.design.strands).contains(h4_40_96_reverse), true);
    // design.add_nick(helix=4, offset=72, forward=False)
    Domain h4_reverse_for_nick7 = h4_40_96_reverse.substrands[0];
    state = app_state_reducer(state, Nick(domain: h4_reverse_for_nick7, offset: 72));
    String h4_after_nick7_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 4, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": false, "start": 72, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h4_after_nick7 = Design.from_json(jsonDecode(h4_after_nick7_json));
    Strand h4_40_72_reverse = h4_after_nick7.strands[0];
    Strand h4_72_96_reverse = h4_after_nick7.strands[1];
    expect(recolor_strands(state.design.strands).contains(h4_40_72_reverse), true);
    expect(recolor_strands(state.design.strands).contains(h4_72_96_reverse), true);
    // design.add_nick(helix=1, offset=24, forward=True)
    Domain h1_forward_for_nick8 = six_helix_rectangle.strands[2].substrands[0];
    state = app_state_reducer(state, Nick(domain: h1_forward_for_nick8, offset: 24));
    String h1_after_nick8_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 1, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": true, "start": 24, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h1_after_nick8 = Design.from_json(jsonDecode(h1_after_nick8_json));
    Strand h1_00_24_forward = h1_after_nick8.strands[0];
    Strand h1_24_96_forward = h1_after_nick8.strands[1];
    expect(recolor_strands(state.design.strands).contains(h1_00_24_forward), true);
    expect(recolor_strands(state.design.strands).contains(h1_24_96_forward), true);
    // design.add_nick(helix=1, offset=56, forward=True)
    Domain h1_forward_for_nick9 = h1_24_96_forward.substrands[0];
    state = app_state_reducer(state, Nick(domain: h1_forward_for_nick9, offset: 56));
    String h1_after_nick9_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 1, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": true, "start": 56, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h1_after_nick9 = Design.from_json(jsonDecode(h1_after_nick9_json));
    Strand h1_24_56_forward = h1_after_nick9.strands[0];
    Strand h1_56_96_forward = h1_after_nick9.strands[1];
    expect(recolor_strands(state.design.strands).contains(h1_24_56_forward), true);
    expect(recolor_strands(state.design.strands).contains(h1_56_96_forward), true);
    // design.add_nick(helix=3, offset=24, forward=True)
    Domain h3_forward_for_nick10 = six_helix_rectangle.strands[6].substrands[0];
    state = app_state_reducer(state, Nick(domain: h3_forward_for_nick10, offset: 24));
    String h3_after_nick10_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 3, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "domains": [
        {"helix": 3, "forward": true, "start": 24, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h3_after_nick10 = Design.from_json(jsonDecode(h3_after_nick10_json));
    Strand h3_00_24_forward = h3_after_nick10.strands[0];
    Strand h3_24_96_forward = h3_after_nick10.strands[1];
    expect(recolor_strands(state.design.strands).contains(h3_00_24_forward), true);
    expect(recolor_strands(state.design.strands).contains(h3_24_96_forward), true);
    // design.add_nick(helix=3, offset=56, forward=True)
    Domain h3_forward_for_nick11 = h3_24_96_forward.substrands[0];
    state = app_state_reducer(state, Nick(domain: h3_forward_for_nick11, offset: 56));
    String h3_after_nick11_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 3, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "domains": [
        {"helix": 3, "forward": true, "start": 56, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h3_after_nick11 = Design.from_json(jsonDecode(h3_after_nick11_json));
    Strand h3_24_56_forward = h3_after_nick11.strands[0];
    Strand h3_56_96_forward = h3_after_nick11.strands[1];
    expect(recolor_strands(state.design.strands).contains(h3_24_56_forward), true);
    expect(recolor_strands(state.design.strands).contains(h3_56_96_forward), true);
    // design.add_nick(helix=5, offset=24, forward=True)
    Domain h5_forward_for_nick12 = six_helix_rectangle.strands[10].substrands[0];
    state = app_state_reducer(state, Nick(domain: h5_forward_for_nick12, offset: 24));
    String h5_after_nick12_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 5, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": true, "start": 24, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h5_after_nick12 = Design.from_json(jsonDecode(h5_after_nick12_json));
    Strand h5_00_24_forward = h5_after_nick12.strands[0];
    Strand h5_24_96_forward = h5_after_nick12.strands[1];
    expect(recolor_strands(state.design.strands).contains(h5_00_24_forward), true);
    expect(recolor_strands(state.design.strands).contains(h5_24_96_forward), true);
    // design.add_nick(helix=5, offset=56, forward=True)
    Domain h5_forward_for_nick13 = h5_24_96_forward.substrands[0];
    state = app_state_reducer(state, Nick(domain: h5_forward_for_nick13, offset: 56));
    String h5_after_nick13_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "domains": [
        {"helix": 5, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": true, "start": 56, "end": 96}
      ]
    }
  ]
 }
  ''';
    Design h5_after_nick13 = Design.from_json(jsonDecode(h5_after_nick13_json));
    Strand h5_24_56_forward = h5_after_nick13.strands[0];
    Strand h5_56_96_forward = h5_after_nick13.strands[1];
    expect(recolor_strands(state.design.strands).contains(h5_24_56_forward), true);
    expect(recolor_strands(state.design.strands).contains(h5_56_96_forward), true);

    String content_after = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]},
    {"grid_position": [0, 1]},
    {"grid_position": [0, 2]},
    {"grid_position": [0, 3]},
    {"grid_position": [0, 4]},
    {"grid_position": [0, 5]}
  ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 72, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": true, "start": 56, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": false, "start": 72, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 3, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "domains": [
        {"helix": 3, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "domains": [
        {"helix": 3, "forward": true, "start": 56, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 3, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": false, "start": 72, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": true, "start": 56, "end": 96}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": false, "start": 0, "end": 48}
      ]
    },
    {
      "domains": [
        {"helix": 5, "forward": false, "start": 48, "end": 96}
      ]
    }
  ]
 }
    ''';

    Design expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);
  });

  //
  //
  //     0            16               32
  // 0  [-------------X--------------->
  //    <-------------X----------------]
  String simple_helix_with_deletion_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 32, "deletions": [16]}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 32, "deletions": [16]}
      ]
    }
  ]
 }
  ''';
  Design simple_helix_with_deletion_design = Design.from_json(jsonDecode(simple_helix_with_deletion_json));
  //     0     8      16      24        32
  // 0  [------>[-----X------->[-------->
  //    <------]<-----X-------]<--------]
  test("two nicks on strand with deletions", () {
    AppState state = app_state_from_design(simple_helix_with_deletion_design);

    Domain strand_to_nick_1 = simple_helix_with_deletion_design.strands[0].substrands[0];
    Domain strand_to_nick_2 = simple_helix_with_deletion_design.strands[1].substrands[0];
    state = app_state_reducer(state, Nick(domain: strand_to_nick_1, offset: 8));
    state = app_state_reducer(state, Nick(domain: strand_to_nick_2, offset: 8));
    String content_after = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", 
  "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 8, "end": 32, "deletions": [16]}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 8, "end": 32, "deletions": [16]}
      ]
    }
  ]
 }
  ''';
    Design expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);

    Domain strand_to_nick3 = expected_design.strands[1].substrands[0];
    Domain strand_to_nick4 = expected_design.strands[3].substrands[0];

    state = app_state_reducer(state, Nick(domain: strand_to_nick3, offset: 24));
    state = app_state_reducer(state, Nick(domain: strand_to_nick4, offset: 24));

    content_after = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", 
  "grid": "square",
  "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 8, "end": 24, "deletions": [16]}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 24, "end": 32}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 8, "end": 24, "deletions": [16]}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 24, "end": 32}
      ]
    }
  ]
 }
  ''';
    expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);
  });

  //
  //
  //     0            16               32
  // 0  [-------------I--------------->
  //    <-------------I----------------]
  String simple_helix_with_insertion_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 32, "insertions": [[16, 3]]}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 32, "insertions": [[16, 3]]}
      ]
    }
  ]
 }
  ''';
  Design simple_helix_with_insertion_design = Design.from_json(jsonDecode(simple_helix_with_insertion_json));
  //     0     8      16      24        32
  // 0  [------>[-----X------->[-------->
  //    <------]<-----X-------]<--------]
  test("two nicks on strand with insertions", () {
    AppState state = app_state_from_design(simple_helix_with_insertion_design);

    Domain strand_to_nick_1 = simple_helix_with_insertion_design.strands[0].substrands[0];
    Domain strand_to_nick_2 = simple_helix_with_insertion_design.strands[1].substrands[0];
    state = app_state_reducer(state, Nick(domain: strand_to_nick_1, offset: 8));
    state = app_state_reducer(state, Nick(domain: strand_to_nick_2, offset: 8));
    String content_after = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 8, "end": 32, "insertions": [[16, 3]]}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 8, "end": 32, "insertions": [[16, 3]]}
      ]
    }
  ]
 }
  ''';
    Design expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);

    Domain strand_to_nick3 = expected_design.strands[1].substrands[0];
    Domain strand_to_nick4 = expected_design.strands[3].substrands[0];

    state = app_state_reducer(state, Nick(domain: strand_to_nick3, offset: 24));
    state = app_state_reducer(state, Nick(domain: strand_to_nick4, offset: 24));

    content_after = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 8, "end": 24, "insertions": [[16, 3]]}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 24, "end": 32}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 8, "end": 24, "insertions": [[16, 3]]}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 24, "end": 32}
      ]
    }
  ]
 }
  ''';
    expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);
  });

  // simple_strand_design
  //     0            16
  //    AGTCAGTCAGTCAGTC
  // 0  [-----------------
  //   ----------------]  \
  //  | TCAGTCAGTCAGTCAG   |
  //  |                    |
  //  |  0             16  |
  //  \ AATTCCGGAATTCCGG   |
  // 1 --------------------/ ---
  //  ---------------------     \
  // /  TTAAGGCCTTAAGGCC        |
  // |                          |
  // |                          |
  // |   0             16       |
  // \  AAAATTTTCCCCGGGG        |
  //  ----------------->        /
  // 2  <----------------------
  //    TTTTAAAAGGGGCCCC
  String simple_strand_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]},{"grid_position": [0, 1]}, {"grid_position": [0, 2]} ],
  "strands": [
    {
      "sequence": "AGTCAGTCAGTCAGTCCCGGAATTCCGGAATTAAAATTTTCCCCGGGG",
      "domains": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16},
        {"helix": 1, "forward": false, "start": 0, "end": 16},
        {"helix": 2, "forward": true,  "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "GACTGACTGACTGACTAATTCCGGAATTCCGGCCCCGGGGAAAATTTT",
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 16},
        {"helix": 1, "forward": true , "start": 0, "end": 16},
        {"helix": 2, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
  Design simple_strand_design = Design.from_json(jsonDecode(simple_strand_json));
  //
  //     0            16
  //    AGTCAGTCAGTCAGTC
  // 0  [-----------------
  //   ----------------]  \
  //  | TCAGTCAGTCAGTCAG   |
  //  |                    |
  //  |  0             16  |
  //  \ AATTCCGGAATTCCGG   |
  // 1 --------------------/ ---
  //  ---------------------     \
  // /  TTAAGGCCTTAAGGCC        |
  // |                          |
  // |                          |
  // |   0             16       |
  // \  AAAATTTTCCCCGGGG        |
  //  ----------------->        /
  // 2  <----------------------
  //    TTTTAAAAGGGGCCCC
  test("add nick to a list of substrands", () {
    AppState state = app_state_from_design(simple_strand_design);

    Domain nick1_target = simple_strand_design.strands[0].substrands[1];
    Domain nick2_target = simple_strand_design.strands[1].substrands[1];
    state = app_state_reducer(state, Nick(domain: nick1_target, offset: 8));
    state = app_state_reducer(state, Nick(domain: nick2_target, offset: 8));

    String content_after = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]},{"grid_position": [0, 1]}, {"grid_position": [0, 2]} ],
  "strands": [
    {
      "sequence": "AGTCAGTCAGTCAGTCCCGGAATT",
      "domains": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16},
        {"helix": 1, "forward": false, "start": 8, "end": 16}
      ]
    },
    {
      "sequence": "CCGGAATTAAAATTTTCCCCGGGG",
      "domains": [
        {"helix": 1, "forward": false, "start": 0, "end": 8},
        {"helix": 2, "forward": true,  "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "GACTGACTGACTGACTAATTCCGG",
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 16},
        {"helix": 1, "forward": true , "start": 0, "end": 8}
      ]
    },
    {
      "sequence": "AATTCCGGCCCCGGGGAAAATTTT",
      "domains": [
        {"helix": 1, "forward": true , "start": 8, "end": 16},
        {"helix": 2, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
    Design expected_design = Design.from_json(jsonDecode(content_after));
    expect_strands_equal(state.design.strands, expected_design.strands);
  });

  //   0       8       16
  // 0 [------>[------->
  //   AGTCAGTC AATTCCGG
  String two_strands_forward_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "sequence": "AGTCAGTC",
      "domains": [
        {"helix": 0, "forward": true , "start": 0, "end": 8}
      ]
    },
    {
      "sequence": "AATTCCGG",
      "domains": [
        {"helix": 0, "forward": true , "start": 8, "end": 16}
      ]
    }
  ]
 }
  ''';
  Design two_strands_forward = Design.from_json(jsonDecode(two_strands_forward_json));

  //   0               16
  // 0 [--------------->
  //   AGTCAGTCAATTCCGG
  String ligate_two_strands_forward_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "sequence": "AGTCAGTCAATTCCGG",
      "domains": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
  Design ligate_two_strands_forward = Design.from_json(jsonDecode(ligate_two_strands_forward_json));
  test("ligate two strands forward using 5p end", () {
    AppState state = app_state_from_design(two_strands_forward);

    DNAEnd dna_end = two_strands_forward.strands[1].dnaend_5p;
    state = app_state_reducer(state, Ligate(dna_end: dna_end));

    expect_strands_equal(state.design.strands, ligate_two_strands_forward.strands);
  });
  test("ligate two strands forward using 3p end", () {
    AppState state = app_state_from_design(two_strands_forward);

    DNAEnd dna_end = two_strands_forward.strands[0].dnaend_3p;
    state = app_state_reducer(state, Ligate(dna_end: dna_end));

    expect_strands_equal(state.design.strands, ligate_two_strands_forward.strands);
  });

  //   0       8       16
  // 0 <------] <-------]
  //   GGCCTTAA CTGACTGA
  String two_strands_reverse_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "sequence": "AATTCCGG",
      "domains": [
        {"helix": 0, "forward": false , "start": 0, "end": 8}
      ]
    },
    {
      "sequence": "AGTCAGTC",
      "domains": [
        {"helix": 0, "forward": false , "start": 8, "end": 16}
      ]
    }
  ]
 }
  ''';
  Design two_strands_reverse = Design.from_json(jsonDecode(two_strands_reverse_json));

  //   0               16
  // 0 <---------------]
  //   GGCCTTAACTGACTGA
  String ligate_two_strands_reverse_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "sequence": "AGTCAGTCAATTCCGG",
      "domains": [
        {"helix": 0, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
  Design ligate_two_strands_reverse = Design.from_json(jsonDecode(ligate_two_strands_reverse_json));
  test("ligate two strands reverse using 5p end", () {
    AppState state = app_state_from_design(two_strands_reverse);

    DNAEnd dna_end = two_strands_reverse.strands[0].dnaend_5p;
    state = app_state_reducer(state, Ligate(dna_end: dna_end));

    expect_strands_equal(state.design.strands, ligate_two_strands_reverse.strands);
  });
  test("ligate two strands reverse using 3p end", () {
    AppState state = app_state_from_design(two_strands_reverse);

    DNAEnd dna_end = two_strands_reverse.strands[1].dnaend_3p;
    state = app_state_reducer(state, Ligate(dna_end: dna_end));

    expect_strands_equal(state.design.strands, ligate_two_strands_reverse.strands);
  });

  //   0                  16
  //
  // 0 [------------------->
  //   <-------------------]
  //
  // 1 [------------------->
  //   <-------------------]
  String two_helices_json = '''
 {
  "version": "${constants.CURRENT_VERSION}",''' +
      r''' 
  "grid": "square", 
  "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]} ],
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
  ''';
  Design two_helices_design = Design.from_json(jsonDecode(two_helices_json));

  //   0                  16
  //   Connect this one
  //   |
  //   v
  // 0 [------------------->
  //   <-------------------]
  //
  //   With this one
  //   |
  //   v
  // 1 [------------------->
  //   <-------------------]
  // test('pencil should ignore connecting a 5p end to a 5p end', () {
  //   AppState state = app_state_from_design(two_helices_design);

  //   Strand h0_forward_strand = two_helices_design.strands[0];
  //   Strand h1_forward_strand = two_helices_design.strands[2];
  //   Helix h0 = two_helices_design.helices[0];
  //   Point<num> start_point = h0.svg_base_pos(0, true);
  //   PotentialCrossover helix_0_5p_end_potential_crossover = PotentialCrossover(
  //     helix_idx: 0,
  //     forward: true,
  //     offset: 0,
  //     color: h0_forward_strand.color.toHexColor().toCssString(),
  //     dna_end_first_click: h0_forward_strand.dnaend_5p,
  //     start_point: start_point,
  //     current_point: start_point,
  //   );
  //   DNAEnd helix_1_5p_end_second_click = h1_forward_strand.dnaend_5p;

  //   state = app_state_reducer(
  //       state,
  //       JoinStrandsByCrossover(
  //         dna_end_second_click: helix_1_5p_end_second_click,
  //         potential_crossover: helix_0_5p_end_potential_crossover,
  //       ));

  //   expect_strands_equal(state.design.strands, two_helices_design.strands);
  // });

  //   0                  16
  //
  //         Connect this one
  //                       |
  //                       v
  // 0 [------------------->
  //   <-------------------]
  //
  //            With this one
  //                       |
  //                       v
  // 1 [------------------->
  //   <-------------------]
  // test('pencil should ignore connecting a 3p end to a 3p end', () {
  //   AppState state = app_state_from_design(two_helices_design);

  //   Strand h0_forward_strand = two_helices_design.strands[0];
  //   Strand h1_forward_strand = two_helices_design.strands[2];
  //   Helix h0 = two_helices_design.helices[0];
  //   Point<num> start_point = h0.svg_base_pos(15, true); // 3p is located on offset = 15 and forward = true
  //   PotentialCrossover helix_0_5p_end_potential_crossover = PotentialCrossover(
  //     helix_idx: 0,
  //     forward: true,
  //     offset: 15,
  //     color: h0_forward_strand.color.toHexColor().toCssString(),
  //     dna_end_first_click: h0_forward_strand.dnaend_3p,
  //     start_point: start_point,
  //     current_point: start_point,
  //   );
  //   DNAEnd helix_1_3p_end_second_click = h1_forward_strand.dnaend_3p;

  //   state = app_state_reducer(
  //       state,
  //       JoinStrandsByCrossover(
  //         dna_end_second_click: helix_1_3p_end_second_click,
  //         potential_crossover: helix_0_5p_end_potential_crossover,
  //       ));

  //   expect_strands_equal(state.design.strands, two_helices_design.strands);
  // });
  //   0                  16
  //
  // 0 [------------------->
  //   --------------------]
  //  /
  //  |
  //  \
  // 1 -------------------->
  //   <-------------------]
  String two_helices_join_inner_strands_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false , "start": 0, "end": 16},
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
  ''';
  Design two_helices_join_inner_strands = Design.from_json(jsonDecode(two_helices_join_inner_strands_json));
  test('pencil should connect a 3p end to a 5p end', () {
    AppState state = app_state_from_design(two_helices_design);
    Map<int, Point<num>> svg_position_map = util.helices_assign_svg(two_helices_design.geometry,
        state.ui_state.invert_y, two_helices_design.helices, two_helices_design.groups);

    Strand h0_reverse_strand = two_helices_design.strands[1];
    Strand h1_forward_strand = two_helices_design.strands[2];
    Helix h0 = two_helices_design.helices[0];
    Point<num> start_point =
        h0.svg_base_pos(0, false, svg_position_map[0].y); // 3p end is 0 offset and forward is false.
    PotentialCrossover helix_0_3p_end_potential_crossover = PotentialCrossover(
      address: Address(
        helix_idx: 0,
        forward: false,
        offset: 0,
      ),
      color: h0_reverse_strand.color.toHexColor().toCssString(),
      dna_end_first_click: h0_reverse_strand.dnaend_3p,
      start_point: start_point,
      current_point: start_point,
    );
    DNAEnd helix_1_5p_end_second_click = h1_forward_strand.dnaend_5p;

    state = app_state_reducer(
        state,
        JoinStrandsByCrossover(
          dna_end_second_click: helix_1_5p_end_second_click,
          dna_end_first_click: helix_0_3p_end_potential_crossover.dna_end_first_click,
        ));

    expect_strands_equal(state.design.strands, two_helices_join_inner_strands.strands);
  });
  test('pencil should connect a 5p end to a 3p end', () {
    AppState state = app_state_from_design(two_helices_design);
    Map<int, Point<num>> svg_position_map = util.helices_assign_svg(two_helices_design.geometry,
        state.ui_state.invert_y, two_helices_design.helices, two_helices_design.groups);

    Strand h0_reverse_strand = two_helices_design.strands[1];
    Strand h1_forward_strand = two_helices_design.strands[2];
    Helix h1 = two_helices_design.helices[1];
    Point<num> start_point =
        h1.svg_base_pos(0, true, svg_position_map[1].y); // 5p end is 0 offset and forward is true.
    PotentialCrossover helix_1_5p_end_potential_crossover = PotentialCrossover(
      address: Address(
        helix_idx: 1,
        forward: true,
        offset: 0,
      ),
      color: h1_forward_strand.color.toHexColor().toCssString(),
      dna_end_first_click: h1_forward_strand.dnaend_5p,
      start_point: start_point,
      current_point: start_point,
    );
    DNAEnd helix_0_3p_end_second_click = h0_reverse_strand.dnaend_5p;

    state = app_state_reducer(
        state,
        JoinStrandsByCrossover(
          dna_end_second_click: helix_0_3p_end_second_click,
          dna_end_first_click: helix_1_5p_end_potential_crossover.dna_end_first_click,
        ));

    expect_strands_equal(state.design.strands, two_helices_join_inner_strands.strands);
  });

  test('add_helix_to_DNA_design', () {
    AppState state = app_state_from_design(two_helices_design);
    state = app_state_reducer(state, HelixAdd(grid_position: GridPosition(0, 2)));

    expect(state.design.helices.length, 3);
    expect(state.design.helices[0], two_helices_design.helices[0]);
    expect(state.design.helices[1], two_helices_design.helices[1]);
    var helix2 = state.design.helices[2];
    expect(helix2.idx, 2);
    expect(helix2.grid_position, GridPosition(0, 2));
    expect(helix2.min_offset, 0);
    expect(helix2.max_offset, 16);
  });

  test('remove_empty_helix_from_design', () {
    AppState original_state = app_state_from_design(two_helices_design);

    AppState second_state = app_state_reducer(original_state, HelixAdd(grid_position: GridPosition(0, 2)));
    AppState final_state = app_state_reducer(second_state, HelixRemove(2));

    expect_design_equal(final_state.design, two_helices_design);
  });

  test('remove_first_helix_from_design', () {
    // see issue #184
    AppState original_state = app_state_from_design(two_helices_design);

    AppState final_state = app_state_reducer(original_state, HelixRemove(0));
    Design final_design = final_state.design;

    Helix helix1 = two_helices_design.helices[1];

    BuiltList<Strand> new_strands = two_helices_design.strands.rebuild((b) => b..removeRange(0, 2));
    Design expected_design = two_helices_design.rebuild((b) => b
      ..helices.replace({1: helix1})
      ..strands.replace(new_strands));

    expect_design_equal(final_design, expected_design);
  });

  test('remove_helices_from_DNA_design', () {
    // Remove helix 0 and 2 from this design.
    //
    // Before:
    //
    //     0            16
    //    AGTCAGTCAGTCAGTC
    // 0  [-----------------
    //   ----------------]  \
    //  | TCAGTCAGTCAGTCAG   |
    //  |                    |
    //  |  0             16  |
    //  \ AATTCCGGAATTCCGG   |
    // 1 --------------------/ ---
    //  ---------------------     \
    // /  TTAAGGCCTTAAGGCC        |
    // |                          |
    // |                          |
    // |   0             16       |
    // \  AAAATTTTCCCCGGGG        |
    //  ----------------->        /
    // 2  <----------------------
    //    TTTTAAAAGGGGCCCC
    //
    // After:
    //    AATTCCGGAATTCCGG
    // 1  [-------------->
    //    <--------------]
    //    TTAAGGCCTTAAGGCC
    String expected_json = r'''
    {
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 1], "idx": 1} ],
      "strands": [
        {
          "sequence": "CCGGAATTCCGGAATT",
          "domains": [
            {"helix": 1, "forward": false, "start": 0, "end": 16}
          ]
        },
        {
          "sequence": "AATTCCGGAATTCCGG",
          "domains": [
            {"helix": 1, "forward": true , "start": 0, "end": 16}
          ]
        }
      ]
    }
  ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));

    AppState original_state = app_state_from_design(simple_strand_design)
        .rebuild((b) => b..ui_state.storables.side_selected_helix_idxs.replace([0, 2]));

    AppState actual_state = app_state_reducer(original_state, HelixRemoveAllSelected());

    expect_design_equal(actual_state.design, expected_design);
  });

  test('remove_helices_from_DNA_design_should_adjust_svg_position_of_helices_with_higher_view_position', () {
    // Remove helix 0 and 2 from this design.
    //
    // Before:
    //
    //     0            16
    //    AGTCAGTCAGTCAGTC
    // 0  [-----------------
    //   ----------------]  \
    //  | TCAGTCAGTCAGTCAG   |
    //  |                    |
    //  |  0             16  |
    //  \ AATTCCGGAATTCCGG   |
    // 1 --------------------/ ---
    //  ---------------------     \
    // /  TTAAGGCCTTAAGGCC        |
    // |                          |
    // |                          |
    // |   0             16       |
    // \  AAAATTTTCCCCGGGG        |
    //  ----------------->        /
    // 2  <----------------------
    //    TTTTAAAAGGGGCCCC
    //
    // After:
    //    AAAATTTTCCCCGGGG
    //    [-------------->
    // 2  <--------------]
    //    TTTTAAAAGGGGCCCC
    String expected_json = r'''
    {
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 2], "idx": 2} ],
      "strands": [
        {
          "sequence": "CCCCGGGGAAAATTTT",
          "domains": [
            {"helix": 2, "forward": false, "start": 0, "end": 16}
          ]
        },
        {
          "sequence": "AAAATTTTCCCCGGGG",
          "domains": [
            {"helix": 2, "forward": true , "start": 0, "end": 16}
          ]
        }
      ]
    }
  ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));

    AppState original_state = app_state_from_design(simple_strand_design)
        .rebuild((b) => b..ui_state.storables.side_selected_helix_idxs = SetBuilder<int>([0, 1]));

    AppState final_state = app_state_reducer(original_state, HelixRemoveAllSelected());

    expect_design_equal(final_state.design, expected_design);
  });

  //   0                  16
  //
  // 0 [------------------->
  //   <-------------------]
  //
  // 4 [------------------->
  //   <-------------------]
  String two_helices_with_helix_idx_gap_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", 
  "grid": "square", 
  "helices": [ 
    {"grid_position": [0, 0], "idx": 0}, 
    {"grid_position": [0, 1], "idx": 4} 
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
        {"helix": 4, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "domains": [
        {"helix": 4, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
  Design two_helices_with_helix_idx_gap_design =
      Design.from_json(jsonDecode(two_helices_with_helix_idx_gap_json));

  test('add_new_helix_be_one_higher_than_max_id', () {
    AppState state = app_state_from_design(two_helices_with_helix_idx_gap_design);

    GridPosition grid_position = GridPosition(0, 2);
    state = app_state_reducer(state, HelixAdd(grid_position: grid_position));

    String expected_json = r'''
    {
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0], "idx": 0}, {"grid_position": [0, 1], "idx": 4}, {"grid_position": [0, 2], "idx": 5, "max_offset": 16}],
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
            {"helix": 4, "forward": true , "start": 0, "end": 16}
          ]
        },
        {
          "domains": [
            {"helix": 4, "forward": false , "start": 0, "end": 16}
          ]
        }
      ]
    }
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));

    expect_design_equal(state.design, expected_design);
  });

  //     0               16
  // 0   [--------------->
  //     <---------------]
  String simple_helix_no_seq_json = r'''
{
"version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
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
  }
]
}
''';
  Design simple_helix_no_seq_design = Design.from_json(jsonDecode(simple_helix_no_seq_json));
  test('Testing_DNAEndsMoveStart', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    AppState actual_state = app_state_reducer(
        initial_state, DNAEndsMoveStart(offset: 0, helix: simple_helix_no_seq_design.helices[0]));

    expect(actual_state.ui_state.dna_ends_are_moving, true);
    expect_design_equal(actual_state.design, simple_helix_no_seq_design);
  });

  test('Testing_DNAEndsMoveStop', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);

    // Starts DNA Ends move.
    AppState actual_state = app_state_reducer(
        initial_state, DNAEndsMoveStart(offset: 0, helix: simple_helix_no_seq_design.helices[0]));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());

    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, simple_helix_no_seq_design);
  });

  test('Testing_DNAEndsMoveCommit_on_forward_strand_5p_end', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_design.strands[0];

    // Starts DNA Ends move.
    AppState actual_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 0, helix: helix0));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());
    // Commits DNA Ends move.
    Domain forward_substrand = forward_strand.substrands.first as Domain;
    DNAEnd dna_end = forward_substrand.dnaend_5p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 0, highest_offset: 15);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 0,
      current_offset: 3,
      helix: helix0,
    );
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // Expected:
    //     0   3            16
    // 0       [----------->
    //     <---------------]
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 3, "end": 16}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 0, "end": 16}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));

    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, expected_design);
  });

  test('Testing_DNAEndsMoveCommit_on_forward_strand_3p_end', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_design.strands[0];

    // Starts DNA Ends move.
    AppState actual_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());
    // Commits DNA Ends move.
    Domain forward_substrand = forward_strand.substrands.first as Domain;
    DNAEnd dna_end = forward_substrand.dnaend_3p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 0, highest_offset: 15);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 15,
      current_offset: 3,
      helix: helix0,
    );
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // Expected:
    //     0   3 4         15 16
    // 0   [--->
    //     <---------------]
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 0, "end": 4}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 0, "end": 16}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect_design_equal(actual_state.design, expected_design);
  });

  test('Testing_DNAEndsMoveCommit_on_reverse_strand_5p_end', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand reverse_strand = simple_helix_no_seq_design.strands.last;

    // Starts DNA Ends move.
    AppState actual_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());
    // Commits DNA Ends move.
    Domain reverse_substrand = reverse_strand.substrands.first as Domain;
    DNAEnd dna_end = reverse_substrand.dnaend_5p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 0, highest_offset: 15);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 15,
      current_offset: 3,
      helix: helix0,
    );
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // Expected:
    //     0   3 4         15 16
    // 0   [--------------->
    //     <--]
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 0, "end": 16}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 0, "end": 4}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, expected_design);
  });

  test('Testing_DNAEndsMoveCommit_on_reverse_strand_3p_end', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand reverse_strand = simple_helix_no_seq_design.strands.last;

    // Starts DNA Ends move.
    AppState actual_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());
    // Commits DNA Ends move.
    Domain reverse_substrand = reverse_strand.substrands.first as Domain;
    DNAEnd dna_end = reverse_substrand.dnaend_3p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 0, highest_offset: 15);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 0,
      current_offset: 3,
      helix: helix0,
    );
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // Expected:
    //     0   3 4         15 16
    // 0   [--------------->
    //         <-----------]
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 0, "end": 16}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 3, "end": 16}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, expected_design);
  });

  test('Testing_DNAEndsMoveCommit_on_two_different_strands', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_design.strands.first;
    Strand reverse_strand = simple_helix_no_seq_design.strands.last;

    // Starts DNA Ends move.
    AppState actual_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 0, helix: helix0));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());

    // Constructs move on forward strand.
    DNAEnd dna_end_forward = forward_strand.dnaend_5p;
    DNAEndMove dna_end_move_forward =
        DNAEndMove(dna_end: dna_end_forward, lowest_offset: 0, highest_offset: 15);

    // Constructs move on reverse strand.
    DNAEnd dna_end_reverse = reverse_strand.dnaend_3p;
    DNAEndMove dna_end_move_reverse =
        DNAEndMove(dna_end: dna_end_reverse, lowest_offset: 0, highest_offset: 15);

    // Create and dispatch DNAEndsMoveCommit action.
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move_forward, dna_end_move_reverse]),
      original_offset: 0,
      current_offset: 3,
      helix: helix0,
    );
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // Expected:
    //     0   3            16
    // 0       [----------->
    //         <-----------]
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 3, "end": 16}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 3, "end": 16}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, expected_design);
  });

  test('Moving_Multiple_DNA_Ends', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_design.strands.first;
    Strand reverse_strand = simple_helix_no_seq_design.strands.last;

    // Starts DNA Ends move.
    AppState mid_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 0, helix: helix0));
    // Stops DNA Ends move.
    mid_state = app_state_reducer(mid_state, DNAEndsMoveStop());
    // Constructs move on forward strand.
    DNAEnd dna_end_forward = forward_strand.dnaend_5p;
    DNAEndMove dna_end_move_forward =
        DNAEndMove(dna_end: dna_end_forward, lowest_offset: 0, highest_offset: 15);
    // Create and dispatch first DNAEndsMoveCommit action.
    DNAEndsMove dna_ends_move_forward = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move_forward]),
      original_offset: 0,
      current_offset: 3,
      helix: helix0,
    );
    mid_state = app_state_reducer(mid_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move_forward));

    // Starts second DNA Ends move.
    AppState final_state = app_state_reducer(mid_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    // Stops second DNA Ends move.
    final_state = app_state_reducer(final_state, DNAEndsMoveStop());
    // Constructs move on reverse strand.
    DNAEnd dna_end_reverse = reverse_strand.dnaend_5p;
    DNAEndMove dna_end_move_reverse =
        DNAEndMove(dna_end: dna_end_reverse, lowest_offset: 0, highest_offset: 15);
    // Create and dispatch second DNAEndsMoveCommit action.
    DNAEndsMove dna_ends_move_reverse = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move_reverse]),
      original_offset: 15,
      current_offset: 4,
      helix: helix0,
    );
    final_state = app_state_reducer(final_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move_reverse));

    // Expected:
    //     0   3           15  16
    // 0       [----------->
    //     <------]
    //            4  5
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 3, "end": 16}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 0, "end": 5}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect(final_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(final_state.design, expected_design);
  });

  test('Undoing_multiple_DNA_end_movements', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_design.strands.first;
    Strand reverse_strand = simple_helix_no_seq_design.strands.last;

    // Starts DNA Ends move.
    AppState mid_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 0, helix: helix0));
    // Stops DNA Ends move.
    mid_state = app_state_reducer(mid_state, DNAEndsMoveStop());
    // Constructs move on forward strand.
    DNAEnd dna_end_forward = forward_strand.dnaend_5p;
    DNAEndMove dna_end_move_forward =
        DNAEndMove(dna_end: dna_end_forward, lowest_offset: 0, highest_offset: 15);
    // Create and dispatch first DNAEndsMoveCommit action.
    DNAEndsMove dna_ends_move_forward = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move_forward]),
      original_offset: 0,
      current_offset: 3,
      helix: helix0,
    );
    mid_state = app_state_reducer(mid_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move_forward));

    // Starts second DNA Ends move.
    AppState final_state = app_state_reducer(mid_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    // Stops second DNA Ends move.
    final_state = app_state_reducer(final_state, DNAEndsMoveStop());
    // Constructs move on reverse strand.
    DNAEnd dna_end_reverse = reverse_strand.dnaend_5p;
    DNAEndMove dna_end_move_reverse =
        DNAEndMove(dna_end: dna_end_reverse, lowest_offset: 0, highest_offset: 15);
    // Create and dispatch second DNAEndsMoveCommit action.
    DNAEndsMove dna_ends_move_reverse = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move_reverse]),
      original_offset: 15,
      current_offset: 4,
      helix: helix0,
    );
    final_state = app_state_reducer(final_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move_reverse));

    // Expected:
    //     0   3           15  16
    // 0       [----------->
    //     <------]
    //            4  5
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 3, "end": 16}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 0, "end": 5}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    UndoRedo expected_undo_redo = UndoRedo().rebuild((b) => b.undo_stack.addAll([
          new UndoRedoItem("move DNA ends", simple_helix_no_seq_design),
          new UndoRedoItem("move DNA ends", mid_state.design)
        ]));

    expect(final_state.ui_state.changed_since_last_save, true);
    expect_design_equal(final_state.design, expected_design);

    // First Undo.
    expected_undo_redo = UndoRedo().rebuild((b) => b
      ..undo_stack.add(new UndoRedoItem("move DNA ends", simple_helix_no_seq_design))
      ..redo_stack.add(new UndoRedoItem("move DNA ends", final_state.design)));
    AppState state_undo_1 = app_state_reducer(final_state, Undo(1));

    expect(state_undo_1.ui_state.changed_since_last_save, true);
    expect(state_undo_1.undo_redo, expected_undo_redo);
    expect_design_equal(state_undo_1.design, mid_state.design);

    // Second Undo.
    expected_undo_redo = UndoRedo().rebuild((b) => b.redo_stack.addAll([
          new UndoRedoItem("move DNA ends", final_state.design),
          new UndoRedoItem("move DNA ends", mid_state.design)
        ]));
    AppState state_undo_2 = app_state_reducer(state_undo_1, Undo(1));

    expect(state_undo_2.ui_state.changed_since_last_save, false);
    expect(state_undo_2.undo_redo, expected_undo_redo);
    expect_design_equal(state_undo_2.design, simple_helix_no_seq_design);
  });

  test('Undoing_multiple_DNA_end_movements_with_extra_DNAEndsMoveStop_see_issue_#72', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_design.strands.first;
    Strand reverse_strand = simple_helix_no_seq_design.strands.last;

    // Starts DNA Ends move.
    AppState mid_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 0, helix: helix0));
    // Stops DNA Ends move.
    mid_state = app_state_reducer(mid_state, DNAEndsMoveStop());
    // Constructs move on forward strand.
    DNAEnd dna_end_forward = forward_strand.dnaend_5p;
    DNAEndMove dna_end_move_forward =
        DNAEndMove(dna_end: dna_end_forward, lowest_offset: 0, highest_offset: 15);
    // Create and dispatch first DNAEndsMoveCommit action.
    DNAEndsMove dna_ends_move_forward = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move_forward]),
      original_offset: 0,
      current_offset: 3,
      helix: helix0,
    );
    mid_state = app_state_reducer(mid_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move_forward));

    // Starts second DNA Ends move.
    AppState final_state = app_state_reducer(mid_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    // Stops second DNA Ends move.
    final_state = app_state_reducer(final_state, DNAEndsMoveStop());

    // Creates this bug https://github.com/UC-Davis-molecular-computing/scadnano/issues/72
    final_state = app_state_reducer(final_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    final_state = app_state_reducer(final_state, DNAEndsMoveStop());
    final_state = app_state_reducer(final_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    final_state = app_state_reducer(final_state, DNAEndsMoveStop());
    final_state = app_state_reducer(final_state, DNAEndsMoveStart(offset: 15, helix: helix0));
    final_state = app_state_reducer(final_state, DNAEndsMoveStop());

    // Constructs move on reverse strand.
    DNAEnd dna_end_reverse = reverse_strand.dnaend_5p;
    DNAEndMove dna_end_move_reverse =
        DNAEndMove(dna_end: dna_end_reverse, lowest_offset: 0, highest_offset: 15);
    // Create and dispatch second DNAEndsMoveCommit action.
    DNAEndsMove dna_ends_move_reverse = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move_reverse]),
      original_offset: 15,
      current_offset: 4,
      helix: helix0,
    );
    final_state = app_state_reducer(final_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move_reverse));

    // Expected:
    //     0   3           15  16
    // 0       [----------->
    //     <------]
    //            4  5
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 3, "end": 16}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 0, "end": 5}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    UndoRedo expected_undo_redo = UndoRedo().rebuild((b) => b.undo_stack.addAll([
          new UndoRedoItem("move DNA ends", simple_helix_no_seq_design),
          new UndoRedoItem("move DNA ends", mid_state.design)
        ]));

    expect(final_state.ui_state.changed_since_last_save, true);
    expect(final_state.undo_redo, expected_undo_redo);
    expect_design_equal(final_state.design, expected_design);

    // First Undo.
    expected_undo_redo = UndoRedo().rebuild((b) => b
      ..undo_stack.add(new UndoRedoItem("move DNA ends", simple_helix_no_seq_design))
      ..redo_stack.add(new UndoRedoItem("move DNA ends", final_state.design)));
    AppState state_undo_1 = app_state_reducer(final_state, Undo(1));

    expect(state_undo_1.ui_state.changed_since_last_save, true);
    expect(state_undo_1.undo_redo, expected_undo_redo);
    expect_design_equal(state_undo_1.design, mid_state.design);

    // Second Undo.
    expected_undo_redo = UndoRedo().rebuild((b) => b.redo_stack.addAll([
          new UndoRedoItem("move DNA ends", final_state.design),
          new UndoRedoItem("move DNA ends", mid_state.design)
        ]));
    AppState state_undo_2 = app_state_reducer(state_undo_1, Undo(1));

    expect(state_undo_2.ui_state.changed_since_last_save, false);
    expect(state_undo_2.undo_redo, expected_undo_redo);
    expect_design_equal(state_undo_2.design, simple_helix_no_seq_design);
  });

  //     0    4      10 11   16
  // 0        [------>
  //          <------]
  String simple_helix_no_seq_smaller_json = r'''
{
"version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0], "max_offset": 16}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 4, "end": 11}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 4, "end": 11}
    ]
  }
]
}
''';
  Design simple_helix_no_seq_smaller_design = Design.from_json(jsonDecode(simple_helix_no_seq_smaller_json));
  test('Dragging_end_less_than_helix_min_offset_see_issue_#77', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_smaller_design);
    Helix helix0 = simple_helix_no_seq_smaller_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_smaller_design.strands[0];

    // Starts DNA Ends move.
    AppState actual_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 4, helix: helix0));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());
    // Commits DNA Ends move.
    // Domain forward_substrand = forward_strand.substrands.first as Domain;
    DNAEnd dna_end = forward_strand.dnaend_5p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 0, highest_offset: 9);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 4,
      current_offset: -6,
      helix: helix0,
    );
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    //     0    4      10 11   16
    // 0   [----------->
    //          <------]
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0], "max_offset": 16}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 0, "end": 11}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 4, "end": 11}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, expected_design);
  });

  // before:
  //     0    4      10 11   16
  // 0        [------>
  //          <------]
  test('Dragging_end_greater_than_helix_max_offset_see_issue_#77', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_smaller_design);
    Helix helix0 = simple_helix_no_seq_smaller_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_smaller_design.strands[0];

    // Starts DNA Ends move.
    AppState actual_state = app_state_reducer(initial_state, DNAEndsMoveStart(offset: 10, helix: helix0));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());
    // Commits DNA Ends move.
    // Domain forward_substrand = forward_strand.substrands.first as Domain;
    DNAEnd dna_end = forward_strand.dnaend_3p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 5, highest_offset: 15);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 10,
      current_offset: 19,
      helix: helix0,
    );
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // after
    //     0    4      10 11   15 16
    // 0        [-------------->
    //          <------]
    String expected_json = r'''
{
"version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0], "max_offset": 16}],
"strands": [
  {
    "domains": [
      {"helix": 0, "forward": true , "start": 4, "end": 16}
    ]
  },
  {
    "domains": [
      {"helix": 0, "forward": false , "start": 4, "end": 11}
    ]
  }
]
}
    ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, expected_design);
  });

  // https://github.com/UC-Davis-molecular-computing/scadnano/issues/83#issuecomment-569432526
  test('test_selected_dna_ends_after_undoing_DNAEndMove_see_issue_83)', () {
    AppState initial_state = app_state_from_design(simple_helix_no_seq_design);
    Helix helix0 = simple_helix_no_seq_design.helices[0];
    Strand forward_strand = simple_helix_no_seq_design.strands[0];
    DNAEnd dna_end = forward_strand.dnaend_5p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 0, highest_offset: 15);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 0,
      current_offset: 7,
      helix: helix0,
    );
    AppState actual_state = initial_state;

    // Put end select mode on
    actual_state = make_ends_selectable(actual_state);

    // Select
    actual_state = app_state_reducer(actual_state, Select(dna_end, toggle: false, only: false));
    // Starts DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStart(offset: 0, helix: helix0));
    // Stops DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveStop());
    // Commits DNA Ends move.
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // Selects new end
    DNAEnd new_dna_end = actual_state.design.strands[0].dnaend_5p;
    actual_state = app_state_reducer(
        actual_state, SelectAll(selectables: BuiltList<Selectable>([new_dna_end]), only: true));

    // Undo DNA Ends move
    actual_state = app_state_reducer(actual_state, Undo(1));
    // Select
    actual_state = app_state_reducer(actual_state, Select(dna_end, toggle: false, only: false));

    expect(actual_state.ui_state.selectables_store.selected_items, BuiltList<Selectable>([dna_end]));
  });

  // two_helices_design (defined earlier)
  //   0                  16
  //
  // 0 [------------------->    <-- \
  //   <-------------------]    <-- |
  //                                | -- selects these ends
  // 1 [------------------->    <-- |
  //   <-------------------]    <-- /
  //
  // After removing helix 1
  //
  //   0                  16
  //
  // 0 [------------------->    nothing is selected now
  //   <-------------------]
  test('test clearing selected ends on deleted helix (see issue #83)', () {
    DNAEnd dna_end_h0_3p = two_helices_design.strands[0].dnaend_3p;
    DNAEnd dna_end_h0_5p = two_helices_design.strands[1].dnaend_5p;
    DNAEnd dna_end_h1_3p = two_helices_design.strands[2].dnaend_3p;
    DNAEnd dna_end_h1_5p = two_helices_design.strands[3].dnaend_5p;
    BuiltList<Selectable> initial_selected_ends =
        BuiltList<Selectable>([dna_end_h0_3p, dna_end_h0_5p, dna_end_h1_3p, dna_end_h1_5p]);
    AppState initial_state = app_state_from_design(two_helices_design);
    AppState actual_state = initial_state;

    actual_state = app_state_reducer(actual_state, SelectAll(selectables: initial_selected_ends, only: true));
    expect(actual_state.ui_state.selectables_store.selected_items, initial_selected_ends.toSet());

    actual_state = app_state_reducer(actual_state, HelixRemove(1));
    expect(actual_state.ui_state.selectables_store.selected_items, BuiltSet<Selectable>());
  });

  test('test_moving_end_over_deletion_see_issue_#92', () {
    //   simple_helix_with_deletion_design
    //
    //     0            16               32
    // 0  [-------------X--------------->
    //    <-------------X----------------]
    AppState initial_state = app_state_from_design(simple_helix_with_deletion_design);

    Helix helix0 = simple_helix_with_deletion_design.helices.values.first;
    Strand forward_strand = simple_helix_with_deletion_design.strands.first;
    DNAEnd dna_end = forward_strand.dnaend_5p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 0, highest_offset: 30);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 0,
      current_offset: 16,
      helix: helix0,
    );
    AppState actual_state = initial_state;

    // Expect:
    //     0            16               32
    // 0                [---------------->
    //    <-------------[----------------]
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    String expected_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 16, "end": 32 }
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 32}
      ]
    }
  ]
 }
  ''';

    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, expected_design);
  });

  test('test_moving_end_over_insertion_see_issue_#92', () {
    //   simple_helix_with_insertion_design
    //
    //     0            16               32
    // 0  [-------------I--------------->
    //    <-------------I----------------]
    AppState initial_state = app_state_from_design(simple_helix_with_insertion_design);

    Helix helix0 = simple_helix_with_insertion_design.helices.values.first;
    Strand forward_strand = simple_helix_with_insertion_design.strands.first;
    DNAEnd dna_end = forward_strand.dnaend_5p;
    DNAEndMove dna_end_move = DNAEndMove(dna_end: dna_end, lowest_offset: 0, highest_offset: 30);
    DNAEndsMove dna_ends_move = DNAEndsMove(
      moves: BuiltList<DNAEndMove>([dna_end_move]),
      original_offset: 0,
      current_offset: 16,
      helix: helix0,
    );
    AppState actual_state = initial_state;

    // Expect:
    //     0            16               32
    // 0                [---------------->
    //    <-------------[----------------]
    actual_state = app_state_reducer(actual_state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    String expected_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true, "start": 16, "end": 32}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 32}
      ]
    }
  ]
 }
  ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect(actual_state.ui_state.dna_ends_are_moving, false);
    expect_design_equal(actual_state.design, expected_design);
  });

  group('Edit modes tests: ', () {
    // This test no longer makes sense. Cannot toggle off without another Edit mode coming on
//    test('EditModeToggle_to_toggle_off', () {
//      AppState initial_state = app_state_from_design(two_helices_design)
//          .rebuild((b) => b..ui_state.storables.edit_modes.replace([EditModeChoice.select]));
//
//      AppState final_state = app_state_reducer(initial_state, EditModeToggle(EditModeChoice.select));
//
//      expect(final_state.ui_state.edit_modes, BuiltSet<EditModeChoice>());
//    });

    test('EditModeToggle_to_toggle_on_with_exclusion', () {
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.edit_modes.replace([EditModeChoice.select]));

      AppState final_state = app_state_reducer(initial_state, EditModeToggle(EditModeChoice.ligate));

      expect(final_state.ui_state.edit_modes, BuiltSet<EditModeChoice>([EditModeChoice.ligate]));
    });

    test('EditModeToggle_to_toggle_on_without_exclusion', () {
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.edit_modes.replace([EditModeChoice.pencil]));

      AppState final_state = app_state_reducer(initial_state, EditModeToggle(EditModeChoice.nick));

      expect(final_state.ui_state.edit_modes, [EditModeChoice.nick, EditModeChoice.pencil].toBuiltSet());
    });

    test('EditModesSet', () {
      AppState initial_state = app_state_from_design(two_helices_design);

      BuiltSet<EditModeChoice> edit_modes = [EditModeChoice.pencil, EditModeChoice.nick].toBuiltSet();

      AppState final_state = app_state_reducer(initial_state, EditModesSet(edit_modes));

      expect(final_state.ui_state.edit_modes, edit_modes);
    });
  });

  test('clicking_out_of_select_mode_unselects_strands', () {
    SelectablesStore edit_mode_store = SelectablesStore().select(two_helices_design.strands[0]);
    AppState initial_state = app_state_from_design(two_helices_design)
        .rebuild((b) => b..ui_state.storables.edit_modes.replace([EditModeChoice.select]));
    initial_state.ui_state.selectables_store.select(two_helices_design.strands[0]);
    AppState final_state = app_state_reducer(initial_state, EditModeToggle(EditModeChoice.pencil));
    expect(final_state.ui_state.selectables_store, edit_mode_store.unselect(two_helices_design.strands[0]));
  });

  group('File Menu tests:', () {
    test('ClearHelixSelectionWhenLoadingNewDesignSet', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state =
          app_state_reducer(initial_state, ClearHelixSelectionWhenLoadingNewDesignSet(clear: true));
      expect(final_state.ui_state.clear_helix_selection_when_loading_new_design, true);
      final_state = app_state_reducer(final_state, ClearHelixSelectionWhenLoadingNewDesignSet(clear: false));
      expect(final_state.ui_state.clear_helix_selection_when_loading_new_design, false);
    });
  });

  group('Select modes tests: ', () {
    test('SelectModeToggle_to_toggle_off', () {
      SelectModeState modes =
          SelectModeState().set_modes([SelectModeChoice.end_3p_strand, SelectModeChoice.end_5p_domain]);
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.select_mode_state.replace(modes));

      AppState final_state =
          app_state_reducer(initial_state, SelectModeToggle(SelectModeChoice.end_3p_strand));

      SelectModeState expected_modes = SelectModeState().set_modes([SelectModeChoice.end_5p_domain]);
      expect(final_state.ui_state.select_mode_state, expected_modes);
    });

    test('test SelectModeToggle to toggle on', () {
      SelectModeState modes =
          SelectModeState().set_modes([SelectModeChoice.end_3p_strand, SelectModeChoice.end_5p_domain]);
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.select_mode_state.replace(modes));

      AppState final_state =
          app_state_reducer(initial_state, SelectModeToggle(SelectModeChoice.end_3p_domain));

      SelectModeState expected_modes = modes.add_mode(SelectModeChoice.end_3p_domain);
      expect(final_state.ui_state.select_mode_state, expected_modes);
    });

    test('test SelectModeToggle to turn strand on', () {
      SelectModeState modes =
          SelectModeState().set_modes([SelectModeChoice.end_3p_strand, SelectModeChoice.end_5p_domain]);
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.select_mode_state.replace(modes));

      AppState final_state = app_state_reducer(initial_state, SelectModeToggle(SelectModeChoice.strand));

      SelectModeState expected_modes = SelectModeState().set_modes([SelectModeChoice.strand]);
      expect(final_state.ui_state.select_mode_state, expected_modes);
    });

    test('test SelectModeToggle to turn crossover on', () {
      SelectModeState modes = SelectModeState().set_modes(
          [SelectModeChoice.end_3p_strand, SelectModeChoice.end_5p_domain, SelectModeChoice.scaffold]);
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.select_mode_state.replace(modes));

      AppState final_state = app_state_reducer(initial_state, SelectModeToggle(SelectModeChoice.crossover));

      SelectModeState expected_modes =
          SelectModeState().set_modes([SelectModeChoice.crossover, SelectModeChoice.scaffold]);
      expect(final_state.ui_state.select_mode_state, expected_modes);
    });

    test('test SelectModeToggle to turn loopout on', () {
      SelectModeState modes = SelectModeState().set_modes(
          [SelectModeChoice.end_3p_strand, SelectModeChoice.end_5p_domain, SelectModeChoice.scaffold]);
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.select_mode_state.replace(modes));

      AppState final_state = app_state_reducer(initial_state, SelectModeToggle(SelectModeChoice.loopout));

      SelectModeState expected_modes =
          SelectModeState().set_modes([SelectModeChoice.loopout, SelectModeChoice.scaffold]);
      expect(final_state.ui_state.select_mode_state, expected_modes);
    });
    test('test SelectModeToggle to turn end on  / turn crossover and loopouts off', () {
      SelectModeState modes = SelectModeState()
          .set_modes([SelectModeChoice.crossover, SelectModeChoice.loopout, SelectModeChoice.scaffold]);
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.select_mode_state.replace(modes));

      AppState final_state =
          app_state_reducer(initial_state, SelectModeToggle(SelectModeChoice.end_3p_strand));

      SelectModeState expected_modes =
          SelectModeState().set_modes([SelectModeChoice.end_3p_strand, SelectModeChoice.scaffold]);
      expect(final_state.ui_state.select_mode_state, expected_modes);
    });

    test('SelectModeToggle clears selectable store', () {
      SelectModeState modes = SelectModeState()
          .set_modes([SelectModeChoice.crossover, SelectModeChoice.loopout, SelectModeChoice.scaffold]);
      SelectablesStore selectables_store = SelectablesStore().select(two_helices_design.strands[0].dnaend_3p);
      AppState initial_state = app_state_from_design(two_helices_design).rebuild((b) => b
        ..ui_state.storables.select_mode_state.replace(modes)
        ..ui_state.selectables_store.replace(selectables_store));

      AppState final_state =
          app_state_reducer(initial_state, SelectModeToggle(SelectModeChoice.end_3p_strand));
      expect(final_state.ui_state.selectables_store, SelectablesStore());
    });

    test('test SelectModeSet', () {
      List<SelectModeChoice> modes = [
        SelectModeChoice.crossover,
        SelectModeChoice.loopout,
        SelectModeChoice.scaffold
      ];
      AppState initial_state = app_state_from_design(two_helices_design);

      AppState final_state = app_state_reducer(initial_state, SelectModesSet(modes));

      expect(final_state.ui_state.select_mode_state, SelectModeState().set_modes(modes));
    });
  });

  group('View_Menu_options_tests:', () {
    test('Test_SetShowDNA', () {
      AppState initial_state = app_state_from_design(two_helices_design);

      AppState final_state = app_state_reducer(initial_state, ShowDNASet(true));
      expect(final_state.ui_state.show_dna, true);
      final_state = app_state_reducer(final_state, ShowDNASet(false));
      expect(final_state.ui_state.show_dna, false);
    });

    test('Test_ShowModificationsSet', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state = app_state_reducer(initial_state, ShowModificationsSet(true));
      expect(final_state.ui_state.show_modifications, true);
      final_state = app_state_reducer(final_state, ShowModificationsSet(false));
      expect(final_state.ui_state.show_modifications, false);
    });

    test('Test_SetModificationDisplayConnector', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state = app_state_reducer(initial_state, SetModificationDisplayConnector(true));
      expect(final_state.ui_state.modification_display_connector, true);
      final_state = app_state_reducer(final_state, SetModificationDisplayConnector(false));
      expect(final_state.ui_state.modification_display_connector, false);
    });

    test('Test_SetDisplayBaseOffsetsOfMajorTicks', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state = app_state_reducer(initial_state, DisplayMajorTicksOffsetsSet(true));
      expect(final_state.ui_state.display_base_offsets_of_major_ticks, true);
      final_state = app_state_reducer(final_state, DisplayMajorTicksOffsetsSet(false));
      expect(final_state.ui_state.display_base_offsets_of_major_ticks, false);
    });

    test('Test_SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state =
          app_state_reducer(initial_state, SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix(true));
      expect(final_state.ui_state.display_base_offsets_of_major_ticks_only_first_helix, true);
      final_state = app_state_reducer(final_state, SetDisplayBaseOffsetsOfMajorTicksOnlyFirstHelix(false));
      expect(final_state.ui_state.display_base_offsets_of_major_ticks_only_first_helix, false);
    });

    test('Test_etDisplayMajorTickWidths', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state = app_state_reducer(initial_state, SetDisplayMajorTickWidths(true));
      expect(final_state.ui_state.display_major_tick_widths, true);
      final_state = app_state_reducer(final_state, SetDisplayMajorTickWidths(false));
      expect(final_state.ui_state.display_major_tick_widths, false);
    });

    test('Test_SetDisplayMajorTickWidthsAllHelices', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state = app_state_reducer(initial_state, SetDisplayMajorTickWidthsAllHelices(true));
      expect(final_state.ui_state.display_major_tick_widths_all_helices, true);
      final_state = app_state_reducer(final_state, SetDisplayMajorTickWidthsAllHelices(false));
      expect(final_state.ui_state.display_major_tick_widths_all_helices, false);
    });

    test('Test_SetModificationFontSize', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state = app_state_reducer(initial_state, ModificationFontSizeSet(45));
      expect(final_state.ui_state.modification_font_size, 45);
    });

    test('Test_SetShowMismatches', () {
      AppState initial_state = app_state_from_design(two_helices_design);

      AppState final_state = app_state_reducer(initial_state, ShowMismatchesSet(true));
      expect(final_state.ui_state.show_mismatches, true);
      final_state = app_state_reducer(final_state, ShowMismatchesSet(false));
      expect(final_state.ui_state.show_mismatches, false);
    });

    test('Test_SetShowEditor', () {
      AppState initial_state = app_state_from_design(two_helices_design);

      AppState final_state = app_state_reducer(initial_state, OxviewShowSet(true));
      expect(final_state.ui_state.show_oxview, true);
      final_state = app_state_reducer(final_state, OxviewShowSet(false));
      expect(final_state.ui_state.show_oxview, false);
    });

    test('Test_SetOnlyDisplaySelectedHelices', () {
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.storables.side_selected_helix_idxs = SetBuilder<int>([1]));

      AppState final_state = app_state_reducer(initial_state, SetOnlyDisplaySelectedHelices(true));
      expect(final_state.ui_state.only_display_selected_helices, true);

      // Setting back to false should reset state back to initial state.
      final_state = app_state_reducer(final_state, SetOnlyDisplaySelectedHelices(false));
      expect(final_state.ui_state.only_display_selected_helices, false);
    });
  });

  group('test saving and loading files: ', () {
    test('Saving DNA design with no unsaved changes', () {
      AppState state = app_state_from_design(simple_strand_design);
      AppState new_state = app_state_reducer(state, SaveDNAFile());

      expect(new_state, state);
    });

    test('Saving DNA design with unsaved changes', () {
      AppState expected_state = app_state_from_design(simple_strand_design);
      AppState old_state = expected_state.rebuild((b) => b.ui_state.changed_since_last_save = false);
      AppState new_state = app_state_reducer(old_state, SaveDNAFile());

      expect(new_state == expected_state, true);
    });

    test('save_design_after_add_helix_to_design', () {
      AppState state = app_state_from_design(two_helices_design);
      state = app_state_reducer(state, HelixAdd(grid_position: GridPosition(0, 2)));
      state = app_state_reducer(state, SaveDNAFile());

      String two_helices_helix_add_json = r'''
 {
  "version": "''' +
          constants.CURRENT_VERSION +
          r'''",
  "grid": "square", 
  "helices": [ 
    {"grid_position": [0, 0]}, 
    {"grid_position": [0, 1]}, 
    {"grid_position": [0, 2], "max_offset": 16} 
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
    ''';
      Design two_helices_helix_add_design = Design.from_json(jsonDecode(two_helices_helix_add_json));

      expect(state.ui_state.changed_since_last_save, false);
      expect(state.undo_redo.undo_stack,
          BuiltList<UndoRedoItem>([new UndoRedoItem("create helix", two_helices_design)]));
      expect_design_equal(state.design, two_helices_helix_add_design);
    });

    test('load_a_valid_design', () {
      AppState state = app_state_from_design(two_helices_design);

      String filename = 'file_test.${constants.default_scadnano_file_extension}';
      AppState final_state =
          app_state_reducer(state, LoadDNAFile(content: simple_strand_json, filename: filename));

      AppState expected_state = app_state_from_design(simple_strand_design)
          .rebuild((b) => b..ui_state.storables.loaded_filename = filename);

      expect(final_state, expected_state);
    });

    test('load an invalid design should leave error message', () {
      AppState state = app_state_from_design(two_helices_design);

      String filename = 'bad_file_test.${constants.default_scadnano_file_extension}';
      AppState final_state = app_state_reducer(state, LoadDNAFile(content: 'not json', filename: filename));

      expect(final_state.error_message != null, true);
      expect(final_state.maybe_design == null, true);
    });

    test('load_and_save_design_with_unused_fields', () {
      var json_before = r'''
      {
        "version": "''' +
          constants.CURRENT_VERSION +
          r'''",
        "grid": "square",
        "extra_design_field": {
          "foo_field": "foo",
          "bar_field": "bar",
          "foobar_field": 42,
          "barfoo_field": [
            11,
            13,
            12.4
          ]
        },
        "helices": [
          {"grid_position": [0, 0], "extra_string": "foobar", "extra_int": 12},
          {"grid_position": [0, 1], "extra_double": 13.1213, "extra_object": {"foo": "field1", "bar": "field2", "foobar": "foo_foo"}, "extra_array": [4, 3, 2, "rand_string", {"object!": "object_field"}]}
        ],
        "strands": [
          {
            "extra_strand_field": {
              "foo_strand_field": "foo_strand",
              "bar_strand_field": "bar",
              "foobar_strand_field": 42,
              "barfoo_strand_field": [
                11,
                13,
                12.4,
                "strand_list_field"
              ]
            },
            "color": "#ff0003",
            "domains": [
              {"helix": 0, "forward": true, "start": 0, "end": 16}
            ],
            "name": "staple1", 
            "vendor_fields": {
              "scale": "25nm", "purification": "STD", "plate": "plate1", "well": "A1",
              "unused_idt_field_foo": {
                "foo_idt_field": "foo_idt",
                "bar_idt_field": "bar",
                "foobar_idt_field": 2,
                "barfoo_idt_field": [
                  12.4,
                  "idt_list_field",
                  "meow",
                  3
                ]
              }
            }
          },
          {
            "color": "#000000",
            "domains": [
              {"helix": 0, "forward": false, "start": 0, "end": 16}
            ]
          },
          {
            "color": "#000000",
            "domains": [
              {"helix": 1, "forward": true, "start": 0, "end": 16},
              {
                "loopout": 3,
                "unknown_field": "FOO"
              },
              {
                "helix": 1, "forward": false, "start": 0, "end": 16,
                "unused_bound_substrand_foo": {
                  "foo_bound_substrand": "foo_bound_substrand_value",
                  "bar_bound_substrand": "bar",
                  "foobar_bound_substrand": 2,
                  "barfoo_bound_substrand": [
                    12.4,
                    "bound_substrand_list_item",
                    "meow",
                    3
                  ]
                }
              }
            ],
            "5prime_modification": "/5Biosg/"
          }
        ],
        "modifications_5p_in_design": {
          "/5Biosg/": {
            "display_text": "B",
            "vendor_code": "/5Biosg/",
            "font_size": 30,
            "location": "5'",
            "extra_modification_field": {
              "foo_modification_field": "foo_modification",
              "bar_modification_field": "bar",
              "foobar_modification_field": 42,
              "barfoo_modification_field": [
                11,
                13,
                12.4,
                "modification_list_field"
              ]
            }
          }
        }
      }
      ''';
      AppState state = app_state_from_design(two_helices_design);

      String filename = 'two_helicies_with_unused_fields.${constants.default_scadnano_file_extension}';
      AppState final_state = app_state_reducer(state, LoadDNAFile(content: json_before, filename: filename));
      var json_before_current_version = json_before.replaceFirst("0.0.1", constants.CURRENT_VERSION);
      var json_map_before = json.decode(json_before_current_version);
      var json_map_after = final_state.design.to_json_serializable();

      expect(json_map_before, json_map_after);
    });
  });

  group('Mouseover_Data_tests:', () {
    test('MouseOverUpdate over an offset', () {
      //   0                  16
      //
      // 0 [------------------->
      //   <-------------------]
      //
      //   MouseOver here -
      //                  |
      //                  |
      //                  v
      //                  12
      // 1 [------------------->
      //   <-------------------]
      AppState state = app_state_from_design(two_helices_design);
      MouseoverParams mouseoverParams = MouseoverParams(1, 12, true);
      state =
          app_state_reducer(state, MouseoverDataUpdate(mouseover_params: [mouseoverParams].toBuiltList()));

      Helix helix = two_helices_design.helices[1];
      int offset = 12;
      Domain domain = two_helices_design.strands[2].domains[0];

      expect(state.ui_state.mouseover_datas[0].helix, helix);
      expect(state.ui_state.mouseover_datas[0].offset, offset);
      expect(state.ui_state.mouseover_datas[0].domain, domain);
    });

    test('MouseOverUpdate from different offset same strand', () {
      //   0                  16
      //
      // 0 [------------------->
      //   <-------------------]
      //
      //        from here -
      //                  |   - to here
      //                  |   |
      //                  v   v
      //                  12 13
      // 1 [------------------->
      //   <-------------------]
      AppState state = app_state_from_design(two_helices_design);
      MouseoverParams mouseoverParams = MouseoverParams(1, 12, true);
      state =
          app_state_reducer(state, MouseoverDataUpdate(mouseover_params: [mouseoverParams].toBuiltList()));

      Helix helix = two_helices_design.helices[1];
      Domain domain = two_helices_design.strands[2].domains[0];

      mouseoverParams = MouseoverParams(1, 13, true);
      state =
          app_state_reducer(state, MouseoverDataUpdate(mouseover_params: [mouseoverParams].toBuiltList()));

      expect(state.ui_state.mouseover_datas[0].helix, helix);
      expect(state.ui_state.mouseover_datas[0].offset, 13);
      expect(state.ui_state.mouseover_datas[0].domain, domain);
    });

    test('MouseOverUpdate from same offset different strand', () {
      //   0                  16
      //
      // 0 [------------------->
      //   <-------------------]
      //
      //        from here -
      //                  |
      //                  |
      //                  v
      //                  12
      // 1 [------------------->
      //   <-------------------]
      //                  12
      //                  ^
      //                  |
      //                  |
      //                  to here
      AppState state = app_state_from_design(two_helices_design);
      MouseoverParams mouseoverParams = MouseoverParams(1, 12, true);
      state =
          app_state_reducer(state, MouseoverDataUpdate(mouseover_params: [mouseoverParams].toBuiltList()));

      Helix helix = two_helices_design.helices[1];
      int offset = 12;
      Domain domain = two_helices_design.strands[2].domains[0];

      mouseoverParams = MouseoverParams(1, 12, false);
      state =
          app_state_reducer(state, MouseoverDataUpdate(mouseover_params: [mouseoverParams].toBuiltList()));

      domain = two_helices_design.strands[3].domains[0];
      expect(state.ui_state.mouseover_datas[0].helix, helix);
      expect(state.ui_state.mouseover_datas[0].offset, offset);
      expect(state.ui_state.mouseover_datas[0].domain, domain);
    });

    test('MouseDataClear from helix to outside of helix', () {
      //   0                  16
      //
      // 0 [------------------->
      //   <-------------------]
      //
      //        from here -
      //                  |
      //                  |
      //                  v
      //                  12     <--- to outside
      // 1 [------------------->
      //   <-------------------]
      AppState state = app_state_from_design(two_helices_design);
      MouseoverParams mouseoverParams = MouseoverParams(1, 12, true);
      state =
          app_state_reducer(state, MouseoverDataUpdate(mouseover_params: [mouseoverParams].toBuiltList()));

      state = app_state_reducer(state, MouseoverDataClear());

      expect(state.ui_state.mouseover_datas, BuiltList<MouseoverData>());
    });

    //   0                  16
    //
    // 0 [------------------->
    //   <--------------------
    //                       |
    // 1 [--------------------
    //   <-------------------]
    String two_helices_crossover_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": true , "start": 0, "end": 16},
        {"helix": 0, "forward": false , "start": 0, "end": 16}
      ]
    },
    {
      "domains": [
        {"helix": 1, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
    Design two_helices_crossover_design = Design.from_json(jsonDecode(two_helices_crossover_json));
    test('HelixRollSetAtOther', () {
      AppState state = app_state_from_design(two_helices_crossover_design);

      state = app_state_reducer(
          state, HelixRollSetAtOther(0, 1, false, 15)); // helix_idx, other_idx, forward, anchor

      Helix expected_helix0 =
          two_helices_crossover_design.helices.values.first.rebuild((b) => b..roll = 235.71428571428567);

      expect(state.design.helices.values.first, expected_helix0);

      state = app_state_reducer(
          state, HelixRollSetAtOther(1, 0, true, 15)); // helix_idx, other_idx, forward, anchor

      Helix expected_helix1 =
          two_helices_crossover_design.helices.values.last.rebuild((b) => b..roll = 205.71428571428567);

      expect(state.design.helices.values.first, expected_helix0);
      expect(state.design.helices.values.last, expected_helix1);
    });
  });

  test('Error message set', () {
    AppState state = util.default_state();
    String message = 'This is an error';
    state = app_state_reducer(state, ErrorMessageSet(message));

    expect(state.error_message, message);
  });

  group('Selection box (side view) tests: ', () {
    Point point = new Point(0, 0);
    bool toggle = true;
    bool is_main = false;
    SelectionBox selectionBox;
    test('SelectionBoxCreate', () {
      selectionBox = optimized_selection_box_reducer(null, SelectionBoxCreate(point, toggle, is_main));
      SelectionBox expected = SelectionBox(point, toggle, is_main);

      expect(selectionBox, expected);
    });

    test('SelectionBoxSizeChange', () {
      Point dragPoint = new Point(5, 10);
      selectionBox =
          optimized_selection_box_reducer(selectionBox, SelectionBoxSizeChange(dragPoint, is_main));

      SelectionBox expected = SelectionBox(point, toggle, is_main).rebuild((b) => b..current = dragPoint);

      expect(selectionBox, expected);
    });

    test('SelectionBoxRemove', () {
      selectionBox = optimized_selection_box_reducer(selectionBox, SelectionBoxRemove(is_main));
      expect(selectionBox, null);
    });
  });

  group('Mouse grid position (side view) tests: ', () {
    AppState state = util.default_state();
    test('MouseGridPositionSideUpdate', () {
      GridPosition gridPosition = GridPosition(4, 2);
      state = app_state_reducer(state, MouseGridPositionSideUpdate(gridPosition));

      expect(state.ui_state.side_view_grid_position_mouse_cursor, gridPosition);
    });

    test('MouseGridPositionSideClear', () {
      state = app_state_reducer(state, MouseGridPositionSideClear());
      expect(state.ui_state.side_view_grid_position_mouse_cursor, null);
    });
  });

  group('Selectables ends tests: ', () {
    //   0                  16
    //
    // 0 [------------------->
    //   <-------------------]
    //
    // 1 [------------------->
    //   <-------------------]
    AppState state = app_state_from_design(two_helices_design);
    DNAEnd h0_forward_3p = two_helices_design.strands.first.dnaend_3p;
    DNAEnd h1_forward_3p = two_helices_design.strands[1].dnaend_3p;
    DNAEnd h1_reverse_5p = two_helices_design.strands.last.dnaend_5p;
    state = make_ends_selectable(state);
    test('select_an_end', () {
      //   0                  16
      //
      // 0 [------------------->  <--  select this 3p end
      //   <-------------------]
      //
      // 1 [------------------->
      //   <-------------------]
      state = app_state_reducer(state, Select(h0_forward_3p, toggle: false, only: false));
      expect(state.ui_state.selectables_store.selected_items, [h0_forward_3p].toBuiltSet());

      //   0                  16
      //
      // 0 [------------------->   <- already selected
      //   <-------------------]
      //
      // 1 [------------------->
      //   <-------------------]
      //   ^
      //   |
      //   select this 5p end
      state = app_state_reducer(state, Select(h1_reverse_5p, toggle: false, only: false));
      expect(state.ui_state.selectables_store.selected_items, [h0_forward_3p, h1_reverse_5p].toBuiltSet());
    });

    test('Unselect end with toggle', () {
      //   0                  16
      //
      // 0 [------------------->   <- toggle this so it is now unselected
      //   <-------------------]
      //
      // 1 [------------------->
      //   <-------------------]
      //   ^
      //   |
      //   already selected
      state = app_state_reducer(state, Select(h0_forward_3p, toggle: true, only: false));
      expect(state.ui_state.selectables_store.selected_items, [h1_reverse_5p].toBuiltSet());
    });

    test('Selecting another end with `only = true` should deselect all other items', () {
      //   0                  16
      //
      // 0 [------------------->
      //   <-------------------]
      //
      // 1 [------------------->    <- Select this end with `only = true`
      //   <-------------------]
      //   ^
      //   |
      //   already selected but should now be unselected because of `only = true`
      state = app_state_reducer(state, Select(h1_forward_3p, toggle: false, only: true));
      expect(state.ui_state.selectables_store.selected_items, [h1_forward_3p].toBuiltSet());
    });

    test('SelectionClear clears all selected items', () {
      state = app_state_reducer(state, SelectionsClear());
      expect(state.ui_state.selectables_store.selected_items, BuiltSet<Selectable>());
    });

    // Setting up state for next test by selecting an end (first line in both subsequent tests):
    //   0                  16
    //
    // 0 [------------------->
    //   <-------------------]  <--  select this 5p end
    //
    // 1 [------------------->
    //   <-------------------]
    DNAEnd h0_reverse_5p = two_helices_design.strands.first.dnaend_5p;

    BuiltList<Selectable> selectables = [h0_forward_3p, h1_forward_3p, h1_reverse_5p].toBuiltList();
    test('SelectAll ends with `only = false`', () {
      state = app_state_reducer(state, Select(h0_reverse_5p, toggle: false, only: false));
      // Setting up state for next test by selecting an end:
      //   0                  16
      //
      // 0 [------------------->  <--  this needs to be selected
      //   <-------------------]  <--  this end STAYS SELECTED
      //
      // 1 [------------------->  <--  this needs to be selected
      //   <-------------------]
      //   ^
      //   |
      //   this needs to be selected
      AppState local_state = app_state_reducer(state, SelectAll(selectables: selectables, only: false));
      BuiltSet<Selectable> expected_selectables =
          selectables.rebuild((b) => b..add(h0_reverse_5p)).toBuiltSet();
      expect(local_state.ui_state.selectables_store.selected_items, expected_selectables);
    });

    test('SelectAll ends with `only = true`', () {
      state = app_state_reducer(state, Select(h0_reverse_5p, toggle: false, only: false));
      // Setting up state for next test by selecting an end:
      //   0                  16
      //
      // 0 [------------------->  <--  this needs to be selected
      //   <-------------------]  <--  this end needs to be UNSELECTED
      //
      // 1 [------------------->  <--  this needs to be selected
      //   <-------------------]
      //   ^
      //   |
      //   this needs to be selected
      AppState local_state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      BuiltSet<Selectable> expected_selectables = selectables.toBuiltSet();
      expect(local_state.ui_state.selectables_store.selected_items, expected_selectables);
    });
  });

  // simple_loopout_design
  //   0                  16
  //                       _
  //   AGTCAGTCAGTCAGTC   / \ A
  // 0 [--------------- -   | A
  //   <--------------- -   | T
  //   TCAGTCAGTCAGTCAG  \_/  T
  String simple_loopout_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "sequence": "AGTCAGTCAGTCAGTCAATTGACTGACTGACTGACT",
      "domains": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16},
        {"loopout": 4},
        {"helix": 0, "forward": false,  "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
  Design simple_loopout_design = Design.from_json(jsonDecode(simple_loopout_json));

  group('DeleteAllSelected tests:', () {
    // two_helices_join_inner_strands
    //   0                  16
    //
    // 0 [-------------------> strand0
    //   --------------------] strand1
    //  /
    //  |
    //  \
    // 1 -------------------->
    //   <-------------------] strand2
    Strand strand0 = two_helices_join_inner_strands.strands[0];
    Strand strand1 = two_helices_join_inner_strands.strands[1];
    Strand strand2 = two_helices_join_inner_strands.strands[2];
    test('select_and_delete_strands', () {
      AppState state = app_state_from_design(two_helices_join_inner_strands);
      BuiltList<Selectable> selectables = [strand0, strand1].toBuiltList();

      state = app_state_reducer(state, SelectModesSet([SelectModeChoice.strand]));
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      expect(state.ui_state.selectables_store.selected_items, selectables.toBuiltSet());

      state = app_state_reducer(state, DeleteAllSelected());

      BuiltList<Strand> remaining_strands = [strand2].toBuiltList();
      expect(state.design.strands, remaining_strands);
    });
    test('Select and delete dna ends', () {
      // two_helices_join_inner_strands
      //   0                  16
      //
      // 0 [-------------------> <--- select this end
      //   --------------------] <--- select this end
      //  /
      //  |
      //  \
      // 1 --------------------> <--- select this end (this is intentionally reduntant)
      //   <-------------------] strand2
      AppState state = app_state_from_design(two_helices_join_inner_strands);
      BuiltList<Selectable> selectables =
          [strand0.dnaend_3p, strand1.dnaend_5p, strand1.dnaend_3p].toBuiltList();

      state = app_state_reducer(
          state, SelectModesSet([SelectModeChoice.end_3p_strand, SelectModeChoice.end_5p_strand]));
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      expect(state.ui_state.selectables_store.selected_items, selectables.toBuiltSet());

      state = app_state_reducer(state, DeleteAllSelected());

      BuiltList<Strand> remaining_strands = [strand2].toBuiltList();
      expect(state.design.strands, remaining_strands);
    });

    test('Select and delete crossover with no dna sequence (see issue #103)', () {
      AppState state = app_state_from_design(two_helices_join_inner_strands);
      Crossover crossover = strand1.crossovers.first;

      state = app_state_reducer(state, SelectModesSet([SelectModeChoice.crossover]));
      state = app_state_reducer(state, Select(crossover, only: false, toggle: false));

      expect(state.ui_state.selectables_store.selected_items, [crossover].toBuiltSet());

      state = app_state_reducer(state, DeleteAllSelected());
      // two_helices_join_inner_strands
      //   0                  16
      //
      // 0 [-------------------> strand0
      //   <-------------------]
      //
      // 1 [------------------->
      //   <-------------------] strand2
      expect_design_equal(state.design, two_helices_design);
    });

    // simple_strand_design
    //     0            16
    //    AGTCAGTCAGTCAGTC
    // 0  [-----------------          1st strand
    //   ----------------]  \         2nd strand
    //  | TCAGTCAGTCAGTCAG   |
    //  |                    |
    //  |  0             16  |
    //  \ AATTCCGGAATTCCGG   |
    // 1 --------------------/ ---
    //  ---------------------     \
    // /  TTAAGGCCTTAAGGCC        |
    // |                          |    <----DELETE THIS CROSSOVER
    // |                          |
    // |   0             16       |
    // \  AAAATTTTCCCCGGGG        |
    //  ----------------->        /
    // 2  <----------------------
    //    TTTTAAAAGGGGCCCC
    test('Select and delete crossover with dna sequence', () {
      AppState state = app_state_from_design(simple_strand_design);
      Crossover crossover = simple_strand_design.strands.last.crossovers.last;

      state = app_state_reducer(state, SelectModesSet([SelectModeChoice.crossover]));
      state = app_state_reducer(state, Select(crossover, only: false, toggle: false));

      expect(state.ui_state.selectables_store.selected_items, [crossover].toBuiltSet());

      state = app_state_reducer(state, DeleteAllSelected());
      // simple_strand_design after deleting crossover
      //     0            16
      //    AGTCAGTCAGTCAGTC
      // 0  [-----------------          1st strand
      //   ----------------]  \         2nd strand
      //  | TCAGTCAGTCAGTCAG   |
      //  |                    |
      //  |  0             16  |
      //  \ AATTCCGGAATTCCGG   |
      // 1 ---------------->   /
      //  ---------------------
      // /  TTAAGGCCTTAAGGCC
      // |
      // |
      // |   0             16
      // \  AAAATTTTCCCCGGGG
      //  ----------------->
      // 2  <--------------]            3rd strand
      //    TTTTAAAAGGGGCCCC
      String expected_json = r'''
 {
  "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]},{"grid_position": [0, 1]}, {"grid_position": [0, 2]} ],
  "strands": [
    {
      "sequence": "AGTCAGTCAGTCAGTCCCGGAATTCCGGAATTAAAATTTTCCCCGGGG",
      "domains": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16},
        {"helix": 1, "forward": false, "start": 0, "end": 16},
        {"helix": 2, "forward": true,  "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "GACTGACTGACTGACTAATTCCGGAATTCCGG",
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 16},
        {"helix": 1, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "CCCCGGGGAAAATTTT",
      "domains": [
        {"helix": 2, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
      Design expected = Design.from_json(jsonDecode(expected_json));

      expect_design_equal(state.design, expected);
    });

    test('select_and_delete_loopout', () {
      // simple_loopout_design
      //   0                  16
      //                       _
      //   AGTCAGTCAGTCAGTC   / \ A
      // 0 [--------------- -   | A
      //   <--------------- -   | T
      //   TCAGTCAGTCAGTCAG  \_/  T
      AppState state = app_state_from_design(simple_loopout_design);

      Loopout loopout = simple_loopout_design.strands.first.loopouts.first;

      state = app_state_reducer(state, SelectModesSet([SelectModeChoice.loopout]));
      state = app_state_reducer(state, Select(loopout, only: false, toggle: false));

      expect(state.ui_state.selectables_store.selected_items, [loopout].toBuiltSet());

      state = app_state_reducer(state, DeleteAllSelected());
      //   0                  16
      //
      //   AGTCAGTCAGTCAGTC
      // 0 [-------------->
      //   <--------------]
      //   TCAGTCAGTCAGTCAG
      String expected_json = r'''
 {
  "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "sequence": "AGTCAGTCAGTCAGTC",
      "domains": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "GACTGACTGACTGACT",
      "domains": [
        {"helix": 0, "forward": false,  "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
      Design expected = Design.from_json(jsonDecode(expected_json));

      expect_design_equal(state.design, expected);
    });
  });

  group('Helix select (side view) tests: ', () {
    // simple_strand_design
    //     0            16
    //    AGTCAGTCAGTCAGTC
    // 0  [-----------------          1st strand
    //   ----------------]  \         2nd strand
    //  | TCAGTCAGTCAGTCAG   |
    //  |                    |
    //  |  0             16  |
    //  \ AATTCCGGAATTCCGG   |
    // 1 --------------------/ ---
    //  ---------------------     \
    // /  TTAAGGCCTTAAGGCC        |
    // |                          |
    // |                          |
    // |   0             16       |
    // \  AAAATTTTCCCCGGGG        |
    //  ----------------->        /
    // 2  <----------------------
    //    TTTTAAAAGGGGCCCC
    AppState state = app_state_from_design(simple_strand_design);

    test('HelixSelect', () {
      state = app_state_reducer(state, HelixSelect(0, true));
      expect(state.ui_state.side_selected_helix_idxs, [0].toBuiltList());
      state = app_state_reducer(state, HelixSelect(1, true));
      expect(state.ui_state.side_selected_helix_idxs, [0, 1].toBuiltList());
      state = app_state_reducer(state, HelixSelect(0, true));
      expect(state.ui_state.side_selected_helix_idxs, [1].toBuiltList());
      state = app_state_reducer(state, HelixSelect(1, false));
      expect(state.ui_state.side_selected_helix_idxs, [1].toBuiltList());
    });

    test('HelixSelect_only_display_selected_helices)', () {
      AppState state = app_state_from_design(simple_strand_design);
      state = app_state_reducer(state, HelixSelect(1, true));
      state = app_state_reducer(state, SetOnlyDisplaySelectedHelices(true));
      expect(state.ui_state.side_selected_helix_idxs, [1].toBuiltList());
      expect(state.ui_state.side_selected_helix_idxs, BuiltSet<int>([1]));
    });

    test('HelixSelectionClear', () {
      state = app_state_reducer(state, HelixSelectionsClear());
      expect(state.ui_state.side_selected_helix_idxs, BuiltList<int>());
    });

    test('HelixSelectionClear_only_display_selected_helices', () {
      // setup
      AppState initial_state = app_state_from_design(simple_strand_design);
      AppState state = app_state_reducer(initial_state, HelixSelect(1, true));
      state = app_state_reducer(state, SetOnlyDisplaySelectedHelices(true));
      expect(state.ui_state.only_display_selected_helices, true);
      expect(state.ui_state.side_selected_helix_idxs, BuiltSet<int>([1]));
      expect(state.design, simple_strand_design);

      // clear should reset helix positions (but keep only display selected helices true).
      state = app_state_reducer(state, HelixSelectionsClear());
      expect(state.ui_state.only_display_selected_helices, true);
      expect(state.ui_state.side_selected_helix_idxs, BuiltList<int>());
      expect(state.design, simple_strand_design);
    });

    // Distance from selection box to enclosing helix.
    var MARGIN = 1;
    test('HelixSelectionAdjust', () {
      // Create box that wraps around the grid from (-radius, -radius) to (radius, radius) to select helix 0
      var x = state.design.geometry.distance_between_helices_svg / 2.0 + MARGIN;
      var y = state.design.geometry.distance_between_helices_svg / 2.0 + MARGIN;
      SelectionBox box = SelectionBox(Point(-x, -y), false, false).rebuild((b) => b..current = Point(x, y));
      state = app_state_reducer(state, HelixSelectionsAdjust(true, box));
      expect(state.ui_state.side_selected_helix_idxs, [0].toBuiltList());
    });

    test('HelixSelectionAdjust_with_toggle_on', () {
      // Currently, 0 is selected, so selecting all helices should unselect 0 and select 1 and 2
      var x = state.design.geometry.distance_between_helices_svg / 2.0 + MARGIN;
      var y = state.design.geometry.distance_between_helices_svg * 3.0 + MARGIN;
      SelectionBox box = SelectionBox(Point(-x, -x), false, false).rebuild((b) => b..current = Point(x, y));
      state = app_state_reducer(state, HelixSelectionsAdjust(true, box));
      expect(state.ui_state.side_selected_helix_idxs, [1, 2].toBuiltList());
    });

    test('HelixSelectionAdjust_with_toggle_on_only_display_selected_helices)', () {
      // setup (set only display selected helices to true and select just 0)
      AppState initial_state = app_state_from_design(simple_strand_design);
      AppState state = app_state_reducer(initial_state, SetOnlyDisplaySelectedHelices(true));
      state = app_state_reducer(state, HelixSelect(0, true));

      // Unselect 0 and select 1 and 2
      var x = state.design.geometry.distance_between_helices_svg / 2.0 + MARGIN;
      var y = state.design.geometry.distance_between_helices_svg * 3 + MARGIN;
      SelectionBox box = SelectionBox(Point(-x, -x), false, false).rebuild((b) => b..current = Point(x, y));
      state = app_state_reducer(state, HelixSelectionsAdjust(true, box));

      expect(state.ui_state.only_display_selected_helices, true);
      expect(state.ui_state.side_selected_helix_idxs, BuiltList<int>([1, 2]));
      expect(state.design, simple_strand_design);
    });

    test('Helix selection clears after load', () {
      AppState initial_state = app_state_from_design(simple_strand_design).rebuild((b) => b
        ..ui_state.storables.side_selected_helix_idxs = SetBuilder<int>([0, 2])
        ..ui_state.storables.clear_helix_selection_when_loading_new_design = true);
      AppState final_state = app_state_reducer(
          initial_state, LoadDNAFile(content: simple_helix_no_seq_json, filename: 'test.sc'));
      expect(final_state.ui_state.storables.side_selected_helix_idxs, BuiltSet<int>());
    });

    test('Helix selection saved after load', () {
      AppState initial_state = app_state_from_design(simple_strand_design).rebuild((b) => b
        ..ui_state.storables.side_selected_helix_idxs = SetBuilder<int>([0, 2])
        ..ui_state.storables.clear_helix_selection_when_loading_new_design = false);
      AppState final_state =
          app_state_reducer(initial_state, LoadDNAFile(content: simple_strand_json, filename: 'test.sc'));
      expect(final_state.ui_state.storables.side_selected_helix_idxs, BuiltSet<int>([0, 2]));
    });

    test('Helix selection saved after load (remove extraneous selected helices)', () {
      AppState initial_state = app_state_from_design(simple_strand_design).rebuild((b) => b
        ..ui_state.storables.side_selected_helix_idxs = SetBuilder<int>([0, 2])
        ..ui_state.storables.clear_helix_selection_when_loading_new_design = false);
      AppState final_state = app_state_reducer(
          initial_state, LoadDNAFile(content: simple_helix_no_seq_json, filename: 'test.sc'));
      expect(final_state.ui_state.storables.side_selected_helix_idxs, BuiltSet<int>([0]));
    });
  });

  group('Helix_Change_min_max_offsets', () {
    // simple_strand_design
    //     0            16
    //    AGTCAGTCAGTCAGTC
    // 0  [-----------------          1st strand
    //   ----------------]  \         2nd strand
    //  | TCAGTCAGTCAGTCAG   |
    //  |                    |
    //  |  0             16  |
    //  \ AATTCCGGAATTCCGG   |
    // 1 --------------------/ ---
    //  ---------------------     \
    // /  TTAAGGCCTTAAGGCC        |
    // |                          |
    // |                          |
    // |   0             16       |
    // \  AAAATTTTCCCCGGGG        |
    //  ----------------->        /
    // 2  <----------------------
    //    TTTTAAAAGGGGCCCC
    test('HelixOffsetChange min/max offsets', () {
      AppState state = app_state_from_design(simple_strand_design);

      state = app_state_reducer(state, HelixOffsetChange(helix_idx: 0, min_offset: 0, max_offset: 60));
      state = app_state_reducer(state, HelixOffsetChange(helix_idx: 1, min_offset: 0, max_offset: 70));
      // No change.
      state = app_state_reducer(state, HelixOffsetChange(helix_idx: 2, min_offset: 0, max_offset: 16));

      String expected_json = r'''
 {
  "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ 
    {"grid_position": [0, 0], "max_offset": 60},
    {"grid_position": [0, 1], "max_offset": 70},
    {"grid_position": [0, 2] }
  ],
  "strands": [
    {
      "sequence": "AGTCAGTCAGTCAGTCCCGGAATTCCGGAATTAAAATTTTCCCCGGGG",
      "domains": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16},
        {"helix": 1, "forward": false, "start": 0, "end": 16},
        {"helix": 2, "forward": true,  "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "GACTGACTGACTGACTAATTCCGGAATTCCGGCCCCGGGGAAAATTTT",
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 16},
        {"helix": 1, "forward": true , "start": 0, "end": 16},
        {"helix": 2, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });
  });

  test('HelixOffsetChangeAll', () {
    AppState state = app_state_from_design(simple_strand_design);
    state = app_state_reducer(state, HelixOffsetChangeAll(min_offset: 0, max_offset: 50));

    String expected_json = r'''
 {
  "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ 
    {"grid_position": [0, 0], "max_offset": 50},
    {"grid_position": [0, 1], "max_offset": 50},
    {"grid_position": [0, 2], "max_offset": 50 }
  ],
  "strands": [
    {
      "sequence": "AGTCAGTCAGTCAGTCCCGGAATTCCGGAATTAAAATTTTCCCCGGGG",
      "domains": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16},
        {"helix": 1, "forward": false, "start": 0, "end": 16},
        {"helix": 2, "forward": true,  "start": 0, "end": 16}
      ]
    },
    {
      "sequence": "GACTGACTGACTGACTAATTCCGGAATTCCGGCCCCGGGGAAAATTTT",
      "domains": [
        {"helix": 0, "forward": false, "start": 0, "end": 16},
        {"helix": 1, "forward": true , "start": 0, "end": 16},
        {"helix": 2, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
 }
  ''';
    Design expected_design = Design.from_json(jsonDecode(expected_json));
    expect_design_equal(state.design, expected_design);
  });

  String design_3helicies_strands_on_1and2_json = r'''
 {
  "version": "''' +
      constants.CURRENT_VERSION +
      r'''", "grid": "square", "helices": [ 
    {"grid_position": [0, 0]},
    {"grid_position": [0, 1]},
    {"grid_position": [0, 2]}
  ],
  "strands": [
    {
      "domains": [
        {"helix": 1, "forward": false, "start": 0, "end": 10}
      ]
    },
    {
      "domains": [
        {"helix": 2, "forward": true, "start": 0, "end": 20}
      ]
    }
  ]
 }
  ''';
  Design design_3helicies_strands_on_1and2 =
      Design.from_json(jsonDecode(design_3helicies_strands_on_1and2_json));
  test('default_helix_max_offsets', () {
    for (var helix = 0; helix < 3; helix++) {
      int expected_max_offset_helix = 20;
      int actual_max_offset_helix = design_3helicies_strands_on_1and2.helices[helix].max_offset;
      expect(actual_max_offset_helix, expected_max_offset_helix);
    }
  });

  group('Loopout length change test:', () {
    test('LoopoutLengthChange', () {
      // simple_loopout_design
      //   0                  16
      //                       _
      //   AGTCAGTCAGTCAGTC   / \ A
      // 0 [--------------- -   | A
      //   <--------------- -   | T
      //   TCAGTCAGTCAGTCAG  \_/  T
      AppState state = app_state_from_design(simple_loopout_design);

      // test changing loopout length to 5
      Loopout loopout = simple_loopout_design.strands.first.loopouts.first;
      state = app_state_reducer(state, LoopoutLengthChange(loopout, 5));
      String expected_json = r'''
      {
        "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
          "strands": [
          {
            "sequence": "AGTCAGTCAGTCAGTCAATT?GACTGACTGACTGACT",
            "domains": [
              {"helix": 0, "forward": true,  "start": 0, "end": 16},
              {"loopout": 5},
              {"helix": 0, "forward": false,  "start": 0, "end": 16}
            ]
          }
        ]
      }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);

      // test changing loopout length to 3
      loopout = state.design.strands.first.loopouts.first;
      state = app_state_reducer(state, LoopoutLengthChange(loopout, 3));
      expected_json = r'''
      {
        "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
          "strands": [
          {
            "sequence": "AGTCAGTCAGTCAGTCAATGACTGACTGACTGACT",
            "domains": [
              {"helix": 0, "forward": true,  "start": 0, "end": 16},
              {"loopout": 3},
              {"helix": 0, "forward": false,  "start": 0, "end": 16}
            ]
          }
        ]
      }
      ''';
      expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });

    test('LoopoutLengthChange to 0 (removes loopout)', () {
      // simple_loopout_design
      //   0                  16
      //                       _
      //   AGTCAGTCAGTCAGTC   / \ A
      // 0 [--------------- -   | A
      //   <--------------- -   | T
      //   TCAGTCAGTCAGTCAG  \_/  T
      AppState state = app_state_from_design(simple_loopout_design);

      // test changing loopout length to 0
      Loopout loopout = simple_loopout_design.strands.first.loopouts.first;
      state = app_state_reducer(state, LoopoutLengthChange(loopout, 0));
      String expected_json = r'''
      {
        "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
          "strands": [
          {
            "sequence": "AGTCAGTCAGTCAGTCGACTGACTGACTGACT",
            "domains": [
              {"helix": 0, "forward": true,  "start": 0, "end": 16},
              {"helix": 0, "forward": false,  "start": 0, "end": 16}
            ]
          }
        ]
      }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });

    test('ConvertCrossoverToLoopout', () {
      //   0                  16
      //
      // 0 [------------------->
      //   --------------------]
      //  /
      //  |  <-- change this to a loopout of 4
      //  \
      // 1 -------------------->
      //   <-------------------]
      AppState state = app_state_from_design(two_helices_join_inner_strands);

      // bring back loopout
      Crossover crossover = state.design.strands[1].crossovers.first;
      state = app_state_reducer(state, ConvertCrossoverToLoopout(crossover, 4));

      String expected_json = r'''
 {
  "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]} ],
  "strands": [
    {
      "domains": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "domains": [
        {"helix": 0, "forward": false , "start": 0, "end": 16},
        {"loopout": 4},
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
  ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });
  });

  test('StrandCreate', () {
    //   0                  16
    //
    // 0
    //
    String one_empty_helix_json = r'''
    {
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [ {"grid_position": [0, 0], "max_offset": 16} ],
      "strands": []
    }
    ''';
    Design one_empty_helix_design = Design.from_json(jsonDecode(one_empty_helix_json));
    AppState state = app_state_from_design(one_empty_helix_design);

    //   0   3       9 10   16
    //
    // 0     [------->
    //
    int helix_idx = 0;
    bool forward = true;
    int start = 3;
    int end = 10;
    state = app_state_reducer(
      state,
      StrandCreateCommit(
        helix_idx: helix_idx,
        forward: forward,
        start: start,
        end: end,
        color: Color.rgb(0, 0, 0),
      ),
    );
    Domain domain = Domain(
      helix: helix_idx,
      forward: true,
      start: start,
      end: end,
      deletions: [],
      insertions: [],
      is_scaffold: false,
      dna_sequence: null,
      is_first: true,
      is_last: true,
    );
    Strand strand = Strand([domain].toBuiltList());
    Design expected = one_empty_helix_design.rebuild((b) => b.strands.replace([strand]));
    expect_design_equal(state.design, expected);

    // should skip creating strand if there is already one there.
    //   0   3  4    9 10  14  16
    //
    // 0     [------->
    //          [--------->    <-- attempt to create this strand should fail
    //          tries to create a strand with start = 4 and end = 14 should fail
    int bad_start = 4;
    int bad_end = 14;

    state = app_state_reducer(
      state,
      StrandCreateCommit(
        helix_idx: helix_idx,
        forward: forward,
        start: bad_start,
        end: bad_end,
        color: Color.rgb(0, 0, 0),
      ),
    );

    expect_design_equal(state.design, expected);
  });
  group('Potential_crossover_and_linking_crossover_and_linking_by_crossover', () {
    //   0                  16
    //
    // 0 [------------------->
    //   <-------------------]
    //
    // 1 [------------------->
    //   <-------------------]
    Map<int, Point<num>> svg_position_map = util.helices_assign_svg(
        two_helices_design.geometry, false, two_helices_design.helices, two_helices_design.groups);

    DNAEnd dnaEnd = two_helices_design.strands.first.dnaend_5p;
    Helix helix0 = two_helices_design.helices.values.first;
    Point<num> start_point = helix0.svg_base_pos(0, true, svg_position_map[helix0.idx].y);

    // The two states of the two store's reducers we want to test:
    AppState state = app_state_from_design(two_helices_design);
    PotentialCrossover potentialCrossoverState = null;

    //   0                  16
    //   Click this one
    //   |
    //   v
    // 0 [------------------->
    //   <-------------------]
    //
    // 1 [------------------->
    //   <-------------------]
    PotentialCrossover potentialCrossover = PotentialCrossover(
      address: Address(
        helix_idx: 0,
        offset: 0,
        forward: true,
      ),
      color: '#000',
      dna_end_first_click: dnaEnd,
      start_point: start_point,
      current_point: start_point,
    );
    test('PotentialCrossoverCreate', () {
      Action action = PotentialCrossoverCreate(potential_crossover: potentialCrossover);

      // Test AppState reducer
      state = app_state_reducer(state, action);
      expect(state.ui_state.potential_crossover_is_drawing, true);

      // Test potential_crossover store's reducer
      potentialCrossoverState = optimized_potential_crossover_reducer(potentialCrossoverState, action);
      expect(potentialCrossoverState, potentialCrossover);
    });

    test('PotentialCrossoverMove', () {
      Point<num> movePoint = Point(42, 24);
      Action action = PotentialCrossoverMove(point: movePoint);

      // Test potential_crossover store's reducer
      PotentialCrossover expectedPotentialCrossover =
          potentialCrossover.rebuild((b) => b.current_point = movePoint);
      potentialCrossoverState = optimized_potential_crossover_reducer(potentialCrossoverState, action);
      expect(potentialCrossoverState, expectedPotentialCrossover);
    });

    test('PotentialCrossoverRemove', () {
      Action action = PotentialCrossoverRemove();

      // Test potential_crossover store's reducer
      PotentialCrossover expectedPotentialCrossover = null;
      potentialCrossoverState = optimized_potential_crossover_reducer(potentialCrossoverState, action);
      expect(potentialCrossoverState, expectedPotentialCrossover);
    });
  });

  group('Select all in helix group test', () {
    /* 0       8
       |-------|

    0  [------->    default_group

    1  [------->    Group 2
    */
    test('SelectWholeStrandsInOneHelixGroup', () {
      var helices = [
        Helix(idx: 0, max_offset: 100, grid: Grid.square),
        Helix(idx: 1, max_offset: 100, grid: Grid.square, group: "Group 2"),
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design.draw_strand(0, 0).move(9).commit().draw_strand(1, 0).move(9).commit();
      var default_group_strand = design.strands.first;
      var action = SelectAllSelectable(current_helix_group_only: true);
      var state = app_state_from_design(design);
      var selectables_store = select_all_selectables_reducer(state.ui_state.selectables_store, state, action);
      expect(selectables_store.selected_strands.length, 1);
      expect(selectables_store.selected_strands.first, default_group_strand);
    });

    /* 0       8
       |-------|

    0  [-------> [-------\    default_group
                         |
                         |
    1  [------->         |    Group 2
                 <-------/
    */
    test('SelectWholeStrandsInTwoHelixGroups', () {
      var helices = [
        Helix(idx: 0, max_offset: 100, grid: Grid.square),
        Helix(idx: 1, max_offset: 100, grid: Grid.square, group: "Group 2"),
      ];
      var design = Design(helices: helices, grid: Grid.square);

      design = design
          .draw_strand(0, 0)
          .move(9)
          .commit()
          .draw_strand(1, 0)
          .move(9)
          .commit()
          .draw_strand(0, 10)
          .move(9)
          .cross(1)
          .move(-9)
          .commit();
      var default_group_strand = design.strands.first;
      var action = SelectAllSelectable(current_helix_group_only: true);
      var state = app_state_from_design(design);
      var selectables_store = select_all_selectables_reducer(state.ui_state.selectables_store, state, action);
      expect(selectables_store.selected_strands.length, 1);
      expect(selectables_store.selected_strands.first, default_group_strand);
    });
  });

  group('Strands move test: ', () {
    //   0                  16                       32
    //
    // 0 [------------------->   strand0
    //   --------------------]   strand1
    //  /
    //  |
    //  \
    // 1 -------------------->
    //   <-------------------]   strand2
    String two_helices_with_empty_offsets_json = r'''
    {
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [
        {"grid_position": [0, 0], "max_offset": 32},
        {"grid_position": [0, 1], "max_offset": 32}
      ],
      "strands": [
        {
          "domains": [
            {"helix": 0, "forward": true , "start": 0, "end": 16}
          ]
        },
        {
          "domains": [
            {"helix": 0, "forward": false , "start": 0, "end": 16},
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
    ''';
    Design two_helices_with_empty_offsets = Design.from_json(jsonDecode(two_helices_with_empty_offsets_json));
    AppState state = app_state_from_design(two_helices_with_empty_offsets);
    StrandsMove strandsMove = null;

    Strand strand1 = two_helices_with_empty_offsets.strands[1];
    Strand strand2 = two_helices_with_empty_offsets.strands[2];
    test('StrandsMoveStart (no copy)', () {
      //   0        7         16                       32
      //
      // 0 [------------------->
      //   --------------------]    <--   select strand1
      //  /         ^
      //  |         |
      //  \         strand move start here
      // 1 -------------------->
      //   <-------------------]    <--   select strand2
      //
      //
      //
      BuiltList<Selectable> selectables = [strand1, strand2].toBuiltList();
      int offset = 7;
      int helix_idx = 0;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));
      state = app_state_reducer(
          state,
          StrandsMoveStart(
            address: address,
            copy: false,
            strands: selectables,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      expect(state.ui_state.selectables_store.selected_items, selectables.toBuiltSet());

      StrandsMove expected_strands_move = StrandsMove(
          strands_moving: selectables,
          all_strands: state.design.strands,
          original_address: address,
          helices: state.design.helices,
          groups: state.design.groups,
          original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          copy: false);

      expect(state.ui_state.strands_move, expected_strands_move);

      // Passes this value on for StrandsMoveCommit test.
      strandsMove = state.ui_state.strands_move;
    });

    test('StrandsMoveAdjustOffset (not allowable)', () {
      //   0        7         16           23    30    32
      //
      // 0 [------------------->
      //   --------------------]
      //  /                                      ^
      //  |                                      |
      //  \                                      moved to here
      // 1 -------------------->
      //   <-------------------]
      int offset = 30;
      int helix_idx = 0;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      // StrandsMove expected_strands_move = state.ui_state.strands_move.rebuild((b) => b
      //   ..allowable = false
      //   ..current_address.replace(address));
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));

      expect(state.ui_state.strands_move, strandsMove);
      // Passes this value on for StrandsMoveCommit test.
      strandsMove = state.ui_state.strands_move;
    });

    test('StrandsMoveAdjustOffset (is allowable)', () {
      //   0        7         16           23    30    32
      //
      // 0 [------------------->
      //   --------------------]
      //  /                                ^
      //  |                                |
      //  \                                moved to here
      // 1 -------------------->
      //   <-------------------]
      int offset = 23;
      int helix_idx = 0;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      StrandsMove expected_strands_move = state.ui_state.strands_move.rebuild((b) => b
        ..allowable = true
        ..current_address.replace(address));
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));

      expect(state.ui_state.strands_move, expected_strands_move);

      // Passes this value on for StrandsMoveCommit test.
      strandsMove = state.ui_state.strands_move;
    });

    test('StrandsMoveStop', () {
      state = app_state_reducer(state, StrandsMoveStop());
      expect(state.ui_state.strands_move, null);
    });

    test('StrandsMoveCommit (for non-copy)', () {
      //   0        7            16      23    30    32
      //
      // 0 [------------------->
      //                          --------------------]
      //                         /
      //                         |
      //                         \
      // 1                        -------------------->
      //                          <-------------------]
      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strandsMove, autopaste: false));

      String expected_json = r'''
      {
        "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [
          {"grid_position": [0, 0], "max_offset": 32},
          {"grid_position": [0, 1], "max_offset": 32}
        ],
        "strands": [
          {
            "domains": [
              {"helix": 0, "forward": true , "start": 0, "end": 16}
            ]
          },
          {
            "domains": [
              {"helix": 0, "forward": false , "start": 16, "end": 32},
              {"helix": 1, "forward": true  , "start": 16, "end": 32}
            ]
          },
          {
            "domains": [
              {"helix": 1, "forward": false , "start": 16, "end": 32}
            ]
          }
        ]
      }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));

      expect_design_equal(state.design, expected_design);

      // Should unselect the strands
      expect(state.ui_state.selectables_store.selected_items, BuiltList<Selectable>());
    });

    test('StrandsMoveStart (with copy)', () {
      //   0        7            16      23    30    32
      //
      // 0 [------------------->
      //                          --------------------]
      //                         /
      //                         |
      //                         \
      // 1                        -------------------->
      //                          <-------------------]    <-- select strand2
      //
      //                          copy!
      Strand new_strand2 = state.design.strands[2];
      BuiltList<Selectable> selectables = [new_strand2].toBuiltList();
      int offset = 16;
      int helix_idx = 1;
      bool forward = false;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, SelectAll(selectables: selectables, only: true));

      expect(state.ui_state.selectables_store.selected_items, selectables);

      state = app_state_reducer(
          state,
          StrandsMoveStart(
            address: address,
            copy: true,
            strands: selectables,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      StrandsMove expected_strands_move = StrandsMove(
          strands_moving: selectables,
          all_strands: state.design.strands,
          original_address: address,
          helices: state.design.helices,
          groups: state.design.groups,
          original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          copy: true);

      expect(state.ui_state.strands_move, expected_strands_move);

      // Allows next test to use this
      strandsMove = expected_strands_move;
    });

    test('StrandsMoveCommit (for copy) (see issue #114)', () {
      //   0        7            16      23    30    32
      //
      // 0 [------------------->
      //                          --------------------]
      //                         /
      //                         |
      //                         \
      // 1                        -------------------->
      //   <-------------------] <-------------------]
      int offset = 0;
      int helix_idx = 1;
      bool forward = false;
      Address address = Address(helix_idx: helix_idx, offset: offset, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));

      strandsMove = strandsMove.rebuild((b) => b.current_address = address.toBuilder());
      expect(state.ui_state.strands_move, strandsMove);

      state = app_state_reducer(state, StrandsMoveStop());
      expect(state.ui_state.strands_move, null);

      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strandsMove, autopaste: false));

      String expected_json = r'''
      {
        "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [
          {"grid_position": [0, 0], "max_offset": 32},
          {"grid_position": [0, 1], "max_offset": 32}
        ],
        "strands": [
          {
            "domains": [
              {"helix": 0, "forward": true , "start": 0, "end": 16}
            ]
          },
          {
            "domains": [
              {"helix": 0, "forward": false , "start": 16, "end": 32},
              {"helix": 1, "forward": true  , "start": 16, "end": 32}
            ]
          },
          {
            "domains": [
              {"helix": 1, "forward": false , "start": 16, "end": 32}
            ]
          },
          {
            "domains": [
              {"helix": 1, "forward": false , "start": 0, "end": 16}
            ]
          }
        ]
      }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));

      expect_design_equal(state.design, expected_design);

      // Should unselect the strands
      expect(state.ui_state.selectables_store.selected_items, BuiltList<Selectable>());
    }, skip: true);
    //FIXME: autopaste; unskip above when we figure out how to fix this test

    String two_helices_with_empty_offsets_non_sequential_idx_json = r'''
    {
      "version": "''' +
        constants.CURRENT_VERSION +
        r'''", "grid": "square", "helices": [
        {"grid_position": [0, 0], "max_offset": 32, "idx": 3},
        {"grid_position": [0, 1], "max_offset": 32, "idx": 4}
      ],
      "strands": [
        {
          "domains": [
            {"helix": 3, "forward": true , "start": 0, "end": 16}
          ]
        },
        {
          "domains": [
            {"helix": 3, "forward": false , "start": 0, "end": 16},
            {"helix": 4, "forward": true , "start": 0, "end": 16}
          ]
        },
        {
          "domains": [
            {"helix": 4, "forward": false , "start": 0, "end": 16}
          ]
        }
      ]
    }
    ''';
    Design two_helices_with_empty_offsets_non_sequential_idx_design =
        Design.from_json(jsonDecode(two_helices_with_empty_offsets_non_sequential_idx_json));
    AppState two_helicies_with_empty_offset_non_sequential_idx_state =
        app_state_from_design(two_helices_with_empty_offsets_non_sequential_idx_design);
    test('StrandsMoveAdjustOffset on out of sequence helices (see issue #240)', () {
      //   0                  16                       32
      //
      // 3 [------------------->   strand0
      //   --------------------]   strand1
      //  /
      //  |
      //  \
      // 4 -------------------->
      //   <-------------------]   strand2

      // Setup
      Strand strand0 = two_helices_with_empty_offsets_non_sequential_idx_design.strands[0];
      BuiltList<Selectable> selectables = [strand0].toBuiltList();
      int offset = 0;
      int helix_idx = 3;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      AppState state = app_state_reducer(two_helicies_with_empty_offset_non_sequential_idx_state,
          SelectAll(selectables: selectables, only: true));
      expect(state.ui_state.selectables_store.selected_items, selectables.toBuiltSet());

      // Expect move start to create correct strands_move object.
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));
      StrandsMove expected_strands_move = StrandsMove(
          strands_moving: selectables,
          all_strands: state.design.strands,
          original_address: address,
          helices: state.design.helices,
          groups: state.design.groups,
          original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          copy: false);
      expect(state.ui_state.strands_move, expected_strands_move);

      //   0                  16                       32
      //
      // 3 [------------------->   strand0: move one offset to the right
      //   --------------------]   strand1
      //  /
      //  |
      //  \
      // 4 -------------------->
      //   <-------------------]   strand2
      offset = 1;
      helix_idx = 3;
      forward = true;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));

      // Check address after adjusting:
      expected_strands_move = state.ui_state.strands_move.rebuild((b) => b
        ..allowable = true
        ..current_address.replace(address));
      expect(state.ui_state.strands_move, expected_strands_move);
    });

    test('StrandsMoveAdjustOffset on out of sequence helices (see issue #240) move to new helix', () {
      // select helix 0
      Strand strand0 = two_helices_with_empty_offsets_non_sequential_idx_design.strands[0];
      BuiltList<Selectable> selectables = [strand0].toBuiltList();
      int offset = 0;
      int helix_idx = 3;
      bool forward = true;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      AppState state = app_state_reducer(two_helicies_with_empty_offset_non_sequential_idx_state,
          SelectAll(selectables: selectables, only: true));
      expect(state.ui_state.selectables_store.selected_items, selectables.toBuiltSet());

      // start move
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //   0                  16                       32
      //
      // 3 [------------------->   drag this strand to here
      //   --------------------]   |
      //  /                        |
      //  |                        |
      //  \                        |
      // 4 -------------------->   v
      //   <-------------------]   [------------------->   moving strand (not placed yet)
      offset = 16;
      helix_idx = 4;
      forward = true;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));

      // Check address after adjusting:
      var expected_strands_move = state.ui_state.strands_move.rebuild((b) => b
        ..allowable = true
        ..current_address.replace(address));
      expect(state.ui_state.strands_move, expected_strands_move);
    });

    test('StrandsMoveAdjustOffset on out of sequence helices (see issue #240) exceed vertical boundary', () {
      // select strand1 and strand2
      Strand strand1 = two_helices_with_empty_offsets_non_sequential_idx_design.strands[1];
      Strand strand2 = two_helices_with_empty_offsets_non_sequential_idx_design.strands[2];
      BuiltList<Selectable> selectables = [strand1, strand2].toBuiltList();
      int offset = 0;
      int helix_idx = 3;
      bool forward = false;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      AppState state = app_state_reducer(two_helicies_with_empty_offset_non_sequential_idx_state,
          SelectAll(selectables: selectables, only: true));
      expect(state.ui_state.selectables_store.selected_items, selectables.toBuiltSet());

      StrandsMove expected_strands_move = StrandsMove(
          strands_moving: selectables,
          all_strands: state.design.strands,
          original_address: address,
          helices: state.design.helices,
          groups: state.design.groups,
          original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          copy: false);

      // start move
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //   0                  16                       32
      //
      // 3 [------------------->   strand0: move one offset to the right
      //   --------------------]   strand1   drag this left end
      //  /                                       |
      //  |                                       |
      //  \                                       v
      // 4 -------------------->                  to this level, so strand2 goes out of bound
      //   <-------------------]   strand2
      offset = 0;
      helix_idx = 4;
      forward = false;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));

      // Check address after adjusting (should be same as before since new one would not be valid):
      expect(state.ui_state.strands_move, expected_strands_move);
    });

    test('StrandsMoveAdjustOffset on out of sequence helices (see issue #240) exceed horizontal boundary',
        () {
      // select strand1 and strand2
      Strand strand1 = two_helices_with_empty_offsets_non_sequential_idx_design.strands[1];
      Strand strand2 = two_helices_with_empty_offsets_non_sequential_idx_design.strands[2];
      BuiltList<Selectable> selectables = [strand1, strand2].toBuiltList();
      int offset = 0;
      int helix_idx = 3;
      bool forward = false;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      AppState state = app_state_reducer(two_helicies_with_empty_offset_non_sequential_idx_state,
          SelectAll(selectables: selectables, only: true));
      expect(state.ui_state.selectables_store.selected_items, selectables.toBuiltSet());

      StrandsMove expected_strands_move = StrandsMove(
          strands_moving: selectables,
          all_strands: state.design.strands,
          original_address: address,
          helices: state.design.helices,
          groups: state.design.groups,
          original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          copy: false);

      // start move
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //   0                  16                       32
      //
      // 3 [------------------->   strand0: move one offset to the right
      //   --------------------]   strand1
      //  /                                       ^
      //  |                                       |
      //  \                                       |
      // 4 -------------------->                  drag strand1, strand2 all the way here
      //   <-------------------]   strand2
      offset = 19;
      helix_idx = 3;
      forward = false;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));

      // Check address after adjusting (should be same as before since new one would not be valid):
      expect(state.ui_state.strands_move, expected_strands_move);
    });

    test('StrandsMoveAdjustOffset on out of sequence helices (see issue #240) multiple adjust', () {
      // select strand1 and strand2
      Strand strand1 = two_helices_with_empty_offsets_non_sequential_idx_design.strands[1];
      Strand strand2 = two_helices_with_empty_offsets_non_sequential_idx_design.strands[2];
      BuiltList<Selectable> selectables = [strand1, strand2].toBuiltList();
      int offset = 0;
      int helix_idx = 3;
      bool forward = false;
      Address address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      AppState state = app_state_reducer(two_helicies_with_empty_offset_non_sequential_idx_state,
          SelectAll(selectables: selectables, only: true));
      expect(state.ui_state.selectables_store.selected_items, selectables.toBuiltSet());

      StrandsMove expected_strands_move = StrandsMove(
          strands_moving: selectables,
          all_strands: state.design.strands,
          original_address: address,
          helices: state.design.helices,
          groups: state.design.groups,
          original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          copy: false);

      // start move
      state = app_state_reducer(
          state,
          StrandsMoveStartSelectedStrands(
            address: address,
            copy: false,
            original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
          ));

      //   0                  16                       32
      //
      // 3 [------------------->   strand0:
      //                         --------------------]   strand1
      //                        /
      //                        |
      //                        \
      // 4                       -------------------->
      //                         <-------------------]   strand2
      offset = 16;
      helix_idx = 3;
      forward = false;
      address = Address(offset: offset, helix_idx: helix_idx, forward: forward);
      state = app_state_reducer(state, StrandsMoveAdjustAddress(address: address));
      expected_strands_move = state.ui_state.strands_move.rebuild((b) => b
        ..allowable = true
        ..current_address.replace(address));

      // Check address after adjusting (should be same as before since new one would not be valid):
      expect(state.ui_state.strands_move, expected_strands_move);
    });
  });

  group('insertion/deletion', () {
    //TODO: add some unit tests that test this when DNA sequences are on the domains, and both domains
    // having the deletion/insertion added are part of the same strand (e.g., a hairpin);
    // this caused a bug because adding the first deletion shifts the DNA sequence, which caused the
    // second domain to be unequal to its previous self in some internal equality check in the reducer
    // (bug has been fixed but it's good if the unit tests catch it)
    test('InsertionAdd', () {
      // Before
      //     0               16
      // 0   [--------------->
      //     <---------------]
      // After:
      //     0      8        16
      // 0   [------I-------->
      //     <------I--------]
      //
      // I = Insertion
      AppState state = app_state_from_design(simple_helix_no_seq_design);

      int offset = 8;
      Domain domain0 = simple_helix_no_seq_design.strands.first.domains.first;
      state = app_state_reducer(state, InsertionAdd(offset: offset, domain: domain0, all_helices: false));
      Domain domain1 = simple_helix_no_seq_design.strands.last.domains.first;
      state = app_state_reducer(state, InsertionAdd(offset: offset, domain: domain1, all_helices: false));
      String expected_json = r'''
      {
        "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
        "strands": [
          {
            "domains": [
              { "helix": 0, "forward": true , "start": 0, "end": 16, "insertions": [[8, 1]] }
            ]
          },
          {
            "domains": [
              { "helix": 0, "forward": false , "start": 0, "end": 16, "insertions": [[8, 1]] }
            ]
          }
        ]
      }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });

    test('InsertionLengthChange', () {
      //   simple_helix_with_insertion_design
      //
      //     0            16               32
      // 0  [-------------I: 3--------------->
      //    <-------------I: 3----------------]
      AppState state = app_state_from_design(simple_helix_with_insertion_design);

      Domain domain = simple_helix_with_insertion_design.strands.first.domains.first;
      Insertion insertion = domain.insertions.first;
      int length = 5;
      state = app_state_reducer(
        state,
        InsertionLengthChange(
          domain: domain,
          insertion: insertion,
          length: length,
        ),
      );

      String expected_json = r'''
        {
          "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
          "strands": [
            {
              "domains": [
                {"helix": 0, "forward": true, "start": 0, "end": 32, "insertions": [[16, 5]]}
              ]
            },
            {
              "domains": [
                {"helix": 0, "forward": false, "start": 0, "end": 32, "insertions": [[16, 3]]}
              ]
            }
          ]
        }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });

    test('DeletionAdd', () {
      // Before
      //     0               16
      // 0   [--------------->
      //     <---------------]
      // After:
      //     0      8        16
      // 0   [------X-------->
      //     <------X--------]
      //
      AppState state = app_state_from_design(simple_helix_no_seq_design);

      int offset = 8;
      Domain domain0 = simple_helix_no_seq_design.strands.first.domains.first;
      state = app_state_reducer(state, DeletionAdd(offset: offset, domain: domain0, all_helices: false));
      Domain domain1 = simple_helix_no_seq_design.strands.last.domains.first;
      state = app_state_reducer(state, DeletionAdd(offset: offset, domain: domain1, all_helices: false));
      String expected_json = r'''
      {
        "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]}],
        "strands": [
          {
            "domains": [
              { "helix": 0, "forward": true , "start": 0, "end": 16, "deletions": [8] }
            ]
          },
          {
            "domains": [
              { "helix": 0, "forward": false , "start": 0, "end": 16, "deletions": [8] }
            ]
          }
        ]
      }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });

    test('InsertionRemove', () {
      //   simple_helix_with_insertion_design
      //
      //     0            16               32
      // 0  [-------------I: 3--------------->
      //    <-------------I: 3----------------]
      AppState state = app_state_from_design(simple_helix_with_insertion_design);
      Domain domain = simple_helix_with_insertion_design.strands.first.domains.first;
      Insertion insertion = domain.insertions.first;
      //   simple_helix_with_insertion_design
      //
      //     0            16               32
      // 0  [--------------------------------->
      //    <-------------I: 3----------------]
      state = app_state_reducer(
        state,
        InsertionRemove(
          domain: domain,
          insertion: insertion,
        ),
      );
      String expected_json = r'''
        {
          "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
          "strands": [
            {
              "domains": [
                {"helix": 0, "forward": true, "start": 0, "end": 32 }
              ]
            },
            {
              "domains": [
                {"helix": 0, "forward": false, "start": 0, "end": 32, "insertions": [[16, 3]]}
              ]
            }
          ]
        }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });

    test('DeletionRemove', () {
      //   simple_helix_with_deletion_design
      //     0            16               32
      // 0  [-------------X--------------->
      //    <-------------X----------------]
      AppState state = app_state_from_design(simple_helix_with_deletion_design);
      Domain domain = simple_helix_with_deletion_design.strands.first.domains.first;
      //   simple_helix_with_insertion_design
      //     0            16               32
      // 0  [----------------------------->
      //    <-------------X----------------]
      state = app_state_reducer(
        state,
        DeletionRemove(
          domain: domain,
          offset: 16,
        ),
      );
      String expected_json = r'''
        {
          "version": "''' +
          constants.CURRENT_VERSION +
          r'''", "grid": "square", "helices": [ {"grid_position": [0, 0]} ],
          "strands": [
            {
              "domains": [
                {"helix": 0, "forward": true, "start": 0, "end": 32 }
              ]
            },
            {
              "domains": [
                {"helix": 0, "forward": false, "start": 0, "end": 32, "deletions": [16]}
              ]
            }
          ]
        }
      ''';
      Design expected_design = Design.from_json(jsonDecode(expected_json));
      expect_design_equal(state.design, expected_design);
    });
  });

  //   0                  16
  //
  // 0 [------------------->
  //   <-------------------]
  //
  // 1 [------------------->
  //   <-------------------]
  String no_grid_two_helices_json = r'''
          {
            "version": "''' +
      constants.CURRENT_VERSION +
      r'''",
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
      ''';
  Design no_grid_two_helices_design = Design.from_json(jsonDecode(no_grid_two_helices_json));

  group('Grid change tests: ', () {
    test('GridChange square to hex', () {
      AppState state = app_state_from_design(two_helices_design);
      state = app_state_reducer(state, GridChange(grid: Grid.hex, group_name: constants.default_group_name));

      List<HelixBuilder> helices_builder =
          two_helices_design.helices.map_values((_, h) => h.toBuilder()).values.toList();
      for (int i = 0; i < helices_builder.length; i++) {
        helices_builder[i].grid = Grid.hex;
      }
      BuiltMap<int, Helix> new_helices =
          {for (var helix in helices_builder) helix.idx: helix.build()}.build();
      Design expected_design = two_helices_design.rebuild((b) => b..helices.replace(new_helices));
      expected_design = expected_design.set_grid(Grid.hex);
      expect_design_equal(state.design, expected_design);
    });

    test('GridChange square to none', () {
      AppState state = app_state_from_design(two_helices_design);
      Grid grid = Grid.none;
      state = app_state_reducer(state, GridChange(grid: grid, group_name: constants.default_group_name));

      var expected_position_h0 = util.grid_position_to_position3d(
          two_helices_design.helices[0].grid_position, Grid.square, two_helices_design.geometry);
      var expected_position_h1 = util.grid_position_to_position3d(
          two_helices_design.helices[1].grid_position, Grid.square, two_helices_design.geometry);

      expect(state.design.default_group().grid, Grid.none);
      num eps = 0.0001;
      expect(state.design.helices[0].position3d.x, closeTo(expected_position_h0.x, eps));
      expect(state.design.helices[0].position3d.y, closeTo(expected_position_h0.y, eps));
      expect(state.design.helices[0].position3d.z, closeTo(expected_position_h0.z, eps));
      expect(state.design.helices[1].position3d.x, closeTo(expected_position_h1.x, eps));
      expect(state.design.helices[1].position3d.y, closeTo(expected_position_h1.y, eps));
      expect(state.design.helices[1].position3d.z, closeTo(expected_position_h1.z, eps));
    });

    test('GridChange_none_to_square', () {
      AppState state = app_state_from_design(no_grid_two_helices_design);
      Grid grid = Grid.square;

      state = app_state_reducer(state, GridChange(grid: grid, group_name: constants.default_group_name));

      Helix original_helix0 = no_grid_two_helices_design.helices[0];
      Helix original_helix1 = no_grid_two_helices_design.helices[1];
      Geometry geometry = no_grid_two_helices_design.geometry;
      Position3D expected_position0 = original_helix0.position3d;
      Position3D expected_position1 = original_helix1.position3d;
      // Since positions start out with positive x coordinates, but grid positions set these based
      // on min_offset, x coordinates should become 0.
      expected_position0 =
          expected_position0.rebuild((b) => b.x = original_helix0.min_offset * geometry.base_width_svg);
      expected_position1 =
          expected_position1.rebuild((b) => b.x = original_helix1.min_offset * geometry.base_width_svg);

      GridPosition expected_grid_position0 =
          util.position3d_to_grid_position(expected_position0, grid, no_grid_two_helices_design.geometry);
      GridPosition expected_grid_position1 =
          util.position3d_to_grid_position(expected_position1, grid, no_grid_two_helices_design.geometry);

      Helix new_helix0 = no_grid_two_helices_design.helices.values.first.rebuild((b) => b
        ..grid = grid
        ..position_ = null
        ..grid_position.replace(expected_grid_position0)
        ..geometry.replace(no_grid_two_helices_design.geometry));
      Helix new_helix1 = no_grid_two_helices_design.helices.values.last.rebuild((b) => b
        ..grid = grid
        ..position_ = null
        ..grid_position.replace(expected_grid_position1)
        ..geometry.replace(no_grid_two_helices_design.geometry));

      Map<int, Helix> new_helices = {0: new_helix0, 1: new_helix1};

      Design expected_design = no_grid_two_helices_design.rebuild((b) => b..helices.replace(new_helices));
      expected_design = expected_design.set_grid(grid);

      expect_design_equal(state.design, expected_design);
    });
  });

  test('Scaffold_set', () {
    AppState state = app_state_from_design(two_helices_design);

    //   0                  16
    //
    // 0 [------------------->
    //   <-------------------]  <-- set this one to be scaffold
    //
    // 1 [------------------->
    //   <-------------------]

    Strand strand = two_helices_design.strands[1];

    Strand new_strand = strand.rebuild((b) => b..is_scaffold = true);
    new_strand = new_strand.initialize();

    Design expected_design = two_helices_design.rebuild((b) => b..strands[1] = new_strand);

    state = app_state_reducer(state, ScaffoldSet(strand: strand, is_scaffold: true));
    expect_design_equal(state.design, expected_design);
  });

  test('HelixPositionSet', () {
    AppState state = app_state_from_design(no_grid_two_helices_design);
    // helix 0 old position: Position3D(x: 10, y: 60, z: 30);
    // helix 0 new position: Position3D(x: 40, y: 30, z: 130);
    // helix 1 old position: Position3D(x: 20, y: 80, z: 50);
    Helix helix0 = no_grid_two_helices_design.helices[0];
    Helix helix1 = no_grid_two_helices_design.helices[1];
    Position3D new_position0 = Position3D(x: 40, y: 30, z: 130);

    Helix expected_helix0 = helix0.rebuild((b) => b..position_.replace(new_position0));
    var expected_helices = {0: expected_helix0, 1: helix1};

    state = app_state_reducer(state, HelixPositionSet(helix_idx: helix0.idx, position: new_position0));
    Design expected_design = no_grid_two_helices_design.rebuild((b) => b.helices.replace(expected_helices));
    expect(state.design, expected_design);
  });

  test('two_helices_Helix_Position_Set', () {
    AppState state = app_state_from_design(no_grid_two_helices_design);
    // helix 0 old position: Position3D(x: 10, y: 60, z: 30);
    // helix 1 old position: Position3D(x: 20, y: 80, z: 50);
    // helix 0 new position: Position3D(x: 200, y: 160, z: 10);
    // helix 1 new position: Position3D(x: 300, y: 280, z: 500);
    Helix helix0 = no_grid_two_helices_design.helices[0];
    Helix helix1 = no_grid_two_helices_design.helices[1];
    Position3D position0 = Position3D(x: 200, y: 160, z: 10);
    Position3D position1 = Position3D(x: 300, y: 280, z: 500);

    Helix expected_helix0 = helix0.rebuild((b) => b..position_.replace(position0));
    Helix expected_helix1 = helix1.rebuild((b) => b..position_.replace(position1));

    var batch_action = BatchAction([
      HelixPositionSet(helix_idx: helix0.idx, position: position0),
      HelixPositionSet(helix_idx: helix1.idx, position: position1),
    ], "set helix position");
    state = app_state_reducer(state, batch_action);
    expect(state.design.helices[0], expected_helix0);
    expect(state.design.helices[1], expected_helix1);
  });

  test('HelixGridPositionSet', () {
    AppState state = app_state_from_design(two_helices_design);
    Helix helix = two_helices_design.helices.values.first;

    GridPosition grid_position = GridPosition(5, -3);
    state = app_state_reducer(state, HelixGridPositionSet(helix: helix, grid_position: grid_position));

    Helix helix0 = state.design.helices[0];
    expect(helix0.grid_position, grid_position);
  });

  group('Test png caching:', () {
    test('LoadDnaSequenceImageUri_loads_new_uri', () {
      AppState old_state = app_state_from_design(two_helices_design);
      String uri = 'test_uri';

      AppState new_state = app_state_reducer(old_state, LoadDnaSequenceImageUri(uri, 20, 30));
      var ui_state = new_state.ui_state;
      expect(ui_state.dna_sequence_png_uri, uri);
      expect(ui_state.dna_sequence_png_horizontal_offset, 20);
      expect(ui_state.dna_sequence_png_vertical_offset, 30);
    });

    test('SetIsZoomAboveThreshold_sets_field_to_true', () {
      AppState old_state = app_state_from_design(two_helices_design);
      AppState new_state = app_state_reducer(old_state, SetIsZoomAboveThreshold(true));
      expect(new_state.ui_state.is_zoom_above_threshold, true);
    });

    test('SetDisablePngCacheUntilActionCompletes', () {
      AppState old_state = app_state_from_design(two_helices_design);

      Action action = ExportSvg(type: ExportSvgType.main);

      AppState new_state = app_state_reducer(old_state, SetExportSvgActionDelayedForPngCache(action));

      expect(new_state.ui_state.export_svg_action_delayed_for_png_cache, action);

      new_state = app_state_reducer(new_state, SetExportSvgActionDelayedForPngCache(null));
      expect(new_state.ui_state.export_svg_action_delayed_for_png_cache, null);
    });
  });

  group('Test DNADesign view order functions: (see issue #240)', () {
    String out_of_order_json = r'''
    {
      "version": "0.3.0",
      "grid": "square",
      "helices": [
        {"grid_position": [0, 0], "idx": 12},
        {"grid_position": [0, 1], "idx": 13},
        {"grid_position": [0, 2], "idx": 15},
        {"grid_position": [0, 3], "idx": 17}
      ],
      "helices_view_order": [12, 15, 17, 13],
      "strands": []
    }
    ''';
    Design out_of_order_design = Design.from_json(json.decode(out_of_order_json));
    test('helices_view_order', () {
      BuiltList<int> expected_helices_view_order = BuiltList<int>([12, 15, 17, 13]);
      expect(out_of_order_design.default_group().helices_view_order, expected_helices_view_order);
    });
    test('helices_view_order', () {
      BuiltMap<int, int> expected_helices_view_order_inverse =
          BuiltMap<int, int>({12: 0, 13: 3, 15: 1, 17: 2});
      expect(out_of_order_design.default_group().helices_view_order_inverse,
          expected_helices_view_order_inverse);
    });
  });

  group('strand_editing_with_modifications_split', () {
    // many_helices_modification.dna
    //    B     Cy3   B
    // 0  [-----------------
    //                     |
    //                     |
    //                     |
    // 1  ------------------
    //    |  B   Cy3
    //    |
    //    |      Cy3    B
    // 2  ------------------
    //                     |
    //                     |
    //                     |
    // 3  ------------------
    //    |  B      Cy3
    //    |
    //    |       Cy3    B
    // 4  ------------------
    //                     |
    //                     |
    //                     |
    // 5  ------------------
    //    |  B     Cy3
    //    |
    //    |        Cy3    B
    // 6  ------------------
    //                     |
    //                     |
    //                     |
    // 7  <-----------------
    //    Cy3  B      Cy3

    String many_helices_modification_json = r'''
    {
      "version": "0.6.7",
      "major_tick_distance": 8,
      "grid": "square",
      "helices": [
        {"grid_position": [0, 0]},
        {"grid_position": [0, 1]},
        {"grid_position": [0, 2]},
        {"grid_position": [0, 3]},
        {"grid_position": [0, 4]},
        {"grid_position": [0, 5]},
        {"grid_position": [0, 6]},
        {"grid_position": [0, 7]}
      ],
      "modifications_in_design": {
        "/iCy3/": {
          "display_text": "Cy3",
          "idt_text": "/iCy3/",
          "location": "internal"
        },
        "/5Biosg/": {
          "display_text": "B",
          "idt_text": "/5Biosg/",
          "location": "5'"
        },
        "/3Cy3Sp/": {
          "display_text": "Cy3",
          "idt_text": "/3Cy3Sp/",
          "location": "3'"
        },
        "/iBiodT/": {
          "display_text": "B",
          "idt_text": "/iBiodT/",
          "location": "internal",
          "allowed_bases": ["T"]
        }
      },
      "strands": [
        {
          "color": "#f74308",
          "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
          "domains": [
            {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]},
            {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]},
            {"helix": 2, "forward": true, "start": 0, "end": 16},
            {"helix": 3, "forward": false, "start": 0, "end": 16},
            {"helix": 4, "forward": true, "start": 0, "end": 16},
            {"helix": 5, "forward": false, "start": 0, "end": 16},
            {"helix": 6, "forward": true, "start": 0, "end": 16},
            {"helix": 7, "forward": false, "start": 0, "end": 16}
          ],
          "5prime_modification": "/5Biosg/",
          "3prime_modification": "/3Cy3Sp/",
          "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/", "21": "/iCy3/", "26": "/iBiodT/", "37": "/iCy3/", "42": "/iBiodT/", "53": "/iCy3/", "58": "/iBiodT/", "69": "/iCy3/", "74": "/iBiodT/", "85": "/iCy3/", "90": "/iBiodT/", "101": "/iCy3/", "106": "/iBiodT/", "117": "/iCy3/", "122": "/iBiodT/"}
        }
      ]
    }
    ''';
    Design many_helices_modification_design = Design.from_json(json.decode(many_helices_modification_json));
    AppState initial_state = app_state_from_design(many_helices_modification_design);

    Crossover crossover23 =
        many_helices_modification_design.crossovers_by_id['crossover-2-3-strand-H0-0-forward'];
    Strand strand = many_helices_modification_design.strands.first;
    Domain domain6 = many_helices_modification_design.strands.first.substrands[6] as Domain;
    test(
      'delete_crossover',
      () {
        // Delete crossover between 2 and 3
        //    B     Cy3   B
        // 0  [-----------------
        //                     |
        //                     |
        //                     |
        // 1  ------------------
        //    |  B   Cy3
        //    |
        //    |      Cy3    B
        // 2  ----------------->
        //
        //
        //
        // 3  -----------------]
        //    |  B      Cy3
        //    |
        //    |       Cy3    B
        // 4  ------------------
        //                     |
        //                     |
        //                     |
        // 5  ------------------
        //    |  B     Cy3
        //    |
        //    |        Cy3    B
        // 6  ------------------
        //                     |
        //                     |
        //                     |
        // 7  <-----------------
        //    Cy3  B      Cy3
        Design expected_design1 = Design.from_json(json.decode(r'''
          {
            "version": "0.6.7",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]},
              {"grid_position": [0, 2]},
              {"grid_position": [0, 3]},
              {"grid_position": [0, 4]},
              {"grid_position": [0, 5]},
              {"grid_position": [0, 6]},
              {"grid_position": [0, 7]}
            ],
            "modifications_in_design": {
              "/5Biosg/": {
                "display_text": "B",
                "idt_text": "/5Biosg/",
                "location": "5'"
              },
              "/3Cy3Sp/": {
                "display_text": "Cy3",
                "idt_text": "/3Cy3Sp/",
                "location": "3'"
              },
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#cc0000",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]},
                  {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]},
                  {"helix": 2, "forward": true, "start": 0, "end": 16}
                ],
                "5prime_modification": "/5Biosg/",
                "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/", "21": "/iCy3/", "26": "/iBiodT/", "37": "/iCy3/", "42": "/iBiodT/"}
              },
              {
                "color": "#32b86c",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 3, "forward": false, "start": 0, "end": 16},
                  {"helix": 4, "forward": true, "start": 0, "end": 16},
                  {"helix": 5, "forward": false, "start": 0, "end": 16},
                  {"helix": 6, "forward": true, "start": 0, "end": 16},
                  {"helix": 7, "forward": false, "start": 0, "end": 16}
                ],
                "3prime_modification": "/3Cy3Sp/",
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/", "39": "/iCy3/", "44": "/iBiodT/", "55": "/iCy3/", "60": "/iBiodT/", "71": "/iCy3/", "76": "/iBiodT/"}
              }
            ]
          }
        '''));

        AppState state = initial_state;
        state = app_state_reducer(state, SelectModesSet([SelectModeChoice.crossover]));
        state = app_state_reducer(state, Select(crossover23, toggle: false, only: true));
        state = app_state_reducer(state, DeleteAllSelected());

        expect_design_equal(state.design, expected_design1);

        Crossover crossover56 = state.design.crossovers_by_id['crossover-2-3-strand-H3-15-reverse'];
        // Delete crossover between 5 and 6.
        //    B     Cy3   B
        // 0  [-----------------
        //                     |
        //                     |
        //                     |
        // 1  ------------------
        //    |  B   Cy3
        //    |
        //    |      Cy3    B
        // 2  ----------------->
        //
        //
        //
        // 3  -----------------]
        //    |  B      Cy3
        //    |
        //    |       Cy3    B
        // 4  ------------------
        //                     |
        //                     |
        //                     |
        // 5  <-----------------
        //       B     Cy3
        //
        //             Cy3    B
        // 6  [-----------------
        //                     |
        //                     |
        //                     |
        // 7  <-----------------
        //    Cy3  B      Cy3
        Design expected_design2 = Design.from_json(json.decode(r'''
          {
            "version": "''' +
            constants.CURRENT_VERSION +
            r'''",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]},
              {"grid_position": [0, 2]},
              {"grid_position": [0, 3]},
              {"grid_position": [0, 4]},
              {"grid_position": [0, 5]},
              {"grid_position": [0, 6]},
              {"grid_position": [0, 7]}
            ],
            "modifications_in_design": {
              "/5Biosg/": {
                "display_text": "B",
                "idt_text": "/5Biosg/",
                "location": "5'"
              },
              "/3Cy3Sp/": {
                "display_text": "Cy3",
                "idt_text": "/3Cy3Sp/",
                "location": "3'"
              },
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#cc0000",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]},
                  {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]},
                  {"helix": 2, "forward": true, "start": 0, "end": 16}
                ],
                "5prime_modification": "/5Biosg/",
                "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/", "21": "/iCy3/", "26": "/iBiodT/", "37": "/iCy3/", "42": "/iBiodT/"}
              },
              {
                "color": "#f74308",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 3, "forward": false, "start": 0, "end": 16},
                  {"helix": 4, "forward": true, "start": 0, "end": 16},
                  {"helix": 5, "forward": false, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/", "39": "/iCy3/", "44": "/iBiodT/"}
              },
              {
                "color": "#57bb00",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 6, "forward": true, "start": 0, "end": 16},
                  {"helix": 7, "forward": false, "start": 0, "end": 16}
                ],
                "3prime_modification": "/3Cy3Sp/",
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/"}
              }
            ]
          }
        '''));

        state = app_state_reducer(state, Select(crossover56, toggle: false, only: true));
        state = app_state_reducer(state, DeleteAllSelected());

        expect_design_equal(state.undo_redo.undo_stack[1].design, expected_design1);
        expect_design_equal(state.undo_redo.undo_stack[0].design, many_helices_modification_design);
        expect_design_equal(state.design, expected_design2);
      },
    );

    test('delete_loopout', () {
      // 0  -----------------]
      //    |  B     Cy3
      //    |  <----------------------------------------------loopout length 3
      //    |      Cy3    B
      // 1  ----------------->
      Design modifications_loopout = Design.from_json(json.decode(r'''
          {
            "version": "0.7.0",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]}
            ],
            "modifications_in_design": {
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#7300de",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": false, "start": 0, "end": 16},
                  {"loopout": 3},
                  {"helix": 1, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/"}
              }
            ]
          }
        '''));
      AppState initial_state = app_state_from_design(modifications_loopout);
      // 0  <----------------]
      //       B     Cy3
      //
      //           Cy3    B
      // 1  [---------------->
      var expected_design = Design.from_json(json.decode(r'''
        {
          "version": "0.7.0",
          "grid": "square",
          "helices": [
            {"grid_position": [0, 0]},
            {"grid_position": [0, 1]}
          ],
          "modifications_in_design": {
            "/iCy3/": {
              "display_text": "Cy3",
              "idt_text": "/iCy3/",
              "location": "internal"
            },
            "/iBiodT/": {
              "display_text": "B",
              "idt_text": "/iBiodT/",
              "location": "internal",
              "allowed_bases": ["T"]
            }
          },
          "strands": [
            {
              "color": "#cc0000",
              "sequence": "TTTTTTTTTTTTTTTT",
              "domains": [
                {"helix": 0, "forward": false, "start": 0, "end": 16}
              ],
              "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
            },
            {
              "color": "#32b86c",
              "sequence": "TTTTTTTTTTTTTTTT",
              "domains": [
                {"helix": 1, "forward": true, "start": 0, "end": 16}
              ],
              "internal_modifications": {"4": "/iCy3/", "9": "/iBiodT/"}
            }
          ]
        }
      '''));

      AppState state = initial_state;
      state = app_state_reducer(state, SelectModesSet([SelectModeChoice.loopout]));
      state = app_state_reducer(
          state,
          Select(modifications_loopout.loopouts_by_id['loopout-1-strand-H0-15-reverse'],
              toggle: false, only: true));
      state = app_state_reducer(state, DeleteAllSelected());

      expect_design_equal(state.design, expected_design);
    });

    test('delete_strand_with_modifications', () {
      // delete_strand_with_modifications
      // 0
      // 1
      // 2
      // 3
      // 4
      // 5
      // 6
      // 7
      Design expected_design = Design.from_json(json.decode(r'''
          {
            "version": "0.6.7",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0], "max_offset": 16},
              {"grid_position": [0, 1], "max_offset": 16},
              {"grid_position": [0, 2], "max_offset": 16},
              {"grid_position": [0, 3], "max_offset": 16},
              {"grid_position": [0, 4], "max_offset": 16},
              {"grid_position": [0, 5], "max_offset": 16},
              {"grid_position": [0, 6], "max_offset": 16},
              {"grid_position": [0, 7], "max_offset": 16}
            ],
            "strands": []
          }
        '''));

      AppState state = initial_state;
      state = app_state_reducer(state, SelectModesSet([SelectModeChoice.strand]));
      state = app_state_reducer(state, Select(strand, toggle: false, only: true));
      state = app_state_reducer(state, DeleteAllSelected());

      expect_design_equal(state.design, expected_design);
      expect(state.ui_state.select_mode_state, SelectModeState().set_modes([SelectModeChoice.strand]));
    });

    test('nick', () {
      // nick at helix 6 offset 0
      //    B     Cy3   B
      // 0  [-----------------
      //                     |
      //                     |
      //                     |
      // 1  ------------------
      //    |  B   Cy3
      //    |
      //    |      Cy3    B
      // 2  ------------------
      //                     |
      //                     |
      //                     |
      // 3  ------------------
      //    |  B      Cy3
      //    |
      //    |       Cy3    B
      // 4  ------------------
      //                     |
      //                     |
      //                     |
      // 5  ------------------
      //    |  B     Cy3
      //    |
      //    |        Cy3    B
      // 6  ---->[------------
      //                     |
      //                     |
      //                     |
      // 7  <-----------------
      //    Cy3  B      Cy3
      var expected_design = Design.from_json(json.decode(r'''
          {
            "version": "0.6.7",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]},
              {"grid_position": [0, 2]},
              {"grid_position": [0, 3]},
              {"grid_position": [0, 4]},
              {"grid_position": [0, 5]},
              {"grid_position": [0, 6]},
              {"grid_position": [0, 7]}
            ],
            "modifications_in_design": {
              "/5Biosg/": {
                "display_text": "B",
                "idt_text": "/5Biosg/",
                "location": "5'"
              },
              "/3Cy3Sp/": {
                "display_text": "Cy3",
                "idt_text": "/3Cy3Sp/",
                "location": "3'"
              },
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#f74308",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]},
                  {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]},
                  {"helix": 2, "forward": true, "start": 0, "end": 16},
                  {"helix": 3, "forward": false, "start": 0, "end": 16},
                  {"helix": 4, "forward": true, "start": 0, "end": 16},
                  {"helix": 5, "forward": false, "start": 0, "end": 16},
                  {"helix": 6, "forward": true, "start": 0, "end": 4}
                ],
                "5prime_modification": "/5Biosg/",
                "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/", "21": "/iCy3/", "26": "/iBiodT/", "37": "/iCy3/", "42": "/iBiodT/", "53": "/iCy3/", "58": "/iBiodT/", "69": "/iCy3/", "74": "/iBiodT/", "85": "/iCy3/", "90": "/iBiodT/"}
              },
              {
                "color": "#32b86c",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 6, "forward": true, "start": 4, "end": 16},
                  {"helix": 7, "forward": false, "start": 0, "end": 16}
                ],
                "3prime_modification": "/3Cy3Sp/",
                "internal_modifications": {"3": "/iCy3/", "8": "/iBiodT/", "19": "/iCy3/", "24": "/iBiodT/"}
              }
            ]
          }
        '''));

      AppState state = initial_state;
      state = app_state_reducer(state, Nick(domain: domain6, offset: 4));

      expect_design_equal(state.design, expected_design);
    });
  });

  group('Test strand editing with modifications -- merge, etc.', () {
    //    B     Cy3   B
    // 0  [---------------->
    //
    //
    //
    // 1  <----------------]
    //       B   Cy3
    //
    //           Cy3    B
    // 2  [---------------->
    //
    //
    //
    // 3  <----------------]
    //       B      Cy3
    //
    //            Cy3    B
    // 4  [----------->[--->
    //
    //
    //
    // 5  -----------------]
    //    |  B     Cy3
    //    |
    //    |      Cy3    B
    // 6  ----------------->
    //
    //
    //
    // 7  <----------------]
    //    Cy3  B      Cy3
    Design many_helices_modifications_split = Design.from_json(json.decode(r'''
        {
          "version": "0.7.0",
          "grid": "square",
          "helices": [
            {"grid_position": [0, 0]},
            {"grid_position": [0, 1]},
            {"grid_position": [0, 2]},
            {"grid_position": [0, 3]},
            {"grid_position": [0, 4]},
            {"grid_position": [0, 5]},
            {"grid_position": [0, 6]},
            {"grid_position": [0, 7]}
          ],
          "modifications_in_design": {
            "/5Biosg/": {
              "display_text": "B",
              "idt_text": "/5Biosg/",
              "location": "5'"
            },
            "/3Cy3Sp/": {
              "display_text": "Cy3",
              "idt_text": "/3Cy3Sp/",
              "location": "3'"
            },
            "/iCy3/": {
              "display_text": "Cy3",
              "idt_text": "/iCy3/",
              "location": "internal"
            },
            "/iBiodT/": {
              "display_text": "B",
              "idt_text": "/iBiodT/",
              "location": "internal",
              "allowed_bases": ["T"]
            }
          },
          "strands": [
            {
              "color": "#03b6a2",
              "sequence": "TTTTTTTTTTTTTT",
              "domains": [
                {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]}
              ],
              "5prime_modification": "/5Biosg/",
              "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/"}
            },
            {
              "color": "#f7931e",
              "sequence": "TTTTTTTTTTTTTTTT",
              "domains": [
                {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]}
              ],
              "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
            },
            {
              "color": "#320096",
              "sequence": "TTTTTTTTTTTTTTTT",
              "domains": [
                {"helix": 2, "forward": true, "start": 0, "end": 16}
              ],
              "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
            },
            {
              "color": "#b8056c",
              "sequence": "TTTTTTTTTTTTTTTT",
              "domains": [
                {"helix": 3, "forward": false, "start": 0, "end": 16}
              ],
              "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
            },
            {
              "color": "#7300de",
              "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
              "domains": [
                {"helix": 5, "forward": false, "start": 0, "end": 16},
                {"helix": 6, "forward": true, "start": 0, "end": 16}
              ],
              "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/"}
            },
            {
              "color": "#888888",
              "sequence": "TTTTTTTTTTTTTTTT",
              "domains": [
                {"helix": 7, "forward": false, "start": 0, "end": 16}
              ],
              "3prime_modification": "/3Cy3Sp/",
              "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
            },
            {
              "color": "#333333",
              "sequence": "TTTTTTTTTT",
              "domains": [
                {"helix": 4, "forward": true, "start": 0, "end": 10}
              ],
              "internal_modifications": {"7": "/iCy3/"}
            },
            {
              "color": "#32b86c",
              "sequence": "TTTTTT",
              "domains": [
                {"helix": 4, "forward": true, "start": 10, "end": 16}
              ],
              "internal_modifications": {"2": "/iBiodT/"}
            }
          ]
        }
      '''));
    AppState initial_state = app_state_from_design(many_helices_modifications_split);
    DNAEnd end_3p_H4 =
        many_helices_modifications_split.ends_3p_strand_by_id['end-3p-substrand-H4-10-16-forward'];
    DNAEnd end_5p_H5 =
        many_helices_modifications_split.ends_5p_strand_by_id['end-5p-substrand-H5-0-16-reverse'];
    DNAEnd end_5p_H4 =
        many_helices_modifications_split.ends_5p_strand_by_id['end-5p-substrand-H4-10-16-forward'];
    Helix helix5 = many_helices_modifications_split.helices[5];
    Strand strand_H4_forward_10 = many_helices_modifications_split.strands[7];
    Strand strand_H4_forward_0 = many_helices_modifications_split.strands[6];
    Strand strand_H3_reverse_0 = many_helices_modifications_split.strands[3];

    test('new crossover', () {
      // Crossover between 4 and 5
      //
      //    B     Cy3   B
      // 0  [---------------->
      //
      //
      //
      // 1  <----------------]
      //       B   Cy3
      //
      //           Cy3    B
      // 2  [---------------->
      //
      //
      //
      // 3  <----------------]
      //       B      Cy3
      //
      //            Cy3    B
      // 4  [----------->[----
      //                     |
      //                     |
      //                     |
      // 5  ------------------
      //    |  B     Cy3
      //    |
      //    |      Cy3    B
      // 6  ----------------->
      //
      //
      //
      // 7  <----------------]
      //    Cy3  B      Cy3
      var expected_design = Design.from_json(json.decode(r'''
          {
            "version": "0.7.0",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]},
              {"grid_position": [0, 2]},
              {"grid_position": [0, 3]},
              {"grid_position": [0, 4]},
              {"grid_position": [0, 5]},
              {"grid_position": [0, 6]},
              {"grid_position": [0, 7]}
            ],
            "modifications_in_design": {
              "/5Biosg/": {
                "display_text": "B",
                "idt_text": "/5Biosg/",
                "location": "5'"
              },
              "/3Cy3Sp/": {
                "display_text": "Cy3",
                "idt_text": "/3Cy3Sp/",
                "location": "3'"
              },
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#03b6a2",
                "sequence": "TTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]}
                ],
                "5prime_modification": "/5Biosg/",
                "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/"}
              },
              {
                "color": "#f7931e",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#320096",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 2, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#b8056c",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 3, "forward": false, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#888888",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 7, "forward": false, "start": 0, "end": 16}
                ],
                "3prime_modification": "/3Cy3Sp/",
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#333333",
                "sequence": "TTTTTTTTTT",
                "domains": [
                  {"helix": 4, "forward": true, "start": 0, "end": 10}
                ],
                "internal_modifications": {"7": "/iCy3/"}
              },
              {
                "color": "#32b86c",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 4, "forward": true, "start": 10, "end": 16},
                  {"helix": 5, "forward": false, "start": 0, "end": 16},
                  {"helix": 6, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"2": "/iBiodT/", "13": "/iCy3/", "18": "/iBiodT/", "29": "/iCy3/", "34": "/iBiodT/"}
              }
            ]
          }
        '''));

      AppState state = initial_state;
      state = app_state_reducer(
          state, JoinStrandsByCrossover(dna_end_first_click: end_3p_H4, dna_end_second_click: end_5p_H5));

      expect_design_equal(state.design, expected_design);
    });

    test('ligate', () {
      // ligate strands in 4
      //
      //    B     Cy3   B
      // 0  [---------------->
      //
      //
      //
      // 1  <----------------]
      //       B   Cy3
      //
      //           Cy3    B
      // 2  [---------------->
      //
      //
      //
      // 3  <----------------]
      //       B      Cy3
      //
      //            Cy3    B
      // 4  [---------------->
      //
      //
      //
      // 5  -----------------]
      //    |  B     Cy3
      //    |
      //    |      Cy3    B
      // 6  ----------------->
      //
      //
      //
      // 7  <----------------]
      //    Cy3  B      Cy3
      var expected_design = Design.from_json(json.decode(r'''
          {
            "version": "0.7.0",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]},
              {"grid_position": [0, 2]},
              {"grid_position": [0, 3]},
              {"grid_position": [0, 4]},
              {"grid_position": [0, 5]},
              {"grid_position": [0, 6]},
              {"grid_position": [0, 7]}
            ],
            "modifications_in_design": {
              "/5Biosg/": {
                "display_text": "B",
                "idt_text": "/5Biosg/",
                "location": "5'"
              },
              "/3Cy3Sp/": {
                "display_text": "Cy3",
                "idt_text": "/3Cy3Sp/",
                "location": "3'"
              },
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#03b6a2",
                "sequence": "TTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]}
                ],
                "5prime_modification": "/5Biosg/",
                "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/"}
              },
              {
                "color": "#f7931e",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#320096",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 2, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#b8056c",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 3, "forward": false, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#7300de",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 5, "forward": false, "start": 0, "end": 16},
                  {"helix": 6, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/"}
              },
              {
                "color": "#888888",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 7, "forward": false, "start": 0, "end": 16}
                ],
                "3prime_modification": "/3Cy3Sp/",
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#333333",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 4, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              }
            ]
          }
        '''));

      AppState state = initial_state;
      state = app_state_reducer(state, Ligate(dna_end: end_5p_H4));

      expect_design_equal(state.design, expected_design);
    });

    test('move DNA end', () {
      // move 5' end on 5 helix to the left by 2 offsets
      //
      //    B     Cy3   B
      // 0  [---------------->
      //
      //
      //
      // 1  <----------------]
      //       B   Cy3
      //
      //           Cy3    B
      // 2  [---------------->
      //
      //
      //
      // 3  <----------------]
      //       B      Cy3
      //
      //            Cy3    B
      // 4  [----------->[--->
      //
      //
      //
      // 5  -------------]
      //    |B   Cy3
      //    |
      //    |        Cy3    B
      // 6  ----------------->
      //
      //
      //
      // 7  <----------------]
      //    Cy3  B      Cy3
      var expected_design = Design.from_json(json.decode(r'''
          {
            "version": "0.7.0",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]},
              {"grid_position": [0, 2]},
              {"grid_position": [0, 3]},
              {"grid_position": [0, 4]},
              {"grid_position": [0, 5], "max_offset": 16},
              {"grid_position": [0, 6]},
              {"grid_position": [0, 7]}
            ],
            "modifications_in_design": {
              "/5Biosg/": {
                "display_text": "B",
                "idt_text": "/5Biosg/",
                "location": "5'"
              },
              "/3Cy3Sp/": {
                "display_text": "Cy3",
                "idt_text": "/3Cy3Sp/",
                "location": "3'"
              },
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#03b6a2",
                "sequence": "TTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]}
                ],
                "5prime_modification": "/5Biosg/",
                "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/"}
              },
              {
                "color": "#f7931e",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#320096",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 2, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#b8056c",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 3, "forward": false, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#7300de",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 5, "forward": false, "start": 0, "end": 14},
                  {"helix": 6, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/"}
              },
              {
                "color": "#888888",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 7, "forward": false, "start": 0, "end": 16}
                ],
                "3prime_modification": "/3Cy3Sp/",
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#333333",
                "sequence": "TTTTTTTTTT",
                "domains": [
                  {"helix": 4, "forward": true, "start": 0, "end": 10}
                ],
                "internal_modifications": {"7": "/iCy3/"}
              },
              {
                "color": "#32b86c",
                "sequence": "TTTTTT",
                "domains": [
                  {"helix": 4, "forward": true, "start": 10, "end": 16}
                ],
                "internal_modifications": {"2": "/iBiodT/"}
              }
            ]
          }
        '''));

      AppState state = initial_state;
      DNAEndMove move = DNAEndMove(dna_end: end_5p_H5, lowest_offset: 0, highest_offset: 16);
      DNAEndsMove moves = DNAEndsMove(
          moves: BuiltList<DNAEndMove>([move]), original_offset: 15, current_offset: 13, helix: helix5);
      state = app_state_reducer(state, DNAEndsMoveCommit(dna_ends_move: moves));

      expect_design_equal(state.design, expected_design);
    });

    test('move_strands', () {
      // move strands at 3 and 4 to 0 and 1
      //
      //    B     Cy3   B
      // 0  [---------------->
      //    <----------------]
      //       B      Cy3
      //
      //
      //            Cy3    B
      // 1  [----------->[--->
      //    <----------------]
      //       B   Cy3
      //
      //           Cy3    B
      // 2  [---------------->
      //
      //
      //
      // 3
      //
      //
      //
      // 4
      //
      //
      //
      // 5  -------------]
      //    |  B     Cy3
      //    |
      //    |      Cy3    B
      // 6  ----------------->
      //
      //
      //
      // 7  <----------------]
      //    Cy3  B      Cy3
      var expected_design = Design.from_json(json.decode(r'''
          {
            "version": "0.7.0",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]},
              {"grid_position": [0, 2]},
              {"grid_position": [0, 3], "max_offset": 16},
              {"grid_position": [0, 4], "max_offset": 16},
              {"grid_position": [0, 5]},
              {"grid_position": [0, 6]},
              {"grid_position": [0, 7]}
            ],
            "modifications_in_design": {
              "/5Biosg/": {
                "display_text": "B",
                "idt_text": "/5Biosg/",
                "location": "5'"
              },
              "/3Cy3Sp/": {
                "display_text": "Cy3",
                "idt_text": "/3Cy3Sp/",
                "location": "3'"
              },
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#03b6a2",
                "sequence": "TTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]}
                ],
                "5prime_modification": "/5Biosg/",
                "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/"}
              },
              {
                "color": "#f7931e",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#320096",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 2, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#b8056c",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": false, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#7300de",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 5, "forward": false, "start": 0, "end": 16},
                  {"helix": 6, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/"}
              },
              {
                "color": "#888888",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 7, "forward": false, "start": 0, "end": 16}
                ],
                "3prime_modification": "/3Cy3Sp/",
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#333333",
                "sequence": "TTTTTTTTTT",
                "domains": [
                  {"helix": 1, "forward": true, "start": 0, "end": 10}
                ],
                "internal_modifications": {"7": "/iCy3/"}
              },
              {
                "color": "#32b86c",
                "sequence": "TTTTTT",
                "domains": [
                  {"helix": 1, "forward": true, "start": 10, "end": 16}
                ],
                "internal_modifications": {"2": "/iBiodT/"}
              }
            ]
          }
        '''));

      AppState state = initial_state;

      BuiltList<Strand> strands_moving =
          BuiltList<Strand>([strand_H3_reverse_0, strand_H4_forward_0, strand_H4_forward_10]);
      BuiltList<Strand> all_strands = many_helices_modifications_split.strands;
      Address original_address = Address(forward: false, helix_idx: 3, offset: 8);
      bool copy = false;

      StrandsMove strands_move = StrandsMove(
        strands_moving: strands_moving,
        all_strands: all_strands,
        original_address: original_address,
        helices: state.design.helices,
        groups: state.design.groups,
        original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
        copy: copy,
      ).rebuild((b) => b..current_address = Address(forward: false, helix_idx: 0, offset: 8).toBuilder());

      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strands_move, autopaste: false));

      expect_design_equal(state.design, expected_design);
    });

    test('copy_and_paste_strands', () {
      // copy strands at 3 and 4 to 0 and 1
      //
      //    B     Cy3   B
      // 0  [---------------->
      //    <----------------]
      //       B      Cy3
      //
      //
      //            Cy3    B
      // 1  [----------->[--->
      //    <----------------]
      //       B   Cy3
      //
      //           Cy3    B
      // 2  [---------------->
      //
      //
      //
      // 3  <----------------]
      //       B      Cy3
      //
      //            Cy3    B
      // 4  [----------->[--->
      //
      //
      //
      // 5  -------------]
      //    |  B     Cy3
      //    |
      //    |      Cy3    B
      // 6  ----------------->
      //
      //
      //
      // 7  <----------------]
      //    Cy3  B      Cy3
      var expected_design = Design.from_json(json.decode(r'''
          {
            "version": "0.7.0",
            "grid": "square",
            "helices": [
              {"grid_position": [0, 0]},
              {"grid_position": [0, 1]},
              {"grid_position": [0, 2]},
              {"grid_position": [0, 3]},
              {"grid_position": [0, 4]},
              {"grid_position": [0, 5]},
              {"grid_position": [0, 6]},
              {"grid_position": [0, 7]}
            ],
            "modifications_in_design": {
              "/5Biosg/": {
                "display_text": "B",
                "idt_text": "/5Biosg/",
                "location": "5'"
              },
              "/3Cy3Sp/": {
                "display_text": "Cy3",
                "idt_text": "/3Cy3Sp/",
                "location": "3'"
              },
              "/iCy3/": {
                "display_text": "Cy3",
                "idt_text": "/iCy3/",
                "location": "internal"
              },
              "/iBiodT/": {
                "display_text": "B",
                "idt_text": "/iBiodT/",
                "location": "internal",
                "allowed_bases": ["T"]
              }
            },
            "strands": [
              {
                "color": "#03b6a2",
                "sequence": "TTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": true, "start": 0, "end": 16, "deletions": [11, 12]}
                ],
                "5prime_modification": "/5Biosg/",
                "internal_modifications": {"5": "/iCy3/", "10": "/iBiodT/"}
              },
              {
                "color": "#f7931e",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[4, 1]]}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#320096",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 2, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#b8056c",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 3, "forward": false, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#7300de",
                "sequence": "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 5, "forward": false, "start": 0, "end": 16},
                  {"helix": 6, "forward": true, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/", "23": "/iCy3/", "28": "/iBiodT/"}
              },
              {
                "color": "#888888",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 7, "forward": false, "start": 0, "end": 16}
                ],
                "3prime_modification": "/3Cy3Sp/",
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#333333",
                "sequence": "TTTTTTTTTT",
                "domains": [
                  {"helix": 4, "forward": true, "start": 0, "end": 10}
                ],
                "internal_modifications": {"7": "/iCy3/"}
              },
              {
                "color": "#32b86c",
                "sequence": "TTTTTT",
                "domains": [
                  {"helix": 4, "forward": true, "start": 10, "end": 16}
                ],
                "internal_modifications": {"2": "/iBiodT/"}
              },
              {
                "color": "#cc0000",
                "sequence": "TTTTTTTTTTTTTTTT",
                "domains": [
                  {"helix": 0, "forward": false, "start": 0, "end": 16}
                ],
                "internal_modifications": {"7": "/iCy3/", "12": "/iBiodT/"}
              },
              {
                "color": "#32b86c",
                "sequence": "TTTTTTTTTT",
                "domains": [
                  {"helix": 1, "forward": true, "start": 0, "end": 10}
                ],
                "internal_modifications": {"7": "/iCy3/"}
              },
              {
                "color": "#f74308",
                "sequence": "TTTTTT",
                "domains": [
                  {"helix": 1, "forward": true, "start": 10, "end": 16}
                ],
                "internal_modifications": {"2": "/iBiodT/"}
              }
            ]
          }
        '''));

      AppState state = initial_state;

      BuiltList<Strand> strands_moving =
          BuiltList<Strand>([strand_H3_reverse_0, strand_H4_forward_0, strand_H4_forward_10]);
      BuiltList<Strand> all_strands = many_helices_modifications_split.strands;
      Address original_address = Address(forward: false, helix_idx: 3, offset: 8);
      bool copy = true;

      StrandsMove strands_move = StrandsMove(
        strands_moving: strands_moving,
        all_strands: all_strands,
        original_address: original_address,
        helices: state.design.helices,
        groups: state.design.groups,
        original_helices_view_order_inverse: state.design.default_group().helices_view_order_inverse,
        copy: copy,
      ).rebuild((b) => b..current_address = Address(forward: false, helix_idx: 0, offset: 8).toBuilder());

      state = app_state_reducer(state, StrandsMoveCommit(strands_move: strands_move, autopaste: false));

      expect_design_equal(state.design, expected_design);
    }, skip: true);
    //FIXME: autopaste; unskip above when we figure out how to fix this test
  });

  group('Test strand color picker actions:', () {
    test('StrandColorPickerShow', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      Strand strand = two_helices_design.strands.first;
      AppState final_state =
          app_state_reducer(initial_state, StrandOrSubstrandColorPickerShow(strand: strand));

      expect(final_state.ui_state.color_picker_strand, strand);
    });

    test('StrandColorPickerHide', () {
      Strand strand = two_helices_design.strands.first;
      AppState initial_state = app_state_from_design(two_helices_design)
          .rebuild((b) => b..ui_state.color_picker_strand = strand.toBuilder());

      AppState final_state = app_state_reducer(initial_state, StrandOrSubstrandColorPickerHide());

      expect(final_state.ui_state.color_picker_strand, null);
    });
  });

  group('DesignNewSet', () {
    test('DesignNewSet should set new design', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state =
          app_state_reducer(initial_state, NewDesignSet(small_design_h0, "some description"));
      expect(final_state.design, small_design_h0);
    });

    test('DesignNewSet should be undoable', () {
      AppState initial_state = app_state_from_design(two_helices_design);
      AppState final_state =
          app_state_reducer(initial_state, NewDesignSet(small_design_h0, "some description"));
      expect(
          final_state.undo_redo,
          UndoRedo().rebuild(
              (b) => b..undo_stack.replace([new UndoRedoItem("some description", two_helices_design)])));
    });
  });

  test('GroupDisplayChange on empty HelixGroup (see issue #573)', () {
    AppState initial_state = app_state_from_design(two_helices_design);
    // Add empty helix group
    AppState state =
        app_state_reducer(initial_state, GroupAdd(name: 'test', group: HelixGroup(helices_view_order: [])));
    // Display new helix group
    AppState final_state = app_state_reducer(state, GroupDisplayedChange(group_name: 'test'));

    // Slice bar offset should be set to null if displayed group has no helices
    expect(null, final_state.ui_state.slice_bar_offset);
  });

  group('Designs_with_helix_pitch_and_helix_yaw_before_version_0.16.0', () {
    test('single_helix_group_and_helices_specify_pitch_and_yaw', () {
      String json_str = r'''
        {
          "helices": [
            {
              "group": "north",
              "position": {"x": 1, "y": 2, "z": 3},
              "pitch": 4,
              "roll": 5,
              "yaw": 6
            },
            {
              "group": "north",
              "position": {"x": 3, "y": 2, "z": 3},
              "roll": 15
            }
          ],
          "groups": {
            "north": {
              "position": {"x": 0, "y": -200, "z": 0},
              "pitch": 21,
              "yaw": 13,
              "grid": "none"
            }
          },
          "strands": [
            {
              "color": "#0066cc",
              "domains": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
            }
          ]
        }
      ''';
      Design d = Design.from_json_str(json_str);
      Helix helix0 = d.helices[0];
      Helix helix1 = d.helices[1];
      expect(helix0.position, Position3D(x: 1, y: 2, z: 3));
      expect(helix0.roll, 5);
      // Helix 0 should have been moved to a new helix group
      String pitch_25_yaw_19_group_name = 'pitch_25_yaw_19';
      HelixGroup pitch_25_yaw_19_group = d.groups[pitch_25_yaw_19_group_name];
      expect(pitch_25_yaw_19_group.pitch, 25);
      expect(pitch_25_yaw_19_group.yaw, 19);
      expect(helix0.group, pitch_25_yaw_19_group_name);
      expect(helix1.position, Position3D(x: 3, y: 2, z: 3));
      expect(helix1.roll, 15);
      expect(helix1.group, "north");
      expect(d.groups.length, 2);
    });

    test('only_individual_helices_specify_pitch_and_yaw', () {
      String json_str = r"""
      {
        "helices": [
          {
            "group": "north",
            "position": {"x": 1, "y": 2, "z": 3},
            "pitch": 25,
            "yaw": 19,
            "roll": 5
          },
          {
            "group": "north",
            "position": {"x": 3, "y": 2, "z": 3},
            "pitch": 21,
            "yaw": 13,
            "roll": 15
          }
        ],
        "groups": {
          "north": {
            "position": {"x": 0, "y": -200, "z": 0},
            "grid": "none"
          }
        },
        "strands": [
          {
            "color": "#0066cc",
            "domains": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
          }
        ]
      }
      """;
      Design d = Design.from_json_str(json_str);
      Helix helix0 = d.helices[0];
      Helix helix1 = d.helices[1];

      // Helix 0 should have been moved to a new helix group
      String pitch_25_yaw_19_group_name = 'pitch_25_yaw_19';
      HelixGroup pitch_25_yaw_19_group = d.groups[pitch_25_yaw_19_group_name];
      expect(helix0.position, Position3D(x: 1, y: 2, z: 3));
      expect(pitch_25_yaw_19_group.pitch, 25);
      expect(pitch_25_yaw_19_group.yaw, 19);
      expect(helix0.roll, 5);
      expect(helix0.group, pitch_25_yaw_19_group_name);

      // Helix 1 should have been moved to a new helix group
      String pitch_21_yaw_13_group_name = 'pitch_21_yaw_13';
      HelixGroup pitch_21_yaw_13_group = d.groups[pitch_21_yaw_13_group_name];
      expect(helix1.position, Position3D(x: 3, y: 2, z: 3));
      expect(pitch_21_yaw_13_group.pitch, 21);
      expect(pitch_21_yaw_13_group.yaw, 13);
      expect(helix1.roll, 15);
      expect(helix1.group, pitch_21_yaw_13_group_name);

      expect(d.groups.length, 3);
    });
    test('only_helix_groups_specify_pitch_and_yaw', () {
      String json_str = r'''
      {
        "helices": [
          {
            "group": "north",
            "position": {"x": 1, "y": 2, "z": 3},
            "roll": 5
          },
          {
            "group": "south",
            "position": {"x": 3, "y": 2, "z": 3},
            "roll": 15
          }
        ],
        "groups": {
          "north": {
            "position": {"x": 0, "y": -200, "z": 0},
            "pitch": 21,
            "yaw": 13,
            "grid": "none"
          },
          "south": {
            "position": {"x": 0, "y": -400, "z": 0},
            "pitch": 23,
            "yaw": 98,
            "grid": "none"
          }
        },
        "strands": [
          {
            "color": "#0066cc",
            "domains": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
          }
        ]
      }
      ''';
      Design d = Design.from_json_str(json_str);
      Helix helix0 = d.helices[0];
      Helix helix1 = d.helices[1];

      String north_str = 'north';
      String south_str = 'south';
      HelixGroup north_group = d.groups[north_str];
      HelixGroup south_group = d.groups[south_str];
      expect(d.groups.length, 2);

      expect(helix0.position, Position3D(x: 1, y: 2, z: 3));
      expect(helix0.roll, 5);
      expect(north_group.pitch, 21);
      expect(north_group.yaw, 13);
      expect(helix0.group, north_str);

      expect(helix1.position, Position3D(x: 3, y: 2, z: 3));
      expect(helix1.roll, 15);
      expect(south_group.pitch, 23);
      expect(south_group.yaw, 98);
      expect(helix1.group, south_str);
    });

    test('both_helix_groups_and_helices_do_not_specify_pitch_nor_yaw', () {
      String json_str = r"""
      {
        "helices": [
          {
            "group": "north",
            "position": {"x": 1, "y": 2, "z": 3},
            "roll": 5
          },
          {
            "group": "south",
            "position": {"x": 3, "y": 2, "z": 3},
            "roll": 15
          }
        ],
        "groups": {
          "north": {
            "position": {"x": 0, "y": -200, "z": 0},
            "grid": "none"
          },
          "south": {
            "position": {"x": 0, "y": -400, "z": 0},
            "grid": "none"
          }
        },
        "strands": [
          {
            "color": "#0066cc",
            "domains": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
          }
        ]
      }
      """;
      Design d = Design.from_json_str(json_str);
      Helix helix0 = d.helices[0];
      Helix helix1 = d.helices[1];

      String north_str = 'north';
      String south_str = 'south';
      HelixGroup north_group = d.groups[north_str];
      HelixGroup south_group = d.groups[south_str];
      expect(d.groups.length, 2);

      expect(helix0.position, Position3D(x: 1, y: 2, z: 3));
      expect(helix0.roll, 5);
      expect(north_group.pitch, 0);
      expect(north_group.yaw, 0);
      expect(helix0.group, north_str);

      expect(helix1.position, Position3D(x: 3, y: 2, z: 3));
      expect(helix1.roll, 15);
      expect(south_group.pitch, 0);
      expect(south_group.yaw, 0);
      expect(helix1.group, south_str);
    });

    test('multiple_helix_groups_helices_specify_pitch_and_yaw', () {
      String json_str = r"""
      {
        "helices": [
          {
            "group": "north",
            "position": {"x": 1, "y": 2, "z": 3},
            "pitch": 4,
            "roll": 5,
            "yaw": 6            },
          {
            "group": "south",
            "position": {"x": 3, "y": 2, "z": 3},
            "roll": 15
          }
        ],
        "groups": {
          "north": {
            "position": {"x": 0, "y": -200, "z": 0},
            "pitch": 21,
            "yaw": 13,
            "grid": "none"
          },
          "south": {
            "position": {"x": 0, "y": -400, "z": 0},
            "pitch": 23,
            "yaw": 98,
            "grid": "none"
          }
        },
        "strands": [
          {
            "color": "#0066cc",
            "domains": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
          }
        ]
      }
      """;
      Design d = Design.from_json_str(json_str);
      Helix helix0 = d.helices[0];
      Helix helix1 = d.helices[1];

      String north_str = 'north';
      String south_str = 'south';
      HelixGroup north_group = d.groups[north_str];
      HelixGroup south_group = d.groups[south_str];
      expect(d.groups.length, 2);
      expect(helix0.position, Position3D(x: 1, y: 2, z: 3));
      expect(helix0.roll, 5);
      expect(north_group.pitch, 25);
      expect(north_group.yaw, 19);
      expect(helix0.group, north_str);
      expect(helix1.position, Position3D(x: 3, y: 2, z: 3));
      expect(helix1.roll, 15);
      expect(south_group.pitch, 23);
      expect(south_group.yaw, 98);
      expect(helix1.group, south_str);
    });

    test('multiple_helix_groups_helices_specify_pitch_and_yaw_invalid', () {
      String json_str = r"""
    {
      "helices": [
        {
          "group": "north",
          "position": {"x": 1, "y": 2, "z": 3},
          "pitch": 4,
          "roll": 5,
          "yaw": 6
        },
        {
          "group": "north",
          "position": {"x": 3, "y": 2, "z": 3},
          "pitch": 10,
          "roll": 5,
          "yaw": 84
        }
      ],
      "groups": {
        "north": {
          "position": {"x": 0, "y": -200, "z": 0},
          "grid": "none"
        },
        "east": {
          "position": {"x": 0, "y": 0, "z": 100},
          "pitch": 45,
          "grid": "square"
        }
      },
      "strands": [
        {
          "color": "#0066cc",
          "domains": [ {"helix": 0, "forward": true, "start": 0, "end": 32} ]
        }
      ]
    }
    """;
      // should fail because multiple helices in same helix group are non-parallel
      expect(() => Design.from_json_str(json_str), throwsA(TypeMatcher<IllegalDesignError>()));
    });
  });

  // Github Issue: https://github.com/UC-Davis-molecular-computing/scadnano/issues/677
  test('adjusting_helices_view_order_should_update_svg_position', () {
    Helix helix0 = Helix(idx: 0, grid_position: GridPosition(0, 0), group: "foo");
    Helix helix1 = Helix(idx: 1, grid_position: GridPosition(0, 1), group: "foo");
    HelixGroup group = HelixGroup(helices_view_order: [0, 1], grid: Grid.square);
    Design design = Design(helices: [helix0, helix1], groups: {"foo": group});
    helix0 = design.helices[0];
    helix1 = design.helices[1];
    AppState state = app_state_from_design(design);
    // Point<num> original_helix0_svg_position = state.design.helices[0].svg_position;
    Point<num> original_helix1_svg_position = state.helix_idx_to_svg_position_map[1];

    HelixGroup new_group = HelixGroup(helices_view_order: [1, 0], grid: Grid.square);
    AppState new_state =
        app_state_reducer(state, GroupChange(old_name: "foo", new_name: "bar", new_group: new_group));

    // New svg position y coordinate should have changed
    expect(new_state.helix_idx_to_svg_position_map[1].y, closeTo(original_helix1_svg_position.y, 0.001));
    var offset = (helix1.position3d.y - helix0.position3d.y) * design.geometry.nm_to_svg_pixels;
    expect(new_state.helix_idx_to_svg_position_map[0].y,
        closeTo(original_helix1_svg_position.y + offset, 0.001));
  });

  // See https://github.com/UC-Davis-molecular-computing/scadnano/pull/703#issuecomment-1003738517
  // Test Description:
  //
  // Setup:
  //     Helix positions:
  //             0     1
  //        0 helix0 helix2
  //        1 helix1
  //
  //     - helix0 and helix2 are selected, helix1 is not selected
  //     - only_display_selected_helices is false, so all three helices
  //       appears in the main view
  //
  // Action: SetOnlyDisplaySelectedHelices
  //
  // Expected Result:
  //     - helix0 stays in same svg position, helix2 now should have same svg
  //       position that helix1 initially had, since helix1 and helix2 are both
  //       the same distance from helix0
  test('display_only_selected_helices_should_reassign_svg', () {
    // Setup:
    Helix helix0 = Helix(idx: 0, grid_position: GridPosition(0, 0));
    Helix helix1 = Helix(idx: 1, grid_position: GridPosition(0, 1));
    Helix helix2 = Helix(idx: 2, grid_position: GridPosition(1, 0));
    Design design = Design(helices: [helix0, helix1, helix2], grid: Grid.square);
    AppState state = app_state_from_design(design).rebuild((b) => b
      ..ui_state.storables.side_selected_helix_idxs.replace([0, 2])
      ..ui_state.storables.only_display_selected_helices = false);

    // Action
    AppState new_state = app_state_reducer(state, SetOnlyDisplaySelectedHelices(true));

    // Verify Expected Result:
    Point<num> helix0_svg = state.helix_idx_to_svg_position_map[0];
    Point<num> helix1_svg = state.helix_idx_to_svg_position_map[1];
    Point<num> new_helix0_svg = new_state.helix_idx_to_svg_position_map[0];
    Point<num> new_helix2_svg = new_state.helix_idx_to_svg_position_map[2];

    expect(new_helix0_svg.y, closeTo(helix0_svg.y, 0.001));
    expect(new_helix2_svg.y, closeTo(helix1_svg.y, 0.001));
  });

  // Setup:
  //      domain1
  //     AAAAAAAA
  //   0 [-------
  //            |
  //   1 <-------
  //     GGGGGGGG
  //     domain2
  //
  // Action: Move 5' end to the right
  //
  // Expected Result:
  //     domain1
  //         AAAA
  //   0     [---
  //            |
  //   1 <-------
  //     GGGGGGGG
  //     domain2
  //
  //   domain2 sequence should remain unchanged, domain1 should trim
  test('dna_ends_move_should_change_domain_sequence_locally__trim', () {
    // Setup:
    Helix helix0 = Helix(idx: 0, grid_position: GridPosition(0, 0), max_offset: 8);
    Helix helix1 = Helix(idx: 1, grid_position: GridPosition(0, 1), max_offset: 8);
    Design design = Design(helices: [helix0, helix1], grid: Grid.square)
        .draw_strand(0, 0)
        .to(8)
        .cross(1)
        .to(0)
        .with_sequence('AAAAAAAAGGGGGGGG')
        .commit();
    AppState state = app_state_from_design(design);

    // Action:
    DNAEndMove move =
        DNAEndMove(dna_end: design.strands.first.dnaend_5p, lowest_offset: 0, highest_offset: 8);
    DNAEndsMove dna_ends_move =
        DNAEndsMove(moves: [move].build(), original_offset: 0, current_offset: 4, helix: helix0);
    AppState new_state = app_state_reducer(state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // Expected Result:
    expect(new_state.design.strands.first.dna_sequence, 'AAAAGGGGGGGG');
  });

  // Setup:
  //      domain1
  //     AAAAAAAA
  //   0 ------->
  //     |
  //   1 -------]
  //     GGGGGGGG
  //     domain2
  //
  // Action: Move 5' end to the right
  //
  // Expected Result:
  //      domain1
  //     AAAAAAAA
  //   0 ------->
  //     |
  //   1 ----------]
  //     ???GGGGGGGG
  //     domain2
  //
  //   domain1 sequence should remain unchanged, domain2 should pad
  test('dna_ends_move_should_change_domain_sequence_locally__pad', () {
    // Setup:
    Helix helix0 = Helix(idx: 0, grid_position: GridPosition(0, 0), max_offset: 16);
    Helix helix1 = Helix(idx: 1, grid_position: GridPosition(0, 1), max_offset: 16);
    Design design = Design(helices: [helix0, helix1], grid: Grid.square)
        .draw_strand(1, 8)
        .to(0)
        .cross(0)
        .to(8)
        .with_sequence('GGGGGGGGAAAAAAAA')
        .commit();
    AppState state = app_state_from_design(design);

    // Action:
    DNAEndMove move =
        DNAEndMove(dna_end: design.strands.first.dnaend_5p, lowest_offset: 0, highest_offset: 16);
    DNAEndsMove dna_ends_move =
        DNAEndsMove(moves: [move].build(), original_offset: 7, current_offset: 10, helix: helix1);
    AppState new_state = app_state_reducer(state, DNAEndsMoveCommit(dna_ends_move: dna_ends_move));

    // Expected Result:
    expect(new_state.design.strands.first.dna_sequence, 'GGGGGGGG???AAAAAAAA');
  });
}

AppState make_ends_selectable(AppState actual_state) {
  var ends_modes = SelectModeChoice.ends_on_origami;
  var end_select_mode_action = SelectModesSet(ends_modes.toBuiltList());
  actual_state = app_state_reducer(actual_state, end_select_mode_action);
  return actual_state;
}
