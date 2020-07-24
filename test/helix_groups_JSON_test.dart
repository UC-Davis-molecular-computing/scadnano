import 'dart:convert';
import 'package:scadnano/src/state/grid.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/constants.dart' as constants;

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
    var json_map = jsonDecode(json_str);
    var design = Design.from_json(json_map);
    var json_map_export = design.to_json_serializable(suppress_indent: false);
    expect(json_map_export.containsKey(constants.grid_key), true);
    expect(json_map_export.containsKey(constants.groups_key), false);
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

  test('JSON_4_helix_groups', () {
    var json_str = '''
{
  "version": "0.10.1",
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
    {"group": "south", "max_offset": 24, "grid_position": [0, 6], "idx": 6},
    {"group": "south", "max_offset": 25, "grid_position": [0, 7], "idx": 7},
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
    {"group": "east", "max_offset": 22, "grid_position": [0, 13], "idx": 13},
    {"group": "east", "max_offset": 23, "grid_position": [0, 15], "idx": 15}
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

    var n = 'n';
    var s = 's';
    var e = 'e';
    var w = 'w';
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

    expect(group_n[constants.grid_key], Grid.honeycomb);
    expect(group_e[constants.grid_key], Grid.square);
    expect(group_s[constants.grid_key], Grid.square);
    expect(group_w[constants.grid_key], Grid.none);

    expect(group_n[constants.pitch_key], closeTo(0, eps));
    expect(group_e[constants.pitch_key], closeTo(45, eps));
    expect(group_s[constants.pitch_key], closeTo(0, eps));
    expect(group_w[constants.pitch_key], closeTo(0, eps));
  });
}
