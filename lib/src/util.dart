@JS()
library util;

import 'dart:convert';
import 'dart:html' hide ImageElement;
import 'dart:js' as js;
import 'dart:math';
import 'dart:svg' hide Point;

import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:scadnano/src/model/ui_model.dart';

import 'model/crossover.dart';
import 'model/dna_end.dart';
import 'model/grid.dart';
import 'model/grid_position.dart';
import 'model/loopout.dart';
import 'model/model.dart';
import 'model/dna_design.dart';
import 'constants.dart' as constants;
import 'model/bound_substrand.dart';
import 'model/selectable.dart';
import 'model/strand.dart';

make_dart_function_available_to_js(String js_function_name, Function dart_func) {
  setProperty(window, js_function_name, allowInterop(dart_func));
}

/// Should only be called once at the start of the program
Future<DNADesign> dna_design_from_url(String url) async {
  String content = await file_content(url);
  Map<String, dynamic> parsed_json = jsonDecode(content);
  DNADesign dna_design = DNADesign.from_json(parsed_json);
  return dna_design;
}

Future<String> file_content(String url) async {
  return await HttpRequest.getString(url).then((content) {
    return content;
  });
}

/// Gets untransformed coordinates of mouse event in svg_elt.
/// XXX: Firefox is the only browser to handle this correctly; cross-browser solution taken from
/// https://stackoverflow.com/questions/19713320/svg-viewbox-doesnt-return-correct-mouse-points-with-nested-svg-in-firefox
Point<num> untransformed_svg_point(SvgSvgElement svg_elt, MouseEvent ev) {
  var svg_point_SVG = svg_elt.createSvgPoint();
  svg_point_SVG.x = ev.client.x;
  svg_point_SVG.y = ev.client.y;
  svg_point_SVG = svg_point_SVG.matrixTransform(svg_elt.getScreenCtm().inverse());
  Point<num> svg_point = Point<num>(svg_point_SVG.x, svg_point_SVG.y);
  return svg_point;
}

Point<num> transform_mouse_coord_to_svg_current_panzoom_side(Point<num> point) {
  return transform_mouse_coord_to_svg(point, current_pan_side(), current_zoom_side());
}

Point<num> transform_mouse_coord_to_svg_current_panzoom_main(Point<num> point) {
  return transform_mouse_coord_to_svg(point, current_pan_main(), current_zoom_main());
}

//TODO: this is still scaled wrong with Firefox; may not even be coming from this code, because it's
// different depending whether the mouse is over the empty helix, or a strand, or a crossover/loopout

/// Transform point by panning and zooming from mouse coordinates to SVG coordinates.
/// (Actually I needed to do what appears to be the inverse transformation here, not sure why.)
Point<num> transform_mouse_coord_to_svg(Point<num> point, Point<num> pan, num zoom) {
  return (point - pan) * (1.0 / zoom);
}

Point<num> transform_svg_to_mouse_coord(Point<num> point, Point<num> pan, num zoom) {
  // Don't know why but Firefox auto-corrects for the current SVG coordinates whereas Chrome does not
  if (browser.isFirefox || browser.isInternetExplorer) {
    return point;
  } else {
    return point * zoom + pan;
  }
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
    return Point<num>(gp.h, gp.v) * 2 * radius;
  } else if (grid == Grid.hex || grid == Grid.honeycomb) {
    num x = gp.h; // x offset from h
    x += cos(2 * pi / 6) * (gp.v % 2); // x offset from v
    num y = sin(2 * pi / 6) * gp.v; // y offset from v
    return Point<num>(x, y) * 2 * radius;
  } else {
    throw ArgumentError('cannot convert grid coordinates for grid unless it is one of square, hex, or honeycomb');
  }
}

/// Translates SVG coordinates in side view to Grid coordinates using the specified grid.
GridPosition side_view_svg_to_grid(Grid grid, Point<num> svg_coord) {
  num radius = constants.SIDE_HELIX_RADIUS;
  if (grid == Grid.square) {
    int h = ((svg_coord.x / (2 * radius)) - 1).round();
    int v = ((svg_coord.y / (2 * radius)) - 1).round();
    int b = 0;
    return GridPosition((gp) => gp
      ..h = h
      ..v = v
      ..b = b);
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

/// Tries to get value in map associated to [key], returning [default_value] if [key] is not present.
/// If transformer is given and the key is found in the map, apply transformer to the associated value and return it.
T get_value_with_default<T, U>(Map<String, dynamic> map, String key, T default_value,
    {T Function(U) transformer = null}) {
  if (!map.containsKey(key)) {
    return default_value;
  } else {
    return transformer == null ? map[key] : transformer(map[key]);
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

String id_insertion(BoundSubstrand substrand, int offset) =>
    'insertion-H${substrand.helix}-O${offset}-${substrand.forward ? 'forward' : 'reverse'}';

Map<Type, List> split_list_selectable_by_type(List<Selectable> selected) {
  Map<Type, List> selected_all = {Crossover: [], Loopout: [], DNAEnd: [], Strand: []};
  for (var selectable in selected) {
    selected_all[selectable.runtimeType].add(selectable);
  }
  return selected_all;
}
