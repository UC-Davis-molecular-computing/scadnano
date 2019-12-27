// import 'dart:convert';
// import 'dart:io';

import 'dart:convert';
import 'dart:html';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/app_ui_state.dart';
import 'package:scadnano/src/state/bound_substrand.dart';
import 'package:scadnano/src/state/dna_design.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/potential_crossover.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/undo_redo.dart';
import 'package:test/test.dart';
import 'package:scadnano/src/state/app_state.dart';

/// Returns the default state of the app.
AppState default_state() {
  var dna_design = DNADesign();
  var ui_state = AppUIState.from_dna_design(dna_design);
  var state = (DEFAULT_AppStateBuilder
        ..dna_design.replace(dna_design)
        ..ui_state.replace(ui_state)
        ..editor_content = '')
      .build();
  return state;
}

/// Returns an [AppState] based on dna design.
AppState app_state_from_dna_design(dna_design) {
  var ui_state = AppUIState.from_dna_design(dna_design);
  var state = (DEFAULT_AppStateBuilder
        ..dna_design.replace(dna_design)
        ..ui_state.replace(ui_state)
        ..editor_content = '')
      .build();
  return state;
}

/// Checks that two lists of strands contain the same elements.
void expect_strands_equal(BuiltList<Strand> actual_strands, BuiltList<Strand> expected_strands) {
  // Check hashing for potential quick comparison.
  if (actual_strands.hashCode != expected_strands.hashCode) {
    expect(actual_strands.length == expected_strands.length, true);
    for (Strand strand in expected_strands) {
      expect(actual_strands.contains(strand), true);
    }
  }
}

/// Asserts that the [actual] matches [matcher] DNADesign.
///
/// This function makes debugging easier by splitting the giant assertion
/// into smaller assertions on individual fields.
void expect_dna_design_equal(DNADesign actual, DNADesign matcher) {
  expect(actual.version, matcher.version);
  expect(actual.grid, matcher.grid);
  expect(actual.major_tick_distance, matcher.major_tick_distance);
  expect(actual.helices, matcher.helices);
  expect_strands_equal(actual.strands, matcher.strands);
  expect(actual.is_origami, matcher.is_origami);
}

/// Asserts that the [actual] matches [matcher] AppUIState.
void expect_ui_state_equal(AppUIState actual, AppUIState matcher) {
  // Not neccessary to split assertion at the moment.
  expect(actual, matcher);
}

/// Asserts that the [actual] matches [matcher] UndoRedo.
void expect_undo_redo_equal(UndoRedo actual, UndoRedo matcher) {
  // Not neccessary to split assertion at the moment.
  expect(actual, matcher);
}

/// Asserts that the [actual] matches [matcher] AppState.
///
/// This function makes debugging easier by splitting the giant assertion
/// into smaller assertions on individual fields.
void expect_app_state_equal(AppState actual, AppState matcher) {
  expect_dna_design_equal(actual.dna_design, matcher.dna_design);
  expect_ui_state_equal(actual.ui_state, matcher.ui_state);
  expect_undo_redo_equal(actual.undo_redo, matcher.undo_redo);
  expect(actual.error_message, matcher.error_message);
  expect(actual.editor_content, matcher.editor_content);
}

main() {
  test('should add a helix in response to HelixAdd', () {
    var state = default_state();
    final grid_position = new GridPosition(5, 10);

    state = app_state_reducer(state, new HelixAdd(grid_position));

    final correct_helix = new Helix(grid_position: grid_position, idx: 0, grid: Grid.square);
    var correct_helices = new BuiltList<Helix>([correct_helix]);
    expect(state.dna_design.helices, correct_helices);
  });

  test('should remove helix in respond to HelixRemove', () {
    var state = default_state();
    final grid_position = new GridPosition(5, 10);

    state = app_state_reducer(state, new HelixAdd(grid_position));
    state = app_state_reducer(state, new HelixRemove(0));

    var correct_helices = new BuiltList<Helix>([]);
    expect(state.dna_design.helices, correct_helices);
  });

  String simple_strand = r"""
 {
  "version": "0.0.1",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 24}
      ]
    }
  ]
} 
  """;
  DNADesign dna_design_simple_strand = DNADesign.from_json(jsonDecode(simple_strand));

  //     before
  //     0        8              24
  // 0   [------------------------>

  //     after
  //     0        8              24
  // 0   [------> [--------------->
  test('test add nick on substrand', () {
    String content_after = r"""
 {
  "version": "0.0.1",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 8, "end": 24}
      ]
    }
  ]
} 
  """;
    var state = app_state_from_dna_design(dna_design_simple_strand);

    BoundSubstrand substrand = dna_design_simple_strand.strands[0].substrands[0] as BoundSubstrand;
    state = app_state_reducer(state, Nick(bound_substrand: substrand, offset: 8));

    DNADesign expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);
  });

  //     before
  //     0        8       16     24
  // 0   [------------------------>

  //     after
  //     0        8        16      24
  // 0   [------> [------> [------->
  test('test add two nicks on substrand', () {
    String content_after = r"""
 {
  "version": "0.0.1",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 8, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 16, "end": 24}
      ]
    }
  ]
} 
  """;
    AppState state = app_state_from_dna_design(dna_design_simple_strand);

    BoundSubstrand nicked_substrand1 = dna_design_simple_strand.strands[0].substrands[0] as BoundSubstrand;
    state = app_state_reducer(state, Nick(bound_substrand: nicked_substrand1, offset: 8));
    BoundSubstrand nicked_substrand2 = state.dna_design.strands[1].substrands[0] as BoundSubstrand;
    state = app_state_reducer(state, Nick(bound_substrand: nicked_substrand2, offset: 16));

    DNADesign expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);
  });

  //     ACGTACGA AACCGGTA
  // 0   [------- ------->
  //     <------- -------]
  //     TTTGGGCC AAACCCGG
  String smaller_design_h0_json = r"""
 {
  "version": "0.0.1",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "dna_sequence": "ACGTACGAAACCGGTA",
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 16}
      ]
    },
    {
      "dna_sequence": "GGCCCAAACCGGGTTT",
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
} 
  """;
  DNADesign small_design_h0 = DNADesign.from_json(jsonDecode(smaller_design_h0_json));

  //     ACGTACGA AACCGGTA
  // 0   [------> [------>
  //     <------- -------]
  //     TTTGGGCC AAACCCGG
  test('test add nick small_design_h0 forward', () {
    String content_after = """
 {
  "version": "0.0.1",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "dna_sequence": "ACGTACGA",
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "dna_sequence": "AACCGGTA",
      "substrands": [
        {"helix": 0, "forward": true, "start": 8, "end": 16}
      ]
    },
    {
      "dna_sequence": "GGCCCAAACCGGGTTT",
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
} 
    """;

    AppState state = app_state_from_dna_design(small_design_h0);

    BoundSubstrand nicked_substrand = small_design_h0.strands[0].substrands[0] as BoundSubstrand;
    state = app_state_reducer(state, Nick(bound_substrand: nicked_substrand, offset: 8));

    DNADesign expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);
  });

  //     0        8        16
  //     ACGTACGA AACCGGTA
  // 0   [------- ------->
  //     <------] <------]
  //     TTTGGGCC AAACCCGG
  test('test add nick small_design_h0 reverse', () {
    String content_after = """
 {
  "version": "0.0.1",
  "helices": [
    {"grid_position": [0, 0]}
  ],
  "strands": [
    {
      "dna_sequence": "ACGTACGAAACCGGTA",
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 16}
      ]
    },
    {
      "dna_sequence": "CCGGGTTT",
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "dna_sequence": "GGCCCAAA",
      "substrands": [
        {"helix": 0, "forward": false, "start": 8, "end": 16}
      ]
    }
  ]
} 
    """;
    AppState state = app_state_from_dna_design(small_design_h0);

    BoundSubstrand nicked_substrand = small_design_h0.strands[1].substrands[0] as BoundSubstrand;
    state = app_state_reducer(state, Nick(bound_substrand: nicked_substrand, offset: 8));

    DNADesign expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);
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
  String six_helix_rectangle_json = r"""
 {
  "version": "0.0.1",
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
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 2, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 2, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 3, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 3, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 4, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 4, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": false, "start": 0, "end": 96}
      ]
    }
  ]
 }
  """;
  DNADesign six_helix_rectangle = DNADesign.from_json(jsonDecode(six_helix_rectangle_json));

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
    AppState state = app_state_from_dna_design(six_helix_rectangle);

    // design.add_nick(helix=5, offset=48, forward=False)
    BoundSubstrand h5_reverse = six_helix_rectangle.strands[11].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h5_reverse, offset: 48));

    String h5_after_nick_json = r"""
 {
  "version": "0.0.1",
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
      "substrands": [
        {"helix": 5, "forward": false, "start": 48, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": false, "start": 0, "end": 48}
      ]
    }
  ]
 }
  """;
    DNADesign h5_after_nick1 = DNADesign.from_json(jsonDecode(h5_after_nick_json));
    Strand h5_96_reverse = h5_after_nick1.strands[0];
    Strand h5_48_reverse = h5_after_nick1.strands[1];
    expect(state.dna_design.strands.contains(h5_96_reverse), true);
    expect(state.dna_design.strands.contains(h5_48_reverse), true);

    // design.add_nick(helix=0, offset=40, forward=False)
    BoundSubstrand h0_reverse = six_helix_rectangle.strands[1].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h0_reverse, offset: 40));
    String h0_after_nick_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 40, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 40}
      ]
    }
  ]
 }
  """;
    DNADesign h0_after_nick2 = DNADesign.from_json(jsonDecode(h0_after_nick_json));
    Strand h0_96_reverse = h0_after_nick2.strands[0];
    Strand h0_40_reverse = h0_after_nick2.strands[1];
    expect(state.dna_design.strands.contains(h0_96_reverse), true);
    expect(state.dna_design.strands.contains(h0_40_reverse), true);

    // design.add_nick(helix=0, offset=72, forward=False)
    BoundSubstrand h0_reverse_for_nick3 = h0_96_reverse.substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h0_reverse_for_nick3, offset: 72));
    String h0_after_nick3_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 72, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h0_after_nick3 = DNADesign.from_json(jsonDecode(h0_after_nick3_json));
    Strand h0_40_72_reverse = h0_after_nick3.strands[0];
    Strand h0_72_96_reverse = h0_after_nick3.strands[1];
    expect(state.dna_design.strands.contains(h0_40_72_reverse), true);
    expect(state.dna_design.strands.contains(h0_72_96_reverse), true);
    // design.add_nick(helix=2, offset=40, forward=False)
    BoundSubstrand h2_reverse_for_nick4 = six_helix_rectangle.strands[5].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h2_reverse_for_nick4, offset: 40));
    String h2_after_nick4_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 2, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "substrands": [
        {"helix": 2, "forward": false, "start": 40, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h2_after_nick4 = DNADesign.from_json(jsonDecode(h2_after_nick4_json));
    Strand h2_00_40_reverse = h2_after_nick4.strands[0];
    Strand h2_40_96_reverse = h2_after_nick4.strands[1];
    expect(state.dna_design.strands.contains(h2_00_40_reverse), true);
    expect(state.dna_design.strands.contains(h2_40_96_reverse), true);
    // design.add_nick(helix=2, offset=72, forward=False)
    BoundSubstrand h2_reverse_for_nick5 = h2_40_96_reverse.substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h2_reverse_for_nick5, offset: 72));
    String h2_after_nick5_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 2, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "substrands": [
        {"helix": 2, "forward": false, "start": 72, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h2_after_nick5 = DNADesign.from_json(jsonDecode(h2_after_nick5_json));
    Strand h2_40_72_reverse = h2_after_nick5.strands[0];
    Strand h2_72_96_reverse = h2_after_nick5.strands[1];
    expect(state.dna_design.strands.contains(h2_40_72_reverse), true);
    expect(state.dna_design.strands.contains(h2_72_96_reverse), true);
    // design.add_nick(helix=4, offset=40, forward=False)
    BoundSubstrand h4_reverse_for_nick6 = six_helix_rectangle.strands[9].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h4_reverse_for_nick6, offset: 40));
    String h4_after_nick6_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 4, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "substrands": [
        {"helix": 4, "forward": false, "start": 40, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h4_after_nick6 = DNADesign.from_json(jsonDecode(h4_after_nick6_json));
    Strand h4_00_40_reverse = h4_after_nick6.strands[0];
    Strand h4_40_96_reverse = h4_after_nick6.strands[1];
    expect(state.dna_design.strands.contains(h4_00_40_reverse), true);
    expect(state.dna_design.strands.contains(h4_40_96_reverse), true);
    // design.add_nick(helix=4, offset=72, forward=False)
    BoundSubstrand h4_reverse_for_nick7 = h4_40_96_reverse.substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h4_reverse_for_nick7, offset: 72));
    String h4_after_nick7_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 4, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "substrands": [
        {"helix": 4, "forward": false, "start": 72, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h4_after_nick7 = DNADesign.from_json(jsonDecode(h4_after_nick7_json));
    Strand h4_40_72_reverse = h4_after_nick7.strands[0];
    Strand h4_72_96_reverse = h4_after_nick7.strands[1];
    expect(state.dna_design.strands.contains(h4_40_72_reverse), true);
    expect(state.dna_design.strands.contains(h4_72_96_reverse), true);
    // design.add_nick(helix=1, offset=24, forward=True)
    BoundSubstrand h1_forward_for_nick8 = six_helix_rectangle.strands[2].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h1_forward_for_nick8, offset: 24));
    String h1_after_nick8_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 1, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true, "start": 24, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h1_after_nick8 = DNADesign.from_json(jsonDecode(h1_after_nick8_json));
    Strand h1_00_24_forward = h1_after_nick8.strands[0];
    Strand h1_24_96_forward = h1_after_nick8.strands[1];
    expect(state.dna_design.strands.contains(h1_00_24_forward), true);
    expect(state.dna_design.strands.contains(h1_24_96_forward), true);
    // design.add_nick(helix=1, offset=56, forward=True)
    BoundSubstrand h1_forward_for_nick9 = h1_24_96_forward.substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h1_forward_for_nick9, offset: 56));
    String h1_after_nick9_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 1, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true, "start": 56, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h1_after_nick9 = DNADesign.from_json(jsonDecode(h1_after_nick9_json));
    Strand h1_24_56_forward = h1_after_nick9.strands[0];
    Strand h1_56_96_forward = h1_after_nick9.strands[1];
    expect(state.dna_design.strands.contains(h1_24_56_forward), true);
    expect(state.dna_design.strands.contains(h1_56_96_forward), true);
    // design.add_nick(helix=3, offset=24, forward=True)
    BoundSubstrand h3_forward_for_nick10 = six_helix_rectangle.strands[6].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h3_forward_for_nick10, offset: 24));
    String h3_after_nick10_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 3, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "substrands": [
        {"helix": 3, "forward": true, "start": 24, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h3_after_nick10 = DNADesign.from_json(jsonDecode(h3_after_nick10_json));
    Strand h3_00_24_forward = h3_after_nick10.strands[0];
    Strand h3_24_96_forward = h3_after_nick10.strands[1];
    expect(state.dna_design.strands.contains(h3_00_24_forward), true);
    expect(state.dna_design.strands.contains(h3_24_96_forward), true);
    // design.add_nick(helix=3, offset=56, forward=True)
    BoundSubstrand h3_forward_for_nick11 = h3_24_96_forward.substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h3_forward_for_nick11, offset: 56));
    String h3_after_nick11_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 3, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "substrands": [
        {"helix": 3, "forward": true, "start": 56, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h3_after_nick11 = DNADesign.from_json(jsonDecode(h3_after_nick11_json));
    Strand h3_24_56_forward = h3_after_nick11.strands[0];
    Strand h3_56_96_forward = h3_after_nick11.strands[1];
    expect(state.dna_design.strands.contains(h3_24_56_forward), true);
    expect(state.dna_design.strands.contains(h3_56_96_forward), true);
    // design.add_nick(helix=5, offset=24, forward=True)
    BoundSubstrand h5_forward_for_nick12 = six_helix_rectangle.strands[10].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h5_forward_for_nick12, offset: 24));
    String h5_after_nick12_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 5, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": true, "start": 24, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h5_after_nick12 = DNADesign.from_json(jsonDecode(h5_after_nick12_json));
    Strand h5_00_24_forward = h5_after_nick12.strands[0];
    Strand h5_24_96_forward = h5_after_nick12.strands[1];
    expect(state.dna_design.strands.contains(h5_00_24_forward), true);
    expect(state.dna_design.strands.contains(h5_24_96_forward), true);
    // design.add_nick(helix=5, offset=56, forward=True)
    BoundSubstrand h5_forward_for_nick13 = h5_24_96_forward.substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: h5_forward_for_nick13, offset: 56));
    String h5_after_nick13_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2]}, {"grid_position": [0, 3]}, {"grid_position": [0, 4]}, {"grid_position": [0, 5]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 5, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": true, "start": 56, "end": 96}
      ]
    }
  ]
 }
  """;
    DNADesign h5_after_nick13 = DNADesign.from_json(jsonDecode(h5_after_nick13_json));
    Strand h5_24_56_forward = h5_after_nick13.strands[0];
    Strand h5_56_96_forward = h5_after_nick13.strands[1];
    expect(state.dna_design.strands.contains(h5_24_56_forward), true);
    expect(state.dna_design.strands.contains(h5_56_96_forward), true);

    String content_after = r"""
 {
  "version": "0.0.1",
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
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 72, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true, "start": 56, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 2, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 2, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "substrands": [
        {"helix": 2, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "substrands": [
        {"helix": 2, "forward": false, "start": 72, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 3, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "substrands": [
        {"helix": 3, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "substrands": [
        {"helix": 3, "forward": true, "start": 56, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 3, "forward": false, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 4, "forward": true, "start": 0, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 4, "forward": false, "start": 0, "end": 40}
      ]
    },
    {
      "substrands": [
        {"helix": 4, "forward": false, "start": 40, "end": 72}
      ]
    },
    {
      "substrands": [
        {"helix": 4, "forward": false, "start": 72, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": true, "start": 0, "end": 24}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": true, "start": 24, "end": 56}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": true, "start": 56, "end": 96}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": false, "start": 0, "end": 48}
      ]
    },
    {
      "substrands": [
        {"helix": 5, "forward": false, "start": 48, "end": 96}
      ]
    }
  ]
 }
    """;

    DNADesign expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);
  });

  //
  //
  //     0            16               32
  // 0  [-------------X--------------->
  //    <-------------X----------------]
  String simple_helix_with_deletion_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 32, "deletions": [16]}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 32, "deletions": [16]}
      ]
    }
  ]
 }
  """;
  DNADesign simple_helix_with_deletion_design = DNADesign.from_json(jsonDecode(simple_helix_with_deletion_json));
  //     0     8      16      24        32
  // 0  [------>[-----X------->[-------->
  //    <------]<-----X-------]<--------]
  test("two nicks on strand with deletions", () {
    AppState state = app_state_from_dna_design(simple_helix_with_deletion_design);

    BoundSubstrand strand_to_nick_1 = simple_helix_with_deletion_design.strands[0].substrands[0];
    BoundSubstrand strand_to_nick_2 = simple_helix_with_deletion_design.strands[1].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: strand_to_nick_1, offset: 8));
    state = app_state_reducer(state, Nick(bound_substrand: strand_to_nick_2, offset: 8));
    String content_after = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 8, "end": 32, "deletions": [16]}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 8, "end": 32, "deletions": [16]}
      ]
    }
  ]
 }
  """;
    DNADesign expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);

    BoundSubstrand strand_to_nick3 = expected_dna_design.strands[1].substrands[0];
    BoundSubstrand strand_to_nick4 = expected_dna_design.strands[3].substrands[0];

    state = app_state_reducer(state, Nick(bound_substrand: strand_to_nick3, offset: 24));
    state = app_state_reducer(state, Nick(bound_substrand: strand_to_nick4, offset: 24));

    content_after = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 8, "end": 24, "deletions": [16]}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 24, "end": 32}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 8, "end": 24, "deletions": [16]}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 24, "end": 32}
      ]
    }
  ]
 }
  """;
    expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);
  });

  //
  //
  //     0            16               32
  // 0  [-------------I--------------->
  //    <-------------I----------------]
  String simple_helix_with_insertion_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 32, "insertions": [[16, 3]]}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 32, "insertions": [[16, 3]]}
      ]
    }
  ]
 }
  """;
  DNADesign simple_helix_with_insertion_design = DNADesign.from_json(jsonDecode(simple_helix_with_insertion_json));
  //     0     8      16      24        32
  // 0  [------>[-----X------->[-------->
  //    <------]<-----X-------]<--------]
  test("two nicks on strand with insertions", () {
    AppState state = app_state_from_dna_design(simple_helix_with_insertion_design);

    BoundSubstrand strand_to_nick_1 = simple_helix_with_insertion_design.strands[0].substrands[0];
    BoundSubstrand strand_to_nick_2 = simple_helix_with_insertion_design.strands[1].substrands[0];
    state = app_state_reducer(state, Nick(bound_substrand: strand_to_nick_1, offset: 8));
    state = app_state_reducer(state, Nick(bound_substrand: strand_to_nick_2, offset: 8));
    String content_after = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 8, "end": 32, "insertions": [[16, 3]]}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 8, "end": 32, "insertions": [[16, 3]]}
      ]
    }
  ]
 }
  """;
    DNADesign expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);

    BoundSubstrand strand_to_nick3 = expected_dna_design.strands[1].substrands[0];
    BoundSubstrand strand_to_nick4 = expected_dna_design.strands[3].substrands[0];

    state = app_state_reducer(state, Nick(bound_substrand: strand_to_nick3, offset: 24));
    state = app_state_reducer(state, Nick(bound_substrand: strand_to_nick4, offset: 24));

    content_after = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 8, "end": 24, "insertions": [[16, 3]]}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": true, "start": 24, "end": 32}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 8, "end": 24, "insertions": [[16, 3]]}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false, "start": 24, "end": 32}
      ]
    }
  ]
 }
  """;
    expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);
  });

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
  String simple_strand_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]},{"grid_position": [0, 1]}, {"grid_position": [0, 2]} ],
  "strands": [
    {
      "dna_sequence": "AGTCAGTCAGTCAGTCCCGGAATTCCGGAATTAAAATTTTCCCCGGGG",
      "substrands": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16},
        {"helix": 1, "forward": false, "start": 0, "end": 16},
        {"helix": 2, "forward": true,  "start": 0, "end": 16}
      ]
    },
    {
      "dna_sequence": "GACTGACTGACTGACTAATTCCGGAATTCCGGCCCCGGGGAAAATTTT",
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 16},
        {"helix": 1, "forward": true , "start": 0, "end": 16},
        {"helix": 2, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
 }
  """;
  DNADesign simple_strand_dna_design = DNADesign.from_json(jsonDecode(simple_strand_json));
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
    AppState state = app_state_from_dna_design(simple_strand_dna_design);

    BoundSubstrand nick1_target = simple_strand_dna_design.strands[0].substrands[1];
    BoundSubstrand nick2_target = simple_strand_dna_design.strands[1].substrands[1];
    state = app_state_reducer(state, Nick(bound_substrand: nick1_target, offset: 8));
    state = app_state_reducer(state, Nick(bound_substrand: nick2_target, offset: 8));

    String content_after = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]},{"grid_position": [0, 1]}, {"grid_position": [0, 2]} ],
  "strands": [
    {
      "dna_sequence": "AGTCAGTCAGTCAGTCCCGGAATT",
      "substrands": [
        {"helix": 0, "forward": true,  "start": 0, "end": 16},
        {"helix": 1, "forward": false, "start": 8, "end": 16}
      ]
    },
    {
      "dna_sequence": "CCGGAATTAAAATTTTCCCCGGGG",
      "substrands": [
        {"helix": 1, "forward": false, "start": 0, "end": 8},
        {"helix": 2, "forward": true,  "start": 0, "end": 16}
      ]
    },
    {
      "dna_sequence": "GACTGACTGACTGACTAATTCCGG",
      "substrands": [
        {"helix": 0, "forward": false, "start": 0, "end": 16},
        {"helix": 1, "forward": true , "start": 0, "end": 8}
      ]
    },
    {
      "dna_sequence": "AATTCCGGCCCCGGGGAAAATTTT",
      "substrands": [
        {"helix": 1, "forward": true , "start": 8, "end": 16},
        {"helix": 2, "forward": false, "start": 0, "end": 16}
      ]
    }
  ]
 }
  """;
    DNADesign expected_dna_design = DNADesign.from_json(jsonDecode(content_after));
    expect_strands_equal(state.dna_design.strands, expected_dna_design.strands);
  });

  //   0       8       16
  // 0 [------>[------->
  //   AGTCAGTC AATTCCGG
  String two_strands_forward_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "dna_sequence": "AGTCAGTC",
      "substrands": [
        {"helix": 0, "forward": true , "start": 0, "end": 8}
      ]
    },
    {
      "dna_sequence": "AATTCCGG",
      "substrands": [
        {"helix": 0, "forward": true , "start": 8, "end": 16}
      ]
    }
  ]
 }
  """;
  DNADesign two_strands_forward = DNADesign.from_json(jsonDecode(two_strands_forward_json));

  //   0               16
  // 0 [--------------->
  //   AGTCAGTCAATTCCGG
  String ligate_two_strands_forward_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "dna_sequence": "AGTCAGTCAATTCCGG",
      "substrands": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    }
  ]
 }
  """;
  DNADesign ligate_two_strands_forward = DNADesign.from_json(jsonDecode(ligate_two_strands_forward_json));
  test("ligate two strands forward using 5p end", () {
    AppState state = app_state_from_dna_design(two_strands_forward);

    DNAEnd dna_end = two_strands_forward.strands[1].dnaend_5p;
    state = app_state_reducer(state, Ligate(dna_end: dna_end));

    expect_strands_equal(state.dna_design.strands, ligate_two_strands_forward.strands);
  });
  test("ligate two strands forward using 3p end", () {
    AppState state = app_state_from_dna_design(two_strands_forward);

    DNAEnd dna_end = two_strands_forward.strands[0].dnaend_3p;
    state = app_state_reducer(state, Ligate(dna_end: dna_end));

    expect_strands_equal(state.dna_design.strands, ligate_two_strands_forward.strands);
  });

  //   0       8       16
  // 0 <------] <-------]
  //   GGCCTTAA CTGACTGA
  String two_strands_reverse_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "dna_sequence": "AATTCCGG",
      "substrands": [
        {"helix": 0, "forward": false , "start": 0, "end": 8}
      ]
    },
    {
      "dna_sequence": "AGTCAGTC",
      "substrands": [
        {"helix": 0, "forward": false , "start": 8, "end": 16}
      ]
    }
  ]
 }
  """;
  DNADesign two_strands_reverse = DNADesign.from_json(jsonDecode(two_strands_reverse_json));

  //   0               16
  // 0 <---------------]
  //   GGCCTTAACTGACTGA
  String ligate_two_strands_reverse_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]} ],
  "strands": [
    {
      "dna_sequence": "AGTCAGTCAATTCCGG",
      "substrands": [
        {"helix": 0, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
  """;
  DNADesign ligate_two_strands_reverse = DNADesign.from_json(jsonDecode(ligate_two_strands_reverse_json));
  test("ligate two strands reverse using 5p end", () {
    AppState state = app_state_from_dna_design(two_strands_reverse);

    DNAEnd dna_end = two_strands_reverse.strands[0].dnaend_5p;
    state = app_state_reducer(state, Ligate(dna_end: dna_end));

    expect_strands_equal(state.dna_design.strands, ligate_two_strands_reverse.strands);
  });
  test("ligate two strands reverse using 3p end", () {
    AppState state = app_state_from_dna_design(two_strands_reverse);

    DNAEnd dna_end = two_strands_reverse.strands[1].dnaend_3p;
    state = app_state_reducer(state, Ligate(dna_end: dna_end));

    expect_strands_equal(state.dna_design.strands, ligate_two_strands_reverse.strands);
  });

  //   0                  16
  //
  // 0 [------------------->
  //   <-------------------]
  //
  // 1 [------------------->
  //   <-------------------]
  String two_helices_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
  """;
  DNADesign two_helices_design = DNADesign.from_json(jsonDecode(two_helices_json));

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
  test('pencil should ignore connecting a 5p end to a 5p end', () {
    AppState state = app_state_from_dna_design(two_helices_design);

    Strand h0_forward_strand = two_helices_design.strands[0];
    Strand h1_forward_strand = two_helices_design.strands[2];
    Helix h0 = two_helices_design.helices[0];
    Point<num> start_point = h0.svg_base_pos(0, true);
    PotentialCrossover helix_0_5p_end_potential_crossover = PotentialCrossover(
      helix_idx: 0,
      forward: true,
      offset: 0,
      color: h0_forward_strand.color.toHexColor().toCssString(),
      dna_end_first_click: h0_forward_strand.dnaend_5p,
      start_point: start_point,
      current_point: start_point,
    );
    DNAEnd helix_1_5p_end_second_click = h1_forward_strand.dnaend_5p;

    state = app_state_reducer(
        state,
        JoinStrandsByCrossover(
          dna_end_second_click: helix_1_5p_end_second_click,
          potential_crossover: helix_0_5p_end_potential_crossover,
        ));

    expect_strands_equal(state.dna_design.strands, two_helices_design.strands);
  });

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
  test('pencil should ignore connecting a 3p end to a 3p end', () {
    AppState state = app_state_from_dna_design(two_helices_design);

    Strand h0_forward_strand = two_helices_design.strands[0];
    Strand h1_forward_strand = two_helices_design.strands[2];
    Helix h0 = two_helices_design.helices[0];
    Point<num> start_point = h0.svg_base_pos(15, true); // 3p is located on offset = 15 and forward = true
    PotentialCrossover helix_0_5p_end_potential_crossover = PotentialCrossover(
      helix_idx: 0,
      forward: true,
      offset: 15,
      color: h0_forward_strand.color.toHexColor().toCssString(),
      dna_end_first_click: h0_forward_strand.dnaend_3p,
      start_point: start_point,
      current_point: start_point,
    );
    DNAEnd helix_1_3p_end_second_click = h1_forward_strand.dnaend_3p;

    state = app_state_reducer(
        state,
        JoinStrandsByCrossover(
          dna_end_second_click: helix_1_3p_end_second_click,
          potential_crossover: helix_0_5p_end_potential_crossover,
        ));

    expect_strands_equal(state.dna_design.strands, two_helices_design.strands);
  });
  //   0                  16
  //
  // 0 [------------------->
  //   --------------------]
  //  /
  //  |
  //  \
  // 1 -------------------->
  //   <-------------------]
  String two_helices_join_inner_strands_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false , "start": 0, "end": 16},
        {"helix": 1, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
  """;
  DNADesign two_helices_join_inner_strands = DNADesign.from_json(jsonDecode(two_helices_join_inner_strands_json));
  test('pencil should connect a 3p end to a 5p end', () {
    AppState state = app_state_from_dna_design(two_helices_design);

    Strand h0_reverse_strand = two_helices_design.strands[1];
    Strand h1_forward_strand = two_helices_design.strands[2];
    Helix h0 = two_helices_design.helices[0];
    Point<num> start_point = h0.svg_base_pos(0, false); // 3p end is 0 offset and forward is false.
    PotentialCrossover helix_0_3p_end_potential_crossover = PotentialCrossover(
      helix_idx: 0,
      forward: false,
      offset: 0,
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
          potential_crossover: helix_0_3p_end_potential_crossover,
        ));

    expect_strands_equal(state.dna_design.strands, two_helices_join_inner_strands.strands);
  });
  test('pencil should connect a 5p end to a 3p end', () {
    AppState state = app_state_from_dna_design(two_helices_design);

    Strand h0_reverse_strand = two_helices_design.strands[1];
    Strand h1_forward_strand = two_helices_design.strands[2];
    Helix h1 = two_helices_design.helices[1];
    Point<num> start_point = h1.svg_base_pos(0, true); // 5p end is 0 offset and forward is true.
    PotentialCrossover helix_1_5p_end_potential_crossover = PotentialCrossover(
      helix_idx: 1,
      forward: true,
      offset: 0,
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
          potential_crossover: helix_1_5p_end_potential_crossover,
        ));

    expect_strands_equal(state.dna_design.strands, two_helices_join_inner_strands.strands);
  });

  test('Saving DNA design with no unsaved changes', () {
    AppState state = app_state_from_dna_design(simple_strand_dna_design);
    AppState new_state = app_state_reducer(state, SaveDNAFile);

    expect(new_state, state);
  });

  test('Saving DNA design with unsaved changes', () {
    AppState expected_state = app_state_from_dna_design(simple_strand_dna_design);
    AppState old_state = expected_state.rebuild((b) => b.ui_state.changed_since_last_save = false);
    AppState new_state = app_state_reducer(old_state, SaveDNAFile);

    expect(new_state == expected_state, true);
  });

  test('add helix to DNA design', () {
    AppState state = app_state_from_dna_design(two_helices_design);
    state = app_state_reducer(state, HelixAdd(GridPosition(0, 2)));

    String two_helices_helix_add_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2], "max_offset": 16} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
    """;
    DNADesign two_helices_helix_add_design = DNADesign.from_json(jsonDecode(two_helices_helix_add_json));
    AppState two_helices_helix_add_state = app_state_from_dna_design(two_helices_helix_add_design);
    two_helices_helix_add_state = two_helices_helix_add_state.rebuild((b) => b
      ..ui_state.changed_since_last_save = true
      ..undo_redo
          .replace(two_helices_helix_add_state.undo_redo.rebuild((b) => b..undo_stack.replace([two_helices_design]))));

    // TODO(benlee12): Figure out consistent rule for svg_position.
    two_helices_helix_add_state.dna_design.helices.forEach((h) => h = h.rebuild((b) => b.svg_position_ = null));

    expect_app_state_equal(state, two_helices_helix_add_state);
  });

  test('save design after add helix to DNA design', () {
    AppState state = app_state_from_dna_design(two_helices_design);
    state = app_state_reducer(state, HelixAdd(GridPosition(0, 2)));
    state = app_state_reducer(state, SaveDNAFile);

    String two_helices_helix_add_json = r"""
 {
  "version": "0.0.1", "helices": [ {"grid_position": [0, 0]}, {"grid_position": [0, 1]}, {"grid_position": [0, 2], "max_offset": 16} ],
  "strands": [
    {
      "substrands": [
        {"helix": 0, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 0, "forward": false , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": true , "start": 0, "end": 16}
      ]
    },
    {
      "substrands": [
        {"helix": 1, "forward": false , "start": 0, "end": 16}
      ]
    }
  ]
 }
    """;
    DNADesign two_helices_helix_add_design = DNADesign.from_json(jsonDecode(two_helices_helix_add_json));
    AppState two_helices_helix_add_state = app_state_from_dna_design(two_helices_helix_add_design);
    two_helices_helix_add_state = two_helices_helix_add_state.rebuild((b) => b
      ..ui_state.changed_since_last_save = false
      ..undo_redo
          .replace(two_helices_helix_add_state.undo_redo.rebuild((b) => b..undo_stack.replace([two_helices_design]))));

    two_helices_helix_add_state.dna_design.helices.forEach((h) => h = h.rebuild((b) => b.svg_position_ = null));

    expect_app_state_equal(state, two_helices_helix_add_state);
  });
}
