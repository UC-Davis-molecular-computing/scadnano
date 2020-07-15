import 'dart:html';
import 'dart:svg' hide Point;
import 'dart:math';

import 'package:built_value/serializer.dart';

import '../app.dart';
import '../serializers.dart';
import 'selectable.dart';

import 'package:built_value/built_value.dart';

part 'selection_box.g.dart';

const ORIGIN = Point<num>(0, 0);

abstract class SelectionBox with BuiltJsonSerializable implements Built<SelectionBox, SelectionBoxBuilder> {
  SelectionBox._();

  factory SelectionBox(Point<num> start, bool toggle, bool is_main) => SelectionBox.from((b) => b
    ..start = start
    ..toggle = toggle
    ..is_main = is_main
    ..current = start);

  factory SelectionBox.from([void Function(SelectionBoxBuilder) updates]) = _$SelectionBox;

  static Serializer<SelectionBox> get serializer => _$selectionBoxSerializer;

  @memoized
  int get hashCode;

  /************************ end BuiltValue boilerplate ************************/

  Point<num> get start; // starting coordinate of drag
  Point<num> get current; // current coordinate of drag
  bool get toggle; // toggle if Ctrl pressed, otherwise selecting
  bool get is_main; // in main view or side view?

  bool get selecting => !toggle;

  num get x => min(start.x, current.x);

  num get y => min(start.y, current.y);

  num get width => (start.x - current.x).abs();

  num get height => (start.y - current.y).abs();

  static const DECIMAL_PLACES = 1;

  static rect_to_string(Rect bbox) => ''
      '${bbox.x.toStringAsFixed(DECIMAL_PLACES)} '
      '${bbox.y.toStringAsFixed(DECIMAL_PLACES)} '
      '${bbox.width.toStringAsFixed(DECIMAL_PLACES)} '
      '${bbox.height.toStringAsFixed(DECIMAL_PLACES)}';

  String toString() => 'start=('
      '${start.x.toStringAsFixed(DECIMAL_PLACES)}, '
      '${start.y.toStringAsFixed(DECIMAL_PLACES)})'
      '  current=('
      '${current.x.toStringAsFixed(DECIMAL_PLACES)}, '
      '${current.y.toStringAsFixed(DECIMAL_PLACES)}), '
      '  is_main=${is_main}';
}

////XXX: code below just checks bounding boxes. for better intersection code maybe use this:
////  https://github.com/thelonious/kld-intersections
//
//// indicates if (l1,h1) intersect (l2,h2) \neq empty
//bool intervals_overlap(num l1, num h1, num l2, num h2) {
//  return h1 >= l2 && h2 >= l1;
//}
//
//// indicates if (l1,h1) \subseteq (l2,h2)
//bool interval_contained(num l1, num h1, num l2, num h2) {
//  return l1 >= l2 && h1 <= h2;
//}
//
//// gets list of elements associated to Selectables that intersect select_box_bbox
//List<SvgElement> get_intersection_list(Rect select_box_bbox) {
//  return get_generalized_intersection_list(select_box_bbox, intervals_overlap);
//}
//
//// gets list of elements associated to Selectables that intersect select_box_bbox
//List<SvgElement> get_enclosure_list(Rect select_box_bbox) {
//  return get_generalized_intersection_list(select_box_bbox, interval_contained);
//}
//
//get_generalized_intersection_list(Rect select_box_bbox, bool overlap(num l1, num h1, num l2, num h2)) {
//  List<SvgElement> elts_intersecting = [];
//  List<Element> selectable_elts = querySelectorAll('.selectable');
//  for (GraphicsElement elt in selectable_elts) {
//    Rect elt_bbox = elt.getBBox();
////    util.transform_rect_svg_to_mouse_coord_main_view(elt_bbox);
//    if (bboxes_intersect_generalized(elt_bbox, select_box_bbox, overlap)) {
//      elts_intersecting.add(elt);
//    }
//  }
//  return elts_intersecting;
//}
//
//bool bboxes_intersect_generalized(
//    Rect elt_bbox, Rect select_box_bbox, bool overlap(num l1, num h1, num l2, num h2)) {
//  num elt_x2 = elt_bbox.x + elt_bbox.width;
//  num select_box_x2 = select_box_bbox.x + select_box_bbox.width;
//  num elt_y2 = elt_bbox.y + elt_bbox.height;
//  num select_box_y2 = select_box_bbox.y + select_box_bbox.height;
//  return overlap(elt_bbox.x, elt_x2, select_box_bbox.x, select_box_x2) &&
//      overlap(elt_bbox.y, elt_y2, select_box_bbox.y, select_box_y2);
//}
