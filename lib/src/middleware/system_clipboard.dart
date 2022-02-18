import 'dart:html';

import 'package:redux/redux.dart';

import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/state/clipboard.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/strand.dart';

import '../reducers/strands_move_reducer.dart' as strands_move_reducer;
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../state/app_state.dart';
import '../reducers/strands_copy_info_reducer.dart';

// unit testing points this global variable at an instance of CLIClipboard,
// since BrowserClipboard doesn't work when running from command line
// (even when unit testing simulates the browser; it gives some error about document not in focus.)
Clipboard clipboard = BrowserClipboard();

// This middleware deals with the system clipboard. It copies selected strand
// info to the clipboard on Ctrl+C, and then reads that information on Ctrl+V or Ctrl+Shift+V.
// Technically it does not read directly from the clipboard; that is done in view/Design.dart
// since it requires an async read, which on completion creates the *PasteInitiate action, which
// contains the text of the clipboard content.

system_clipboard_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.CopySelectedStrands) {
    put_strand_info_on_clipboard(store);
    next(action);
  } else if (action is actions.CopySelectedDomains) {
    put_domains_info_on_clipboard(store);
    next(action);
  } else if (action is actions.ManualPasteInitiate) {
    handle_manual_paste_initiate(store, action, next);
  } else if (action is actions.AutoPasteInitiate) {
    handle_autopaste_initiate(store, action, next);
  } else {
    next(action);
  }
}

void handle_manual_paste_initiate(
    Store<AppState> store, actions.ManualPasteInitiate action, NextDispatcher next) {
  // This re-does some of the work of manual_paste_initiate_reducer in the call to next(action) below,
  // but it keeps the side effect of printing an error message out of the reducer.
  if (paste_is_impossible_from_clipboard(action.clipboard_content, action.in_browser)) return;

  // manual_paste_initiate_reducer parses clipboard content and update state.ui_state.strands_copy_info
  next(action);

  // now state.ui_state.strands_copy_info has been set by reducer, use it to initiate StrandsMoveStart
  // to let user pick where to paste
  var copy_info = store.state.ui_state.copy_info;
  var paste_start_action = actions.StrandsMoveStart(
    strands: copy_info.strands,
    address: copy_info.copied_address,
    copy: true,
    original_helices_view_order_inverse: copy_info.helices_view_order_inverse,
  );

  store.dispatch(paste_start_action);
}

void handle_autopaste_initiate(Store<AppState> store, actions.AutoPasteInitiate action, NextDispatcher next) {
  if (paste_is_impossible_from_clipboard(action.clipboard_content, action.in_browser)) return;

  // autopaste_initiate_reducer parses clipboard content and update state.ui_state.strands_copy_info
  next(action);

  // now state.ui_state.strands_copy_info has been set by reducer, use it to paste in a default location
  var copy_info = store.state.ui_state.copy_info;

  // test to see if we can paste at original address; if so then this is a new Design
  // (or user deleted originally copied strands). If so then paste there, otherwise go with
  // copy_info.next_address.
  var strands_move = copy_info.create_strands_move(store.state, start_at_copied: true);
  if (!strands_move_reducer.in_bounds_and_allowable(store.state.design, strands_move)) {
    strands_move = copy_info.create_strands_move(store.state, start_at_copied: false);
  }

  var paste_commit_action = actions.StrandsMoveCommit(strands_move: strands_move, autopaste: true);

  store.dispatch(paste_commit_action);
}

// either
// 1) clipboard doesn't have strands and helices_view_order, or
// 2) strands is empty, or
// 3) helices_view_order is null
bool paste_is_impossible_from_clipboard(String clipboard_content, bool in_browser) {
  var strands_and_helices_view_order = parse_strands_and_helices_view_order_from_clipboard(clipboard_content);
  if (strands_and_helices_view_order == null) return true;

  List<Strand> strands = strands_and_helices_view_order[0];
  List<int> helices_view_order = strands_and_helices_view_order[1];
  bool is_domain = strands_and_helices_view_order[2];

  if (strands.isEmpty) return true;

  // indicates helices came from more than one HelixGroup, so no way to paste
  if (helices_view_order == null && !is_domain) {
    var msg = 'copied Strands came from more than one HelixGroup, so they cannot be pasted.';
    print(msg);
    if (in_browser) {
      window.alert(msg);
    }
    return true;
  }
  return false;
}

void put_domains_info_on_clipboard(Store<AppState> store) {
  var domains = store.state.ui_state.selectables_store.selected_domains;
  if (domains.isNotEmpty) {
    List<String> clipboard_strings = [];
    for (var domain in domains) {
      var domain_json = json_encode(domain);
      domain_json = domain_json.replaceAll('\n', '\n    ');
      clipboard_strings.add(domain_json);
    }
    var domain_json = clipboard_strings.join(',\n    ');

    var clipboard_content = '''{
  "${constants.substrands_key}": [
    ${domain_json}
  ]
}''';
    clipboard.write(clipboard_content);
  }
}

void put_strand_info_on_clipboard(Store<AppState> store) {
  // create JSON representing strands
  var strands = store.state.ui_state.selectables_store.selected_strands;
  if (strands.isNotEmpty) {
    List<String> clipboard_strings = [];
    for (var strand in strands) {
      var strand_json = json_encode(strand);
      strand_json = strand_json.replaceAll('\n', '\n    ');
      clipboard_strings.add(strand_json);
    }
    var strands_json = clipboard_strings.join(',\n    ');

    // if strand domains are all on same group, output helices_view_order to JSON as well
    // helices_view_order will be null if not all copied strands came from same HelixGroup
    List<int> helices_view_order = null;
    var design = store.state.design;
    var group_names = design.group_names_of_strands(strands);
    if (group_names.length == 1) {
      HelixGroup group = design.group_of_domain(strands.first.first_domain);
      helices_view_order = group.helices_view_order.toList();
    }

    var clipboard_content = '''{
  "${constants.strands_key}": [
    ${strands_json}
  ],
  "${constants.helices_view_order_key}": ${helices_view_order}
}''';

    clipboard.write(clipboard_content);
  }
}
