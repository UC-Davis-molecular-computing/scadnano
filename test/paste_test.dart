// @dart=2.9

@Timeout(Duration(seconds: 5))

import 'package:scadnano/src/state/clipboard.dart';
import 'package:test/test.dart';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';

import 'package:scadnano/src/reducers/app_state_reducer.dart';
import 'package:scadnano/src/state/address.dart';
import 'package:scadnano/src/state/app_state.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/grid.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/middleware/system_clipboard.dart' as system_clipboard;

import 'package:scadnano/src/state/design.dart';
import 'package:scadnano/src/actions/actions.dart' as actions;

import 'utils.dart';

main() {
  system_clipboard.clipboard = CLIClipboard();
  CLIClipboard clipboard = system_clipboard.clipboard as CLIClipboard;

  //////////////////////////////////////////////////////////////////////////////////////////////////////
  // paste strands from one design to a newly loaded design
  //////////////////////////////////////////////////////////////////////////////////////////////////////
  group('PasteToNewDesign', () {
    List<Helix> helices;
    Strand orig_strand;
    Strand second_strand;
    AppState state;
    List<int> all_helices = [0, 1];
    var origin_address = Address(helix_idx: 0, offset: 0, forward: true);
    Store<AppState> store;
    // need Store.dispatch for middleware side effects of copying to (mock) system clipboard
    //  app_state_from_design by default uses mock Clipboard object with write and read functions,
    //  which can be used for unit testing, since dart:html window object
    //  is not available for command-line Dart VM apps

    setUp(() {
      helices = [for (int helix in all_helices) Helix(idx: helix, max_offset: 40, grid: Grid.square)];
      Design design = Design(helices: helices, grid: Grid.square);
      design = design.strand(0, 0).move(10).commit();
      design = design.strand(0, 20).move(10).cross(1).move(-5).commit();
      orig_strand = design.strands[0];
      second_strand = design.strands[1];
      store = store_from_design(design);
      state = store.state;
    });
    /*
        0         10        20        30        40

    0f  [-------->          [--------+
    0r                               |
                                     |
    1f                               |
    1r                           <---+
    */

    test('manual_paste_after_loading_new_design', () {
      /*
          0         10        20        30        40

      0f
      0r

      1f            [--------> // after pasting
      1r
      */
      // select only strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      // state = app_state_reducer(state, select_action);
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = test_dispatch(store, copy_action);
      var copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 2);

      // load new design
      var json_content = '''{
        "grid": "square",
        "helices": [
          { "grid_position": [0, 0], "max_offset": 40 },
          { "grid_position": [0, 1], "max_offset": 40 }
        ],
        "strands": []
      }''';
      var load_action = actions.LoadDNAFile(
          content: json_content, filename: 'new_file.sc', write_local_storage: false, unit_testing: true);
      state = test_dispatch(store, load_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 0);

      // simulate Ctrl+V; view/design.dart handle the async aspect of reading from the clipboard,
      // we need to synchronously mock it here for unit testing
      var manual_paste_initiate_action =
          actions.ManualPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, manual_paste_initiate_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, null);

      expect(state.design.strands.length, 0);

      // simulate clicking to select position to paste after Ctrl+V
      // manual paste to helix 0, offset 10, forward
      var manual_pasted_address = Address(helix_idx: 1, offset: 10, forward: true);
      var manual_pasted_translation =
          AddressDifference(helix_idx_delta: 1, offset_delta: 10, forward_delta: false);
      var next_address_after_manual_paste = Address(helix_idx: 2, offset: 20, forward: true);
      var strands_move = copy_info.create_strands_move(state);
      strands_move = strands_move.rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move, autopaste: false);
      state = test_dispatch(store, manual_paste_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, manual_pasted_address);
      expect(copy_info.translation, manual_pasted_translation);
      expect(copy_info.next_paste_address, next_address_after_manual_paste);
      expect(state.design.strands.length, 1);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);
    });

    test('manual_paste_two_strands_after_loading_new_design_different_helices_and_view_order', () {
      /*
          0         10        20        30        40

      5f
      5r

      3f            [-------->          [--------+ // after pasting
      3r                                         |
                                                 |
      7f                                         |
      7r                                     <---+
      */
      // select all strands
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = test_dispatch(store, select_action);
      select_action = actions.Select(second_strand, toggle: false, only: false);
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = test_dispatch(store, copy_action);
      var copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 2);

      // load new design
      var json_content = '''{
        "grid": "square",
        "helices": [
          { "idx": 3, "grid_position": [0, 1], "max_offset": 40 },
          { "idx": 5, "grid_position": [0, 0], "max_offset": 40 },
          { "idx": 7, "grid_position": [0, 2], "max_offset": 40 }
        ],
        "helices_view_order": [5, 3, 7],
        "strands": []
      }''';
      var load_action = actions.LoadDNAFile(
          content: json_content, filename: 'new_file.sc', write_local_storage: false, unit_testing: true);
      state = test_dispatch(store, load_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 0);

      // simulate Ctrl+V; view/design.dart handle the async aspect of reading from the clipboard,
      // we need to synchronously mock it here for unit testing
      var manual_paste_initiate_action =
          actions.ManualPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      test_dispatch(store, manual_paste_initiate_action);
      state = store.state;
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, null);

      expect(state.design.strands.length, 0);

      // simulate clicking to select position to paste after Ctrl+V
      // manual paste to helix 0, offset 10, forward
      var manual_pasted_address = Address(helix_idx: 3, offset: 10, forward: true);
      var strands_move = copy_info.create_strands_move(state);
      strands_move = strands_move.rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move, autopaste: false);
      state = test_dispatch(store, manual_paste_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, manual_pasted_address);
      expect(copy_info.translation, null);

      expect(state.design.strands.length, 2);
      expect(state.design.strands.first.first_domain.helix, 3);
      expect(state.design.strands.first.first_domain.start, 10);
      expect(state.design.strands.first.first_domain.end, 20);
      expect(state.design.strands.first.first_domain.forward, true);

      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.end, 40);
      expect(state.design.strands.last.first_domain.forward, true);
      expect(state.design.strands.last.last_domain.helix, 7);
      expect(state.design.strands.last.last_domain.start, 35);
      expect(state.design.strands.last.last_domain.end, 40);
      expect(state.design.strands.last.last_domain.forward, false);
    });

    test('manual_paste_illegal_address_after_loading_new_design_different_helices_and_view_order', () {
      /*
          0         10        20        30

      5f
      5r

      3f            [-------->          [--------+ // after pasting; illegal because out of bounds
      3r                                         |
                                                 |
      7f                                         |
      7r                                     <---+
      */
      // select all strands
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = test_dispatch(store, select_action);
      select_action = actions.Select(second_strand, toggle: false, only: false);
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = test_dispatch(store, copy_action);
      var copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 2);

      // load new design
      var json_content = '''{
        "grid": "square",
        "helices": [
          { "idx": 3, "grid_position": [0, 1], "max_offset": 30 },
          { "idx": 5, "grid_position": [0, 0], "max_offset": 30 },
          { "idx": 7, "grid_position": [0, 2], "max_offset": 30 }
        ],
        "helices_view_order": [5, 3, 7],
        "strands": []
      }''';
      var load_action = actions.LoadDNAFile(
          content: json_content, filename: 'new_file.sc', write_local_storage: false, unit_testing: true);
      state = test_dispatch(store, load_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 0);

      // simulate Ctrl+V; view/design.dart handle the async aspect of reading from the clipboard,
      // we need to synchronously mock it here for unit testing
      var manual_paste_initiate_action =
          actions.ManualPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      test_dispatch(store, manual_paste_initiate_action);
      state = store.state;
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, null);

      expect(state.design.strands.length, 0);

      // simulate clicking to select position to paste after Ctrl+V
      // manual paste to helix 0, offset 10, forward (should have no effect because out of bounds)
      var manual_pasted_address = Address(helix_idx: 3, offset: 10, forward: true);
      var strands_move = copy_info.create_strands_move(state);
      strands_move = strands_move.rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move, autopaste: false);
      state = test_dispatch(store, manual_paste_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, null);
      expect(copy_info.translation, null);

      expect(state.design.strands.length, 0);
    });

    test(
        'manual_paste_overlapping_strand_not_allowable_after_loading_new_design_different_helices_and_view_order',
        () {
      /*
          0         10        20        30

      5f
      5r
                      [--> // strand already here
      3f            [-------->    // after pasting; illegal because overlapping
      3r

      7f
      7r
      */
      // select top left strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = test_dispatch(store, copy_action);
      var copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 2);

      // load new design
      var json_content = '''{
        "grid": "square",
        "helices": [
          { "idx": 3, "grid_position": [0, 1], "max_offset": 40 },
          { "idx": 5, "grid_position": [0, 0], "max_offset": 40 },
          { "idx": 7, "grid_position": [0, 2], "max_offset": 40 }
        ],
        "helices_view_order": [5, 3, 7],
        "strands": [
          {
            "domains": [
              {"helix": 3, "forward": true, "start": 12, "end": 16}
            ]
          }
        ]
      }''';
      var load_action = actions.LoadDNAFile(
          content: json_content, filename: 'new_file.sc', write_local_storage: false, unit_testing: true);
      state = test_dispatch(store, load_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 1);

      // simulate Ctrl+V; view/design.dart handle the async aspect of reading from the clipboard,
      // we need to synchronously mock it here for unit testing
      var manual_paste_initiate_action =
          actions.ManualPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, manual_paste_initiate_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, null);

      expect(state.design.strands.length, 1);

      // simulate clicking to select position to paste after Ctrl+V
      // manual paste to helix 0, offset 10, forward (should be disallowed)
      var manual_pasted_address = Address(helix_idx: 3, offset: 10, forward: true);
      var strands_move = copy_info.create_strands_move(state);
      strands_move = strands_move.rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move, autopaste: false);
      state = test_dispatch(store, manual_paste_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, null);
      expect(copy_info.translation, null);

      expect(state.design.strands.length, 1);
    });

    test('autopaste_one_strand_after_loading_new_design', () {
      /*
          0         10        20        30        40

      0f  [-------->
      0r

      1f
      1r
      */
      // select one strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = test_dispatch(store, copy_action);
      var copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 2);

      // load new design
      var json_content = '''{
        "grid": "square",
        "helices": [
          { "grid_position": [0, 0], "max_offset": 50 },
          { "grid_position": [0, 1], "max_offset": 50 }
        ],
        "strands": []
      }''';
      var load_action = actions.LoadDNAFile(
          content: json_content, filename: 'new_file.sc', write_local_storage: false, unit_testing: true);
      state = test_dispatch(store, load_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 0);



      // autopaste to helix 0, offset 0
      var autopaste_action =
          actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, autopaste_action);
      expect(state.design.strands.length, 1);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 1, offset 0
      var autopaste_action_1 =
          actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, autopaste_action_1);
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 2, offset 0 (should have no effect because out of bounds)
      var autopaste_action_2 =
          actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, autopaste_action_2);
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);
    });
    // }, skip: true);
  });
  // }, skip: true);

  //////////////////////////////////////////////////////////////////////////////////////////////////////
  // manual paste to other HelixGroup
  //////////////////////////////////////////////////////////////////////////////////////////////////////
  group('manual_paste_to_other_HelixGroup', () {
    List<Helix> helices;
    Strand orig_strand;
    var origin_address = Address(helix_idx: 0, offset: 0, forward: true);
    List<int> all_helices = [0, 1, 2, 3, 4, 5, 6, 7];
    Store<AppState> store;

    setUp(() {
      helices = [
        for (int idx in all_helices)
          Helix(idx: idx, max_offset: 40, grid: Grid.square, group: idx < 4 ? 'group1' : 'group2')
      ];
      var groups = {
        'group1': HelixGroup(grid: Grid.square, helices_view_order: [0, 1, 2, 3]),
        'group2': HelixGroup(grid: Grid.square, helices_view_order: [5, 4, 7, 6]),
      };
      Design design = Design(helices: helices, grid: Grid.square, groups: groups);
      design = design.strand(0, 0).move(10).cross(1).move(-10).commit();
      orig_strand = design.strands.first;
      store = store_from_design(design);
    });
    /*
    group 1
        0         10        20        30        40

    0f  [--------+ // select, copy
    0r           |
                 |
    1f           |
    1r  <--------+

    2f
    2r

    3f
    3r

    group 2
        0         10        20        30        40

    0f
    0r

    1f
    1r

    2f
    2r

    3f
    3r
    */

    test('manual_paste_other_helix_group_reordered_helices', () {
      /*
      group 1
          0         10        20        30        40

      0f  [--------+
      0r           |
                   |
      1f           |
      1r  <--------+

      2f
      2r

      3f
      3r

      group 2 (note non-default helices_view_order)
          0         10        20        30        40

      5f
      5r

      4f            [--------+  // manual paste
      4r                     |
                             |
      7f                     |
      7r            <--------+

      6f
      6r
      */
      // select only strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      var state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = test_dispatch(store, copy_action);
      var copy_info = state.ui_state.copy_info;
      expect(copy_info, null);

      expect(state.design.strands.length, 1);
      expect(state.design.strands.first.first_domain.helix, 0);
      expect(state.design.strands.first.first_domain.start, 0);
      expect(state.design.strands.first.first_domain.end, 10);
      expect(state.design.strands.first.first_domain.forward, true);
      expect(state.design.strands.first.last_domain.helix, 1);
      expect(state.design.strands.first.last_domain.start, 0);
      expect(state.design.strands.first.last_domain.end, 10);
      expect(state.design.strands.first.last_domain.forward, false);

      // simulate Ctrl+V, which allows user to pick where to paste
      var manual_paste_initiate_action =
          actions.ManualPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, manual_paste_initiate_action);
      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, null);

      expect(state.design.strands.length, 1);

      // simulate clicking to select position to paste after Ctrl+V
      // manual paste to helix 4, offset 10, forward
      var manual_pasted_address = Address(helix_idx: 4, offset: 10, forward: true);
      var strands_move = copy_info.create_strands_move(state);
      strands_move = strands_move.rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move, autopaste: false);
      state = test_dispatch(store, manual_paste_action);

      copy_info = state.ui_state.copy_info;
      expect(copy_info.copied_address, origin_address);
      expect(copy_info.prev_paste_address, manual_pasted_address);
      expect(state.design.strands.length, 2);
      expect(state.design.strands.first.first_domain.helix, 0);
      expect(state.design.strands.first.first_domain.start, 0);
      expect(state.design.strands.first.first_domain.end, 10);
      expect(state.design.strands.first.first_domain.forward, true);
      expect(state.design.strands.first.last_domain.helix, 1);
      expect(state.design.strands.first.last_domain.start, 0);
      expect(state.design.strands.first.last_domain.end, 10);
      expect(state.design.strands.first.last_domain.forward, false);
      expect(state.design.strands.last.first_domain.helix, 4);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.end, 20);
      expect(state.design.strands.last.first_domain.forward, true);
      expect(state.design.strands.last.last_domain.helix, 7);
      expect(state.design.strands.last.last_domain.start, 10);
      expect(state.design.strands.last.last_domain.end, 20);
      expect(state.design.strands.last.last_domain.forward, false);
    });
  });
  // }, skip: true);

  //////////////////////////////////////////////////////////////////////////////////////////////////////
  // Autopaste
  //////////////////////////////////////////////////////////////////////////////////////////////////////
  group('AutoPaste', () {
    List<Helix> helices;
    Strand orig_strand;
    AppState state;
    // var origin_address = Address(helix_idx: 0, offset: 0, forward: true);
    List<int> all_helices = [0, 1, 2, 3];
    Store<AppState> store;

    setUp(() {
      helices = [for (int helix in all_helices) Helix(idx: helix, max_offset: 40, grid: Grid.square)];
      Design design = Design(helices: helices, grid: Grid.square);
      design = design.strand(0, 0).move(10).commit();
      orig_strand = design.strands.first;
      store = store_from_design(design);
      state = store.state;
    });
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

    test('manual_paste_auto_auto_auto__go_off_edge', () {
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
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = test_dispatch(store, copy_action);
      var copy_info = state.ui_state.copy_info;

      expect(state.design.strands.length, 1);

      // simulate Ctrl+V; view/design.dart handle the async aspect of reading from the clipboard,
      // we need to synchronously mock it here for unit testing
      var manual_paste_initiate_action =
      actions.ManualPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, manual_paste_initiate_action);
      copy_info = state.ui_state.copy_info;

      expect(state.design.strands.length, 1);

      // simulate clicking to select position to paste after Ctrl+V
      // manual paste to helix 1, offset 10, forward
      var manual_pasted_address = Address(helix_idx: 1, offset: 10, forward: true);
      var strands_move = copy_info.create_strands_move(state);
      strands_move = strands_move.rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move, autopaste: false);
      state = test_dispatch(store, manual_paste_action);

      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 2
      var autopaste_action_2 =
      actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, autopaste_action_2);
      copy_info = state.ui_state.copy_info;
      expect(state.design.strands.length, 3);
      expect(state.design.strands.last.first_domain.helix, 2);
      expect(state.design.strands.last.first_domain.start, 20);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 3
      var autopaste_action_3 =
      actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, autopaste_action_3);
      copy_info = state.ui_state.copy_info;
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.forward, true);

      // attempted autopaste to helix 4; should do nothing
      var autopaste_action_4 =
      actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, autopaste_action_4);
      copy_info = state.ui_state.copy_info;
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.forward, true);
    });

    test('autopaste_with_default_translation_down', () {
      /*
          0         10        20        30        40
          select/copy

      0f  [-------->
      0r

      1f  [--------> autopaste 1
      1r

      2f  [--------> autopaste 2
      2r

      3f  [--------> autopaste 3
      3r
          // autopaste 4 should have no effect
      */

      // select topmost strand
      state = test_dispatch(store, actions.Select(orig_strand, toggle: false, only: true));
      expect(state.ui_state.copy_info, null);

      // copy
      state = test_dispatch(store, actions.CopySelectedStrands());

      expect(state.design.strands.length, 1);

      // autopaste to helix 1, offset 0
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.end, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 2, offset 0
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 3);
      expect(state.design.strands.last.first_domain.helix, 2);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.end, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 3, offset 0
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.end, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // attempted autopaste to helix 4, offset 0, should have no effect
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.end, 10);
      expect(state.design.strands.last.first_domain.forward, true);
    });

    test('autopaste_with_default_translation_first_down_then_right', () {
      /*
          0         10        20        30        40
          select/copy

      0f  [-------->
      0r

      1f  [--------> autopaste 1
      1r

      2f  [--------> autopaste 2
      2r

      3f  [--------> autopaste 3
      3r

          attempted autopaste 4 should have no effect
      */

      // select topmost strand
      state = test_dispatch(store, actions.Select(orig_strand, toggle: false, only: true));
      expect(state.ui_state.copy_info, null);

      // copy
      state = test_dispatch(store, actions.CopySelectedStrands());

      expect(state.design.strands.length, 1);

      // autopaste to helix 1, offset 0
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.end, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 2, offset 0
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 3);
      expect(state.design.strands.last.first_domain.helix, 2);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.end, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 3, offset 0
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.end, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to helix 4, offset 0 (should have no effect
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 4);
      expect(state.design.strands.last.first_domain.helix, 3);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.end, 10);
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
      Design design = state.design.strand(1, 0).to(10).commit();
      design = design.strand(2, 0).to(10).commit();
      design = design.strand(3, 0).to(10).commit();
      store = store_from_design(design);
      state = store.state;

      // select topmost strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      state = test_dispatch(store, actions.CopySelectedStrands());

      expect(state.design.strands.length, 4);

      // autopaste to offset 10
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 5);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to offset 20
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 6);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 20);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to offset 30
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 7);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste to offset 40 (should have no effect)
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      expect(state.design.strands.length, 7);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 30);
      expect(state.design.strands.last.first_domain.forward, true);
    });

    test('autopaste_strand_paste_different_color_with_default_translation_down_then_right', () {
      // same as autopaste_with_default_translation_down_then_right
      // but set pasted strands to have different color
      state = test_dispatch(store, actions.StrandPasteKeepColorSet(keep: false));

      // select topmost strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      state = test_dispatch(store, actions.CopySelectedStrands());

      expect(state.design.strands.length, 1);

      // autopaste to helix 1
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));

      // autopaste to helix 2
      state = test_dispatch(
          store, actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false));

      // colors should all be different
      expect(state.design.strands[0].color, isNot(state.design.strands[1].color));
      expect(state.design.strands[0].color, isNot(state.design.strands[2].color));
      expect(state.design.strands[1].color, isNot(state.design.strands[2].color));
    });

    test('manual-paste_undo_manual-paste_autopaste', () {
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
      state = test_dispatch(store, actions.Select(orig_strand, toggle: false, only: true));
      expect(state.ui_state.copy_info, null);

      // copy
      state = test_dispatch(store, actions.CopySelectedStrands());

      expect(state.design.strands.length, 1);

      // simulate Ctrl+V; view/design.dart handle the async aspect of reading from the clipboard,
      // we need to synchronously mock it here for unit testing
      state = test_dispatch(
          store, actions.ManualPasteInitiate(clipboard_content: clipboard.content, in_browser: false));
      var copy_info = state.ui_state.copy_info;

      expect(state.design.strands.length, 1);

      // simulate clicking to select position to paste after Ctrl+V
      // manual paste to helix 1, offset 10, forward
      var manual_pasted_address = Address(helix_idx: 1, offset: 10, forward: true);
      var strands_move = copy_info.create_strands_move(state);
      strands_move = strands_move.rebuild((b) => b..current_address = manual_pasted_address.toBuilder());
      var manual_paste_action = actions.StrandsMoveCommit(strands_move: strands_move, autopaste: false);
      state = test_dispatch(store, manual_paste_action);

      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // undo last manual paste
      state = test_dispatch(store, actions.Undo());

      expect(state.design.strands.length, 1);
      expect(state.design.strands.last.first_domain.helix, 0);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);

      // manual paste in same spot again
      state = test_dispatch(store, manual_paste_action);

      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 10);
      expect(state.design.strands.last.first_domain.forward, true);

      // autopaste
      state = test_dispatch(store, actions.AutoPasteInitiate(clipboard_content: clipboard.content));

      expect(state.design.strands.length, 3);
      expect(state.design.strands.last.first_domain.helix, 2);
      expect(state.design.strands.last.first_domain.start, 20);
      expect(state.design.strands.last.first_domain.forward, true);
    });

    test('autopaste__unselect_pasted_strand__autopaste', () {
      /*
      tests for a bug where unselecting a pasted strand cleared the copy buffer

          0         10        20        30        40

      0f  [--------> select, then copy
      0r

      1f  [--------> autopaste to helix 1
      1r

      2f
      2r

      3f
      3r

      unselect all

          0         10        20        30        40

      0f  [--------> select, then copy
      0r

      1f  [--------> autopaste to helix 1
      1r

      2f  [--------> autopaste to helix 2
      2r

      3f
      3r
      */

      // select topmost strand
      var select_action = actions.Select(orig_strand, toggle: false, only: true);
      state = test_dispatch(store, select_action);
      expect(state.ui_state.copy_info, null);

      // copy
      var copy_action = actions.CopySelectedStrands();
      state = test_dispatch(store, copy_action);

      expect(state.design.strands.length, 1);

      // autopaste to helix 1
      var autopaste_action_1 =
          actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, autopaste_action_1);
      expect(state.design.strands.length, 2);
      expect(state.design.strands.last.first_domain.helix, 1);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);

      // unselect
      var unselect_action = actions.SelectionsClear();
      state = test_dispatch(store, unselect_action);

      // autopaste to helix 2
      var autopaste_action_2 =
          actions.AutoPasteInitiate(clipboard_content: clipboard.content, in_browser: false);
      state = test_dispatch(store, autopaste_action_2);
      expect(state.design.strands.length, 3);
      expect(state.design.strands.last.first_domain.helix, 2);
      expect(state.design.strands.last.first_domain.start, 0);
      expect(state.design.strands.last.first_domain.forward, true);
    });
  });
  // }, skip: true);
}
