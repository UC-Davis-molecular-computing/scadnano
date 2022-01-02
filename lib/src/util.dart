@JS()
library util;

import 'dart:html';
import 'dart:js' as js;
import 'dart:math';
import 'dart:async';
import 'dart:svg' hide Point, ImageElement;
import 'dart:typed_data';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:scadnano/src/reducers/helices_reducer.dart';

import 'state/design_side_rotation_data.dart';
import 'state/modification.dart';
import 'state/address.dart';
import 'middleware/export_svg.dart';
import 'state/app_state.dart';
import 'state/app_ui_state.dart';
import 'state/domains_move.dart';
import 'state/group.dart';
import 'state/strands_move.dart';
import 'view/design.dart';
import 'package:tuple/tuple.dart';
import 'package:quiver/iterables.dart' as quiver;

import 'app.dart';
import 'json_serializable.dart';
import 'state/crossover.dart';
import 'state/dialog.dart';
import 'state/dna_end.dart';
import 'state/geometry.dart';
import 'state/grid.dart';
import 'state/grid_position.dart';
import 'state/helix.dart';
import 'state/loopout.dart';
import 'state/design.dart';
import 'state/mouseover_data.dart';
import 'constants.dart' as constants;
import 'state/domain.dart';
import 'state/position3d.dart';
import 'state/select_mode.dart';
import 'state/selectable.dart';
import 'state/selection_box.dart';
import 'state/strand.dart';
import 'actions/actions.dart' as actions;

const ASSERTION_ERROR_MESSAGE = 'You have discovered a bug. Please send this entire error message to\n'
    '  ${constants.BUG_REPORT_URL}';

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

final ColorCycler color_cycler = ColorCycler();

class ColorCycler {
  static List<Color> colors = [
    Color.rgb(204, 0, 0),
    Color.rgb(50, 184, 108),
    Color.rgb(247, 67, 8),
    Color.rgb(87, 187, 0),
    Color.rgb(0, 114, 0),
    Color.rgb(170, 170, 0),
    Color.rgb(3, 182, 162),
    Color.rgb(247, 147, 30),
    // Color.rgb(23, 0, 222), // don't like this because it looks too much like scaffold
    Color.rgb(50, 0, 150), // this one is better contrast with scaffold
    Color.rgb(184, 5, 108),
    Color.rgb(51, 51, 51),
    Color.rgb(115, 0, 222),
    Color.rgb(136, 136, 136),
  ];

  int idx = 0;

  ColorCycler();

  Color next() {
    Color next_color = colors[idx];
    idx = (idx + 1) % colors.length;
    return next_color;
  }

  static final Color scaffold_color = constants.default_scaffold_color;
}

final scaffold_color = ColorCycler.scaffold_color;

// converts from decimal integer representation of Color to hex string representation of color
// e.g., 0066cc hex is 26316 decimal
String color_decimal_int_to_hex(int d) {
  String hex = d.toRadixString(16);
  String hex_padded = hex.padLeft(6, '0');
  return "#${hex_padded}";
}

// converts from hex string representation of Color to decimal integer representation of color
// e.g., 0066cc hex is 26316 decimal
int color_hex_to_decimal_int(String hex) {
  if (hex[0] == '#') {
    hex = hex.substring(1);
  }
  int d = int.parse(hex, radix: 16);
  return d;
}

HelixGroup current_group_from_strands_move(Design design, StrandsMove strands_move) {
  var group_name = current_group_name_from_strands_move(design, strands_move);
  return design.groups[group_name];
}

String current_group_name_from_strands_move(Design design, StrandsMove strands_move) {
  var helix_idx = strands_move.current_address.helix_idx;
  var helix = design.helices[helix_idx];
  return helix?.group;
}

HelixGroup original_group_from_domains_move(Design design, DomainsMove domains_move) {
  var group_name = original_group_name_from_domains_move(design, domains_move);
  return design.groups[group_name];
}

String original_group_name_from_domains_move(Design design, DomainsMove domains_move) {
  var helix_idx = domains_move.original_address.helix_idx;
  var helix = design.helices[helix_idx];
  return helix.group;
}

HelixGroup current_group_from_domains_move(Design design, DomainsMove domains_move) {
  var group_name = current_group_name_from_domains_move(design, domains_move);
  return design.groups[group_name];
}

String current_group_name_from_domains_move(Design design, DomainsMove domains_move) {
  var helix_idx = domains_move.current_address.helix_idx;
  var helix = design.helices[helix_idx];
  return helix.group;
}

int binary_search<T>(List<T> list, T value, int compare(T v1, T v2)) =>
    binary_search_rec(list, value, compare, 0, list.length - 1);

int binary_search_rec<T>(List<T> list, T value, int compare(T v1, T v2), int min, int max) {
  if (min > max) {
    return null;
  }

  final int mid = (max + min) ~/ 2;

  if (compare(value, list[mid]) < 0) {
    return binary_search_rec(list, value, compare, min, mid - 1);
  } else if (compare(value, list[mid]) > 0) {
    return binary_search_rec(list, value, compare, mid + 1, max);
  } else {
    return mid;
  }
}

const EPSILON = 0.000000001;

/// Tests if [x1] and [x2] are within [epsilon] of each other.
bool are_close(double x1, double x2, [double epsilon = EPSILON]) => (x1 - x2).abs() < epsilon;

/// Tests if [x1] and [x2] are within [epsilon] of each other.
bool are_all_close(Iterable<double> x1s, Iterable<double> x2s, [double epsilon = EPSILON]) => [
      for (var pair in quiver.zip([x1s, x2s])) pair
    ].every((pair) => are_close(pair[0], pair[1], epsilon));

/// If [val] is close to an int, return that int, otherwise return the value.
num to_int_if_close(double val, [double epsilon = EPSILON]) =>
    are_close(val, val.roundToDouble()) ? val.round() : val;

bool is_increasing<T extends Comparable>(Iterable<T> items) {
  T prev = null;
  for (T val in items) {
    if (prev != null) {
      if (prev.compareTo(val) >= 0) {
        return false;
      }
    }
    prev = val;
  }
  return true;
}

/// Given list of ints, return list of distances between them, with first equal to first, e.g.
///   deltas([2,3,5,7,11]) == [2, 1, 2, 2, 4]
List<int> deltas(Iterable<int> nums) {
  if (nums.isEmpty) {
    return [];
  }

  List<int> deltas = [];
  int prev = 0;
  for (int num in nums) {
    int delta = num - prev;
    deltas.add(delta);
    prev = num;
  }
  return deltas;
}

Future<String> get_text_file_content(String url) async =>
    await HttpRequest.getString(url).then((content) => content);

///// Go to url specifying a directory, and if directory listing is enabled, parse the names of the
///// files ending in .sc. TODO: implement this, doesn't work now with local server
//Future<List<String>> get_sc_files_in_directory(String url) async {
//  String page = await HttpRequest.getString(url).then((content) => content);
//  print('page=\n$page');
//  var regex = RegExp(r'href="(.*\.${constants.all_scadnano_file_extensions})"');
//  var matches = regex.allMatches(page);
//  for (var match in matches) {
//    print('match: $match');
//  }
//  return [];
//}

Future<ByteBuffer> get_binary_file_content(String url) async {
  return await HttpRequest.request(url, responseType: 'arraybuffer').then((request) {
    return request.response;
  });
}

/// Pops up dialog to ask user for information and returns responses.
/// Returns null if dialog was canceled.
Future<List<DialogItem>> dialog(Dialog dialog) async {
  if (app.state.ui_state.dialog != null) {
    app.dispatch(actions.DialogHide());
  }
  // https://api.dart.dev/stable/2.7.0/dart-async/Completer-class.html
  Completer<List<DialogItem>> completer = Completer<List<DialogItem>>();
  dialog = dialog.rebuild((b) => b
    ..on_submit = (List<DialogItem> items) {
      completer.complete(items);
    });
  app.dispatch(actions.DialogShow(dialog: dialog));
  return completer.future;
}

/// Gets grid position of mouse cursor in side view.
GridPosition grid_position_of_mouse_in_side_view(Grid grid, bool invert_y, Geometry geometry,
    {Point<num> mouse_pos = null, MouseEvent event = null}) {
  SvgSvgElement side_view_elt = querySelector('#${SIDE_VIEW_SVG_ID}') as SvgSvgElement;
  var svg_pos = transformed_svg_point(side_view_elt, false, mouse_pos: mouse_pos, event: event);
  var grid_pos = side_view_svg_to_grid(grid, svg_pos, invert_y, geometry);
  return grid_pos;
}

bool version_precedes(String v1_str, String v2_str) {
  var version1 = get_version(v1_str);
  var version2 = get_version(v2_str);
  return version1 < version2;
}

class Version {
  int major;
  int minor;
  int patch;

  Version(this.major, this.minor, this.patch);

  bool operator <(Version other) =>
      (major < other.major) ||
      (major == other.major && minor < other.minor) ||
      (major == other.major && minor == other.minor && patch < other.patch);
}

/// Pulls major/minor/patch integers from version_str, e.g., "2.13.432" becomes the Tuple (2, 13, 432)
Version get_version(String version_str) {
  var regex = RegExp(r"(\d+)\.(\d+)\.(\d+)");
  var match = regex.firstMatch(version_str);
  var match_g1 = match.group(1);
  var match_g2 = match.group(2);
  var match_g3 = match.group(3);
  int major = int.parse(match_g1);
  int minor = int.parse(match_g2);
  int patch = int.parse(match_g3);
  return Version(major, minor, patch);
}

/// Indicates whether two lists contain the same elements (not necessarily in the same order).
bool lists_contain_same_elts<T extends Comparable>(Iterable<T> elts1, Iterable<T> elts2) {
  List<T> list1 = List<T>.from(elts1);
  List<T> list2 = List<T>.from(elts2);
  list1.sort();
  list2.sort();
  var eq = ListEquality().equals;
  return eq(list1, list2);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// assign SVG coordinates to helices

/// Returns SVG position for helices
Map<int, Point<num>> helices_assign_svg(
    Geometry geometry, bool invert_y, BuiltMap<int, Helix> helices, BuiltMap<String, HelixGroup> groups,
    {BuiltSet<int> selected_helix_idxs = null}) {
  if (selected_helix_idxs == null || selected_helix_idxs.isEmpty) {
    selected_helix_idxs = [for (var helix in helices.values) helix.idx].toBuiltSet();
  }

  Map<int, Point<num>> svg_positions = {};

  Set<String> group_names = {for (var helix in helices.values) helix.group};
  Map<String, Map<int, Helix>> selected_helices_by_group = {for (var name in group_names) name: {}};
  for (int idx in selected_helix_idxs) {
    var helix = helices[idx];
    selected_helices_by_group[helix.group][idx] = helix;
  }

  // process by groups because view order only makes sense within a group, and we need
  // to go in view order
  for (var group_name in selected_helices_by_group.keys) {
    HelixGroup group = groups[group_name];
    var selected_helices_sorted_by_view_order =
        List<Helix>.from(selected_helices_by_group[group_name].values);
    selected_helices_sorted_by_view_order.sort(
        (h1, h2) => group.helices_view_order_inverse[h1.idx] - group.helices_view_order_inverse[h2.idx]);

    num prev_y = null;

    Helix prev_helix = null;
    for (var helix in selected_helices_sorted_by_view_order) {
      // Assertion: Helices should already be updated by reducers
      assert(helix.geometry == geometry);
      assert(helix.invert_y == invert_y);
      num x = main_view_svg_x_of_helix(geometry, helix);
      num y = main_view_svg_y_of_helix(geometry, helix);
      if (prev_helix != null) {
        num delta_y;
        if (helix.grid.is_none) {
          var prev_pos = prev_helix.position_;
          var pos = helix.position_;
          delta_y = pos.distance_xy(prev_pos) * geometry.nm_to_svg_pixels;
        } else {
          var prev_grid_position = prev_helix.grid_position;
          var grid_position = helix.grid_position;
          delta_y = prev_grid_position.distance_lattice(grid_position, helix.grid) *
              geometry.distance_between_helices_svg;
        }
        y = prev_y + delta_y;
      }
      prev_y = y;
      prev_helix = helix;

      svg_positions[helix.idx] = Point<num>(x, invert_y ? -y : y);
    }
  }

  return svg_positions;
}

num main_view_svg_x_of_helix(Geometry geometry, Helix helix) {
  num x = helix.position3d.z * geometry.nm_to_svg_pixels;
  return x;
}

num main_view_svg_y_of_helix(Geometry geometry, Helix helix) {
  num y = helix.position3d.y * geometry.nm_to_svg_pixels;
  return y;
}

num norm_l2(num x, num y) => sqrt(pow(x, 2) + pow(y, 2));

Map<int, Helix> helices_list_to_map(List<Helix> helices) => {for (var helix in helices) helix.idx: helix};

/// If obj is a NoIndent, unwrap the object from it, otherwise return obj.
dynamic unwrap_from_noindent(dynamic obj) => obj is NoIndent ? obj.value : obj;

/// Finds two indices of elements in list that repeat, returning null if all elements are distinct.
Tuple2<int, int> repeated_element_indices<T>(List<T> list) {
  Map<T, int> elt_to_idx = {};
  // should take time n log n; we don't do linear search for indices until we know which element repeats
  for (int i2 = 0; i2 < list.length; i2++) {
    T elt = list[i2];
    int i1 = elt_to_idx[elt];
    if (i1 != null) {
      return Tuple2<int, int>(i1, i2);
    }
    elt_to_idx[elt] = i2;
  }
  return null;
}

/// Indicates if left button is pressed during [event],
/// even if the left button was not the one pressed, e.g., if it is pressed while moving or pressing
/// the right button.
/// NOTE: Returns false if left mouse button goes up. For that use left_mouse_button_caused_mouse_event.
bool left_mouse_button_pressed_during_mouse_event(MouseEvent event) => event.buttons & 1 == 1;

/// Indicates if left mouse button going down or up caused [event].
bool left_mouse_button_caused_mouse_event(MouseEvent event) => event.button == 0;

//////////////////////////////////////////////////////////////////////////////////////////////////////////
// transforming of points

/// find distance from a point to a rectangle (0 if point is inside rectangle).
/// Rectangle is defined by an upper-left corner, width and height, and rotation angle.
/// We first unrotate the point about the upper-left corner,
/// then calculate using the simpler method for axis-aligned rectangles.
num distance_to_rectangle(Point<num> point, Point<num> upper_left_corner, num width, num height, num angle) {
  var distances = xy_distances_to_rectangle(point, upper_left_corner, width, height, angle);
  return sqrt(distances.x * distances.x + distances.y * distances.y);
}

/// Returns (dx,dy) representing distances from point to rectangle. Can be negative to indicate if
/// point is above or below rectangle, or left or right of it.
/// This is assuming the rectangle is "unrotated" by -angle.
Point<num> xy_distances_to_rectangle(
    Point<num> point, Point<num> upper_left_corner, num width, num height, num angle) {
  Point<num> unrotated_point = rotate(point, -angle, origin: upper_left_corner);
  num x_low = upper_left_corner.x;
  num x_hi = upper_left_corner.x + width;
  num y_low = upper_left_corner.y;
  num y_hi = upper_left_corner.y + height;
  num dx, dy;
  if (x_low <= unrotated_point.x && unrotated_point.x <= x_hi) {
    dx = 0;
  } else {
    if (unrotated_point.x <= x_low) {
      dx = unrotated_point.x - x_low;
    } else {
      dx = unrotated_point.x - x_hi;
    }
  }
  if (y_low <= unrotated_point.y && unrotated_point.y <= y_hi) {
    dy = 0;
  } else {
    if (unrotated_point.y <= y_low) {
      dy = unrotated_point.y - y_low;
    } else {
      dy = unrotated_point.y - y_hi;
    }
  }
  return Point<num>(dx, dy);
}

/// Finds closest point in rectangle to [point]. If [point] is inside rectangle, returns [point];
Point<num> closest_point_in_rectangle(
    Point<num> point, Point<num> upper_left_corner, num width, num height, num angle) {
  var distances = xy_distances_to_rectangle(point, upper_left_corner, width, height, angle);
  Point<num> unrotated_point = rotate(point, -angle, origin: upper_left_corner);
  num x = unrotated_point.x + distances.x;
  num y = unrotated_point.y + distances.y;
  var unrotated_point_in_rectangle = Point<num>(x, y);
  var rotated_point_in_rectangle = rotate(unrotated_point_in_rectangle, angle, origin: upper_left_corner);
  return rotated_point_in_rectangle;
}

/// Return helix where click event occurred, or the closest (e.g. if click was on a crossover).
Helix find_closest_helix(MouseEvent event, Iterable<Helix> helices, BuiltMap<String, HelixGroup> groups,
    Geometry geometry, BuiltMap<int, Point<num>> helix_idx_to_svg_position_map) {
  var svg_clicked_point = svg_position_of_mouse_click(event);

  num min_dist = null;
  Helix closest_helix = null;
  for (var helix in helices) {
    var group = groups[helix.group];
    var helix_upper_left_corner =
        group.transform_point_main_view(helix_idx_to_svg_position_map[helix.idx], geometry);
    var dist = distance_to_rectangle(
        svg_clicked_point, helix_upper_left_corner, helix.svg_width, helix.svg_height, group.pitch);
    if (min_dist == null || min_dist > dist) {
      min_dist = dist;
      closest_helix = helix;
    }
  }
  return closest_helix;
}

/// Returns `offset` if offset is within bounds of helices in `helices_in_group`.
/// If `offset` is too high, returns the upper bound offset.
/// If `offset` is too low, returns the lower bound offset.
/// If `offset` is null, returns the lower bound offset.
/// If no helices in `helices_in_group` returns null.
int bounded_offset_in_helices_group(int offset, Iterable<Helix> helices_in_group) {
  var range = find_helix_group_min_max(helices_in_group);
  if (range == null) {
    return null;
  }

  var min_offset = range.x;
  var max_offset = range.y;

  if (offset != null) {
    return min(max_offset - 1, max(offset, min_offset));
  } else {
    return min_offset;
  }
}

/// Find min_offset and max_offset range of list of of helices.
/// If list is empty, return null
Point<int> find_helix_group_min_max(Iterable<Helix> helices_in_group) {
  if (helices_in_group.isEmpty) {
    return null;
  }
  int min_offset = helices_in_group.first.min_offset;
  int max_offset = helices_in_group.first.max_offset;
  for (var helix in helices_in_group) {
    min_offset = min(helix.min_offset, min_offset);
    max_offset = max(helix.max_offset, max_offset);
  }
  return Point(min_offset, max_offset);
}

/// Return closest offset in a helix group where click event occured.
int find_closest_offset(MouseEvent event, Iterable<Helix> helices_in_group, HelixGroup group,
    Geometry geometry, num helices_in_group_first_svg_position_x) {
  var svg_clicked_point = svg_position_of_mouse_click(event);
  var svg_clicked_point_untransformed =
      group.transform_point_main_view(svg_clicked_point, geometry, inverse: true);

  var range = find_helix_group_min_max(helices_in_group);
  var min_offset = range.x;
  var max_offset = range.y;

  int closest_offset_unbounded = helices_in_group.first
      .svg_x_to_offset(svg_clicked_point_untransformed.x, helices_in_group_first_svg_position_x);

  // max_offset in helix is non-inclusive, so highest offset value is max_offset - 1
  return min(max_offset - 1, max(closest_offset_unbounded, min_offset));
}

/// Return list of mouseover data about helix group `group_name` at `offset`.
BuiltList<DesignSideRotationData> rotation_datas_at_offset_in_group(
    int offset, Design design, String group_name) {
  List<DesignSideRotationParams> rotation_params_list = [];
  if (offset != null) {
    for (var helix_idx in design.helix_idxs_in_group[group_name]) {
      var helix = design.helices[helix_idx];
      if (offset >= helix.min_offset && offset < helix.max_offset) {
        var rotation_params = DesignSideRotationParams(helix_idx, offset);
        rotation_params_list.add(rotation_params);
      }
    }
  }
  return DesignSideRotationData.from_params(design, rotation_params_list).toBuiltList();
}

/// Return (closest) helix, offset and direction where click event occurred.
Address find_closest_address(MouseEvent event, Iterable<Helix> helices, BuiltMap<String, HelixGroup> groups,
    Geometry geometry, BuiltMap<num, Point<num>> helix_idx_to_svg_position_map) {
  var svg_clicked_point = svg_position_of_mouse_click(event);

  Helix helix = find_closest_helix(event, helices, groups, geometry, helix_idx_to_svg_position_map);
  var helix_svg_position = helix_idx_to_svg_position_map[helix.idx];

  var group = groups[helix.group];
  var helix_upper_left_corner =
      group.transform_point_main_view(helix_idx_to_svg_position_map[helix.idx], geometry);
  var closest_point_in_helix = closest_point_in_rectangle(
      svg_clicked_point, helix_upper_left_corner, helix.svg_width, helix.svg_height, group.pitch);

  var closest_point_in_helix_untransformed =
      group.transform_point_main_view(closest_point_in_helix, geometry, inverse: true);

  int offset = helix.svg_x_to_offset(closest_point_in_helix_untransformed.x, helix_svg_position.x);
  bool forward = helix.svg_y_is_forward(closest_point_in_helix_untransformed.y, helix_svg_position.y);

//  print('* get_closest_address *');
//  print('  closest helix: ${helix.idx}');
//  print('  offset = ${offset}');
//  print('  forward = ${forward}');
  return Address(helix_idx: helix.idx, offset: offset, forward: forward);
}

//XXX: don't know why I need to correct for this here, but not when responding to a selection box mouse event
// might be related to the fact that the mouse coordinates for the selection box are detected outside of React
Point<num> svg_position_of_mouse_click(MouseEvent event) {
  Point<num> offset_in_svg_elt;
  if (browser.isFirefox) {
    offset_in_svg_elt = get_svg_point(event);
  } else {
    offset_in_svg_elt = event.offset;
  }
  return transform_mouse_coord_to_svg_current_panzoom(offset_in_svg_elt, true);
}

Point<num> get_svg_point(MouseEvent event) {
  if (browser.isFirefox) {
    SvgElement target = event.target as SvgElement;
    Element svg_elt = svg_ancestor(target);
    var rect = svg_elt.getBoundingClientRect().topLeft;
    var offset = event.client - rect;
    return offset;
  } else {
    return event.client;
  }
}

SvgSvgElement svg_ancestor(SvgElement elt) {
  while (!(elt is SvgSvgElement)) {
    elt = elt.parent as SvgElement;
  }
  return elt as SvgSvgElement;
}

Point<num> rect_to_point(Rect rect) => Point<num>(rect.x, rect.y);

Point<int> round_point(Point<num> point) => Point<int>(point.x.round(), point.y.round());

Point<num> transform_mouse_coord_to_svg_current_panzoom_correct_firefox(
    MouseEvent event, bool is_main_view, SvgSvgElement view_svg) {
  Point<num> point;
  if (!browser.isFirefox) {
    point = event.offset;
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
Point<num> untransformed_svg_point(SvgSvgElement svg_elt,
    {Point<num> mouse_pos = null, MouseEvent event = null}) {
  var svg_point_SVG = svg_elt.createSvgPoint();
  if (mouse_pos == null) {
    assert(event != null);
    mouse_pos = event.client;
  }
  svg_point_SVG.x = mouse_pos.x;
  svg_point_SVG.y = mouse_pos.y;
  //TODO: consider using svg_elt.getCtm(): https://github.com/anvaka/panzoom/commit/49be4a1bd6361598b79f29fe99adc2c125d93678
  var svg_point_SVG_1 = svg_point_SVG.matrixTransform(svg_elt.getScreenCtm().inverse());
  Point<num> svg_point = Point<num>(svg_point_SVG_1.x, svg_point_SVG_1.y);
  return svg_point;
}

/// Gets untransformed coordinates of mouse event in svg_elt.
/// XXX: Firefox is the only browser to handle this correctly; cross-browser solution taken from
/// https://stackoverflow.com/questions/19713320/svg-viewbox-doesnt-return-correct-mouse-points-with-nested-svg-in-firefox
Point<num> transformed_svg_point(SvgSvgElement svg_elt, bool is_main,
    {Point<num> mouse_pos = null, MouseEvent event = null}) {
  var svg_pos_untransformed = untransformed_svg_point(svg_elt, mouse_pos: mouse_pos, event: event);
  var svg_pos = transform_mouse_coord_to_svg_current_panzoom(svg_pos_untransformed, is_main);
  return svg_pos;
}

Point<num> transform_mouse_coord_to_svg_current_panzoom(Point<num> point, bool is_main) {
  return transform_mouse_coord_to_svg(point, current_pan(is_main), current_zoom(is_main));
}

/// Transform point by panning and zooming from mouse coordinates to SVG coordinates.
/// (Actually I needed to do what appears to be the inverse transformation here, not sure why.)
Point<num> transform_mouse_coord_to_svg(Point<num> point, Point<num> pan, num zoom) {
  return (point - pan) * (1.0 / zoom);
}

Point<num> transform_svg_to_mouse_coord_current_panzoom(Point<num> point, bool is_main) {
  return transform_svg_to_mouse_coord(point, current_pan(is_main), current_zoom(is_main));
}

Point<num> transform_svg_to_mouse_coord(Point<num> point, Point<num> pan, num zoom) {
  // Don't know why but Firefox auto-corrects for the current SVG coordinates whereas Chrome does not
  if (browser.isFirefox || browser.isInternetExplorer) {
    return point;
  } else {
    return point * zoom + pan;
  }
}

Rectangle<num> svg_rect_to_rectangle(Rect rect) => Rectangle<num>(rect.x, rect.y, rect.width, rect.height);

transform_rect(
    Point<num> transform(Point<num> p, Point<num> pan, num zoom), Rect rect, Point<num> pan, num zoom) {
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
  transform_rect_mouse_coord_to_svg(rect, current_pan(true), current_zoom(true));
}

transform_rect_svg_to_mouse_coord_main_view(Rect rect) {
  transform_rect_svg_to_mouse_coord(rect, current_pan(true), current_zoom(true));
}

Point<num> side_view_grid_to_svg(GridPosition gp, Grid grid, bool invert_y, Geometry geometry) {
  Point<num> point;
  if (grid == Grid.square) {
    point = Point<num>(gp.h, gp.v);
  } else if (grid == Grid.hex) {
    point = hex_grid_position_to_position2d_diameter_1_circles(gp);
  } else if (grid == Grid.honeycomb) {
    point = honeycomb_grid_position_to_position2d_diameter_1_circles(gp);
  } else {
    throw ArgumentError(
        'cannot convert grid coordinates for grid unless it is one of square, hex, or honeycomb');
  }
  if (invert_y) {
    num x = point.x;
    num y = point.y;
    point = Point<num>(-x, -y);
  }
  return point * geometry.distance_between_helices_svg;
}

/// see here for definitions: https://www.redblobgames.com/grids/hexagons/
enum HexGridCoordinateSystem { odd_r, even_r, odd_q, even_q }

/// Converts from hex grid_position to absolute real-number position,
/// assuming each grid circle has diameter 1,
/// and the center of circle at grid_position (0,0) is the origin.
Point<num> hex_grid_position_to_position2d_diameter_1_circles(GridPosition gp,
    [HexGridCoordinateSystem coordinate_system = HexGridCoordinateSystem.odd_q]) {
  num x, y;
  if (coordinate_system == HexGridCoordinateSystem.odd_r) {
    x = gp.h; // x offset from h
    if (gp.v % 2 == 1) {
      x += cos(2 * pi / 6); // x offset from v
    }
    y = sin(2 * pi / 6) * gp.v; // y offset from v
  } else if (coordinate_system == HexGridCoordinateSystem.even_q) {
    y = gp.v;
    if (gp.h % 2 == 1) {
      y -= cos(2 * pi / 6);
    }
    x = sin(2 * pi / 6) * gp.h;
  } else if (coordinate_system == HexGridCoordinateSystem.odd_q) {
    y = gp.v;
    if (gp.h % 2 == 1) {
      y += cos(2 * pi / 6);
    }
    x = sin(2 * pi / 6) * gp.h;
  } else {
    throw UnsupportedError('coordinate system ${coordinate_system} not supported');
  }
  return Point<num>(x, y);
}

// Uses cadnano coordinate system:
//   https://github.com/UC-Davis-molecular-computing/scadnano-python-package/blob/master/misc/cadnano-format-specs/v2.txt
// briefly,
// They increase in these directions:   +----> row
//                                      |
//                                      |
//                                      V
//                                     col
//
// When honeycomb lattice, a "row" is in fact a zigzag pattern:
//
//            .   .   .             .   .
//              .   .   .   or    .   .   .
//
// The first is used when the row is even and the second when the row is odd.
Point<num> honeycomb_grid_position_to_position2d_diameter_1_circles(GridPosition gp) {
  num x, y;
  y = 1.5 * gp.v;
  if (gp.h % 2 == 0 && gp.v % 2 == 1) {
    y += 0.5;
  } else if (gp.h % 2 == 1 && gp.v % 2 == 0) {
    y += cos(2 * pi / 6);
  }
  x = gp.h * sin(2 * pi / 6);
  return Point<num>(x, y);
  // below inverts the rows, i.e., implements the convention
  //   "The first is used when the row is odd and the second when the row is even."
  // in the documentation above.
//  num x, y;
//  y = 1.5 * gp.v;
//  if (gp.h % 2 == 0 && gp.v % 2 == 1) {
//    y -= 0.5;
//  } else if (gp.h % 2 == 1 && gp.v % 2 == 0) {
//    y -= cos(2 * pi / 6);
//  }
//  z = gp.h * sin(2 * pi / 6);
//  return Point<num>(z, y);
}

/// Translates SVG coordinates in side view to Grid coordinates using the specified grid.
GridPosition side_view_svg_to_grid(Grid grid, Point<num> svg_coord, bool invert_y, Geometry geometry,
    [HexGridCoordinateSystem coordinate_system = HexGridCoordinateSystem.odd_q]) {
  num x = svg_coord.x / geometry.distance_between_helices_svg;
  num y = svg_coord.y / geometry.distance_between_helices_svg;
  GridPosition gp = position_2d_to_grid_position_diameter_1_circles(grid, x, y, coordinate_system);
  if (invert_y) {
    gp = GridPosition(-gp.h, -gp.v);
  }
  return gp;
}

GridPosition position_2d_to_grid_position_diameter_1_circles(Grid grid, num x, num y,
    [HexGridCoordinateSystem coordinate_system = HexGridCoordinateSystem.odd_q]) {
  int h, v;
  // below here computes inverse of hex_grid_position_to_position2d_diameter_1_circles
  if (grid == Grid.none) {
    throw ArgumentError('cannot output grid coordinates for grid = Grid.none');
  } else if (grid == Grid.square) {
    h = x.round();
    v = y.round();
  } else if (grid == Grid.honeycomb) {
    h = (x / sin(2 * pi / 6)).round();
    if (h % 2 == 0) {
      int remainder_by_3 = y.floor() % 3;
      if (remainder_by_3 == 2) {
        y -= 0.5;
      }
    } else if (h % 2 == 1) {
      int remainder_by_3 = (y - cos(2 * pi / 6)).floor() % 3;
      if (remainder_by_3 == 1) {
        y -= cos(2 * pi / 6);
      }
    }
    v = (y / 1.5).round();
  } else if (grid == Grid.hex) {
    if (coordinate_system == HexGridCoordinateSystem.odd_r) {
      v = (y / sin(2 * pi / 6)).round();
      if (v % 2 == 1) {
        x -= cos(2 * pi / 6);
      }
      h = x.round();
    } else if (coordinate_system == HexGridCoordinateSystem.even_q) {
      h = (x / sin(2 * pi / 6)).round();
      if (h % 2 == 1) {
        y += cos(2 * pi / 6);
      }
      v = y.round();
    } else if (coordinate_system == HexGridCoordinateSystem.odd_q) {
      h = (x / sin(2 * pi / 6)).round();
      if (h % 2 == 1) {
        y -= cos(2 * pi / 6);
      }
      v = y.round();
    } else {
      throw UnsupportedError('coordinate system ${coordinate_system} not supported');
    }
  }
  var gp = GridPosition(h, v);
  return gp;
}

GridPosition position3d_to_grid_position(Position3D position, Grid grid, Geometry geometry) {
  var position_normalized_diameter_1 = position * (1.0 / geometry.distance_between_helices_nm);
  var gp = position_2d_to_grid_position_diameter_1_circles(
      grid, position_normalized_diameter_1.z, position_normalized_diameter_1.y);
  return gp;
}

Position3D grid_position_to_position3d(GridPosition grid_position, Grid grid, Geometry geometry) {
  num y, z;
  if (grid == Grid.square) {
    z = grid_position.h * geometry.distance_between_helices_nm;
    y = grid_position.v * geometry.distance_between_helices_nm;
  } else if (grid == Grid.hex) {
    Point<num> point = hex_grid_position_to_position2d_diameter_1_circles(grid_position);
    z = point.x * geometry.distance_between_helices_nm;
    y = point.y * geometry.distance_between_helices_nm;
  } else if (grid == Grid.honeycomb) {
    Point<num> point = honeycomb_grid_position_to_position2d_diameter_1_circles(grid_position);
    z = point.x * geometry.distance_between_helices_nm;
    y = point.y * geometry.distance_between_helices_nm;
  } else {
    throw ArgumentError(
        'cannot convert grid coordinates for grid unless it is one of square, hex, or honeycomb');
  }
  return Position3D(x: 0, y: y, z: z);
}

Point<num> position3d_to_side_view_svg(Position3D position, bool invert_y, Geometry geometry) => Point<num>(
      position.x * geometry.nm_to_svg_pixels * (invert_y ? -1 : 1),
      position.y * geometry.nm_to_svg_pixels * (invert_y ? -1 : 1),
    );

Position3D svg_side_view_to_position3d(Point<num> svg_pos, bool invert_y, Geometry geometry) => Position3D(
      x: svg_pos.x / geometry.nm_to_svg_pixels * (invert_y ? -1 : 1),
      y: svg_pos.y / geometry.nm_to_svg_pixels * (invert_y ? -1 : 1),
      z: 0,
    );

/// This goes into "window", so in JS you can access window.editor_content, and in Brython you can do this:
/// from browser import window
/// print(window['editor_content'])
save_editor_content_to_js_context(String new_content) {
  js.context[constants.editor_content_js_key] = new_content;
}

/// Tries to get value in map associated to key, but raises an exception if the key is not present.
/// Since this is only used for [Design]s, it throws an [IllegalDesignError].
/// [legacy_keys] is a list of older key names for this same value that work in addition to [key].
/// [name] is the name of the class in which we expect to find this key (e.g., we expect to find
/// "domains" in Strand
dynamic mandatory_field(Map<String, dynamic> map, String key, String name,
    {List<String> legacy_keys = const []}) {
  if (!map.containsKey(key)) {
    for (var legacy_key in legacy_keys) {
      if (map.containsKey(legacy_key)) {
        return map[legacy_key];
      }
    }
    var msg = 'key "${key}" is missing from the description of a ${name}:\n  ${map}';
    if (legacy_keys.isNotEmpty) {
      msg += '\nThese legacy keys are also supported, but were not found either: ${legacy_keys.join(", ")}';
    }
    throw IllegalDesignError(msg);
  } else {
    return map[key];
  }
}

/// Tries to get value in map associated to [key], returning [default_value] if [key] is not present.
/// If [transformer] is given and the key is found in the map, apply [transformer] to the associated value
/// and return it.
/// If [key] is not present but one of [legacy_keys] is, then that value is used.
/// If [legacy_transformer] is specified and a legacy key is used, then
/// [legacy_transformer] is used instead of [transformer]/
T optional_field<T, U>(Map<String, dynamic> map, String key, T default_value,
    {T Function(U) transformer = null,
    List<String> legacy_keys = const [],
    T Function(U) legacy_transformer = null}) {
  var value = null;
  if (!map.containsKey(key)) {
    for (var legacy_key in legacy_keys) {
      if (map.containsKey(legacy_key)) {
        value = map[legacy_key];
        if (legacy_transformer != null) {
          return legacy_transformer(value);
        }
        break;
      }
    }
    if (value == null) {
      return default_value;
    }
  } else {
    value = map[key];
  }
  if (transformer == null) {
    return value;
  } else {
    return transformer(value);
  }
}

/// Tries to get value in map associated to [key], returning null if [key] is not present.
/// If transformer is given and the key is found in the map, apply transformer to the associated value
/// and return it.
/// This function is needed because calling [optional_field] with default_value = null will result
/// in a type error, since Dart generics type inference will think the return type should be Null
/// instead of whatever is the type of the value in the map.
T optional_field_with_null_default<T, U>(Map<String, dynamic> map, String key,
    {T Function(U) transformer = null, List<String> legacy_keys = const []}) {
  if (!map.containsKey(key)) {
    for (var legacy_key in legacy_keys) {
      if (map.containsKey(legacy_key)) {
        return map[legacy_key];
      }
    }
    return null;
  } else {
    if (transformer == null) {
      return map[key];
    } else {
      return transformer(map[key]);
    }
  }
}

num sigmoid(num x) {
  return 1.0 / (1.0 + exp(-x));
}

@JS(constants.js_function_name_cache_svg)
external ImageElement cache_svg(String svg_elt_id);

@JS(constants.js_function_name_current_zoom_main)
external num current_zoom_main_js();

@JS(constants.js_function_name_current_zoom_side)
external num current_zoom_side_js();

@JS(constants.js_function_name_current_pan_main)
external List<num> _current_pan_main_js();

@JS(constants.js_function_name_current_pan_side)
external List<num> _current_pan_side_js();

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

set_pan_side(Point<num> pos) => _set_pan_side_js(Pan(x: pos.x, y: pos.y));

set_pan_main(Point<num> pos) => _set_pan_main_js(Pan(x: pos.x, y: pos.y));

Point<num> current_pan(bool is_main) {
  var ret = is_main ? _current_pan_main_js() : _current_pan_side_js();
  return Point<num>(ret[0], ret[1]);
}

num current_zoom(bool is_main) => is_main ? current_zoom_main_js() : current_zoom_side_js();

CssStyleSheet get_scadnano_stylesheet() {
  for (var stylesheet in document.styleSheets) {
    if (stylesheet.href.contains(constants.scadnano_css_stylesheet_name)) {
      return stylesheet;
    }
  }
  throw AssertionError('cannot find stylesheet containing "${constants.scadnano_css_stylesheet_name}" '
      'in its href\nlist of stylesheet hrefs:\n'
      '${[for (var sheet in document.styleSheets) sheet.href].join("\n")}');
}

/// Indicates if loopout between two given strands is a hairpin.
bool is_hairpin(Domain prev_ss, Domain next_ss) {
  bool is_hairpin = prev_ss.helix == next_ss.helix &&
      prev_ss.forward != next_ss.forward &&
      (prev_ss.offset_3p - next_ss.offset_5p).abs() < 3;
  return is_hairpin;
}

enum BlobType { text, binary, image, excel }

String blob_type_to_string(BlobType blob_type) {
  switch (blob_type) {
    case BlobType.text:
      return 'text/plain;charset=utf-8';
    case BlobType.binary:
      return 'application/octet-stream';
    case BlobType.image:
      return 'image/svg+xml;charset=utf-8,';
    case BlobType.excel:
      // https://stackoverflow.com/questions/974079/setting-mime-type-for-excel-document
//      return 'application/vnd.ms-excel';
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  }
  throw AssertionError(ASSERTION_ERROR_MESSAGE);
}

/// [and_then] is a callback to do if the file save dialog is not canceled and no other error occurs.
/// Currently, it doesn't do much good, because it is called whether the user cancels or not. But if someday
/// we get around the issues described here:
///   https://github.com/UC-Davis-molecular-computing/scadnano/issues/282
///   https://github.com/UC-Davis-molecular-computing/scadnano/issues/292
/// then it will be nice to have it happen only if the save is successful.
save_file(String default_filename, var content,
    {BlobType blob_type = BlobType.text, void Function() and_then = null}) async {
  try {
    String blob_type_string = blob_type_to_string(blob_type);
    Blob blob = new Blob([content], blob_type_string);
    String url = Url.createObjectUrlFromBlob(blob);
    var link = new AnchorElement()
      ..href = url
      ..download = default_filename;

    if (browser.isFirefox) {
      document.body.children.add(link);
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
  var msg = 'error while saving file: ${e}'
      '${stack_trace_message_bug_report(stack_trace)}';
  window.alert(msg);
}

String stack_trace_message_bug_report(stack_trace) {
  return '\n'
      '\n**********************************************************************************'
      '\n* If you believe this is due to a bug in scadnano, please file a bug report at   *'
      '\n*   ${constants.BUG_REPORT_URL}${' ' * (77 - constants.BUG_REPORT_URL.length)}*'
      '\n* Include this entire message in the email.                                      *'
      '\n**********************************************************************************'
      '\n\nstack trace:'
      '\n${stack_trace}';
}

pprint(Map map) {
  print('{');
  for (var key in map.keys) {
    print('$key: ${map[key]},');
  }
  print('}');
}

String id_domain(Domain domain) =>
    'domain-H${domain.helix}-S${domain.start}-E${domain.end}-${domain.forward ? 'forward' : 'reverse'}';

String id_insertion(Domain domain, int offset) =>
    'insertion-H${domain.helix}-O${offset}-${domain.forward ? 'forward' : 'reverse'}';

String id_deletion(Domain domain, int offset) =>
    'deletion-H${domain.helix}-O${offset}-${domain.forward ? 'forward' : 'reverse'}';

String id_modification_5p(Strand strand, Modification5Prime mod) => 'modification-5p-${strand.id}';

String id_modification_3p(Strand strand, Modification3Prime mod) => 'modification-3p-${strand.id}';

String id_modification_int(Strand strand, ModificationInternal mod, Address address) =>
    'modification-int-H${address.helix_idx}-${address.offset}-'
    '${address.forward ? "forward" : "reverse"}-${strand.id}';

Map<Type, List> split_list_selectable_by_type(List<Selectable> selected) {
  Map<Type, List> selected_all = {Crossover: [], Loopout: [], DNAEnd: [], Strand: []};
  for (var selectable in selected) {
    selected_all[selectable.runtimeType].add(selectable);
  }
  return selected_all;
}

num to_degrees(num radians) => radians * 360 / (2 * pi);

num to_radians(num degrees) => degrees * 2 * pi / 360;

//num rotation_between_helices(BuiltMap<int, Helix> helices, actions.HelixRollSetAtOther action) {
//  Helix helix = helices[action.helix_idx];
//  Helix helix_other = helices[action.helix_other_idx];
//
//  num rotation = helix.angle_to(helix_other);
//  if (!action.forward) {
//    rotation = (rotation - 150) % 360;
//  }
//
//  return rotation;
//}

num rotation_between_helices(Helix helix, Helix helix_other, bool forward, Geometry geometry) {
  num rotation = helix.angle_to(helix_other);
  if (!forward) {
    rotation = (rotation - geometry.minor_groove_angle) % 360;
  }
  return rotation;
}

/// Rotate [point] about [origin] by [angle_degrees] degrees.
Point<num> rotate(Point<num> point, num angle_degrees, {Point<num> origin = const Point<num>(0, 0)}) {
  num angle_radians = to_radians(angle_degrees);
  var point_relative_to_origin = point - origin;
  num x = point_relative_to_origin.x * cos(angle_radians) - point_relative_to_origin.y * sin(angle_radians);
  num y = point_relative_to_origin.x * sin(angle_radians) + point_relative_to_origin.y * cos(angle_radians);
  var point_rotated_relative_to_origin = Point<num>(x, y);
  var point_rotated = point_rotated_relative_to_origin + origin;
  return point_rotated;
}

bool helices_view_order_is_default(BuiltList<int> helix_idxs, HelixGroup group) {
  var default_helices_view_order = List<int>.from(helix_idxs);
  default_helices_view_order.sort();
  var helices_view_order = group.helices_view_order.toList();
  var eq = const ListEquality().equals;
  bool helices_view_order_is_default = eq(helices_view_order, default_helices_view_order);
  return helices_view_order_is_default;
}

List<int> identity_permutation(int length) => [for (int i = 0; i < length; i++) i];

/// Return offset and direction on helix where click event occurred.
Address get_address_on_helix(
    MouseEvent event, Helix helix, HelixGroup group, Geometry geometry, Point<num> helix_svg_position) {
  var closest_address = find_closest_address(
      event, [helix], {helix.group: group}.build(), geometry, {helix.idx: helix_svg_position}.build());
  return closest_address;
}

String remove_whitespace_and_uppercase(String string) {
  var string_no_spaces = string.replaceAll(RegExp(r'\s+'), '');
  return string_no_spaces.toUpperCase();
}

/// Return [sequence] modified to have length [length].
/// If [sequence.length] < [length], pad with [constants.DNA_BASE_WILDCARD].
/// If [sequence.length] > [length], remove extra symbols.
String pad_dna(String sequence, int length) {
  if (sequence.length > length) {
    sequence = sequence.substring(0, length);
  } else if (sequence.length < length) {
    sequence += constants.DNA_BASE_WILDCARD * (length - sequence.length);
  }
  return sequence;
}

/// Takes a "union" of two equal-length strings [s1] and [s2].
/// Whenever one has a symbol [wildcard] and the other does not, the result has the non-wildcard symbol.
/// Throws [ArgumentError] if [s1] and [s2] are not the same length or do not agree on non-wildcard
/// symbols at any position.
String merge_wildcards(String s1, String s2, String wildcard) {
  if (s1.length != s2.length) {
    throw ArgumentError('\ns1=${s1} and\ns2=${s2}\nare not the same length.');
  }
  List<String> union_builder = [];
  for (int i = 0; i < s1.length; i++) {
    String c1 = s1[i];
    String c2 = s2[i];
    if (c1 == wildcard) {
      union_builder.add(c2);
    } else if (c2 == wildcard) {
      union_builder.add(c1);
    } else if (c1 != c2) {
      throw ArgumentError('s1=${s1} and s2=${s2} have unequal symbols ${c1} and ${c2} at position ${i}.');
    } else if (c1 == c2) {
      union_builder.add(c1); // doesn't matter which we pick in this case
    } else {
      throw AssertionError('should be unreachable');
    }
  }
  return union_builder.join('');
}

/// Takes a "union" of two equal-length strings [s1] and [s2].
/// Whenever one has a symbol [wildcard] and the other does not, the result has the non-wildcard symbol.
/// Throws [ArgumentError] if [s1] and [s2] are not the same length or do not agree on non-wildcard
/// symbols at any position.
String merge_wildcards_favor_first(String s1, String s2, String wildcard) {
  if (s1.length != s2.length) {
    throw ArgumentError('\ns1=${s1} and\ns2=${s2}\nare not the same length.');
  }
  List<String> union_builder = [];
  for (int i = 0; i < s1.length; i++) {
    String c1 = s1[i];
    String c2 = s2[i];
    if (c1 == wildcard) {
      union_builder.add(c2);
    } else if (c2 == wildcard) {
      union_builder.add(c1);
    } else {
      union_builder.add(c1);
    }
  }
  return union_builder.join('');
}

/// Ensure is a valid DNA sequence.
/// Throw [FormatException] if it contains symbols other than base symbols a c g t A C G T and whitespace,
/// and if it does not have at least one base symbol.
check_dna_sequence(String seq) {
  var seq_no_spaces = seq.replaceAll(RegExp(r'\s+'), '');
  if (seq_no_spaces.isEmpty) {
    throw FormatException('"${seq}" is not a valid DNA sequence; it cannot be empty');
  }
  RegExp regex = RegExp(r'^(a|c|g|t|A|C|G|T)+$');
  if (regex.hasMatch(seq_no_spaces)) {
    return true;
  } else {
    String counter_example;
    for (int i = 0; i < seq_no_spaces.length; i++) {
      counter_example = seq_no_spaces[i];
      if (counter_example != 'A' &&
          counter_example != 'C' &&
          counter_example != 'G' &&
          counter_example != 'T' &&
          counter_example != 'a' &&
          counter_example != 'c' &&
          counter_example != 'g' &&
          counter_example != 't') {
        break;
      }
    }
    String seq_with_newlines = with_newlines(seq, 100);
    throw FormatException(r'<pre>' +
        seq_with_newlines +
        r'</pre>' +
        'is not a valid DNA sequence; it can only contain the symbols a c g t A C G T '
            'but it contains the symbol ${counter_example}');
  }
}

/// Puts newline symbols every [width] offsets into [string].
String with_newlines(String string, int width) {
  List<String> lines = [];
  for (int i = 0; i < string.length; i += width) {
    String line = string.substring(i, min(i + width, string.length));
    lines.add(line);
  }
  return lines.join('\n');
}

/// Return reverse Watson-Crick complement of seq. (leave non-base symbols alone)
String wc(String seq) => seq.split('').reversed.map((base) => wc_base(base)).join('');

String wc_base(String base) {
  switch (base) {
    case 'A':
      return 'T';
    case 'a':
      return 't';
    case 'C':
      return 'G';
    case 'C':
      return 'g';
    case 'G':
      return 'C';
    case 'g':
      return 'c';
    case 'T':
      return 'A';
    case 't':
      return 'a';
  }
  return base;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// unit testing utilities

/// Returns the default state of the app.
AppState default_state({Grid grid = Grid.none}) {
  var design = Design(grid: grid);
  var ui_state = AppUIState.from_design(design);
  var state = (DEFAULT_AppState.toBuilder()
        ..design = design.toBuilder()
        ..ui_state.replace(ui_state)
        ..editor_content = '')
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
  GraphicsElement dna_sequence_element = dna_sequence_element_list.first;
  GraphicsElement strands_element = strands_element_list.first;

  // Wraps dna_sequence_element in a SVG Element because required for Blob
  SvgSvgElement svg = SvgSvgElement();
  GraphicsElement dna_sequence_element_copy = clone_and_apply_style(dna_sequence_element);

  GraphicsElement strands_element_copy = clone_and_apply_style(strands_element);
  strands_element_copy.setAttribute('display', 'none');

  // Translates dna_sequence_element_copy down so that it's Blob uri captures the topmost dna sequence
  // inside of it's view box.
  Rect bbox = dna_sequence_element.getBBox();
  num dna_sequence_png_horizontal_offset = constants.DNA_SEQUENCE_HORIZONTAL_OFFSET - bbox.x;
  num dna_sequence_png_vertical_offset = constants.DNA_SEQUENCE_VERTICAL_OFFSET - bbox.y;
  dna_sequence_element_copy.setAttribute(
      'transform', 'translate(${dna_sequence_png_horizontal_offset}, ${dna_sequence_png_vertical_offset})');

  // Append copy to svg wrapper element.
  svg.children.add(strands_element_copy);
  svg.children.add(dna_sequence_element_copy);

  // Firefox requires explicit size on svg to draw on canvas.
  // https://stackoverflow.com/questions/34706891/canvas-draw-image-issue-on-firefox-works-well-in-chrome
  var svg_width = (bbox.width + constants.DNA_SEQUENCE_HORIZONTAL_OFFSET).toInt();
  var svg_height = (bbox.height + constants.DNA_SEQUENCE_VERTICAL_OFFSET).toInt();
  svg.setAttribute('width', svg_width.toString());
  svg.setAttribute('height', svg_height.toString());

  // Serializes svg into a string containing XML.
  String data = XmlSerializer().serializeToString(svg);

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
  CanvasElement canvas = document.createElement('canvas');

  canvas.width = svg_width;
  canvas.height = svg_height;
  canvas.setAttribute('style', 'width: ${canvas.width}px; height: ${canvas.height}px;');

  CanvasRenderingContext2D ctx = canvas.context2D;
  ctx.clearRect(0, 0, bbox.width, bbox.height);

  // IF (DEBUGGING)
  // ImageElement img = document.getElementById('img-dev');
  // img.src = url;
  // ELSE
  ImageElement img = new ImageElement(src: url);

  img.onLoad.listen((_) {
    ctx.drawImage(img, 0, 0);
    Url.revokeObjectUrl(url);
    String img_uri = canvas.toDataUrl('image/png');
    app.dispatch(actions.LoadDnaSequenceImageUri(
        img_uri, -dna_sequence_png_horizontal_offset, -dna_sequence_png_vertical_offset));
  });
}

/// Returns `true` if png is used/should be used `false` otherwise.
///
/// PNG will be used if there is a png uri `dna_sequence_png_uri`,
/// and the zoom is not above threshold `is_zoom_above_threshold`,
/// and there is no pending action `disable_png_cache_until_action_completes`.
bool use_png(String dna_sequence_png_uri, bool is_zoom_above_threshold,
    actions.Action disable_png_cache_until_action_completes) {
  return dna_sequence_png_uri != null &&
      !is_zoom_above_threshold &&
      disable_png_cache_until_action_completes == null;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Saving unused fields

/// Given a `map` and a list of `fields`, returns a `MapBuilder`
/// with all of the fields from `fields` removed.
MapBuilder<String, Object> unused_fields_map(Map<String, Object> map, List<String> fields) {
  var new_map = Map.from(map);
  for (var field in fields) {
    new_map.remove(field);
  }
  return MapBuilder<String, Object>(new_map);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// asynchronous alert dialog

async_alert(String msg) async {
  await null;
  Timer(Duration(microseconds: 1), () => window.alert(msg));
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// detect duplicates in list

List<T> remove_duplicates<T>(Iterable<T> list) => LinkedHashSet<T>.from(list).toList();

/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mouseover Data

bool show_mouseover_data() {
  return app.state.ui_state.show_mouseover_data;
}

const DEBUG_PRINT_MOUSEOVER = false;
//const DEBUG_PRINT_MOUSEOVER = true;

mouse_leave_update_mouseover() {
  if (show_mouseover_data()) {
    app.dispatch(actions.MouseoverDataClear());
  }
}

update_mouseover(SyntheticMouseEvent event_syn, Helix helix, Point<num> helix_svg_position) {
  if (show_mouseover_data()) {
    MouseEvent event = event_syn.nativeEvent;
    var group = app.state.design.groups[helix.group];
    var geometry = app.state.design.geometry;
    var address = get_address_on_helix(event, helix, group, geometry, helix_svg_position);
    int offset = address.offset;
    bool forward = address.forward;

    if (DEBUG_PRINT_MOUSEOVER) {
      Point<num> pan = current_pan(true);
      num zoom = current_zoom(true);
      print('mouse event: '
          'x = ${event.offset.x},   '
          'y = ${event.offset.y},   '
          'pan = (${pan.x.toStringAsFixed(2)}, ${pan.y.toStringAsFixed(2)}),   '
          'zoom = ${zoom.toStringAsFixed(2)},   '
          //        'svg_x = ${svg_x.toStringAsFixed(2)},   '
          //        'svg_y = ${svg_y.toStringAsFixed(2)},   '
          'helix = ${helix.idx},   '
          'offset = ${offset},   '
          'forward = ${forward}');
    }

    var mouseover_params = MouseoverParams(helix.idx, offset, forward);

    BuiltList<MouseoverData> mouseover_datas = app.state.ui_state.mouseover_datas;

    if (needs_update(mouseover_params, mouseover_datas)) {
      //    print('dispatching MouseoverDataUpdate from DesignMainMouseoverRectHelix for helix ${helix.idx}');
      app.dispatch(
          actions.MouseoverDataUpdate(mouseover_params: BuiltList<MouseoverParams>([mouseover_params])));
    } else {
      //    print('skipping MouseoverDataUpdate from DesignMainMouseoverRectHelix for helix ${helix.idx}');
    }
  }
}

// only needs updating if the MouseoverData that would be created is not already in the list
bool needs_update(MouseoverParams mouseover_params, BuiltList<MouseoverData> mouseover_datas) {
  bool needs = true;
//  print('needs update?');
//  print('  mouseover_datas: ${mouseover_datas}');
  for (var mouseover_data in mouseover_datas) {
//    print('  old helix.idx: ${mouseover_data.helix.idx}');
//    print('  new helix.idx: ${mouseover_params.helix_idx}');
//    print('  old offset: ${mouseover_data.offset}');
//    print('  new offset: ${mouseover_params.offset}');
//    print('  old forward: ${mouseover_data.substrand?.forward}');
//    print('  new forward: ${mouseover_params.forward}');
    if (mouseover_data.helix.idx == mouseover_params.helix_idx &&
        mouseover_data.offset == mouseover_params.offset &&
        mouseover_data.domain?.forward == mouseover_params.forward) {
      needs = false;
    }
//    else {
//      print("need to print because "
//          "mouseover_data.helix.idx = ${mouseover_data.helix.idx} "
//          "mouseover_params.helix_idx = ${mouseover_params.helix_idx} "
//          "mouseover_data.offset = ${mouseover_data.offset} "
//          "mouseover_params.offset = ${mouseover_params.offset} "
//          "mouseover_data.substrand.forward = ${mouseover_data.substrand.forward} "
//          "mouseover_params.forward = ${mouseover_params.forward}");
//    }
  }
  return needs;
}

Map<int, int> invert_helices_view_order(Iterable<int> helices_view_order) {
  var view_order_inverse = Map<int, int>();
  int order = 0;
  for (var idx in helices_view_order) {
    view_order_inverse[idx] = order++;
  }
  return view_order_inverse;
}
