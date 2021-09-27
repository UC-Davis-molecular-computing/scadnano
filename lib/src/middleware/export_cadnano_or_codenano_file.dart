import 'dart:collection';
import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:redux/redux.dart';
import '../state/design.dart';
import '../state/grid.dart';

import '../json_serializable.dart';
import '../actions/actions.dart' as actions;
import '../state/app_state.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;

export_cadnano_or_codenano_file_middleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  next(action);

  AppState state = store.state;
  if (action is actions.ExportCadnanoFile) {
    _save_file_cadnano(state);
  } else if (action is actions.ExportCodenanoFile) {
    _save_file_codenano(state);
  }
}

_save_file_cadnano(AppState state) async {
  // var response = await http.post(
  //   constants.export_url,
  //   body: json_encode(state.design),
  //   headers: {"Content-Type": "application/json"},
  // );

  // if (response.statusCode == 200) {
  //   String default_filename = state.ui_state.loaded_filename;
  //   default_filename = path.setExtension(default_filename, '.json');
  //   util.save_file(default_filename, response.body);
  // } else {
  //   Map response_body_json = jsonDecode(response.body);
  //   window.alert('Error exporting file: ${response_body_json['error']}');
  // }

  try {
    Map<String, dynamic> content_serializable = new LinkedHashMap();

    var encoder = SuppressableIndentEncoder(Replacer());
    var content_serializable_final = state.design.to_cadnano_v2();
    content_serializable.addAll(content_serializable_final);
    var json_str = encoder.convert(content_serializable);

    String default_filename = state.ui_state.loaded_filename;
    default_filename = path.setExtension(default_filename, '.json');
    util.save_file(default_filename, json_str);
  } on IllegalCadnanoDesignError catch (e) {
    window.alert('Error exporting file: ${e.cause}');
  }
}

_save_file_codenano(AppState state) async {
  Design design = state.design;
  if (design == null) {
    return;
  }

  var grids = design.groups.values.map((group) => group.grid).toSet();
  if (!(grids.length == 1 && grids.first == Grid.none)) {
    var msg = 'Grid must be set to none for all helix groups to export to codenano. '
        'First convert all grids to none.';
    window.alert(msg);
    return;
  }

  Map design_json = state.design.to_json_serializable(suppress_indent: true);

  // codenano parameters; taken from an example file
  design_json['parameters'] = {
    "z_step": 0.332,
    "helix_radius": 1.0,
    "bases_per_turn": 10.5,
    "groove_angle": -2.2175948142986774,
    "inter_helix_gap": 0.65,
  };

  // change version to version of codenano when I got the example file
  design_json[constants.version_key] = '0.4.12';

  List helices_json = design_json[constants.helices_key];
  for (Map helix_json in helices_json) {
    // add pitch, roll, and yaw defaults explicitly, and convert to radians
    for (var angle_key in [constants.pitch_key, constants.roll_key, constants.yaw_key]) {
      num degrees = helix_json[angle_key];
      helix_json[angle_key] = degrees == null ? 0.0 : util.to_radians(degrees);
    }
    // change "position" to "origin"
    var pos = helix_json[constants.position_key];
    helix_json.remove(constants.position_key);
    helix_json['origin'] = pos;
  }

  List strands_json = design_json[constants.strands_key];
  for (Map strand_json in strands_json) {
    // change color to integer convention
    if (strand_json.containsKey(constants.color_key)) {
      var color = strand_json[constants.color_key];
      var color_int = util.color_hex_to_decimal_int(color);
      strand_json[constants.color_key] = color_int;
    }
    // change "forward" to "right"
    for (NoIndent no_indent_json in strand_json[constants.substrands_key]) {
      Map domain_json = no_indent_json.value;
      if (!domain_json.containsKey(constants.forward_key)) {
        window.alert('To export, strands cannot have any loopouts. '
            'Please remove all loopouts before exporting.');
        return;
      }
      bool forward = domain_json[constants.forward_key];
      domain_json.remove(constants.forward_key);
      domain_json['right'] = forward;
    }
  }

  var encoder = SuppressableIndentEncoder(Replacer(), suppress: true);
  var json_str = encoder.convert(design_json);
  var default_filename = path.setExtension(state.ui_state.loaded_filename, '-codenano.json');
  util.save_file(default_filename, json_str);
}
