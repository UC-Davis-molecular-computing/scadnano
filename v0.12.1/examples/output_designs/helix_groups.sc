{
  "version": "0.11.0",
  "groups": {
    "north": {
      "position": {"x": 0, "y": -10, "z": 0},
      "grid": "honeycomb"
    },
    "east": {
      "position": {"x": 10, "y": 0, "z": 0},
      "grid": "square"
    },
    "south": {
      "position": {"x": 0, "y": 10, "z": 0},
      "grid": "square",
      "helices_view_order": [7, 6]
    },
    "west": {
      "position": {"x": -10, "y": 0, "z": 0},
      "grid": "none"
    },
    "r": {
      "position": {"x": 10, "y": 10, "z": 0},
      "pitch": 45,
      "grid": "square"
    }
  },
  "helices": [
    {"group": "north", "max_offset": 20, "grid_position": [0, 0], "idx": 0},
    {"group": "north", "max_offset": 21, "grid_position": [1, 0], "idx": 1},
    {"group": "north", "max_offset": 19, "grid_position": [1, 1], "idx": 2},
    {"group": "north", "max_offset": 18, "grid_position": [0, 1], "idx": 3},
    {"group": "north", "max_offset": 17, "grid_position": [-1, 1], "idx": 4},
    {"group": "north", "max_offset": 16, "grid_position": [-1, 0], "idx": 5},
    {"group": "south", "max_offset": 24, "grid_position": [0, 1], "idx": 6},
    {"group": "south", "max_offset": 25, "grid_position": [0, 0], "idx": 7},
    {
      "group": "west",
      "max_offset": 26,
      "position": {"x": 0, "y": 0, "z": 0},
      "idx": 8
    },
    {
      "group": "west",
      "max_offset": 27,
      "position": {"x": 0, "y": 3, "z": 0},
      "idx": 9
    },
    {"group": "r", "max_offset": 26, "grid_position": [0, 0], "idx": 10},
    {"group": "r", "max_offset": 27, "grid_position": [0, 1], "idx": 11},
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
        {"helix": 4, "forward": true, "start": 10, "end": 13}
      ]
    },
    {
      "color": "#888888",
      "domains": [
        {"helix": 6, "forward": true, "start": 0, "end": 8},
        {"helix": 7, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#32b86c",
      "domains": [
        {"helix": 8, "forward": true, "start": 0, "end": 8},
        {"helix": 9, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#333333",
      "domains": [
        {"helix": 13, "forward": true, "start": 0, "end": 8},
        {"helix": 15, "forward": false, "start": 0, "end": 8}
      ]
    },
    {
      "color": "#320096",
      "domains": [
        {"helix": 8, "forward": true, "start": 8, "end": 11}
      ]
    },
    {
      "color": "#03b6a2",
      "domains": [
        {"helix": 13, "forward": true, "start": 8, "end": 11}
      ]
    },
    {
      "color": "#7300de",
      "domains": [
        {"helix": 10, "forward": true, "start": 0, "end": 8},
        {"helix": 11, "forward": false, "start": 0, "end": 8}
      ]
    }
  ]
}