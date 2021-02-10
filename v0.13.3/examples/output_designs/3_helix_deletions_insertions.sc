{
  "version": "0.11.0",
  "grid": "square",
  "helices": [
    {"max_offset": 64, "grid_position": [0, 0]},
    {"grid_position": [0, 1]},
    {"max_offset": 64, "grid_position": [0, 2]}
  ],
  "strands": [
    {
      "color": "#0066cc",
      "sequence": "AACTAACTAACTAACTAACTAACTAACTAACTAACTAACTAACTAACTAACTAACTAACTAACTAACTAACT",
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
      "sequence": "TTAGTTAGTTAGTTAGTTTAGTTAGTTAGTTAG",
      "domains": [
        {"helix": 1, "forward": true, "start": 0, "end": 16, "deletions": [12], "insertions": [[6, 3]]},
        {"helix": 0, "forward": false, "start": 0, "end": 16, "deletions": [11, 12], "insertions": [[6, 1]]}
      ]
    },
    {
      "color": "#57bb00",
      "sequence": "TTAGTTAGTTAGTTAGTAGTTAGTTAGTTAGTTAGT",
      "domains": [
        {"helix": 0, "forward": false, "start": 16, "end": 32, "deletions": [24], "insertions": [[18, 2]]},
        {"helix": 1, "forward": true, "start": 16, "end": 32, "deletions": [24], "insertions": [[18, 4]]}
      ]
    },
    {
      "color": "#888888",
      "sequence": "AACTAACTAACTAACT",
      "domains": [
        {"helix": 1, "forward": true, "start": 32, "end": 48}
      ]
    },
    {
      "color": "#32b86c",
      "sequence": "GGTAGGTAGGTAGGTA",
      "domains": [
        {"helix": 1, "forward": true, "start": 48, "end": 64}
      ]
    },
    {
      "color": "#333333",
      "domains": [
        {"helix": 2, "forward": false, "start": 32, "end": 48}
      ]
    },
    {
      "color": "#320096",
      "domains": [
        {"helix": 2, "forward": true, "start": 16, "end": 32}
      ]
    },
    {
      "color": "#03b6a2",
      "sequence": "AGTTAGTTAGTTAGTT",
      "domains": [
        {"helix": 1, "forward": false, "start": 32, "end": 48}
      ]
    },
    {
      "color": "#7300de",
      "sequence": "TACCTACCTACCTACC",
      "domains": [
        {"helix": 1, "forward": false, "start": 48, "end": 64}
      ]
    },
    {
      "color": "#aaaa00",
      "domains": [
        {"helix": 2, "forward": true, "start": 32, "end": 48}
      ]
    },
    {
      "color": "#b8056c",
      "domains": [
        {"helix": 2, "forward": true, "start": 0, "end": 16}
      ]
    }
  ]
}