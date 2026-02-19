import 'dart:html';
import 'dart:js' as js;

import 'package:built_collection/built_collection.dart';

import 'actions/actions.dart' as actions;
import 'app.dart';
import 'constants.dart' as constants;

// The origin (scheme + host) of the oxView iframe, used to filter incoming postMessage events.
const String _OXVIEW_ORIGIN = 'https://sulcgroup.github.io';

/// Call once at startup to begin listening for messages posted from the oxView iframe
/// via window.parent.postMessage(...).
setup_oxview_message_listener() {
  window.onMessage.listen((MessageEvent event) {
    if (event.origin != _OXVIEW_ORIGIN) return;
    try {
      var data = js.JsObject.fromBrowserObject(event.data);
      print('Received message from oxView: $data');
      _handle_oxview_message(data);
    } catch (e) {
      print('oxView message error: $e');
    }
  });
}

_handle_oxview_message(js.JsObject data) {
  String? message = data['message'] as String?;

  if (message == 'strands_deleted') {
    // oxView sends: { message: 'strand_deleted', strand_indices: [<int>, ...] }
    js.JsArray raw = data['strand_indices'] as js.JsArray;
    var strand_indices = BuiltList<int>([for (var idx in raw) (idx as num).toInt()]);
    app.dispatch(actions.StrandsDeleteByIndex(strand_indices: strand_indices));
  }
}
