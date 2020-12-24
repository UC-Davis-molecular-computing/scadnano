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
    _autostaple(store.state);
  } else if (action is actions.Autobreak) {
    _autobreak(store.state, action);
  } else {
    next(action);
  }
}

_autostaple(AppState state) async {
  var response = await http.post(
    constants.autostaple_url,
    body: json_encode(state.design),
    headers: {"Content-Type": "application/json"},
  );

  _handle_response(response, state);
}

_autobreak(AppState state, actions.Autobreak action) async {
  var body = jsonEncode({
    'settings': {
      'minStapleLegLen': action.min_distance_to_xover,
      'minStapleLen': action.min_length,
      'maxStapleLen': action.max_length,
      'tgtStapleLen': action.target_length,
    },
    'design': state.design.to_json_serializable()
  });
  var response = await http.post(
    constants.autobreak_url,
    body: body,
    headers: {"Content-Type": "application/json"},
  );

  _handle_response(response, state);
}

void _handle_response(http.Response response, AppState state) {
  if (response.statusCode == 200) {
    var json_model_text = response.body;
    var map = jsonDecode(json_model_text);
    var design_new = Design.from_json(map, state.ui_state.invert_xy);
    app.dispatch(actions.NewDesignSet(design: design_new));
  } else {
    Map response_body_json = jsonDecode(response.body);
    window.alert('Error: ${response_body_json['error']}');
  }
}