{
  "version": "0.9.11",
  "grid": "square",
  "helices": [
    {"max_offset": 48, "grid_position": [0, 0]},
    {"max_offset": 48, "grid_position": [0, 1]}
  ],
  "strands": [
    {
      "color": "#0066cc",
      "sequence": "AACGTAACGTAACGTAACGTAACGTAACGTAACGTAACGTAACGTAACGTAACGTAACGTAACGTAACG",
      "domains": [
        {"helix": 1, "forward": false, "start": 8, "end": 24, "deletions": [20]},
        {"helix": 0, "forward": true, "start": 8, "end": 40, "insertions": [[14, 1], [26, 2]]},
        {"loopout": 3},
        {"helix": 1, "forward": false, "start": 24, "end": 40}
      ],
      "is_scaffold": true,
      "label": "scaffold label"
    },
    {
      "color": "#f74308",
      "sequence": "ACGTTACGTTACGTTTTACGTTACGTTACGTT",
      "domains": [
        {"helix": 1, "forward": true, "start": 8, "end": 24, "deletions": [20]},
        {"helix": 0, "forward": false, "start": 8, "end": 24, "insertions": [[14, 1]]}
      ],
      "label": "left staple"
    },
    {
      "color": "#57bb00",
      "sequence": "ACGTTACGTTACGTTACGCGTTACGTTACGTTAC",
      "domains": [
        {"helix": 0, "forward": false, "start": 24, "end": 40, "insertions": [[26, 2]]},
        {"helix": 1, "forward": true, "start": 24, "end": 40}
      ],
      "label": "right staple"
    }
  ]
}