/// Pure utility functions with no dependency on app.dart, actions.dart, view code, or DOM globals.
/// These can be safely used by state/ files without introducing circular or heavy transitive imports.
///
/// util.dart re-exports this file, so existing code using `import 'util.dart' as util;`
/// continues to work without changes.
library util_state;

import 'dart:collection';
import 'dart:html';
import 'dart:math';
import 'dart:svg' show Rect;
import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:collection/collection.dart';
import 'package:quiver/iterables.dart' as quiver;

import 'json_serializable.dart';
import 'state/address.dart';
import 'state/crossover.dart';
import 'state/design.dart';
import 'state/design_side_rotation_data.dart';
import 'state/domain.dart';
import 'state/dna_end.dart';
import 'state/domains_move.dart';
import 'state/extension.dart';
import 'state/geometry.dart';
import 'state/grid.dart';
import 'state/grid_position.dart';
import 'state/group.dart';
import 'state/helix.dart';
import 'state/loopout.dart';
import 'state/modification.dart';
import 'state/mouseover_data.dart';
import 'state/position3d.dart';
import 'state/selectable.dart';
import 'state/strand.dart';
import 'state/strands_move.dart';
import 'constants.dart' as constants;

const ASSERTION_ERROR_MESSAGE = '''
You have discovered a bug. Please file a bug report as a GitHub issue at
  ${constants.BUG_REPORT_URL}
Please include as much detail as possible. For instance, it is helpful to upload the design
you were working on, as well as indicating the steps to reproduce the error. Please also
into the bug report any additional error information displayed in the app. Thank you!''';

/////////////////////////////////////////////////////////////////////////////
// ColorCycler

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

/////////////////////////////////////////////////////////////////////////////
// color conversion

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

Color parse_json_color(Object json_obj) {
  try {
    if (json_obj is Map) {
      int r = json_obj['r'];
      int g = json_obj['g'];
      int b = json_obj['b'];
      return RgbColor(r, g, b);
    } else if (json_obj is String) {
      return HexColor(json_obj);
    } else if (json_obj is int) {
      String hex_str = color_decimal_int_to_hex(json_obj);
      return HexColor(hex_str);
    } else {
      throw ArgumentError.value(
        'JSON object representing color must be a Map, String, or int, '
        'but instead it is a ${json_obj.runtimeType}:\n${json_obj}',
      );
    }
  } on Exception {
    print("WARNING: I couldn't understand the color specification ${json_obj}, so I'm substituting black.");
    return RgbColor.name('black');
  }
}

/////////////////////////////////////////////////////////////////////////////
// strands/domains move helpers

HelixGroup current_group_from_strands_move(Design design, StrandsMove strands_move) {
  var group_name = current_group_name_from_strands_move(design, strands_move);
  return design.groups[group_name]!;
}

String current_group_name_from_strands_move(Design design, StrandsMove strands_move) {
  var helix_idx = strands_move.current_address.helix_idx;
  var helix = design.helices[helix_idx]!;
  return helix.group;
}

HelixGroup original_group_from_domains_move(Design design, DomainsMove domains_move) {
  var group_name = original_group_name_from_domains_move(design, domains_move);
  return design.groups[group_name]!;
}

String original_group_name_from_domains_move(Design design, DomainsMove domains_move) {
  var helix_idx = domains_move.original_address.helix_idx;
  var helix = design.helices[helix_idx]!;
  return helix.group;
}

HelixGroup current_group_from_domains_move(Design design, DomainsMove domains_move) {
  var group_name = current_group_name_from_domains_move(design, domains_move);
  return design.groups[group_name]!;
}

String current_group_name_from_domains_move(Design design, DomainsMove domains_move) {
  var helix_idx = domains_move.current_address.helix_idx;
  var helix = design.helices[helix_idx]!;
  return helix.group;
}

/////////////////////////////////////////////////////////////////////////////
// binary search

int? binary_search<T>(List<T> list, T value, int compare(T v1, T v2)) =>
    binary_search_rec(list, value, compare, 0, list.length - 1);

int? binary_search_rec<T>(List<T> list, T value, int compare(T v1, T v2), int min, int max) {
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

/////////////////////////////////////////////////////////////////////////////
// numeric utilities

const EPSILON = 0.000000001;

/// Tests if [x1] and [x2] are within [epsilon] of each other.
bool are_close(double x1, double x2, [double epsilon = EPSILON]) => (x1 - x2).abs() < epsilon;

/// Tests if [x1] and [x2] are within [epsilon] of each other.
bool are_all_close(Iterable<double> x1s, Iterable<double> x2s, [double epsilon = EPSILON]) => [
  for (var pair in quiver.zip([x1s, x2s])) pair,
].every((pair) => are_close(pair[0], pair[1], epsilon));

/// If [val] is close to an int, return that int, otherwise return the value.
num to_int_if_close(double val, [double epsilon = EPSILON]) =>
    are_close(val, val.roundToDouble()) ? val.round() : val;

double sigmoid(num x) {
  return 1.0 / (1.0 + exp(-x));
}

double norm_l2(double x, double y) => sqrt(x * x + y * y);

double round(double x, int precision) {
  var x_big = x * pow(10, precision);
  int x_big_int = x_big.round();
  x = x_big_int / pow(10, precision);
  return x;
}

/////////////////////////////////////////////////////////////////////////////
// list utilities

bool is_increasing<T extends Comparable>(Iterable<T> items) {
  T? prev = null;
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

/// Indicates whether two lists contain the same elements (not necessarily in the same order).
bool lists_contain_same_elts<T extends Comparable>(Iterable<T> elts1, Iterable<T> elts2) {
  List<T> list1 = List<T>.from(elts1);
  List<T> list2 = List<T>.from(elts2);
  list1.sort();
  list2.sort();
  var eq = ListEquality().equals;
  return eq(list1, list2);
}

/// Finds two indices of elements in list that repeat, returning null if all elements are distinct.
(int, int)? repeated_element_indices<T>(List<T> list) {
  Map<T, int> elt_to_idx = {};
  // should take time n log n; we don't do linear search for indices until we know which element repeats
  for (int i2 = 0; i2 < list.length; i2++) {
    T elt = list[i2];
    int? i1 = elt_to_idx[elt];
    if (i1 != null) {
      return (i1, i2);
    }
    elt_to_idx[elt] = i2;
  }
  return null;
}

List<int> identity_permutation(int length) => [for (int i = 0; i < length; i++) i];

List<T> remove_duplicates<T>(Iterable<T> list) => LinkedHashSet<T>.from(list).toList();

BuiltSet<T> add_if_not_null<T>(BuiltSet<T> set, T? elt) => elt == null ? set : set.rebuild((b) => b.add(elt));

/////////////////////////////////////////////////////////////////////////////
// HTTP file content

Future<String> get_text_file_content(String url) async =>
    await HttpRequest.getString(url).then((content) => content);

Future<ByteBuffer> get_binary_file_content(String url) async {
  return await HttpRequest.request(url, responseType: 'arraybuffer').then((request) {
    return request.response;
  });
}

/////////////////////////////////////////////////////////////////////////////
// version comparison

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
  var match = regex.firstMatch(version_str)!;
  var match_g1 = match.group(1)!;
  var match_g2 = match.group(2)!;
  var match_g3 = match.group(3)!;
  int major = int.parse(match_g1);
  int minor = int.parse(match_g2);
  int patch = int.parse(match_g3);
  return Version(major, minor, patch);
}

/////////////////////////////////////////////////////////////////////////////
// helix SVG position calculation

/// Returns SVG position for helices
Map<int, Point<double>> helices_assign_svg(
  Design design,
  bool invert_y,
  BuiltMap<int, Helix> helices,
  BuiltMap<String, HelixGroup> groups, {
  BuiltSet<int>? helix_idxs_to_calculate = null,
}) {
  if (helix_idxs_to_calculate == null || helix_idxs_to_calculate.isEmpty) {
    helix_idxs_to_calculate = [for (var helix in helices.values) helix.idx].toBuiltSet();
  }

  Map<int, Point<double>> svg_positions = {};

  // process by groups because view order only makes sense within a group, and we need
  // to go in view order
  for (var group_name in groups.keys) {
    HelixGroup group = groups[group_name]!;
    var geometry = group.geometry ?? design.geometry;

    double? prev_y = null;

    Helix? prev_helix = null;
    for (var helix_idx in group.helices_view_order) {
      if (helix_idxs_to_calculate.contains(helix_idx)) {
        Helix helix = helices[helix_idx]!;

        // Assertion: Helices should already be updated by reducers
        double x = main_view_svg_x_of_helix(geometry, helix);
        double y = main_view_svg_y_of_helix(geometry, helix);
        if (prev_helix != null) {
          num delta_y;
          if (helix.grid.is_none) {
            var prev_pos = prev_helix.position_!;
            var pos = helix.position_!;
            delta_y = pos.distance_xy(prev_pos) * geometry.nm_to_svg_pixels;
          } else {
            var prev_grid_position = prev_helix.grid_position!;
            var grid_position = helix.grid_position!;
            delta_y =
                prev_grid_position.distance_lattice(grid_position, helix.grid) *
                geometry.distance_between_helices_svg;
          }
          y = prev_y! + delta_y;
        }
        prev_y = y;
        prev_helix = helix;

        svg_positions[helix.idx] = Point<double>(x, invert_y ? -y : y);
      }
    }
  }

  return svg_positions;
}

double main_view_svg_x_of_helix(Geometry geometry, Helix helix) {
  double x = helix.position3d(geometry).z * geometry.nm_to_svg_pixels;
  return x;
}

double main_view_svg_y_of_helix(Geometry geometry, Helix helix) {
  double y = helix.position3d(geometry).y * geometry.nm_to_svg_pixels;
  return y;
}

Map<int, Helix> helices_list_to_map(List<Helix> helices) => {for (var helix in helices) helix.idx: helix};

bool helices_view_order_is_default(BuiltList<int> helix_idxs, HelixGroup group) {
  var default_helices_view_order = List<int>.from(helix_idxs);
  default_helices_view_order.sort();
  var helices_view_order = group.helices_view_order.toList();
  var eq = const ListEquality().equals;
  bool helices_view_order_is_default = eq(helices_view_order, default_helices_view_order);
  return helices_view_order_is_default;
}

Map<int, int> invert_helices_view_order(Iterable<int> helices_view_order) {
  var view_order_inverse = Map<int, int>();
  int order = 0;
  for (var idx in helices_view_order) {
    view_order_inverse[idx] = order++;
  }
  return view_order_inverse;
}

/// Returns `offset` if offset is within bounds of helices in `helices_in_group`.
/// If `offset` is too high, returns the upper bound offset.
/// If `offset` is too low, returns the lower bound offset.
/// If `offset` is null, returns the lower bound offset.
/// If no helices in `helices_in_group` returns null.
int? bounded_offset_in_helices_group(int? offset, Iterable<Helix> helices_in_group) {
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
Point<int>? find_helix_group_min_max(Iterable<Helix> helices_in_group) {
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

/////////////////////////////////////////////////////////////////////////////
// angle and rotation utilities

double to_degrees(double radians) => radians * 360 / (2 * pi);

double to_radians(double degrees) => degrees * 2 * pi / 360;

double degrees(double rad) => rad * 180 / pi;

double radians(double deg) => deg * pi / 180;

double rotation_between_helices(Helix helix, Helix helix_other, bool forward, Geometry geometry) {
  double rotation = helix.angle_to(helix_other, geometry);
  if (!forward) {
    rotation = (rotation - geometry.minor_groove_angle) % 360;
  }
  return rotation;
}

/// Rotate [point] about [origin] by [angle_degrees] degrees.
Point<double> rotate(
  Point<double> point,
  double angle_degrees, {
  Point<double> origin = const Point<double>(0, 0),
}) {
  double angle_radians = to_radians(angle_degrees);
  var point_relative_to_origin = point - origin;
  double x =
      point_relative_to_origin.x * cos(angle_radians) - point_relative_to_origin.y * sin(angle_radians);
  double y =
      point_relative_to_origin.x * sin(angle_radians) + point_relative_to_origin.y * cos(angle_radians);
  var point_rotated_relative_to_origin = Point<double>(x, y);
  var point_rotated = point_rotated_relative_to_origin + origin;
  return point_rotated;
}

// Computes angle between `helix` and `other_helix` in degrees.
double angle_from_helix_to_helix(Helix helix, Helix other_helix, Geometry geometry) {
  var p1 = helix.position(geometry);
  var p2 = other_helix.position(geometry);

  // negate y_diff because y increases going down in the main view
  var y_diff = -(p2.y - p1.y);
  var x_diff = p2.x - p1.x;

  var angle = degrees(atan2(y_diff, x_diff));

  // negate angle because we rotate clockwise
  angle = -angle;

  // subtract 90 since we define 0 angle to be up instead of right
  angle += 90;

  // normalize to be in range [0, 360)
  angle %= 360;

  return angle;
}

double minimum_strain_angle(List<(double, double)> relative_angles) {
  var adjusted_angles = [for (var angle in relative_angles) angle.$1 - angle.$2];
  var ave_angle = average_angle(adjusted_angles);
  var min_strain_angle = -ave_angle;
  min_strain_angle %= 360;
  return min_strain_angle;
}

double angle_distance(double x, double y) {
  var a = (x - y) % 360;
  var b = (y - x) % 360;
  var diff = a < b ? -a : b;
  return diff;
}

double sum_squared_angle_distances(List<double> angles, double angle) {
  double sum = 0.0;
  for (var a in angles) {
    var dist = angle_distance(angle, a);
    sum += dist * dist;
  }
  return sum;
}

double average_angle(List<double> angles) {
  int num_angles = angles.length;
  double mean_angle = 0.0;
  if (num_angles > 0) {
    mean_angle = angles.reduce((a, b) => a + b) / num_angles;
  }

  double min_dist = double.infinity;
  double optimal_angle = 0;
  for (int n = 0; n < num_angles; n++) {
    var candidate_angle = mean_angle + 360.0 * n / num_angles;
    var candidate_dist = sum_squared_angle_distances(angles, candidate_angle);
    if (min_dist > candidate_dist) {
      min_dist = candidate_dist;
      optimal_angle = candidate_angle;
    }
  }

  optimal_angle %= 360.0;

  // taking mod 360 sometimes results in 360.0 instead of 0.0. This is hacky but fixes it.
  if ((360.0 - optimal_angle).abs() < 0.000000001) {
    optimal_angle = 0.0;
  }

  // in case it's a nice round number, let's get rid of the floating-point error artifacts here
  optimal_angle = round(optimal_angle, 9);

  return optimal_angle;
}

/////////////////////////////////////////////////////////////////////////////
// geometry: distance to rectangle, closest point in rectangle

/// find distance from a point to a rectangle (0 if point is inside rectangle).
/// Rectangle is defined by an upper-left corner, width and height, and rotation angle.
/// We first unrotate the point about the upper-left corner,
/// then calculate using the simpler method for axis-aligned rectangles.
double distance_to_rectangle(
  Point<double> point,
  Point<double> upper_left_corner,
  double width,
  double height,
  double angle,
) {
  var distances = xy_distances_to_rectangle(point, upper_left_corner, width, height, angle);
  return sqrt(distances.x * distances.x + distances.y * distances.y);
}

/// Returns (dx,dy) representing distances from point to rectangle. Can be negative to indicate if
/// point is above or below rectangle, or left or right of it.
/// This is assuming the rectangle is "unrotated" by -angle.
Point<double> xy_distances_to_rectangle(
  Point<double> point,
  Point<double> upper_left_corner,
  double width,
  double height,
  double angle,
) {
  Point<double> unrotated_point = rotate(point, -angle, origin: upper_left_corner);
  double x_low = upper_left_corner.x;
  double x_hi = upper_left_corner.x + width;
  double y_low = upper_left_corner.y;
  double y_hi = upper_left_corner.y + height;
  double dx, dy;
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
  return Point<double>(dx, dy);
}

/// Finds closest point in rectangle to [point]. If [point] is inside rectangle, returns [point];
Point<double> closest_point_in_rectangle(
  Point<double> point,
  Point<double> upper_left_corner,
  double width,
  double height,
  double angle,
) {
  var distances = xy_distances_to_rectangle(point, upper_left_corner, width, height, angle);
  Point<double> unrotated_point = rotate(point, -angle, origin: upper_left_corner);
  double x = unrotated_point.x + distances.x;
  double y = unrotated_point.y + distances.y;
  var unrotated_point_in_rectangle = Point<double>(x, y);
  var rotated_point_in_rectangle = rotate(unrotated_point_in_rectangle, angle, origin: upper_left_corner);
  return rotated_point_in_rectangle;
}

/////////////////////////////////////////////////////////////////////////////
// grid position conversions

/// see here for definitions: https://www.redblobgames.com/grids/hexagons/
enum HexGridCoordinateSystem { odd_r, even_r, odd_q, even_q }

/// Converts from hex grid_position to absolute real-number position,
/// assuming each grid circle has diameter 1,
/// and the center of circle at grid_position (0,0) is the origin.
Point<double> hex_grid_position_to_position2d_diameter_1_circles(
  GridPosition gp, [
  HexGridCoordinateSystem coordinate_system = HexGridCoordinateSystem.odd_q,
]) {
  double x, y;
  if (coordinate_system == HexGridCoordinateSystem.odd_r) {
    x = gp.h as double; // x offset from h
    if (gp.v % 2 == 1) {
      x += cos(2 * pi / 6); // x offset from v
    }
    y = sin(2 * pi / 6) * gp.v; // y offset from v
  } else if (coordinate_system == HexGridCoordinateSystem.even_q) {
    y = gp.v as double;
    if (gp.h % 2 == 1) {
      y -= cos(2 * pi / 6);
    }
    x = sin(2 * pi / 6) * gp.h;
  } else if (coordinate_system == HexGridCoordinateSystem.odd_q) {
    y = gp.v as double;
    if (gp.h % 2 == 1) {
      y += cos(2 * pi / 6);
    }
    x = sin(2 * pi / 6) * gp.h;
  } else {
    throw UnsupportedError('coordinate system ${coordinate_system} not supported');
  }
  return Point<double>(x, y);
}

Point<double> honeycomb_grid_position_to_position2d_diameter_1_circles(GridPosition gp) {
  double x, y;
  y = 1.5 * gp.v;
  if (gp.h % 2 == 0 && gp.v % 2 == 1) {
    y += 0.5;
  } else if (gp.h % 2 == 1 && gp.v % 2 == 0) {
    y += cos(2 * pi / 6);
  }
  x = gp.h * sin(2 * pi / 6);
  return Point<double>(x, y);
}

Point<double> side_view_grid_to_svg(GridPosition gp, Grid grid, bool invert_y, Geometry geometry) {
  Point<double> point;
  if (grid == Grid.square) {
    point = Point<double>(gp.h as double, gp.v as double);
  } else if (grid == Grid.hex) {
    point = hex_grid_position_to_position2d_diameter_1_circles(gp);
  } else if (grid == Grid.honeycomb) {
    point = honeycomb_grid_position_to_position2d_diameter_1_circles(gp);
  } else {
    throw ArgumentError(
      'cannot convert grid coordinates for grid unless it is one of square, hex, or honeycomb',
    );
  }
  if (invert_y) {
    double x = point.x;
    double y = point.y;
    point = Point<double>(-x, -y);
  }
  return point * geometry.distance_between_helices_svg;
}

/// Translates SVG coordinates in side view to Grid coordinates using the specified grid.
GridPosition side_view_svg_to_grid(
  Grid grid,
  Point<double> svg_coord,
  bool invert_y,
  Geometry geometry, [
  HexGridCoordinateSystem coordinate_system = HexGridCoordinateSystem.odd_q,
]) {
  num x = svg_coord.x / geometry.distance_between_helices_svg;
  num y = svg_coord.y / geometry.distance_between_helices_svg;
  GridPosition gp = position_2d_to_grid_position_diameter_1_circles(grid, x, y, coordinate_system);
  if (invert_y) {
    gp = GridPosition(-gp.h, -gp.v);
  }
  return gp;
}

GridPosition position_2d_to_grid_position_diameter_1_circles(
  Grid grid,
  num x,
  num y, [
  HexGridCoordinateSystem coordinate_system = HexGridCoordinateSystem.odd_q,
]) {
  int? h = null, v = null;
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
  var gp = GridPosition(h!, v!);
  return gp;
}

GridPosition position3d_to_grid_position(Position3D position, Grid grid, Geometry geometry) {
  var position_normalized_diameter_1 = position * (1.0 / geometry.distance_between_helices_nm);
  var gp = position_2d_to_grid_position_diameter_1_circles(
    grid,
    position_normalized_diameter_1.z,
    position_normalized_diameter_1.y,
  );
  return gp;
}

Position3D grid_position_to_position3d(GridPosition grid_position, Grid grid, Geometry geometry) {
  double x, y;

  if (grid == Grid.square) {
    x = grid_position.h * geometry.distance_between_helices_nm;
    y = grid_position.v * geometry.distance_between_helices_nm;
  } else if (grid == Grid.hex) {
    Point<double> point = hex_grid_position_to_position2d_diameter_1_circles(grid_position);
    x = point.x * geometry.distance_between_helices_nm;
    y = point.y * geometry.distance_between_helices_nm;
  } else if (grid == Grid.honeycomb) {
    Point<double> point = honeycomb_grid_position_to_position2d_diameter_1_circles(grid_position);
    x = point.x * geometry.distance_between_helices_nm;
    y = point.y * geometry.distance_between_helices_nm;
  } else {
    throw ArgumentError(
      'cannot convert grid coordinates for grid unless it is one of square, hex, or honeycomb',
    );
  }
  return Position3D(x: x, y: y, z: 0);
}

Point<double> position3d_to_side_view_svg(Position3D position, bool invert_y, Geometry geometry) =>
    Point<double>(
      position.x * geometry.nm_to_svg_pixels * (invert_y ? -1 : 1),
      position.y * geometry.nm_to_svg_pixels * (invert_y ? -1 : 1),
    );

Position3D svg_side_view_to_position3d(Point<double> svg_pos, bool invert_y, Geometry geometry) => Position3D(
  x: svg_pos.x / geometry.nm_to_svg_pixels * (invert_y ? -1 : 1),
  y: svg_pos.y / geometry.nm_to_svg_pixels * (invert_y ? -1 : 1),
  z: 0,
);

/////////////////////////////////////////////////////////////////////////////
// mouseover data helpers

// only needs updating if the MouseoverData that would be created is not already in the list
bool needs_update(MouseoverParams mouseover_params, BuiltList<MouseoverData> mouseover_datas) {
  bool needs = true;
  for (var mouseover_data in mouseover_datas) {
    if (mouseover_data.helix.idx == mouseover_params.helix_idx &&
        mouseover_data.offset == mouseover_params.offset &&
        mouseover_data.domain?.forward == mouseover_params.forward) {
      needs = false;
    }
  }
  return needs;
}

/// Return list of mouseover data about helix group `group_name` at `offset`.
BuiltList<DesignSideRotationData> rotation_datas_at_offset_in_group(
  int? offset,
  Design design,
  String group_name,
) {
  List<DesignSideRotationParams> rotation_params_list = [];
  if (offset != null) {
    for (var helix_idx in design.helix_idxs_in_group[group_name]!) {
      var helix = design.helices[helix_idx]!;
      if (offset >= helix.min_offset && offset < helix.max_offset) {
        var rotation_params = DesignSideRotationParams(helix_idx, offset);
        rotation_params_list.add(rotation_params);
      }
    }
  }
  return DesignSideRotationData.from_params(design, rotation_params_list).toBuiltList();
}

/////////////////////////////////////////////////////////////////////////////
// JSON parsing utilities

/// Tries to get value in map associated to key, but raises an exception if the key is not present.
/// Since this is only used for [Design]s, it throws an [IllegalDesignError].
/// [legacy_keys] is a list of older key names for this same value that work in addition to [key].
/// [name] is the name of the class in which we expect to find this key (e.g., we expect to find
/// "domains" in Strand
dynamic mandatory_field(
  Map<String, dynamic> map,
  String key,
  String name, {
  List<String> legacy_keys = const [],
}) {
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
T optional_field<T, U>(
  Map<String, dynamic> map,
  String key,
  T default_value, {
  T Function(U)? transformer = null,
  List<String> legacy_keys = const [],
  T Function(U)? legacy_transformer = null,
}) {
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
T? optional_field_with_null_default<T extends Object, U extends Object>(
  Map<String, dynamic> map,
  String key, {
  T Function(U)? transformer = null,
  List<String> legacy_keys = const [],
}) {
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

/////////////////////////////////////////////////////////////////////////////
// Saving unused fields

/// Given a `map` and a list of `fields`, returns a `MapBuilder`
/// with all of the fields from `fields` removed.
MapBuilder<String, Object?> unused_fields_map(Map<String, dynamic> map, List<String> fields) {
  var new_map = Map.from(map);
  for (var field in fields) {
    new_map.remove(field);
  }
  return MapBuilder<String, Object>(new_map);
}

/// If obj is a NoIndent, unwrap the object from it, otherwise return obj.
dynamic unwrap_from_noindent(dynamic obj) => obj is NoIndent ? obj.value : obj;

/////////////////////////////////////////////////////////////////////////////
// mouse event helpers

/// Indicates if left button is pressed during [event],
/// even if the left button was not the one pressed, e.g., if it is pressed while moving or pressing
/// the right button.
/// NOTE: Returns false if left mouse button goes up. For that use left_mouse_button_caused_mouse_event.
bool left_mouse_button_pressed_during_mouse_event(MouseEvent event) => event.buttons! & 1 == 1;

/// Indicates if left mouse button going down or up caused [event].
bool left_mouse_button_caused_mouse_event(MouseEvent event) => event.button == 0;

/////////////////////////////////////////////////////////////////////////////
// point utilities

Point<double> rect_to_point(Rect rect) => Point<double>(rect.x! as double, rect.y! as double);

Point<int> round_point(Point<double> point) => Point<int>(point.x.round(), point.y.round());

Point<double> from_point_num(Point<num> point) => Point<double>(point.x.toDouble(), point.y.toDouble());

/////////////////////////////////////////////////////////////////////////////
// ID generation

String id_helix(Helix helix) => 'helix-H${helix.idx}';

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

/////////////////////////////////////////////////////////////////////////////
// selectable helpers

Map<Type, List> split_list_selectable_by_type(List<Selectable> selected) {
  Map<Type, List> selected_all = {Crossover: [], Loopout: [], DNAEnd: [], Strand: []};
  for (var selectable in selected) {
    selected_all[selectable.runtimeType]!.add(selectable);
  }
  return selected_all;
}

/////////////////////////////////////////////////////////////////////////////
// loopout helpers

/// Indicates if loopout between two given strands is a hairpin.
bool is_hairpin(Domain prev_ss, Domain next_ss) {
  bool is_hairpin =
      prev_ss.helix == next_ss.helix &&
      prev_ss.forward != next_ss.forward &&
      (prev_ss.offset_3p - next_ss.offset_5p).abs() < 3;
  return is_hairpin;
}

/////////////////////////////////////////////////////////////////////////////
// BlobType

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
}

/////////////////////////////////////////////////////////////////////////////
// DNA sequence utilities

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
  RegExp regex = RegExp(r'^([acgtACGT])+$');
  if (regex.hasMatch(seq_no_spaces)) {
    return true;
  } else {
    String counter_example = "NONE";
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
    throw FormatException(
      r'<pre>' +
          seq_with_newlines +
          r'</pre>' +
          'is not a valid DNA sequence; it can only contain the symbols a c g t A C G T '
              'but it contains the symbol ${counter_example}',
    );
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
    case 'c':
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

var set_equality = SetEquality();

/// Indicates if `base1` and `base2` are complementary DNA bases.
bool bases_complementary(String base1, String base2, {bool allow_wildcard = false}) {
  if (allow_wildcard && (base1 == constants.DNA_BASE_WILDCARD || base2 == constants.DNA_BASE_WILDCARD)) {
    return true;
  }

  if (base1.length != 1 || base2.length != 1) {
    throw ArgumentError(
      'base1 and base2 must each be a single character: '
      'base1 = ${base1}, base2 = ${base2}',
    );
  }
  base1 = base1.toUpperCase();
  base2 = base2.toUpperCase();

  return set_equality.equals({base1, base2}, {'A', 'T'}) || set_equality.equals({base1, base2}, {'C', 'G'});
}

/// Indicates if `seq1` and `seq2` are reverse complementary DNA sequences.
/// Either is allowed to be null if `allow_null` is true.
bool reverse_complementary(
  String? seq1,
  String? seq2, {
  bool allow_wildcard = false,
  bool allow_null = false,
}) {
  if (seq1 == null || seq2 == null) {
    return allow_null;
  }

  if (seq1.length != seq2.length) {
    return false;
  }
  for (int i = 0, j = seq2.length - 1; i < seq1.length; i++, j--) {
    var b1 = seq1[i];
    var b2 = seq2[j];
    if (!bases_complementary(b1, b2, allow_wildcard: allow_wildcard)) {
      return false;
    }
  }

  return true;
}

/////////////////////////////////////////////////////////////////////////////
// Extension SVG helpers

double compute_end_rotation(double display_angle, bool forward, bool is_5p) {
  var radians = display_angle * 2 * pi / 360.0;
  // convert to rectangular coordinates to make reflection easier
  num x = cos(radians);
  num y = sin(radians);
  // honestly I don't quite understand why the following rules work,
  // but I played with it until they looked right.
  y = -y;
  if (!forward) {
    x = -x;
  }
  if ((forward && is_5p) || (!forward && !is_5p)) {
    x = -x;
  }
  // convert back from rectangular coordinates to radians
  var reflected_radians = atan2(y, x);
  var degrees = reflected_radians * 360.0 / (2 * pi);
  return degrees;
}

Point<double> compute_extension_attached_end_svg(
  Extension ext,
  Domain adj_dom,
  Helix adj_helix,
  num adj_helix_svg_y,
  Geometry geometry,
) {
  int end_offset = ext.is_5p ? adj_dom.offset_5p : adj_dom.offset_3p;
  Point<double> extension_attached_end_svg = adj_helix.svg_base_pos(
    end_offset,
    adj_dom.forward,
    adj_helix_svg_y,
    geometry,
  );
  return extension_attached_end_svg;
}

// computes the SVG coordinates of the end of an Extension that is not shared with the adjacent Domain
Point<double> compute_extension_free_end_svg(
  Point<double> attached_end_svg,
  Extension ext,
  Domain adjacent_domain,
  Geometry geometry,
) {
  double x = attached_end_svg.x;
  double y = attached_end_svg.y;
  var angle_radians = ext.display_angle * 2 * pi / 360.0;
  // convert polar coordinates in Extension to rectangular coordinates, and convert from nm to SVG pixels
  num x_delta = ext.display_length * cos(angle_radians) * geometry.nm_to_svg_pixels;
  num y_delta = ext.display_length * sin(angle_radians) * geometry.nm_to_svg_pixels;
  if (adjacent_domain.forward) {
    y_delta = -y_delta;
  }
  if ((adjacent_domain.forward && ext.is_5p) || (!adjacent_domain.forward && !ext.is_5p)) {
    x_delta = -x_delta;
  }
  x += x_delta;
  y += y_delta;
  Point<double> ext_end_svg = Point<double>(x, y);
  return ext_end_svg;
}

(double, double) compute_extension_length_and_angle_from_point(
  Point<double> current_mouse_point,
  Point<double> attached_end_svg,
  Extension ext,
  Domain adjacent_domain,
  Geometry geometry,
) {
  num new_x = current_mouse_point.x;
  num new_y = current_mouse_point.y;
  num old_x = attached_end_svg.x;
  num old_y = attached_end_svg.y;
  num x_delta = new_x - old_x;
  num y_delta = new_y - old_y;
  double display_length = sqrt(x_delta * x_delta + y_delta * y_delta) * geometry.svg_pixels_to_nm;
  var angle_radians = atan2(y_delta, x_delta);
  if (adjacent_domain.forward) {
    angle_radians = -angle_radians;
  }
  if ((adjacent_domain.forward && ext.is_5p) || (!adjacent_domain.forward && !ext.is_5p)) {
    angle_radians = pi - angle_radians;
  }
  return (display_length, angle_radians * 180 / pi);
}

/////////////////////////////////////////////////////////////////////////////
// error message helpers

String stack_trace_message_bug_report(stack_trace) {
  return '\n'
      '\n**********************************************************************************'
      '\n* If you believe this is due to a bug in scadnano, please file a bug report at   *'
      '\n*   ${constants.BUG_REPORT_URL}${' ' * (77 - constants.BUG_REPORT_URL.length)}*'
      '\n* Include this entire message in the email, as well as any detail that may help  *'
      '\n* us, including uploading the scadnano design, as well as indicating steps to    *'
      '\n* help us to reproduce the error.                                                *'
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

/////////////////////////////////////////////////////////////////////////////
// FixedList

/// This is used primarily with [Dialog] and [DialogItem] (but also in a few other places in the codebase),
/// so that I can pre-allocate a fixed-size list and lazily initialize its elements, without assigning them
/// null initially and having to declare the type of items is [DialogItem]?,
/// which would require later using `!` to assert that they are not null.
/// Instead, this class checks at runtime that each item is initialized before
/// being read.
class FixedList<T> extends Iterable<T> {
  final List<T?> _items;
  final List<bool> _initialized;

  FixedList(int length)
    : _items = List<T?>.filled(length, null),
      _initialized = List<bool>.filled(length, false);

  void _set(int index, T value) {
    _items[index] = value;
    _initialized[index] = true;
  }

  T _get(int index) {
    if (!_initialized[index]) {
      throw StateError('Item at index $index has not been initialized');
    }
    return _items[index]!;
  }

  // Operator overloading for setting elements
  void operator []=(int index, T value) => _set(index, value);

  // Operator overloading for getting elements
  T operator [](int index) => _get(index);

  @override
  int get length => _items.length;

  @override
  Iterator<T> get iterator => _FixedListIterator(this);

  // Implement elementAt to ensure safe access during iteration
  @override
  T elementAt(int index) => _get(index);
}

class _FixedListIterator<T> implements Iterator<T> {
  final FixedList<T> _list;
  int _index = -1;

  _FixedListIterator(this._list);

  @override
  T get current {
    if (_index < 0 || _index >= _list.length) {
      throw StateError('No element');
    }
    return _list[_index];
  }

  @override
  bool moveNext() {
    if (_index >= _list.length - 1) {
      return false;
    }
    _index++;
    if (!_list._initialized[_index]) {
      throw StateError('Uninitialized element encountered at index $_index during iteration');
    }
    return true;
  }
}

/////////////////////////////////////////////////////////////////////////////
// SVG rect utility

Rectangle<double> svg_rect_to_rectangle(Rect rect) =>
    Rectangle<double>(rect.x! as double, rect.y! as double, rect.width! as double, rect.height! as double);

/////////////////////////////////////////////////////////////////////////////
// transform utilities (pure, no browser/JS dependency)

/// Transform point by panning and zooming from mouse coordinates to SVG coordinates.
/// (Actually I needed to do what appears to be the inverse transformation here, not sure why.)
Point<double> transform_mouse_coord_to_svg(Point<double> point, Point<double> pan, double zoom) {
  return (point - pan) * (1.0 / zoom);
}

const DEBUG_PRINT_MOUSEOVER = false;
