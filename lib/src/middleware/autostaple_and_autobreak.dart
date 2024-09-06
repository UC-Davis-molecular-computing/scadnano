// @dart=2.9
import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;

import 'package:redux/redux.dart';
import '../state/design.dart';
import '../app.dart';

import '../json_serializable.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../constants.dart' as constants;

autostaple_and_autobreak_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action is actions.Autostaple) {
    _autostaple(store);
  } else if (action is actions.Autobreak) {
    _autobreak(store, action);
  } else {
    next(action);
  }
}

_autostaple(Store<AppState> store) async {
  var response = await http.post(
    constants.autostaple_url,
    body: json_encode(store.state.design),
    headers: {"Content-Type": "application/json"},
  );

  _handle_response(store, response, "autostaple");
}

_autobreak(Store<AppState> store, actions.Autobreak action) async {
  var body = jsonEncode({
    'settings': {
      'minStapleLegLen': action.min_distance_to_xover,
      'minStapleLen': action.min_length,
      'maxStapleLen': action.max_length,
      'tgtStapleLen': action.target_length,
    },
    'design': store.state.design.to_json_serializable()
  });
  var response = await http.post(
    constants.autobreak_url,
    body: body,
    headers: {"Content-Type": "application/json"},
  );

  _handle_response(store, response, "autobreak");
}

void _handle_response(Store<AppState> store, http.Response response, String short_description) {
  if (response.statusCode == 200) {
    var json_model_text = response.body;
    var design_new = Design.from_json_str(json_model_text, store.state.ui_state.invert_y);
    store.dispatch(actions.NewDesignSet(design_new, short_description));
  } else {
    Map response_body_json = jsonDecode(response.body);
    window.alert('Error: ${response_body_json['error']}');
  }
}
