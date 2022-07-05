{
  "version": "0.11.0",
  "grid": "square",
  "helices": [
    {"grid_position": [0, 0]},
    {"grid_position": [0, 1]}
  ],
  "strands": [
    {
      "color": "#0066cc",
      "domains": [
        {"helix": 1, "forward": false, "start": 0, "end": 16, "deletions": [12], "insertions": [[6, 3]]},
        {"helix": 0, "forward": true, "start": 0, "end": 32, "deletions": [11, 12, 24], "insertions": [[6, 1], [18, 2]]},
        {"loopout": 3},
        {"helix": 1, "forward": false, "start": 16, "end": 32, "deletions": [24], "insertions": [[18, 4]]}
      ],
      "is_scaffold": true
    },
    {
      "color": "#f74308",
      "domains": [
        {"helix": 1, "forward": true, "start": 0, "end": 16, "deletions": [12], "insertions": [[6, 3]]},
        {"helix": 0, "forward": false, "start": 0, "end": 16, "deletions": [11, 12], "insertions": [[6, 1]]}
      ]
    },
    {
      "color": "#57bb00",
      "domains": [
        {"helix": 0, "forward": false, "start": 16, "end": 32, "deletions": [24], "insertions": [[18, 2]]},
        {"helix": 1, "forward": true, "start": 16, "end": 32, "deletions": [24], "insertions": [[18, 4]]}
      ]
    }
  ]
}
