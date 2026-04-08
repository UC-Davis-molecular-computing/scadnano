@JS()
library util;

import 'dart:html';
import 'dart:js' as js;
import 'dart:math';
import 'dart:async';
import 'dart:svg' hide Point, ImageElement;

import 'package:xml/xml.dart';

import 'package:built_collection/built_collection.dart';
import 'package:over_react/over_react.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:scadnano/src/state/strand_creation.dart';

import 'middleware/export_svg.dart';
import 'state/address.dart';
import 'state/app_state.dart';
import 'state/app_ui_state.dart';
import 'state/group.dart';
import 'view/design.dart';

import 'app.dart';
import 'state/dialog.dart';
import 'state/geometry.dart';
import 'state/grid.dart';
import 'state/grid_position.dart';
import 'state/helix.dart';
import 'state/design.dart';
import 'state/mouseover_data.dart';
import 'constants.dart' as constants;
import 'state/select_mode.dart';
import 'state/selection_box.dart';
import 'actions/actions.dart' as actions;

// Re-export all pure utility functions so that existing `import 'util.dart' as util;` continues to work.
export 'util_state.dart';
// Also import for use within this file.
import 'util_state.dart';

/////////////////////////////////////////////////////////////////////////////
// interop between Dart and JS

make_dart_function_available_to_js(String js_function_name, Function dart_func) {
  setProperty(window, js_function_name, allowInterop(dart_func));
}

@JS()
external void set_allow_pan(bool allow);

@JS()
external void set_zoom_speed(double speed);

// END interop between Dart and JS
/////////////////////////////////////////////////////////////////////////////

/// Gets grid position of mouse cursor in side view.
GridPosition grid_position_of_mouse_in_side_view(
  Grid grid,
  bool invert_y,
  Geometry geometry, {
  Point<double>? mouse_pos = null,
  MouseEvent? event = null,
}) {
  SvgSvgElement side_view_elt = querySelector('#${SIDE_VIEW_SVG_ID}') as SvgSvgElement;
  var svg_pos = transformed_svg_point(side_view_elt, false, mouse_pos: mouse_pos, event: event);
  var grid_pos = side_view_svg_to_grid(grid, svg_pos, invert_y, geometry);
  return grid_pos;
}

/// Pops up dialog to ask user for information and returns responses.
/// Returns null if dialog was canceled.
/// For some reason we are allowed to declare the return type as Future<List<DialogItem>> (non-nullable)
/// even though the Dart language specification explicitly states that if the Completer never completes,
/// then the return value is `null`. So we add the `?` explicitly so that we get
/// a compiler error if we try to treat the return value as non-nullable.
Future<List<DialogItem>?> dialog(Dialog dialog) async {
  if (app.state.ui_state.dialog != null) {
    app.dispatch(actions.DialogHide());
  }
  // https://api.dart.dev/stable/2.7.0/dart-async/Completer-class.html
  Completer<List<DialogItem>?> completer = Completer<List<DialogItem>?>();
  dialog = dialog.rebuild(
    (b) =>
        b
          ..on_submit = (List<DialogItem>? items) {
            completer.complete(items);
          },
  );
  app.dispatch(actions.DialogShow(dialog: dialog));
  return completer.future;
}

/// Return helix where click event occurred, or the closest (e.g. if click was on a crossover).
Helix find_closest_helix(
  MouseEvent event,
  Iterable<Helix> helices,
  BuiltMap<String, HelixGroup> groups,
  Geometry geometry,
  BuiltMap<int, Point<double>> helix_idx_to_svg_position_map,
) {
  var svg_clicked_point = svg_position_of_mouse_click(event);

  double? min_dist = null;
  Helix? closest_helix = null;
  for (var helix in helices) {
    var group = groups[helix.group]!;
    var helix_upper_left_corner = group.transform_point_main_view(
      helix_idx_to_svg_position_map[helix.idx]!,
      geometry,
    );
    var dist = distance_to_rectangle(
      svg_clicked_point,
      helix_upper_left_corner,
      helix.svg_width(geometry),
      helix.svg_height(geometry),
      group.pitch,
    );
    if (min_dist == null || min_dist > dist) {
      min_dist = dist;
      closest_helix = helix;
    }
  }
  return closest_helix!;
}

/// Return closest offset in a helix group where click event occured.
int find_closest_offset(
  MouseEvent event,
  Iterable<Helix> helices_in_group,
  HelixGroup group,
  Geometry geometry,
  num helices_in_group_first_svg_position_x,
) {
  var svg_clicked_point = svg_position_of_mouse_click(event);
  var svg_clicked_point_untransformed = group.transform_point_main_view(
    svg_clicked_point,
    geometry,
    inverse: true,
  );

  var range = find_helix_group_min_max(helices_in_group)!;
  var min_offset = range.x;
  var max_offset = range.y;

  int closest_offset_unbounded = helices_in_group.first.svg_x_to_offset(
    svg_clicked_point_untransformed.x,
    helices_in_group_first_svg_position_x,
    geometry,
  );

  // max_offset in helix is non-inclusive, so highest offset value is max_offset - 1
  return min(max_offset - 1, max(closest_offset_unbounded, min_offset));
}

/// Return (closest) helix, offset and direction where click event occurred.
Address find_closest_address(
  MouseEvent event,
  Iterable<Helix> helices,
  BuiltMap<String, HelixGroup> groups,
  Geometry geometry,
  BuiltMap<int, Point<double>> helix_idx_to_svg_position_map,
) {
  var svg_clicked_point = svg_position_of_mouse_click(event);

  Helix helix = find_closest_helix(event, helices, groups, geometry, helix_idx_to_svg_position_map);
  var helix_svg_position = helix_idx_to_svg_position_map[helix.idx]!;

  var group = groups[helix.group]!;
  var helix_upper_left_corner = group.transform_point_main_view(
    helix_idx_to_svg_position_map[helix.idx]!,
    geometry,
  );
  var closest_point_in_helix = closest_point_in_rectangle(
    svg_clicked_point,
    helix_upper_left_corner,
    helix.svg_width(geometry),
    helix.svg_height(geometry),
    group.pitch,
  );

  var closest_point_in_helix_untransformed = group.transform_point_main_view(
    closest_point_in_helix,
    geometry,
    inverse: true,
  );

  int offset = helix.svg_x_to_offset(closest_point_in_helix_untransformed.x, helix_svg_position.x, geometry);
  bool forward = helix.svg_y_is_forward(
    closest_point_in_helix_untransformed.y,
    helix_svg_position.y,
    geometry,
  );

  //  print('* get_closest_address *');
  //  print('  forward = ${forward}');
  return Address(helix_idx: helix.idx, offset: offset, forward: forward);
  //  print('  closest helix: ${helix.idx}');
  //  print('  offset = ${offset}');
}

/// Return (closest) helix, offset and direction where click event occurred.
Address find_closest_address_with_infinite_helix_boundaries(
  MouseEvent event,
  Helix helix,
  BuiltMap<String, HelixGroup> groups,
  Geometry geometry,
  BuiltMap<num, Point<double>> helix_idx_to_svg_position_map,
  StrandCreation strand_creation,
) {
  var svg_clicked_point = svg_position_of_mouse_click(event);

  // Helix helix = find_closest_helix(event, helices, groups, geometry, helix_idx_to_svg_position_map);
  var helix_svg_position = helix_idx_to_svg_position_map[helix.idx]!;

  var group = groups[helix.group]!;
  // var helix_upper_left_corner =
  //     group.transform_point_main_view(helix_idx_to_svg_position_map[helix.idx], geometry);

  var closest_point_in_helix = svg_clicked_point;

  var closest_point_in_helix_untransformed = group.transform_point_main_view(
    closest_point_in_helix,
    geometry,
    inverse: true,
  );

  int offset = helix.svg_x_to_offset(closest_point_in_helix_untransformed.x, helix_svg_position.x, geometry);
  bool forward = helix.svg_y_is_forward(
    closest_point_in_helix_untransformed.y,
    helix_svg_position.y,
    geometry,
  );

  //  print('  forward = ${forward}');
  return Address(helix_idx: helix.idx, offset: offset, forward: forward);
}

//XXX: don't know why I need to correct for this here, but not when responding to a selection box mouse event
// might be related to the fact that the mouse coordinates for the selection box are detected outside of React
Point<double> svg_position_of_mouse_click(MouseEvent event) {
  Point<double> offset_in_svg_elt;
  if (browser.isFirefox) {
    offset_in_svg_elt = get_svg_point(event);
  } else {
    offset_in_svg_elt = from_point_num(event.offset);
  }
  return transform_mouse_coord_to_svg_current_panzoom(offset_in_svg_elt, true);
}

Point<double> get_svg_point(MouseEvent event) {
  if (browser.isFirefox) {
    SvgElement target = event.target as SvgElement;
    Element svg_elt = svg_ancestor(target);
    var rect = svg_elt.getBoundingClientRect().topLeft;
    var offset = event.client - rect;
    return from_point_num(offset);
  } else {
    return from_point_num(event.client);
  }
}

SvgSvgElement svg_ancestor(SvgElement elt) {
  while (!(elt is SvgSvgElement)) {
    elt = elt.parent as SvgElement;
  }
  return elt;
}

Point<double> transform_mouse_coord_to_svg_current_panzoom_correct_firefox(
  MouseEvent event,
  bool is_main_view,
  SvgSvgElement view_svg,
) {
  Point<double> point;
  if (!browser.isFirefox) {
    point = from_point_num(event.offset);
    point = transform_mouse_coord_to_svg_current_panzoom(point, is_main_view);
  } else {
    point = untransformed_svg_point(view_svg, event: event);
    point = transform_mouse_coord_to_svg_current_panzoom(point, is_main_view);
  }
  return point;
}

/// Gets untransformed coordinates of mouse_pos. If mouse_pos==null, get it from mouse event.client.
/// XXX: Firefox is the only browser to handle this correctly; cross-browser solution taken from
/// https://stackoverflow.com/questions/19713320/svg-viewbox-doesnt-return-correct-mouse-points-with-nested-svg-in-firefox
Point<double> untransformed_svg_point(
  SvgSvgElement svg_elt, {
  Point<double>? mouse_pos = null,
  MouseEvent? event = null,
}) {
  var svg_point_SVG = svg_elt.createSvgPoint();
  if (mouse_pos == null) {
    assert(event != null);
    mouse_pos = from_point_num(event!.client);
  }
  svg_point_SVG.x = mouse_pos.x;
  svg_point_SVG.y = mouse_pos.y;
  //TODO: consider using svg_elt.getCtm(): https://github.com/anvaka/panzoom/commit/49be4a1bd6361598b79f29fe99adc2c125d93678
  var svg_point_SVG_1 = svg_point_SVG.matrixTransform(svg_elt.getScreenCtm().inverse());
  Point<double> svg_point = Point<double>(svg_point_SVG_1.x! as double, svg_point_SVG_1.y! as double);
  return svg_point;
}

/// Gets untransformed coordinates of mouse event in svg_elt.
/// XXX: Firefox is the only browser to handle this correctly; cross-browser solution taken from
/// https://stackoverflow.com/questions/19713320/svg-viewbox-doesnt-return-correct-mouse-points-with-nested-svg-in-firefox
Point<double> transformed_svg_point(
  SvgSvgElement svg_elt,
  bool is_main, {
  Point<double>? mouse_pos = null,
  MouseEvent? event = null,
}) {
  var svg_pos_untransformed = untransformed_svg_point(svg_elt, mouse_pos: mouse_pos, event: event);
  var svg_pos = transform_mouse_coord_to_svg_current_panzoom(svg_pos_untransformed, is_main);
  return svg_pos;
}

Point<double> transform_mouse_coord_to_svg_current_panzoom(Point<double> point, bool is_main) {
  return transform_mouse_coord_to_svg(point, current_pan(is_main), current_zoom(is_main));
}

Point<double> transform_svg_to_mouse_coord_current_panzoom(Point<double> point, bool is_main) {
  return transform_svg_to_mouse_coord(point, current_pan(is_main), current_zoom(is_main));
}

Point<double> transform_svg_to_mouse_coord(Point<double> point, Point<double> pan, double zoom) {
  // Don't know why but Firefox auto-corrects for the current SVG coordinates whereas Chrome does not
  if (browser.isFirefox || browser.isInternetExplorer) {
    return point;
  } else {
    return point * zoom + pan;
  }
}

transform_rect(
  Point<double> transform(Point<double> p, Point<double> pan, double zoom),
  Rect rect,
  Point<double> pan,
  double zoom,
) {
  var up_left = Point<double>(rect.x! as double, rect.y! as double);
  var low_right = Point<double>(rect.x! + rect.width! as double, rect.y! + rect.height! as double);
  var up_left_tran = transform(up_left, pan, zoom);
  var low_right_tran = transform(low_right, pan, zoom);
  rect.x = up_left_tran.x;
  rect.y = up_left_tran.y;
  rect.width = low_right_tran.x - rect.x!;
  rect.height = low_right_tran.y - rect.y!;
}

///Modifies Rect in place because there doesn't seem to be a constructor:
/// https://api.dartlang.org/stable/2.5.2/dart-svg/Rect-class.html
transform_rect_mouse_coord_to_svg(Rect rect, Point<double> pan, double zoom) {
  transform_rect(transform_mouse_coord_to_svg, rect, pan, zoom);
}

///Modifies Rect in place because there doesn't seem to be a constructor:
/// https://api.dartlang.org/stable/2.5.2/dart-svg/Rect-class.html
transform_rect_svg_to_mouse_coord(Rect rect, Point<double> pan, double zoom) {
  transform_rect(transform_svg_to_mouse_coord, rect, pan, zoom);
}

transform_rect_mouse_coord_to_svg_main_view(Rect rect) {
  transform_rect_mouse_coord_to_svg(rect, current_pan(true), current_zoom(true));
}

transform_rect_svg_to_mouse_coord_main_view(Rect rect) {
  transform_rect_svg_to_mouse_coord(rect, current_pan(true), current_zoom(true));
}

@JS()
external clipboard_write(String blob_type_string, Blob content);

@JS(constants.js_function_name_cache_svg)
external ImageElement cache_svg(String svg_elt_id);

@JS(constants.js_function_name_current_zoom_main)
external double current_zoom_main_js();

@JS(constants.js_function_name_current_zoom_side)
external double current_zoom_side_js();

@JS(constants.js_function_name_current_pan_main)
external List<double> _current_pan_main_js();

@JS(constants.js_function_name_current_pan_side)
external List<double> _current_pan_side_js();

@JS(constants.js_function_name_set_zoom_side)
external set_zoom_side(num zoom);

@JS(constants.js_function_name_set_zoom_main)
external set_zoom_main(num zoom);

@JS(constants.js_function_name_set_pan_side)
external _set_pan_side_js(Pan pan);

@JS(constants.js_function_name_set_pan_main)
external _set_pan_main_js(Pan pan);

@JS(constants.js_function_name_fit_and_center)
external fit_and_center();

@JS()
@anonymous
class Pan {
  external num get x;

  external num get y;

  external factory Pan({num x, num y});
}

set_pan_side(Point<double> pos) => _set_pan_side_js(Pan(x: pos.x, y: pos.y));

set_pan_main(Point<double> pos) => _set_pan_main_js(Pan(x: pos.x, y: pos.y));

Point<double> current_pan(bool is_main) {
  var ret = is_main ? _current_pan_main_js() : _current_pan_side_js();
  return Point<double>(ret[0], ret[1]);
}

double current_zoom(bool is_main) => is_main ? current_zoom_main_js() : current_zoom_side_js();

CssStyleSheet get_scadnano_stylesheet() {
  for (var stylesheet in document.styleSheets!) {
    if (stylesheet.href != null && stylesheet.href!.contains(constants.scadnano_css_stylesheet_name)) {
      return stylesheet as CssStyleSheet;
    }
  }
  throw AssertionError(
    'cannot find stylesheet containing "${constants.scadnano_css_stylesheet_name}" '
    'in its href\nlist of stylesheet hrefs:\n'
    '${[for (var sheet in document.styleSheets!) sheet.href].join("\n")}',
  );
}

String serialize_svg(SvgSvgElement svg_element, {bool pretty = true}) {
  // Clone the SVG element to avoid modifying the original
  var cloned_svg = svg_element.clone(true) as SvgSvgElement;

  // Ensure the svg namespace is declared
  cloned_svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');

  // Find all elements that use xlink
  var xlink_elements = cloned_svg.querySelectorAll('[*|href]');
  for (var element in xlink_elements) {
    element.setAttribute('xmlns:xlink', 'http://www.w3.org/1999/xlink');
  }

  // Serialize to string
  var serialized = cloned_svg.outerHtml!;

  // Pretty print if requested
  if (pretty) {
    // from xml package; note that you have to be careful to import it because there's an
    // XmlDocument in the standard library as well, with no `parse` static method.
    var document = XmlDocument.parse(serialized);
    serialized = document.toXmlString(pretty: true, indent: '  ');
  }

  return serialized;
}

copy_svg_as_png(SvgSvgElement svg_element) async {
  try {
    String source = serialize_svg(svg_element);
    var svgUrl = Url.createObjectUrlFromBlob(new Blob([source], 'image/svg+xml'));
    var svgImage = new ImageElement(src: svgUrl);
    document.body!.append(svgImage);
    svgImage.addEventListener('load', (event) async {
      var canvas = new CanvasElement();
      canvas.width = svg_element.viewBox!.baseVal!.width! * 2 as int;
      canvas.height = svg_element.viewBox!.baseVal!.height! * 2 as int;
      var canvasCtx = canvas.context2D;
      canvasCtx.drawImage(svgImage, 0, 0);
      var imgData = await canvas.toBlob('image/png');
      clipboard_write('image/png', imgData);
      svgImage.remove();

      Url.revokeObjectUrl(svgUrl);
    });
    svgImage.src = svgUrl;

    // window.navigator.clipboard.write(DataTransfer()..setData(blob_type_string, content));
  } on Exception catch (e, stackTrace) {
    print(stackTrace);
  } on Error catch (e, stackTrace) {
    print(stackTrace);
  }
}

/// [and_then] is a callback to do if the file save dialog is not canceled and no other error occurs.
/// Currently, it doesn't do much good, because it is called whether the user cancels or not. But if someday
/// we get around the issues described here:
///   https://github.com/UC-Davis-molecular-computing/scadnano/issues/282
///   https://github.com/UC-Davis-molecular-computing/scadnano/issues/292
/// then it will be nice to have it happen only if the save is successful.
save_file(
  String default_filename,
  var content, {
  BlobType blob_type = BlobType.text,
  void Function()? and_then = null,
}) async {
  try {
    String blob_type_string = blob_type_to_string(blob_type);
    Blob blob = new Blob([content], blob_type_string);
    String url = Url.createObjectUrlFromBlob(blob);
    var link =
        new AnchorElement()
          ..href = url
          ..download = default_filename;

    if (browser.isFirefox) {
      document.body!.children.add(link);
    }
    //It's tough to detect if the user cancels, or what filename they chose. See
    // https://github.com/UC-Davis-molecular-computing/scadnano/issues/282
    // https://github.com/UC-Davis-molecular-computing/scadnano/issues/292
    link.click();

    if (browser.isFirefox) {
      link.remove();
    }

    Url.revokeObjectUrl(url);
    if (and_then != null) {
      and_then();
    }
  } on Exception catch (e, stackTrace) {
    _alert_error_saving(e, stackTrace);
  } on Error catch (e, stackTrace) {
    _alert_error_saving(e, stackTrace);
  }

  //TODO: create separate textfield for user to enter desired save filename that we use above
  // we cannot pull it from the download dialog due to security:
  //  https://github.com/eligrey/FileSaver.js/issues/75
  //  https://github.com/WICG/native-file-system
}

_alert_error_saving(e, stack_trace) {
  var msg =
      'error while saving file: ${e}'
      '${stack_trace_message_bug_report(stack_trace)}';
  window.alert(msg);
}

/// This goes into "window", so in JS you can access window.editor_content, and in Brython you can do this:
/// from browser import window
/// print(window['editor_content'])
save_editor_content_to_js_context(String new_content) {
  js.context[constants.editor_content_js_key] = new_content;
}

/// Return offset and direction on helix where click event occurred.
Address get_address_on_helix(
  MouseEvent event,
  Helix helix,
  HelixGroup group,
  Geometry geometry,
  Point<double> helix_svg_position,
) {
  var closest_address = find_closest_address(
    event,
    [helix],
    {helix.group: group}.build(),
    geometry,
    {helix.idx: helix_svg_position}.build(),
  );
  return closest_address;
}

/// Returns the default state of the app.
AppState default_state({Grid grid = Grid.none}) {
  var design = Design(grid: grid);
  var ui_state = AppUIState.from_design(design);
  var state =
      (DEFAULT_AppState.toBuilder()
            ..maybe_design = design.toBuilder()
            ..ui_state.replace(ui_state))
          .build();
  return state;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// svg caching

String dna_sequence_classname = "dna-sequences-main-view";
String dna_sequence_png_id = 'dna-sequences-main-view-png';
String strands_classname = "strands-main-view";

/// Callback to sent to JavaScript function `setup_svg_panzoom` so that
/// the JavaScript code in index.html can dispatch `SetIzZoomAboveThreshold` actions.
void dispatch_set_zoom_threshold(bool new_zoom_threshold) {
  app.dispatch(actions.SetIsZoomAboveThreshold(new_zoom_threshold));
}

/// Callback to sent to JavaScript function `setup_svg_panzoom` so that
/// the JavaScript code can dispatch `LoadDnaSequenceImageUri` actions.
void svg_to_png_data() {
  // Queries for essential dom elements.
  List<Node> dna_sequence_element_list = document.getElementsByClassName(dna_sequence_classname);
  List<Node> strands_element_list = document.getElementsByClassName(strands_classname);

  // Returns if png is already being used
  if (document.getElementById(dna_sequence_png_id) != null ||
      // or if there is no dna_sequence due to Show DNA off
      dna_sequence_element_list.isEmpty ||
      // or if there is no strands
      strands_element_list.isEmpty ||
      // or if there is no dna sequence due to design
      (dna_sequence_element_list.first as GraphicsElement).children.isEmpty ||
      // or if cache already exists
      app.state.ui_state.dna_sequence_png_uri != null) {
    return;
  }

  // Assigns neccessary DOM elements (guaranteed by conditionals above).
  GraphicsElement dna_sequence_element = dna_sequence_element_list.first as GraphicsElement;
  GraphicsElement strands_element = strands_element_list.first as GraphicsElement;

  // Wraps dna_sequence_element in a SVG Element because required for Blob
  SvgSvgElement svg = SvgSvgElement();
  GraphicsElement dna_sequence_element_copy = clone_and_apply_style(dna_sequence_element) as GraphicsElement;

  GraphicsElement strands_element_copy = clone_and_apply_style(strands_element) as GraphicsElement;
  strands_element_copy.setAttribute('display', 'none');

  // Translates dna_sequence_element_copy down so that it's Blob uri captures the topmost dna sequence
  // inside of it's view box.
  Rect bbox = dna_sequence_element.getBBox();
  double dna_sequence_png_horizontal_offset = constants.DNA_SEQUENCE_HORIZONTAL_OFFSET - bbox.x!;
  double dna_sequence_png_vertical_offset = constants.DNA_SEQUENCE_VERTICAL_OFFSET - bbox.y!;
  dna_sequence_element_copy.setAttribute(
    'transform',
    'translate(${dna_sequence_png_horizontal_offset}, ${dna_sequence_png_vertical_offset})',
  );

  // Append copy to svg wrapper element.
  svg.children.add(strands_element_copy);
  svg.children.add(dna_sequence_element_copy);

  // Firefox requires explicit size on svg to draw on canvas.
  // https://stackoverflow.com/questions/34706891/canvas-draw-image-issue-on-firefox-works-well-in-chrome
  var svg_width = (bbox.width! + constants.DNA_SEQUENCE_HORIZONTAL_OFFSET).toInt();
  var svg_height = (bbox.height! + constants.DNA_SEQUENCE_VERTICAL_OFFSET).toInt();
  svg.setAttribute('width', svg_width.toString());
  svg.setAttribute('height', svg_height.toString());

  // Serializes svg into a string containing XML.
  String data = serialize_svg(svg);

  // Constructs a Blob that contains `data` as MIME type of svg.
  Blob svg_blob = Blob([data], blob_type_to_string(BlobType.image));

  // Creates a DOMString containing the URL representing the svg.
  String url = Url.createObjectUrl(svg_blob);

  // Debug: print content of svg blob
  // HttpRequest.getString(url).then((String fileContents) {
  //   print(fileContents);
  // }).catchError((error) {
  //   print(error.toString());
  // });

  // IF (DEBUGGING)
  // Uncomment out canvas-dev element in view.dart to use
  // CanvasElement canvas = document.getElementById('canvas-dev');
  // ELSE
  CanvasElement canvas = document.createElement('canvas') as CanvasElement;

  canvas.width = svg_width;
  canvas.height = svg_height;
  canvas.setAttribute('style', 'width: ${canvas.width}px; height: ${canvas.height}px;');

  CanvasRenderingContext2D ctx = canvas.context2D;
  ctx.clearRect(0, 0, bbox.width!, bbox.height!);

  // IF (DEBUGGING)
  // ImageElement img = document.getElementById('img-dev');
  // img.src = url;
  // ELSE
  ImageElement img = new ImageElement(src: url);

  img.onLoad.listen((_) {
    ctx.drawImage(img, 0, 0);
    Url.revokeObjectUrl(url);
    String img_uri = canvas.toDataUrl('image/png');
    app.dispatch(
      actions.LoadDnaSequenceImageUri(
        img_uri,
        -dna_sequence_png_horizontal_offset,
        -dna_sequence_png_vertical_offset,
      ),
    );
  });
}

/// Returns `true` if png is used/should be used `false` otherwise.
///
/// PNG will be used if there is a png uri `dna_sequence_png_uri`,
/// and the zoom is not above threshold `is_zoom_above_threshold`,
/// and there is no pending action `disable_png_cache_until_action_completes`.
bool use_png(
  String? dna_sequence_png_uri,
  bool is_zoom_above_threshold,
  actions.ExportSvg? export_svg_action_delayed_for_png_cache,
  bool disable_png_caching_dna_sequences,
) {
  return dna_sequence_png_uri != null &&
      !is_zoom_above_threshold &&
      export_svg_action_delayed_for_png_cache == null &&
      !disable_png_caching_dna_sequences;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// asynchronous alert dialog

async_alert(String msg) async {
  await null;
  Timer(Duration(microseconds: 1), () => window.alert(msg));
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mouseover Data

bool show_mouseover_data() {
  return app.state.ui_state.show_mouseover_data;
}

mouse_leave_update_mouseover() {
  if (show_mouseover_data()) {
    app.dispatch(actions.MouseoverDataClear());
  }
}

update_mouseover(SyntheticMouseEvent event_syn, Helix helix, Point<double> helix_svg_position) {
  if (show_mouseover_data()) {
    MouseEvent event = event_syn.nativeEvent;
    var group = app.state.design.groups[helix.group]!;
    var geometry = group.geometry ?? app.state.design.geometry;
    var address = get_address_on_helix(event, helix, group, geometry, helix_svg_position);
    int offset = address.offset;
    bool forward = address.forward;

    if (DEBUG_PRINT_MOUSEOVER) {
      Point<double> pan = current_pan(true);
      num zoom = current_zoom(true);
      print(
        'mouse event: '
        'x = ${event.offset.x},   '
        'y = ${event.offset.y},   '
        'pan = (${pan.x.toStringAsFixed(2)}, ${pan.y.toStringAsFixed(2)}),   '
        'zoom = ${zoom.toStringAsFixed(2)},   '
        //        'svg_x = ${svg_x.toStringAsFixed(2)},   '
        //        'svg_y = ${svg_y.toStringAsFixed(2)},   '
        'helix = ${helix.idx},   '
        'offset = ${offset},   '
        'forward = ${forward}',
      );
    }

    var mouseover_params = MouseoverParams(helix.idx, offset, forward);

    BuiltList<MouseoverData> mouseover_datas = app.state.ui_state.mouseover_datas;

    if (needs_update(mouseover_params, mouseover_datas)) {
      //    print('dispatching MouseoverDataUpdate from DesignMainMouseoverRectHelix for helix ${helix.idx}');
      app.dispatch(
        actions.MouseoverDataUpdate(mouseover_params: BuiltList<MouseoverParams>([mouseover_params])),
      );
    } else {
      //    print('skipping MouseoverDataUpdate from DesignMainMouseoverRectHelix for helix ${helix.idx}');
    }
  }
}
