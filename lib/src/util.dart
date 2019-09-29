@JS()
library util;

import 'dart:convert';
import 'dart:core';
import 'dart:html';
import 'dart:js' as js;
import 'dart:math';

import 'package:js/js.dart';
import 'package:platform_detect/platform_detect.dart';

//import 'model/model.dart';
import 'model/model.dart';
import 'model/dna_design.dart';
import 'constants.dart' as constants;
import 'model/strand.dart';

/// Should only be called once at the start of the program
Future<Model> model_from_url(String url) async {
  Model model = Model.empty();

//  var dna_design = await _dna_design_from_url(url);
  String content = await file_content(url);
  Map<String, dynamic> parsed_json = jsonDecode(content);
//  var dna_design = DNADesign.from_json(parsed_json);
//  var dna_design = DNADesign();
  model.dna_design.read_from_json(parsed_json);
//  return dna_design;

//  model.dna_design = dna_design;
  return model;
}

//Future<DNADesign> _dna_design_from_url(String url) async {
//  String content = await file_content(url);
//  Map<String, dynamic> parsed_json = jsonDecode(content);
////  var dna_design = DNADesign.from_json(parsed_json);
//  var dna_design = DNADesign();
//  dna_design.read_from_json(parsed_json);
//  return dna_design;
//}

Future<String> file_content(String url) async {
  return await HttpRequest.getString(url).then((content) {
    return content;
  });
}

/// Transform point by panning and zooming.
/// (Actually I needed to do what appears to be the inverse transformation here, not sure why.)
Point<num> transform(Point<num> point, Point<num> pan, num zoom) {
  num ret_x;
  num ret_y;
  if (browser.isFirefox || browser.isInternetExplorer) {
    // Don't know why but Firefox auto-corrects for the current SVG coordinates whereas Chrome does not
    ret_x = point.x;
    ret_y = point.y;
  } else {
    ret_x = (point.x - pan.x) / zoom;
    ret_y = (point.y - pan.y) / zoom;
  }
  return Point<num>(ret_x, ret_y);
}

/// This goes into "window", so in JS you can access window.editor_content, and in Brython you can do this:
/// from browser import window
/// print(window['editor_content'])
save_editor_content_to_js_context(String new_content) {
  js.context[constants.editor_content_js_key] = new_content;
}

/// Tries to get value in map associated to key, but raises an exception if the key is not present.
/// Since this is only used for [DNADesign]s, it throws an [IllegalDNADesignError].
dynamic get_value(Map<String, dynamic> map, String key, String name) {
  if (!map.containsKey(key)) {
    throw IllegalDNADesignError('key "${key}" is missing from map describing ${name}:\n  ${map}');
  } else {
    return map[key];
  }
}

num sigmoid(num x) {
  return 1.0 / (1.0 + exp(-x));
}

@JS(constants.js_function_name_cache_svg)
external ImageElement cache_svg(String svg_elt_id);

@JS(constants.js_function_name_current_zoom)
external num current_zoom();

@JS(constants.js_function_name_current_pan)
external List<num> current_pan_js();

Point<num> current_pan() {
  var ret = current_pan_js();
  return Point<num>(ret[0], ret[1]);
}

String substrand_line_id(BoundSubstrand substrand) =>
    'substrand-H${substrand.helix}-O${substrand.start}-${substrand.forward ? 'right' : 'left'}';

String insertion_id(BoundSubstrand substrand, int offset) =>
    'insertion-H${substrand.helix}-O${offset}-${substrand.forward ? 'right' : 'left'}';

String loopout_id(Loopout loopout, BoundSubstrand prev_ss, BoundSubstrand next_ss) =>
    'loopout-H${prev_ss.helix}-O${prev_ss.offset_3p}-H${next_ss.helix}-O${next_ss.offset_5p}';

/// Indicates if loopout between two given strands is a hairpin.
bool is_hairpin(BoundSubstrand prev_ss, BoundSubstrand next_ss) {
  bool is_hairpin = prev_ss.helix == next_ss.helix &&
      prev_ss.forward != next_ss.forward &&
      (prev_ss.offset_3p - next_ss.offset_5p).abs() < 3;
  return is_hairpin;
}

save_file(String default_filename, String content) async {
//  String json_dna_design_text = json_encode(app.model.dna_design);
  Blob blob = new Blob([content], 'text/plain;charset=utf-8');
  String url = Url.createObjectUrlFromBlob(blob);
//  String filename = app.model.menu_view_ui_model.loaded_filename;
  var link = new AnchorElement()
    ..href = url
    ..download = default_filename;

  if (browser.isFirefox) {
    document.body.children.add(link);
  }
  //TODO: this await is my attempt to block until the user has selected a file, but it doesn't work.
  // The code keeps executing while they pick their file. Figure out how to detect if they picked a file or cancelled
  // If they cancelled then we should act as though nothing happened (in particular the Controller should not
  // send an Action indicating that the file was saved.
  //TODO: consider using one of these libraries if possible:
  //  https://github.com/jimmywarting/StreamSaver.js
  //  https://github.com/eligrey/FileSaver.js
  await link.click();

  if (browser.isFirefox) {
    link.remove();
  }

  Url.revokeObjectUrl(url);

  //TODO: create separate textfield for user to enter desired save filename that we use above
  // we cannot pull it from the download dialog due to security:
  //  https://github.com/eligrey/FileSaver.js/issues/75
  //  https://github.com/WICG/native-file-system
}
