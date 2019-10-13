@JS()
library util;

import 'dart:convert';
import 'dart:html' hide ImageElement;
import 'dart:js' as js;
import 'dart:math';
import 'dart:svg' hide Point;

import 'package:js/js.dart';
import 'package:platform_detect/platform_detect.dart';

import 'model/helix.dart';
import 'model/model.dart';
import 'model/dna_design.dart';
import 'constants.dart' as constants;
import 'model/bound_substrand.dart';

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

Point<num> transform_mouse_coord_to_svg_current_panzoom_side(Point<num> point) {
  return transform_mouse_coord_to_svg(point, current_pan_side(), current_zoom_side());
}

Point<num> transform_mouse_coord_to_svg_current_panzoom_main(Point<num> point) {
  return transform_mouse_coord_to_svg(point, current_pan_main(), current_zoom_main());
}

/// Transform point by panning and zooming from mouse coordinates to SVG coordinates.
/// (Actually I needed to do what appears to be the inverse transformation here, not sure why.)
Point<num> transform_mouse_coord_to_svg(Point<num> point, Point<num> pan, num zoom) {
  num ret_x;
  num ret_y;
//  if (browser.isFirefox || browser.isInternetExplorer) {
//    // Don't know why but Firefox auto-corrects for the current SVG coordinates whereas Chrome does not
//    ret_x = point.x;
//    ret_y = point.y;
//  } else {
    ret_x = (point.x - pan.x) / zoom;
    ret_y = (point.y - pan.y) / zoom;
//  }
  return Point<num>(ret_x, ret_y);
}

Point<num> transform_svg_to_mouse_coord(Point<num> point, Point<num> pan, num zoom) {
  num ret_x;
  num ret_y;
  if (browser.isFirefox || browser.isInternetExplorer) {
    // Don't know why but Firefox auto-corrects for the current SVG coordinates whereas Chrome does not
    ret_x = point.x;
    ret_y = point.y;
  } else {
    ret_x = point.x * zoom + pan.x;
    ret_y = point.y * zoom + pan.y;
  }
  return Point<num>(ret_x, ret_y);
}

transform_rect(Point<num> transform(Point<num> p, Point<num> pan, num zoom), Rect rect, Point<num> pan, num zoom) {
  var up_left = Point<num>(rect.x, rect.y);
  var low_right = Point<num>(rect.x + rect.width, rect.y + rect.height);
  var up_left_tran = transform(up_left, pan, zoom);
  var low_right_tran = transform(low_right, pan, zoom);
  rect.x = up_left_tran.x;
  rect.y = up_left_tran.y;
  rect.width = low_right_tran.x - rect.x;
  rect.height = low_right_tran.y - rect.y;
}

///Modifies Rect in place because there doesn't seem to be a constructor:
/// https://api.dartlang.org/stable/2.5.2/dart-svg/Rect-class.html
transform_rect_mouse_coord_to_svg(Rect rect, Point<num> pan, num zoom) {
  transform_rect(transform_mouse_coord_to_svg, rect, pan, zoom);
}

///Modifies Rect in place because there doesn't seem to be a constructor:
/// https://api.dartlang.org/stable/2.5.2/dart-svg/Rect-class.html
transform_rect_svg_to_mouse_coord(Rect rect, Point<num> pan, num zoom) {
  transform_rect(transform_svg_to_mouse_coord, rect, pan, zoom);
}

transform_rect_mouse_coord_to_svg_main_view(Rect rect) {
  transform_rect_mouse_coord_to_svg(rect, current_pan_main(), current_zoom_main());
}

transform_rect_svg_to_mouse_coord_main_view(Rect rect) {
  transform_rect_svg_to_mouse_coord(rect, current_pan_main(), current_zoom_main());
}

Point<num> side_view_grid_to_svg(GridPosition gp, Grid grid) {
  num radius = constants.SIDE_HELIX_RADIUS;
  if (grid == Grid.square) {
    return Point<num>(2 * radius * (gp.h + 1), 2 * radius * (gp.v + 1));
  } else if (grid == Grid.hex || grid == Grid.honeycomb) {
    throw UnimplementedError('hex and honeycomb grids not yet supported');
  } else {
    throw ArgumentError('cannot convert grid coordinates for grid = Grid.none');
  }
}

/// Translates SVG coordinates in side view to Grid coordinates using the specified grid.
GridPosition side_view_svg_to_grid(Grid grid, Point<num> svg_coord) {
  num radius = constants.SIDE_HELIX_RADIUS;
  if (grid == Grid.square) {
    int h = ((svg_coord.x / (2 * radius)) - 1).round();
    int v = ((svg_coord.y / (2 * radius)) - 1).round();
    int b = 0;
    return GridPosition(h, v, b);
  } else if (grid == Grid.hex || grid == Grid.honeycomb) {
    throw UnimplementedError('hex and honeycomb grids not yet supported');
  } else {
    throw ArgumentError('cannot output grid coordinates for grid = Grid.none');
  }
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

@JS(constants.js_function_name_current_zoom_main)
external num current_zoom_main();

@JS(constants.js_function_name_current_pan_main)
external List<num> current_pan_main_js();

Point<num> current_pan_main() {
  var ret = current_pan_main_js();
  return Point<num>(ret[0], ret[1]);
}

@JS(constants.js_function_name_current_zoom_side)
external num current_zoom_side();

@JS(constants.js_function_name_current_pan_side)
external List<num> current_pan_side_js();

Point<num> current_pan_side() {
  var ret = current_pan_side_js();
  return Point<num>(ret[0], ret[1]);
}

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

pprint(Map map) {
  print('{');
  for (var key in map.keys) {
    print('$key: ${map[key]},');
  }
  print('}');
}

/// Unique IDs for parts of model to associate view components to model.

//String id_strand(Strand strand) {
//  BoundSubstrand first_ss = this
//      .bound_substrands()
//      .first;
//  return 'strand-H${first_ss.helix}-${first_ss.offset_5p}-${first_ss.forward ? 'forward' : 'reverse'}';
//}
//
//String id_5p(BoundSubstrand substrand) => '5p-end-${id_substrand(substrand)}';
//
//String id_3p(BoundSubstrand substrand) => '3p-end-${id_substrand(substrand)}';
//
//String id_substrand(BoundSubstrand substrand) =>
//    'substrand-H${substrand.helix}-O${substrand.start}-${substrand.forward ? 'forward' : 'reverse'}';
//
//String id_loopout(Loopout loopout) => 'loopout-${loopout.order()}-${id_strand(loopout.strand)}';
//
//String id_crossover(Crossover crossover) =>
//    'crossover-${id_strand(crossover.prev_substrand.strand)}-${id_strand(crossover.next_substrand.strand)}';


String id_insertion(BoundSubstrand substrand, int offset) =>
    'insertion-H${substrand.helix}-O${offset}-${substrand.forward ? 'forward' : 'reverse'}';

//String loopout_id(Loopout loopout, BoundSubstrand prev_ss, BoundSubstrand next_ss) =>
//    'loopout-H${prev_ss.helix}-O${prev_ss.offset_3p}-H${next_ss.helix}-O${next_ss.offset_5p}';;
