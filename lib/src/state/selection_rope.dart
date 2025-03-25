import 'dart:math';

import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';

import '../serializers.dart';

part 'selection_rope.g.dart';

abstract class SelectionRope
    with BuiltJsonSerializable
    implements Built<SelectionRope, SelectionRopeBuilder> {
  SelectionRope._();

  factory SelectionRope(bool toggle) => SelectionRope.from((b) => b
    ..current_point = null
    ..toggle = toggle
    ..points.replace([])
    ..is_main = null);

  factory SelectionRope.from([void Function(SelectionRopeBuilder) updates]) = _$SelectionRope;

  static Serializer<SelectionRope> get serializer => _$selectionRopeSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  bool get toggle; // toggle if Ctrl pressed, otherwise selecting

  bool get selecting => !toggle;

  // when we first create the selection box, there are no points
  // (the user just clicked Ctrl or Shift in rope select mode),
  // and we don't know whether it is the main view yet or not
  BuiltList<Point<double>> get points; // points in polygon

  // This is null initially, before any points have been added, since the `SelectionRope` object it made
  // in response to a keyboard event (pressing the Ctrl or Shift key while in the main or side view).
  // After the first SelectionRopeMouseMove action, it is set to the current point, but we have to wait
  // for a MouseEvent before we can access the cursor position to set this, i.e., the first time the
  // mouse moves after the Ctrl or Shift keys were pressed.
  Point<double>? get current_point; // point where mouse is, on click it is added to points if legal

  bool? get is_main; // in main view or side view?
  // Once a reducer first encounters the
  // SelectionRope object with is_main == null, it will set is_main based on the value of
  // actions.SelectionRopeAddPoint.is_main.

  static const DECIMAL_PLACES = 1;

  @memoized
  BuiltList<Line> get lines {
    List<Line> result = [];
    for (int i = 0; i < points.length - 1; i++) {
      var p1 = points[i];
      var p2 = points[i + 1];
      var line = Line(p1, p2);
      result.add(line);
    }
    return result.build();
  }

  @memoized
  BuiltList<Line> get lines_without_last {
    List<Line> result = [];
    for (int i = 0; i < points.length - 2; i++) {
      var p1 = points[i];
      var p2 = points[i + 1];
      var line = Line(p1, p2);
      result.add(line);
    }
    return result.build();
  }

  @memoized
  BuiltList<Line> get lines_without_first {
    List<Line> result = [];
    for (int i = 1; i < points.length - 1; i++) {
      var p1 = points[i];
      var p2 = points[i + 1];
      var line = Line(p1, p2);
      result.add(line);
    }
    return result.build();
  }

  // check if adding new_point would cause self-intersection
  bool creates_self_intersection(Point<double> new_point) {
    if (points.isEmpty) {
      return false;
    }

    var new_penultimate_line = Line(points.last, new_point);
    for (var line in lines_without_last) {
      if (line.intersects(new_penultimate_line)) {
        return true;
      }
    }

    var new_last_line = Line(new_point, points.first);
    for (var line in lines_without_first) {
      if (line.intersects(new_last_line)) {
        return true;
      }
    }

    if (lines.isNotEmpty) {
      // there will be an intersection with the line from current last point to new_point
      // at the point where they meet,
      // but the only way they intersect *more* is if they are collinear and point in opposite directions
      var last_line = lines.last;
      if (last_line.intersects_line_to_new_point(new_point)) {
        return true;
      }

      // same goes for line from new_point to first point, and line from first point to second point
      var first_line = lines.first;
      if (first_line.intersects_line_from_new_point(new_point)) {
        return true;
      }
    }

    return false;
  }

  /// Indicates if the "potential" selection rope, the one we'd get by appending current_point to
  /// the list points, is illegal.
  bool potential_is_illegal() {
    if (this.current_point != null) {
      return creates_self_intersection(this.current_point!);
    } else {
      return false;
    }
  }
}

int f(int? i) {
  if (i != null) {
    return i + 1;
  } else {
    return 0;
  }
}

// line from (x1,y1) to (x2,y2)
abstract class Line with BuiltJsonSerializable implements Built<Line, LineBuilder> {
  factory Line(Point<double> p1, Point<double> p2) => Line.from((b) => b
    ..p1 = p1
    ..p2 = p2);

  factory Line.from([void Function(LineBuilder) updates]) = _$Line;

  Line._();

  static Serializer<Line> get serializer => _$lineSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  Point<double> get p1;

  Point<double> get p2;

  // https://www.tutorialspoint.com/Check-if-two-line-segments-intersect
  bool intersects(Line line2) {
    // four direction for two lines and points of other line
    Orientation dir1 = orientation(p1, p2, line2.p1);
    Orientation dir2 = orientation(p1, p2, line2.p2);
    Orientation dir3 = orientation(line2.p1, line2.p2, p1);
    Orientation dir4 = orientation(line2.p1, line2.p2, p2);

    if (dir1 != dir2 && dir3 != dir4) {
      // they are intersecting
      return true;
    }

    if (dir1 == Orientation.collinear && contains_point(line2.p1)) {
      // p2 of line2 is on line1
      return true;
    }

    if (dir2 == Orientation.collinear && contains_point(line2.p2)) {
      // p1 of line2 is on line1
      return true;
    }

    if (dir3 == Orientation.collinear && line2.contains_point(p1)) {
      // p2 of line1 is on line2
      return true;
    }

    if (dir4 == Orientation.collinear && line2.contains_point(p2)) {
      // p1 of line1 is on line 2
      return true;
    }

    return false;
  }

  /// check whether p is on this line or not, including endpoints,
  /// unless [interior] is true, in which case endpoints are excluded
  bool contains_point(Point<double> p) =>
      p.x < max(p1.x, p2.x) && p.x < min(p1.x, p2.x) && p.y < max(p1.y, p2.y) && p.y < min(p1.y, p2.y);

  /// Gives direction of cycle a --> b --> c --> a in the plane.
  static Orientation orientation(Point<double> a, Point<double> b, Point<double> c) {
    num val = (b.y - a.y) * (c.x - b.x) - (b.x - a.x) * (c.y - b.y);
    if (val == 0) {
      return Orientation.collinear;
    } else if (val < 0) {
      return Orientation.counterclockwise;
    } else {
      return Orientation.clockwise;
    }
  }

  /// Indicates if this line intersects the line drawn from p2 to new_point at a point other than p2.
  /// This is true if and only if the points p1, p2, and new_point are collinear, and the vector from
  /// p2 to new_point points in the opposite direction as the vector from p1 to p2.
  bool intersects_line_to_new_point(Point<double> new_point) {
    if (orientation(p1, p2, new_point) != Orientation.collinear) {
      return false;
    }
    var v1 = p2 - p1;
    var v2 = new_point - p2;
    return !vectors_point_same_direction(v1, v2);
  }

  /// Indicates if this line intersects the line drawn from new_point to p1 at a point other than p1.
  /// This is true if and only if the points p1, p2, and new_point are collinear, and the vector from
  /// new_point to p1 points in the opposite direction as the vector from p1 to p2.
  bool intersects_line_from_new_point(Point<double> new_point) {
    if (orientation(new_point, p1, p2) != Orientation.collinear) {
      return false;
    }
    var v1 = new_point - p1;
    var v2 = p2 - p1;
    return !vectors_point_same_direction(v1, v2);
  }
}

/// Indicate if vector from p1 to p2 points in the same direction (positive dot product) as
/// the vector from p3 to p4.
bool vectors_point_same_direction(Point<double> v1, Point<double> v2) => v1.x * v2.x + v1.y * v2.y > 0;

enum Orientation {
  collinear,
  counterclockwise,
  clockwise,
}
