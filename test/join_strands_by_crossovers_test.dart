// @dart=2.9

import 'package:scadnano/src/reducers/change_loopout_length.dart';
import 'package:scadnano/src/reducers/delete_reducer.dart';
import 'package:scadnano/src/reducers/design_reducer.dart';
import 'package:scadnano/src/reducers/nick_ligate_join_by_crossover_reducers.dart';
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/domain.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/select_mode.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  group('JoinStrandsByMultipleCrossovers', () {
    List<Helix> helices;
    Design design;
    actions.JoinStrandsByMultipleCrossovers join_action;
    setUp(() {
      helices = [
        for (int helix in [0, 1, 2, 3]) Helix(idx: helix, max_offset: 100, grid: Grid.square)
      ];

      int right_end = 40;

      design = Design(helices: helices, grid: Grid.square);

      // scaffolds
      for (int helix in [0, 1, 2, 3]) {
        int scaffold_5p = 0;
        int scaffold_move = right_end ~/ 2;
        if (helix % 2 != 0) {
          scaffold_5p = right_end;
          scaffold_move = -scaffold_move;
        }

        if (helix == 0) {
          // top scaffold has no nick
          design = design.draw_strand(0, 0).to(right_end).as_scaffold().commit();
        } else {
          design = design.draw_strand(helix, scaffold_5p).move(scaffold_move).as_scaffold().commit();
          design =
              design.draw_strand(helix, scaffold_5p + scaffold_move).move(scaffold_move).as_scaffold().commit();
        }
      }

      // staples
      for (int helix in [0, 1, 2, 3]) {
        int staple_5p = 0;
        int staple_move = right_end ~/ 4;
        if (helix % 2 == 0) {
          staple_5p = right_end;
          staple_move = -staple_move;
        }
        int staple_offset = staple_5p;
        for (int i = 0; i < 4; i++) {
          design = design.draw_strand(helix, staple_offset).move(staple_move).commit();
          staple_offset += staple_move;
        }
      }

      join_action = actions.JoinStrandsByMultipleCrossovers();
    });
    /*
        0         10        20        30        40
                                                    strand order
    0f  [-------------------------------------->    0
    0r  <--------]<--------]<--------]<--------]    10 9 8 7

    1f  [-------->[-------->[-------->[-------->    11 12 13 14
    1r  <------------------]<------------------]    2 1

    2f  [------------------>[------------------>    3 4
    2r  <--------]<--------]<--------]<--------]    18 17 16 15

    3f  [-------->[-------->[-------->[-------->    19 20 21 22
    3r  <------------------]<------------------]    6 5
    */

    test('all_scaffold', () {
      /*
        0         10        20        30        40
    0f  +--------------------------------------+
    0r /<--------]<--------]<--------]<--------]\
       |                                        |
    1f \[-------->[-------->[-------->[-------->/
    1r  +------------------++------------------+
                           ||
    2f  +------------------++------------------+
    2r /<--------]<--------]<--------]<--------]\
       |                                        |
    3f \[-------->[-------->[-------->[-------->/
    3r  +------------------]<------------------+
      */
      // select all scaffold ends (including the two middle at the bottom that won't get matched)
      var state = app_state_from_design(design);
      List<DNAEnd> selected_ends = [];
      for (var strand in design.strands.sublist(0, 7)) {
        selected_ends.add(strand.dnaend_5p);
        selected_ends.add(strand.dnaend_3p);
      }
      state = state.rebuild((b) => b..ui_state.selectables_store.selected_items.replace(selected_ends));

      design = design_global_reducer(design, state, join_action);

      expect(design.strands.length, 17);

      // scaffold should be last because it was just added
      var scaffold = design.strands.last;
      expect(scaffold.is_scaffold, true);
      for (int i=0; i<16; i++) {
        var staple = design.strands[i];
        expect(staple.is_scaffold, false);
      }

      expect(scaffold.substrands.length, 7);
      for (int i=0; i<16; i++) {
        var staple = design.strands[i];
        expect(staple.substrands.length, 1);
      }
    });

    test('all_staple', () {
      /*
        0         10        20        30        40
                                                    strand order
    0f  [-------------------------------------->    0
    0r  +--------++--------++--------++--------+
        |        ||        ||        ||        |
    1f  +--------++--------++--------++--------+
    1r  <------------------]<------------------]    2 1

    2f  [------------------>[------------------>    3 4
    2r  +--------++--------++--------++--------+
        |        ||        ||        ||        |
    3f  +--------++--------++--------++--------+
    3r  <------------------]<------------------]    6 5
      */
      // select all staple ends
      var state = app_state_from_design(design);
      List<DNAEnd> selected_ends = [];
      for (var strand in design.strands.sublist(7, 23)) {
        selected_ends.add(strand.dnaend_5p);
        selected_ends.add(strand.dnaend_3p);
      }
      state = state.rebuild((b) => b..ui_state.selectables_store.selected_items.replace(selected_ends));

      design = design_global_reducer(design, state, join_action);

      expect(design.strands.length, 15);

      for (int i=0; i<7; i++) {
        var scaffold = design.strands[i];
        expect(scaffold.is_scaffold, true);
        expect(scaffold.substrands.length, 1);
        expect(scaffold.circular, false);
      }
      for (int i=7; i<15; i++) {
        var staple = design.strands[i];
        expect(staple.is_scaffold, false);
        expect(staple.substrands.length, 2);
        expect(staple.circular, true);
      }
    });


    test('all_scaffold_and_staple', () {
      /*
        0         10        20        30        40
                                                    strand order
    0f  +--------------------------------------+    0
    0r |+--------++--------++--------++--------+\
       ||        ||        ||        ||        ||
    1f \+--------++--------++--------++--------+/
    1r  +------------------++------------------+    2 1
                           ||
    2f  +------------------++------------------+    3 4
    2r /+--------++--------++--------++--------+\
       ||        ||        ||        ||        ||
    3f \+--------++--------++--------++--------+/
    3r  +------------------]<------------------+    6 5
      */
      // select all scaffold and all staple ends
      var state = app_state_from_design(design);
      List<DNAEnd> selected_ends = [];
      for (var strand in design.strands) {
        selected_ends.add(strand.dnaend_5p);
        selected_ends.add(strand.dnaend_3p);
      }
      state = state.rebuild((b) => b..ui_state.selectables_store.selected_items.replace(selected_ends));

      design = design_global_reducer(design, state, join_action);

      expect(design.strands.length, 9);

      bool found_scaffold = false;
      for (int i=0; i<9; i++) {
        var strand = design.strands[i];
        if (strand.is_scaffold) {
          expect(found_scaffold, false);
          found_scaffold = true;
          expect(strand.substrands.length, 7);
          expect(strand.circular, false);
        } else {
          expect(strand.is_scaffold, false);
          expect(strand.substrands.length, 2);
          expect(strand.circular, true);
        }
      }
    });

  });
}
