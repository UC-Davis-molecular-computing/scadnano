import 'package:built_collection/built_collection.dart';

import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/address.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/strands_move.dart';
import 'package:test/test.dart';

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  group('AutoPaste', () {
    List<Helix> helices;
    Design design;
    Strand orig_strand;
    AppState state;
    var origin_address = Address(helix_idx: 0, offset: 0, forward: true);
    var default_translation = AddressDifference(helix_idx_delta: 1, offset_delta: 0, forward_delta: false);
    var default_next_address = Address(helix_idx: 1, offset: 0, forward: true);
    List<int> all_helices = [0, 1, 2, 3];

    setup() {
      helices = [for (int helix in all_helices) Helix(idx: helix, max_offset: 40, grid: Grid.square)];

      design = Design(helices: helices, grid: Grid.square);

      design = design.strand(0, 0).move(10).commit();
      orig_strand = design.strands.first;
      state = app_state_from_design(design);
    }

    setUp(setup);
    /*
        0         10        20        30        40

    0f  [-------->
    0r

    1f
    1r

    2f
    2r

    3f
    3r
    */

    test('autopaste_with_default_translation_down', () {
      /*
          0         10        20        30        40

      0f  [--------> select, then copy
      0r

      1f  [--------> autopaste to helix 1
      1r

      2f  [--------> autopaste to helix 2
      2r

      3f  [--------> autopaste to helix 3
      3r

          [attempt autopaste with no effect]
      */

      // select topmost strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = app_state_reducer(state, select_action);
      expect(state.ui_state.strands_copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = app_state_reducer(state, copy_action);
      var copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, origin_address);
      expect(copy_info.translation, default_translation);
      expect(copy_info.next_address, default_next_address);

      var autopaste_address_helix_1 = Address(helix_idx: 1, offset: 0, forward: true);
      var autopaste_address_helix_2 = Address(helix_idx: 2, offset: 0, forward: true);
      var autopaste_address_helix_3 = Address(helix_idx: 3, offset: 0, forward: true);
      var autopaste_address_helix_4 = Address(helix_idx: 4, offset: 0, forward: true);

      //  these tests would be more robust by checking the actual positions of the strands
      expect(design.strands.length, 1);

      // autopaste to helix 1
      var strands_move_for_autopaste_1 = copy_info.create_strands_move(state.design);
      var autopaste_action_1 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_1);
      state = app_state_reducer(state, autopaste_action_1);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_address_helix_1);
      expect(copy_info.translation, default_translation);
      expect(copy_info.next_address, autopaste_address_helix_2);
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 2
      var strands_move_for_autopaste_2 = copy_info.create_strands_move(state.design);
      var autopaste_action_2 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_2);
      state = app_state_reducer(state, autopaste_action_2);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_address_helix_2);
      expect(copy_info.translation, default_translation);
      expect(copy_info.next_address, autopaste_address_helix_3);
      expect(state.design.strands.length, 3);
      expect(state.design.strands.last.first_domain.helix, 2);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 3
      var strands_move_for_autopaste_3 = copy_info.create_strands_move(state.design);
      var autopaste_action_3 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_3);
      state = app_state_reducer(state, autopaste_action_3);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_address_helix_3);
      expect(copy_info.translation, default_translation);
      expect(copy_info.next_address, autopaste_address_helix_4);
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 4 (should have no effect)
      var strands_move_for_autopaste_4 = copy_info.create_strands_move(state.design);
      var autopaste_action_4 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_4);
      state = app_state_reducer(state, autopaste_action_4);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_address_helix_3);
      expect(copy_info.translation, default_translation);
      expect(copy_info.next_address, autopaste_address_helix_4);
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);
    });

    test('autopaste_with_default_translation_right', () {
      /*
          0         10        20        30        40

      0f  [--------> select, then copy
      0r

      1f  [--------> already here
      1r

      2f  [--------> already here
      2r

      3f  [--------> already here
      3r

          0         10        20        30        40
                    autopaste autopaste autopaste [attempt autopaste with no effect]
      0f  [-------->[-------->[-------->[-------->
      0r

      1f  [-------->
      1r

      2f  [-------->
      2r

      3f  [-------->
      3r
      */

      // add strands on all helices
      design = design.strand(1, 0).to(10).commit();
      design = design.strand(2, 0).to(10).commit();
      design = design.strand(3, 0).to(10).commit();
      state = state.rebuild((b) => b..design.replace(design));

      // select topmost strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = app_state_reducer(state, select_action);
      expect(state.ui_state.strands_copy_info, null);

      var autopaste_right_offset_10 = Address(helix_idx: 0, offset: 10, forward: true);
      var autopaste_right_offset_20 = Address(helix_idx: 0, offset: 20, forward: true);
      var autopaste_right_offset_30 = Address(helix_idx: 0, offset: 30, forward: true);
      var autopaste_right_offset_40 = Address(helix_idx: 0, offset: 40, forward: true);

      // copy
      var default_translation_right =
          AddressDifference(helix_idx_delta: 0, offset_delta: 10, forward_delta: false);
      var copy_action = actions.CopySelectedStrands();
      state = app_state_reducer(state, copy_action);
      var copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, origin_address);
      expect(copy_info.translation, default_translation_right);
      expect(copy_info.next_address, autopaste_right_offset_10);
      expect(state.design.strands.length, 4);

      // autopaste to offset 10
      var strands_move_for_autopaste_1 = copy_info.create_strands_move(state.design);
      var autopaste_action_1 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_1);
      state = app_state_reducer(state, autopaste_action_1);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_right_offset_10);
      expect(copy_info.translation, default_translation_right);
      expect(copy_info.next_address, autopaste_right_offset_20);
      expect(state.design.strands.length, 5);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to offset 20
      var strands_move_for_autopaste_2 = copy_info.create_strands_move(state.design);
      var autopaste_action_2 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_2);
      state = app_state_reducer(state, autopaste_action_2);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_right_offset_20);
      expect(copy_info.translation, default_translation_right);
      expect(copy_info.next_address, autopaste_right_offset_30);
      expect(state.design.strands.length, 6);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 20);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to offset 30
      var strands_move_for_autopaste_3 = copy_info.create_strands_move(state.design);
      var autopaste_action_3 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_3);
      state = app_state_reducer(state, autopaste_action_3);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_right_offset_30);
      expect(copy_info.translation, default_translation_right);
      expect(copy_info.next_address, autopaste_right_offset_40);
      expect(state.design.strands.length, 7);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to offset 40 (should have no effect)
      var strands_move_for_autopaste_4 = copy_info.create_strands_move(state.design);
      var autopaste_action_4 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_4);
      state = app_state_reducer(state, autopaste_action_4);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_right_offset_30);
      expect(copy_info.translation, default_translation_right);
      expect(copy_info.next_address, autopaste_right_offset_40);
      expect(state.design.strands.length, 7);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.forward, true);
    });

    test('manual-paste_undo_manual-paste_auto', () {
      /*
          0         10        20        30        40

      0f  [--------> select, then copy
      0r

      1f            [--------> manual paste
      1r

      2f
      2r

      3f
      3r

      then undo the last manual paste

          0         10        20        30        40

      0f  [-------->
      0r

      1f            [--------> manual paste (again)
      1r

      2f                      [--------> autopaste
      2r

      3f
      3r
      */

      // select topmost strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = app_state_reducer(state, select_action);
      expect(state.ui_state.strands_copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = app_state_reducer(state, copy_action);
      var copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, origin_address);
      expect(copy_info.translation, default_translation);
      expect(copy_info.next_address, default_next_address);

      expect(state.design.strands.length, 1);

      // manual paste to helix 1, offset 10, forward
      var manual_pasted_address = Address(helix_idx: 1, offset: 10, forward: true);
      var manual_pasted_translation =
          AddressDifference(helix_idx_delta: 1, offset_delta: 10, forward_delta: false);
      var next_address_after_manual_paste = Address(helix_idx: 2, offset: 20, forward: true);
      var strands_move = StrandsMove(
        strands_moving: [orig_strand].toBuiltList(),
        all_strands: design.strands,
        helices: design.helices,
        groups: design.groups,
        original_address: origin_address,
        copy: true,
      ).rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move);
      state = app_state_reducer(state, manual_paste_action);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, manual_pasted_address);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_address, next_address_after_manual_paste);
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // undo last manual paste
      var undo_action = actions.Undo();
      state = app_state_reducer(state, undo_action);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, manual_pasted_address);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_address, next_address_after_manual_paste);
      expect(state.design.strands.length, 1);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);

      // manual paste in same spot again
      state = app_state_reducer(state, manual_paste_action);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, manual_pasted_address);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_address, next_address_after_manual_paste);
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste
      var autopaste_address_helix_2 = Address(helix_idx: 2, offset: 20, forward: true);
      var autopaste_address_helix_3 = Address(helix_idx: 3, offset: 30, forward: true);
      var strands_move_autopaste = copy_info.create_strands_move(state.design);
      var autopaste_action = actions.StrandsAutoPaste(strands_move: strands_move_autopaste);
      state = app_state_reducer(state, autopaste_action);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_address_helix_2);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_address, autopaste_address_helix_3);
      expect(state.design.strands.length, 3);
      expect(state.design.strands.last.first_domain.helix, 2);
      expect(state.design.strands.last.first_domain.start, 20);
      expect(state.design.strands.last.first_domain.forward, true);
    });

    test('manual-paste_auto_auto_auto__go_off_edge', () {
      /*
          0         10        20        30        40

      0f  [--------> select, then copy
      0r

      1f            [--------> manual paste
      1r

      2f                      [--------> autopaste
      2r

      3f                                [--------> autopaste
      3r

                                                  [--------> out-of-bounds autopaste (should be ignored)
      */

      // select topmost strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = app_state_reducer(state, select_action);
      expect(state.ui_state.strands_copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = app_state_reducer(state, copy_action);
      var copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, origin_address);
      expect(copy_info.translation, default_translation);
      expect(copy_info.next_address, default_next_address);

      expect(state.design.strands.length, 1);

      // manual paste to helix 1, offset 10, forward
      var manual_pasted_address = Address(helix_idx: 1, offset: 10, forward: true);
      var manual_pasted_translation =
          AddressDifference(helix_idx_delta: 1, offset_delta: 10, forward_delta: false);
      var next_address_after_manual_paste = Address(helix_idx: 2, offset: 20, forward: true);
      var strands_move = StrandsMove(
        strands_moving: [orig_strand].toBuiltList(),
        all_strands: design.strands,
        helices: design.helices,
        groups: design.groups,
        original_address: origin_address,
        copy: true,
      ).rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move);
      state = app_state_reducer(state, manual_paste_action);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, manual_pasted_address);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_address, next_address_after_manual_paste);
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      var autopaste_address_helix_2 = Address(helix_idx: 2, offset: 20, forward: true);
      var autopaste_address_helix_3 = Address(helix_idx: 3, offset: 30, forward: true);
      var autopaste_address_helix_4 = Address(helix_idx: 4, offset: 40, forward: true);

      // autopaste to helix 2
      var strands_move_for_autopaste_2 = copy_info.create_strands_move(state.design);
      var autopaste_action_2 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_2);
      state = app_state_reducer(state, autopaste_action_2);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_address_helix_2);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_address, autopaste_address_helix_3);
      expect(state.design.strands.length, 3);
      expect(state.design.strands.last.first_domain.helix, 2);
      expect(state.design.strands.last.first_domain.start, 20);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 3
      var strands_move_for_autopaste_3 = copy_info.create_strands_move(state.design);
      var autopaste_action_3 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_3);
      state = app_state_reducer(state, autopaste_action_3);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_address_helix_3);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_address, autopaste_address_helix_4);
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.forward, true);

      // attempted autopaste to helix 4; should do nothing
      var strands_move_for_autopaste_4 = copy_info.create_strands_move(state.design);
      var autopaste_action_4 = actions.StrandsAutoPaste(strands_move: strands_move_for_autopaste_4);
      state = app_state_reducer(state, autopaste_action_4);
      copy_info = state.ui_state.strands_copy_info;
      expect(copy_info.original_address, origin_address);
      expect(copy_info.current_address, autopaste_address_helix_3);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_address, autopaste_address_helix_4);
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.forward, true);
    });
  });
}
