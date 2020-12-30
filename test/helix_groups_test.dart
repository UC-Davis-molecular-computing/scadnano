import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/position3d.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/actions/actions.dart';
import 'package:scadnano/src/reducers/design_reducer.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/grid_position.dart';
import 'package:scadnano/src/extension_methods.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/constants.dart' as constants;

import 'utils.dart';

main() {
  test('JSON_no_groups_ensure_grid_in_JSON', () {
    var json_str = '''
{
  "grid": "square",
  "helices": [
    {"max_offset": 20, "grid_position": [0, 0]},
    {"max_offset": 21, "grid_position": [0, 1]},
    {"max_offset": 22, "grid_position": [0, 2]},
    {"max_offset": 23, "grid_position": [0, 3]}
  ],
  "strands": [
    {
      "color": "#f74308",
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8},
        {"helix": 1, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#57bb00",
      "domains": [
        {"helix": 2, "forward": true, "start": 0, "end": 8},
        {"helix": 3, "forward": false, "start": 0, "end": 8}
      ]
    }
  ]
}
    ''';
    var design = Design.from_json_str(json_str);
    var json_map_export = design.to_json_serializable(suppress_indent: false);
    expect(json_map_export.containsKey(constants.grid_key), true);
    expect(json_map_export.containsKey(constants.groups_key), false);
  });

  test('JSON_groups_ensure_no_grid_or_helices_view_order_in_JSON', () {
    var json_str = '''
{
  "groups": {
    "north": {
      "position": {"x": 0, "y": -200, "z": 0},
      "grid": "honeycomb"
    },
    "east": {
      "position": {"x": 0, "y": 0, "z": 100},
      "pitch": 45,
      "grid": "square"
    }
  },
  "helices": [
    {"group": "north", "max_offset": 20, "grid_position": [0, 0]},
    {"group": "north", "max_offset": 21, "grid_position": [0, 1]},
    {"group": "east", "max_offset": 22, "grid_position": [0, 13]},
    {"group": "east", "max_offset": 23, "grid_position": [0, 15]}
  ],
  "strands": []
}
    ''';
    var json_map = jsonDecode(json_str);
    var design = Design.from_json(json_map);
    var json_map_export = design.to_json_serializable(suppress_indent: false);
    expect(json_map_export.containsKey(constants.grid_key), false);
    expect(json_map_export.containsKey(constants.helices_view_order_key), false);
    expect(json_map_export.containsKey(constants.groups_key), true);
  });

  test('JSON_bad_no_groups_but_helices_reference_groups', () {
    var json_str = '''
{
  "grid": "square",
  "helices": [
    {"group": "north", "max_offset": 20, "grid_position": [0, 0]},
    {"group": "north", "max_offset": 21, "grid_position": [0, 1]},
    {"group": "east", "max_offset": 22, "grid_position": [0, 2]},
    {"group": "east", "max_offset": 23, "grid_position": [0, 3]}
  ],
  "strands": [
    {
      "color": "#f74308",
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8},
        {"helix": 1, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#57bb00",
      "domains": [
        {"helix": 2, "forward": true, "start": 0, "end": 8},
        {"helix": 3, "forward": false, "start": 0, "end": 8}
      ]
    }
  ]
}
    ''';
    var json_map = jsonDecode(json_str);
    expect(() => Design.from_json(json_map), throwsException);
  });

  test('JSON_bad_uses_groups_and_top_level_grid', () {
    var json_str = '''
{
  "grid": "none",
  "groups": {
    "north": {
      "position": {"x": 0, "y": -200, "z": 0},
      "grid": "honeycomb"
    },
    "east": {
      "position": {"x": 0, "y": 0, "z": 100},
      "pitch": 45,
      "grid": "square"
    }
  },
  "helices": [
    {"group": "north", "max_offset": 20, "grid_position": [1, 1]},
    {"group": "north", "max_offset": 21, "grid_position": [0, 1]},
    {"group": "east", "max_offset": 22, "grid_position": [0, 13]},
    {"group": "east", "max_offset": 23, "grid_position": [0, 15]}
  ],
  "strands": [
    {
      "color": "#f74308",
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8},
        {"helix": 1, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#57bb00",
      "domains": [
        {"helix": 2, "forward": true, "start": 0, "end": 8},
        {"helix": 3, "forward": false, "start": 0, "end": 8}
      ]
    }
  ]
}
        ''';
    var json_map = jsonDecode(json_str);
    expect(() => Design.from_json(json_map), throwsException);
  });

  test('JSON_bad_uses_groups_and_top_level_helices_view_order', () {
    var json_str = '''
{
  "helices_view_order": [3, 2, 1, 0],
  "groups": {
    "north": {
      "position": {"x": 0, "y": -200, "z": 0},
      "grid": "honeycomb"
    },
    "east": {
      "position": {"x": 0, "y": 0, "z": 100},
      "pitch": 45,
      "grid": "square"
    }
  },
  "helices": [
    {"group": "north", "max_offset": 20, "grid_position": [1, 1]},
    {"group": "north", "max_offset": 21, "grid_position": [0, 1]},
    {"group": "east", "max_offset": 22, "grid_position": [0, 13]},
    {"group": "east", "max_offset": 23, "grid_position": [0, 15]}
  ],
  "strands": [
    {
      "color": "#f74308",
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8},
        {"helix": 1, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#57bb00",
      "domains": [
        {"helix": 2, "forward": true, "start": 0, "end": 8},
        {"helix": 3, "forward": false, "start": 0, "end": 8}
      ]
    }
  ]
}
        ''';
    var json_map = jsonDecode(json_str);
    expect(() => Design.from_json(json_map), throwsException);
  });

  group('group_with_4_helix_groups', () {
    var json_str = '''
{
  "groups": {
    "north": {
      "position": {"x": 0, "y": -200, "z": 0},
      "grid": "honeycomb"
    },
    "east": {
      "position": {"x": 0, "y": 0, "z": 100},
      "pitch": 45,
      "grid": "square"
    },
    "south": {
      "position": {"x": 0, "y": 70, "z": 0},
      "grid": "square",
      "helices_view_order": [7, 6]
    },
    "west": {
      "position": {"x": 0, "y": 0, "z": 0},
      "grid": "none"
    }
  },
  "helices": [
    {"group": "north", "max_offset": 20, "grid_position": [1, 1], "idx": 0},
    {"group": "north", "max_offset": 21, "grid_position": [0, 1], "idx": 1},
    {"group": "north", "max_offset": 19, "grid_position": [0, 2], "idx": 2},
    {"group": "north", "max_offset": 18, "grid_position": [1, 2], "idx": 3},
    {"group": "north", "max_offset": 17, "grid_position": [2, 2], "idx": 4},
    {"group": "north", "max_offset": 16, "grid_position": [2, 1], "idx": 5},
    {"group": "south", "max_offset": 24, "grid_position": [0, 0], "idx": 6},
    {"group": "south", "max_offset": 25, "grid_position": [0, 1], "idx": 7},
    {
      "group": "west",
      "max_offset": 26,
      "position": {"x": 0, "y": 0, "z": 0},
      "idx": 8
    },
    {
      "group": "west",
      "max_offset": 27,
      "position": {"x": 0, "y": 2.5, "z": 0},
      "idx": 9
    },
    {"group": "east", "max_offset": 22, "grid_position": [0, 0], "idx": 13},
    {"group": "east", "max_offset": 23, "grid_position": [0, 1], "idx": 15}
  ],
  "strands": [
    {
      "color": "#f74308",
      "domains": [
        {"helix": 0, "forward": true, "start": 0, "end": 8},
        {"helix": 1, "forward": false, "start": 0, "end": 8},
        {"helix": 2, "forward": true, "start": 0, "end": 8},
        {"helix": 3, "forward": false, "start": 0, "end": 8},
        {"helix": 4, "forward": true, "start": 0, "end": 8},
        {"helix": 5, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#57bb00",
      "domains": [
        {"helix": 6, "forward": true, "start": 0, "end": 8},
        {"helix": 7, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#888888",
      "domains": [
        {"helix": 8, "forward": true, "start": 0, "end": 8},
        {"helix": 9, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#32b86c",
      "domains": [
        {"helix": 13, "forward": true, "start": 0, "end": 8},
        {"helix": 15, "forward": false, "start": 0, "end": 8}
      ]
    }
  ]
}
        ''';
    var json_map = jsonDecode(json_str);
    var design = Design.from_json(json_map);
    var state = app_state_from_design(design);
    var n = 'north';
    var s = 'south';
    var e = 'east';
    var w = 'west';

    test('JSON_4_helix_groups', () {
      var groups = design.groups;

      expect(groups.length, 4);

      expect(groups[n].helices_view_order, [0, 1, 2, 3, 4, 5]);
      expect(groups[s].helices_view_order, [7, 6]);
      expect(groups[w].helices_view_order, [8, 9]);
      expect(groups[e].helices_view_order, [13, 15]);

      expect(groups[n].grid, Grid.honeycomb);
      expect(groups[e].grid, Grid.square);
      expect(groups[s].grid, Grid.square);
      expect(groups[w].grid, Grid.none);

      num eps = 0.000001;
      expect(groups[n].pitch, closeTo(0, eps));
      expect(groups[e].pitch, closeTo(45, eps));
      expect(groups[s].pitch, closeTo(0, eps));
      expect(groups[w].pitch, closeTo(0, eps));

      Map<String, dynamic> json_map_export = design.to_json_serializable(suppress_indent: false);
      expect(json_map_export.containsKey(constants.groups_key), true);

      Map<String, dynamic> groups_map = json_map_export[constants.groups_key];
      expect(groups_map.length, 4);

      Set<String> names = groups_map.keys.toSet();
      expect(names, {n, e, s, w});

      Map<String, dynamic> group_n = groups_map[n];
      Map<String, dynamic> group_e = groups_map[e];
      Map<String, dynamic> group_s = groups_map[s];
      Map<String, dynamic> group_w = groups_map[w];

      Map<String, dynamic> pos_n = group_n[constants.position_key];
      expect(pos_n['x'], closeTo(0, eps));
      expect(pos_n['y'], closeTo(-200, eps));
      expect(pos_n['z'], closeTo(0, eps));

      Map<String, dynamic> pos_e = group_e[constants.position_key];
      expect(pos_e['x'], closeTo(0, eps));
      expect(pos_e['y'], closeTo(0, eps));
      expect(pos_e['z'], closeTo(100, eps));

      Map<String, dynamic> pos_s = group_s[constants.position_key];
      expect(pos_s['x'], closeTo(0, eps));
      expect(pos_s['y'], closeTo(70, eps));
      expect(pos_s['z'], closeTo(0, eps));

      Map<String, dynamic> pos_w = group_w[constants.position_key];
      expect(pos_w['x'], closeTo(0, eps));
      expect(pos_w['y'], closeTo(0, eps));
      expect(pos_w['z'], closeTo(0, eps));

      expect(group_n[constants.grid_key], Grid.honeycomb.name);
      expect(group_e[constants.grid_key], Grid.square.name);
      expect(group_s[constants.grid_key], Grid.square.name);
      expect(group_w[constants.grid_key], Grid.none.name);

      // if pitch is 0, that's the default, so won't get written to JSON
      expect(group_n[constants.pitch_key], null);
      expect(group_e[constants.pitch_key], closeTo(45, eps));
      expect(group_s[constants.pitch_key], null);
      expect(group_w[constants.pitch_key], null);

      // test auto-assignment of grid_positions based on helices view order
      expect(design.helices[6].grid_position, GridPosition(0, 0));
      expect(design.helices[7].grid_position, GridPosition(0, 1));
      expect(design.helices[13].grid_position, GridPosition(0, 0));
      expect(design.helices[15].grid_position, GridPosition(0, 1));
    });

    test('helix_add_correct_view_order', () {
      var group_name = s;
      var new_grid_position = GridPosition(0, 2);
      state = state.rebuild((b) => b..ui_state.storables.displayed_group_name = group_name);
      var action = HelixAdd(grid_position: new_grid_position);
      var new_design = design_whole_global_reducer(design, state, action);

      expect(new_design.helices.length, 13);
      expect(new_design.helices.keys.max, 16);

      var new_helix = new_design.helices[16];
      expect(new_helix.group, group_name);
      expect(new_helix.grid_position, new_grid_position);

      expect(new_design.groups[s].helices_view_order[0], 7);
      expect(new_design.groups[s].helices_view_order[1], 6);
      expect(new_design.groups[s].helices_view_order[2], 16);
    });

    test('helix_remove_correct_view_order', () {
      var group_name = s;
      state = state.rebuild((b) => b..ui_state.storables.displayed_group_name = group_name);
      var action = HelixRemove(7);
      var new_design = design_whole_global_reducer(design, state, action);

      expect(new_design.helices.length, 11);
      expect(new_design.helices.keys.max, 15);

      expect(new_design.groups[s].helices_view_order[0], 6);
    });
  });

  test('helices_in_default_group_nondefault_indices', () {
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
    Design design = Design.from_json(jsonDecode(two_helices_with_helix_idx_gap_json));
    expect(design.groups.length, 1);
    expect(design.default_group().grid, Grid.square);
    expect(design.default_group().helices_view_order, [0, 4]);
  });

  test('helices_in_default_group_nondefault_view_order', () {
    String two_helices_with_helix_idx_gap_json = r'''
{
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
    Design design = Design.from_json(jsonDecode(two_helices_with_helix_idx_gap_json));
    expect(design.groups.length, 1);
    expect(design.default_group().grid, Grid.square);
    expect(design.default_group().helices_view_order, [12, 15, 17, 13].build());
    expect(
        design.default_group().helices_view_order_inverse, {12: 0, 15: 1, 17: 2, 13: 3}.build());
  });

  test('x_and_z_coordinates_of_group_and_none_grid_helices_should_swap_for_early_version', () {
    String json_str = r'''
      {
        "version": "0.12.0",
        "groups": {
          "east": {
            "position": {"x": 3, "y": 0, "z": 100},
            "pitch": 45,
            "grid": "square"
          },
          "west": {
            "position": {"x": 4, "y": 0, "z": 5},
            "grid": "none"
          }
        },
        "helices": [
          {
            "group": "west",
            "max_offset": 26,
            "position": {"x": 6, "y": 8, "z": 7},
            "idx": 8
          },
          {
            "group": "west",
            "max_offset": 27,
            "position": {"x": 2, "y": 2.5, "z": 1},
            "idx": 9
          },
          {"group": "east", "max_offset": 22, "grid_position": [0, 0], "idx": 13},
          {"group": "east", "max_offset": 23, "grid_position": [0, 1], "idx": 15}
        ],
        "strands": []
      }
    ''';
    var json_map = jsonDecode(json_str);
    var design = Design.from_json(json_map);
    var e = 'east';
    var w = 'west';
    var groups = design.groups;

    expect(groups.length, 2);

    expect(groups[w].helices_view_order, [8, 9]);
    expect(groups[e].helices_view_order, [13, 15]);

    expect(groups[e].grid, Grid.square);
    expect(groups[w].grid, Grid.none);

    num eps = 0.000001;
    expect(groups[e].pitch, closeTo(45, eps));
    expect(groups[w].pitch, closeTo(0, eps));

    Map<String, dynamic> json_map_export = design.to_json_serializable(suppress_indent: false);
    expect(json_map_export.containsKey(constants.groups_key), true);

    Map<String, dynamic> groups_map = json_map_export[constants.groups_key];
    expect(groups_map.length, 2);

    Set<String> names = groups_map.keys.toSet();
    expect(names, {e, w});

    Map<String, dynamic> group_e = groups_map[e];
    Map<String, dynamic> group_w = groups_map[w];

    // x and z coordinates should be swapped
    Map<String, dynamic> pos_e = group_e[constants.position_key];
    expect(pos_e['x'], closeTo(100, eps));
    expect(pos_e['y'], closeTo(0, eps));
    expect(pos_e['z'], closeTo(3, eps));

    // x and z coordinates should be swapped
    Map<String, dynamic> pos_w = group_w[constants.position_key];
    expect(pos_w['x'], closeTo(5, eps));
    expect(pos_w['y'], closeTo(0, eps));
    expect(pos_w['z'], closeTo(4, eps));

    expect(group_e[constants.grid_key], Grid.square.name);
    expect(group_w[constants.grid_key], Grid.none.name);

    // if pitch is 0, that's the default, so won't get written to JSON
    expect(group_e[constants.pitch_key], closeTo(45, eps));
    expect(group_w[constants.pitch_key], null);

    // test auto-assignment of grid_positions based on helices view order
    expect(design.helices[13].grid_position, GridPosition(0, 0));
    expect(design.helices[15].grid_position, GridPosition(0, 1));

    // test that x and z cordinate swapped for helices in helix group using none grid
    expect(design.helices[8].position, Position3D(x: 7, y: 8, z: 6));
    expect(design.helices[9].position, Position3D(x: 1, y: 2.5, z: 2));
  });
}
