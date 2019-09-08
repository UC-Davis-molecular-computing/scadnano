@JS()
library util;

import 'package:js/js.dart';
import 'dart:convert';
import 'dart:core';
import 'dart:html';
import 'dart:js' as js;
import 'dart:math';

import 'package:platform_detect/platform_detect.dart';

import 'model.dart';
import 'constants.dart' as constants;

Future<Model> model_from_url(String url) async {
  Model model = Model.empty();
  var dna_design = await _dna_design_from_url(url);
  model.dna_design = dna_design;
  return model;
}

Future<DNADesign> _dna_design_from_url(String url) async {
  return await HttpRequest.getString(url).then((content) {
    Map<String, dynamic> parsed_json = jsonDecode(content);
    var dna_design = DNADesign.from_json(parsed_json);
    return dna_design;
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
dynamic get_value(Map<String, dynamic> map, String key) {
  if (!map.containsKey(key)) {
    throw ArgumentError('key "${key}" is missing from map ${map}');
  } else {
    return map[key];
  }
}

num sigmoid(num x) {
  return 1.0 / (1.0 + exp(-x));
}

@JS(constants.js_function_name_cache_svg)
external ImageElement cache_svg(String svg_elt_id);