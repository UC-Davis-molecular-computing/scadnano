import 'package:test/test.dart';
import 'package:redux/redux.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;
import 'package:scadnano/src/constants.dart' as constants;

import 'utils.dart';


main() {
  initializeComponentTests();
  group('helices_positions_set_based_on_crossovers', () {
    test('helices_angle', () {
      Design helices_angle = design_from_string("""
        {
          "version": "${constants.CURRENT_VERSION}",""" + r"""
          "grid": "none",
          "helices": [
            {"position": {"x": 0, "y": 0, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 2.5, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 5, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 7.5, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 10, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 12.5, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 15, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 17.5, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 20, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 22.5, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 25, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64},
            {"position": {"x": 0, "y": 27.5, "z": 0}, "major_ticks": [0, 10, 21, 31, 42, 52, 63], "max_offset": 64}
          ],
          "strands": [
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 1, "forward": true, "start": 0, "end": 21},
                {"helix": 0, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 2, "forward": true, "start": 10, "end": 31},
                {"helix": 1, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 3, "forward": true, "start": 0, "end": 21},
                {"helix": 2, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 4, "forward": true, "start": 10, "end": 31},
                {"helix": 3, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 5, "forward": true, "start": 0, "end": 21},
                {"helix": 4, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 6, "forward": true, "start": 10, "end": 31},
                {"helix": 5, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 7, "forward": true, "start": 0, "end": 21},
                {"helix": 6, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 8, "forward": true, "start": 10, "end": 31},
                {"helix": 7, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 9, "forward": true, "start": 0, "end": 21},
                {"helix": 8, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 10, "forward": true, "start": 10, "end": 31},
                {"helix": 9, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 11, "forward": true, "start": 0, "end": 21},
                {"helix": 10, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 1, "forward": true, "start": 21, "end": 42},
                {"helix": 0, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 2, "forward": true, "start": 31, "end": 52},
                {"helix": 1, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 3, "forward": true, "start": 21, "end": 42},
                {"helix": 2, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 4, "forward": true, "start": 31, "end": 52},
                {"helix": 3, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 5, "forward": true, "start": 21, "end": 42},
                {"helix": 4, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 6, "forward": true, "start": 31, "end": 52},
                {"helix": 5, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 7, "forward": true, "start": 21, "end": 42},
                {"helix": 6, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 8, "forward": true, "start": 31, "end": 52},
                {"helix": 7, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 9, "forward": true, "start": 21, "end": 42},
                {"helix": 8, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 10, "forward": true, "start": 31, "end": 52},
                {"helix": 9, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 11, "forward": true, "start": 21, "end": 42},
                {"helix": 10, "forward": false, "start": 21, "end": 42}
              ]
            }
          ]
        }
      """);
      Store<AppState> store = store_from_design(helices_angle);
      store.dispatch(actions.HelicesPositionsSetBasedOnCrossovers());

      Design expected_design = design_from_string("""
        {
          "version": "${constants.CURRENT_VERSION}",""" + r"""
          "grid": "none",
          "helices": [
            {
              "position": {"x": 0, "y": 0, "z": 0},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 330,
              "position": {"x": 0, "y": 1.0847093477938932, "z": 2.2524221697560485},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 300,
              "position": {"x": 0, "y": 0.17135678687790956, "z": 4.5796065413665605},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 270,
              "position": {"x": 0, "y": -1.2369433582811473, "z": 6.645203477156547},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 240,
              "position": {"x": 0, "y": -3.7090204238439677, "z": 7.017809142596987},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 210,
              "position": {"x": 0, "y": -6.202029916796918, "z": 6.830983908630923},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 180,
              "position": {"x": 0, "y": -7.760754421443755, "z": 4.876405202460852},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 150,
              "position": {"x": 0, "y": -8.845463769237648, "z": 2.6239830327048033},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 120,
              "position": {"x": 0, "y": -7.932111208321665, "z": 0.2967986610942912},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 90,
              "position": {"x": 0, "y": -6.523811063162608, "z": -1.7687982746956945},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 60,
              "position": {"x": 0, "y": -4.051733997599787, "z": -2.1414039401361347},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            },
            {
              "roll": 30,
              "position": {"x": 0, "y": -1.558724504646837, "z": -1.9545787061700721},
              "major_ticks": [0, 10, 21, 31, 42, 52, 63],
              "max_offset": 64
            }
          ],
          "strands": [
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 1, "forward": true, "start": 0, "end": 21},
                {"helix": 0, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 2, "forward": true, "start": 10, "end": 31},
                {"helix": 1, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 3, "forward": true, "start": 0, "end": 21},
                {"helix": 2, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 4, "forward": true, "start": 10, "end": 31},
                {"helix": 3, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 5, "forward": true, "start": 0, "end": 21},
                {"helix": 4, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 6, "forward": true, "start": 10, "end": 31},
                {"helix": 5, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 7, "forward": true, "start": 0, "end": 21},
                {"helix": 6, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 8, "forward": true, "start": 10, "end": 31},
                {"helix": 7, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 9, "forward": true, "start": 0, "end": 21},
                {"helix": 8, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 10, "forward": true, "start": 10, "end": 31},
                {"helix": 9, "forward": false, "start": 10, "end": 31}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 11, "forward": true, "start": 0, "end": 21},
                {"helix": 10, "forward": false, "start": 0, "end": 21}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 1, "forward": true, "start": 21, "end": 42},
                {"helix": 0, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 2, "forward": true, "start": 31, "end": 52},
                {"helix": 1, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 3, "forward": true, "start": 21, "end": 42},
                {"helix": 2, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 4, "forward": true, "start": 31, "end": 52},
                {"helix": 3, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 5, "forward": true, "start": 21, "end": 42},
                {"helix": 4, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 6, "forward": true, "start": 31, "end": 52},
                {"helix": 5, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 7, "forward": true, "start": 21, "end": 42},
                {"helix": 6, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 8, "forward": true, "start": 31, "end": 52},
                {"helix": 7, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 9, "forward": true, "start": 21, "end": 42},
                {"helix": 8, "forward": false, "start": 21, "end": 42}
              ]
            },
            {
              "color": "#0000cc",
              "domains": [
                {"helix": 10, "forward": true, "start": 31, "end": 52},
                {"helix": 9, "forward": false, "start": 31, "end": 52}
              ]
            },
            {
              "color": "#cc0000",
              "domains": [
                {"helix": 11, "forward": true, "start": 21, "end": 42},
                {"helix": 10, "forward": false, "start": 21, "end": 42}
              ]
            }
          ]
        }
      """);
      expect_design_equal(store.state.design, expected_design);
    });
  });
}