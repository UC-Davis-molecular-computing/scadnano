import 'dart:html';

import 'package:built_collection/built_collection.dart';

import 'actions/actions.dart' as actions;
import 'app.dart';

// The origin (scheme + host) of the oxView iframe, used to filter incoming postMessage events.
const String _OXVIEW_ORIGIN = 'https://sulcgroup.github.io';

/// Call once at startup to begin listening for messages posted from the oxView iframe
/// via window.parent.postMessage(...).
setup_oxview_message_listener() {
  print("window.location.origin = '${window.location.origin}'");
  window.onMessage.listen((MessageEvent event) {
    if (event.origin != _OXVIEW_ORIGIN) return;
    try {
      var data = event.data as Map;
      _handle_oxview_message(data);
    } catch (e) {
      print('oxView message error: $e');
    }
  });
}

_handle_oxview_message(Map data) {
  String? message = data['message'] as String?;

  if (message == 'strands_deleted') {
    var raw = data['strand_indices'] as List;
    var strand_indices = BuiltList<int>([for (var idx in raw) (idx as num).toInt()]);
    app.dispatch(actions.StrandsDeleteByIndex(strand_indices: strand_indices));
  }
}
