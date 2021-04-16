import 'dart:convert';
import 'dart:html';
import 'package:redux/redux.dart';
import 'package:scadnano/src/json_serializable.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/state/strands_copy_info.dart';

import '../actions/actions.dart' as actions;
import '../state/app_state.dart';

// For now only handles Strands, but we could potentially handle selected Domains, etc.
copy_selected_object_text_to_system_clipboard_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.CopySelectedStrands) {
    List<String> clipboard_strings = [];
    for (var item in store.state.ui_state.selectables_store.selected_strands) {
      clipboard_strings.add(json_encode(item));
    }
    var content = clipboard_strings.join(',\n');
    window.navigator.clipboard.writeText('[\n${content}\n]');
  }
  next(action);
}

// not a middleware currently, but when we convert to pure React, it will be
Future<StrandsCopyInfo> get_copied_strands_from_system_clipboard() async {
  List<Strand> strands = await parse_strands_from_clipboard();

  print('strands: ${strands}');
}

Future<List<Strand>> parse_strands_from_clipboard() async {
  String content = await window.navigator.clipboard.readText();
  String error_msg = 'no strand info found on system clipboard; nothing to paste; '
      'content of system clipboard: "${content}"';

  // try to parse JSON as a list
  List strand_jsons;
  try {
    strand_jsons = jsonDecode(content);
  } on Exception  {
    print(error_msg);
    return null;
  } on Error  {
    print(error_msg);
    return null;
  }

  // try to interpret JSON list as list of strands
  List<Strand> strands = [];
  for (var strand_json in strand_jsons) {
    Strand strand;
    try {
      strand = Strand.from_json(strand_json);
    } on Exception  {
      print(error_msg);
      return null;
    } on Error  {
      print(error_msg);
      return null;
    }
    strands.add(strand);
  }

  return strands;
}
