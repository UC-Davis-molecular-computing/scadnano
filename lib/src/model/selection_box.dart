import 'dart:html';
import 'dart:svg' hide Point;
import 'dart:math';

import 'package:built_value/serializer.dart';

import '../app.dart';
import '../serializers.dart';
import 'selectable.dart';
import '../actions/actions_OLD.dart';

import 'package:built_value/built_value.dart';

part 'selection_box.g.dart';

const ORIGIN = Point<num>(0, 0);

abstract class SelectionBox with BuiltJsonSerializable implements Built<SelectionBox, SelectionBoxBuilder> {
  SelectionBox._();

  factory SelectionBox(Point<num> start, bool toggling) => SelectionBox.from((b) => b
    ..start = start
    ..toggling = toggling
    ..current = start);

  factory SelectionBox.from([void Function(SelectionBoxBuilder) updates]) = _$SelectionBox;

  static Serializer<SelectionBox> get serializer => _$selectionBoxSerializer;

  /************************ end BuiltValue boilerplate ************************/

  Point<num> get start; // starting coordinate of drag
  Point<num> get current; // current coordinate of drag
  bool get toggling; // toggling if Ctrl pressed, otherwise selecting
  bool get selecting => !toggling;

  num get x => min(start.x, current.x);

  num get y => min(start.y, current.y);

  num get width => (start.x - current.x).abs();

  num get height => (start.y - current.y).abs();

  static const DECIMAL_PLACES = 1;

  static rectToString(Rect bbox) => ''
      '${bbox.x.toStringAsFixed(DECIMAL_PLACES)} '
      '${bbox.y.toStringAsFixed(DECIMAL_PLACES)} '
      '${bbox.width.toStringAsFixed(DECIMAL_PLACES)} '
      '${bbox.height.toStringAsFixed(DECIMAL_PLACES)}';

  String toString() => 'start=('
      '${x.toStringAsFixed(DECIMAL_PLACES)}, '
      '${y.toStringAsFixed(DECIMAL_PLACES)})'
      '  current=('
      '${width.toStringAsFixed(DECIMAL_PLACES)}, '
      '${height.toStringAsFixed(DECIMAL_PLACES)})';

  //TODO: update this code to handle side view or main view, and call it from view/design.dart when drag ends
  //XXX: in principle this should be updateable every time the mouse moves and the selection box changes,
  // but in practice, the currently selected items and/or the Actions fired affected the results returned by
  // getIntersectionList, getEnclosureList, checkIntersection, checkEnclosure, so that they would falsely say certain
  // elements are or are not intersecting the rectangle. It does not have this problem to check only at the end of
  // the rectangle dragging, so we leave it like this for now.
  update_selections() {
//    if (parent_svg_elt == null) {
//      parent_svg_elt = querySelector('#main-view-svg') as SvgSvgElement;
//    }

    RectElement select_box = querySelector('#selection-box') as RectElement;
    if (select_box == null) {
      return;
    }

    //XXX: Firefox does not have getIntersectionList or getEnclosureList
    // (no progress for 10 years on that: https://bugzilla.mozilla.org/show_bug.cgi?id=501421)
    // It didn't work well anyway in Chrome and I basically had to implement it myself anyway based
    // on bounding boxes.

    Rect select_box_bbox = select_box.getBBox();
//    util.transform_rect_svg_to_mouse_coord_main_view(select_box_bbox);

    var selectables_by_id = app.state.ui_state.selectables_store.selectables_by_id;

//    var elts_all = parent_svg_elt.getEnclosureList(select_box_bbox, null).map((elt) => elt as SvgElement);
//    var elts_all = parent_svg_elt.getIntersectionList(select_box_bbox, null).map((elt) => elt as SvgElement);
//    Set<SvgElement> elts_overlapping = elts_all.where((elt) => elt.classes.contains('selectable')).toSet();

//    Set<SvgElement> elts_overlapping =
//        get_intersection_list(select_box_bbox).map((elt) => elt as SvgElement).toSet();
    Set<SvgElement> elts_overlapping = get_enclosure_list(select_box_bbox).map((elt) => elt as SvgElement).toSet();
//    print('elts_overlapping: $elts_overlapping');

//    Set<Selectable> overlapping_now = {for (var elt in elts_overlapping) selectables_by_id[elt.id]};
    List<Selectable> overlapping_now = [
      for (var elt in elts_overlapping) if (selectables_by_id.containsKey(elt.id)) selectables_by_id[elt.id]
    ];

//    print('elts_overlapping ids: ${[for (var elt in elts_overlapping) elt.id]}');
//    print('overlapping_now:      $overlapping_now');

//    List<Selectable> overlapping_now_select_mode_enabled = [
//      for (var obj in overlapping_now) if (app.model.select_mode_store.is_selectable(obj)) obj
//    ];
    List<Selectable> overlapping_now_select_mode_enabled = [];
    for (var obj in overlapping_now) {
//      print('obj: $obj');
      if (app.state.ui_state.select_mode_state.is_selectable(obj)) {
        overlapping_now_select_mode_enabled.add(obj);
      }
    }

//    Set<Selectable> overlapping_before = Set<Selectable>.from(selectables_overlapping);
//    Set<Selectable> newly_overlapping = overlapping_now.difference(overlapping_before);
//    Set<Selectable> newly_nonoverlapping = overlapping_before.difference(overlapping_now);

//    print('overlapping_now_select_mode_enabled: $overlapping_now_select_mode_enabled');

    if (toggling) {
//      print('toggling  overlapping_now: $overlapping_now');
      Actions_OLD.toggle_all(overlapping_now_select_mode_enabled);
    } else {
//      print('selecting overlapping_now: $overlapping_now');
      Actions_OLD.select_all(overlapping_now_select_mode_enabled);
    }
  }
}

//XXX: code below just checks bounding boxes. for better intersection code maybe use this:
//  https://github.com/thelonious/kld-intersections

// indicates if (l1,h1) intersect (l2,h2) \neq empty
bool intervals_overlap(num l1, num h1, num l2, num h2) {
  return h1 >= l2 && h2 >= l1;
}

// indicates if (l1,h1) \subseteq (l2,h2)
bool interval_contained(num l1, num h1, num l2, num h2) {
  return l1 >= l2 && h1 <= h2;
}

// gets list of elements associated to Selectables that intersect select_box_bbox
List<SvgElement> get_intersection_list(Rect select_box_bbox) {
  return get_generalized_intersection_list(select_box_bbox, intervals_overlap);
}

// gets list of elements associated to Selectables that intersect select_box_bbox
List<SvgElement> get_enclosure_list(Rect select_box_bbox) {
  return get_generalized_intersection_list(select_box_bbox, interval_contained);
}

get_generalized_intersection_list(Rect select_box_bbox, bool overlap(num l1, num h1, num l2, num h2)) {
  List<SvgElement> elts_intersecting = [];
  List<Element> selectable_elts = querySelectorAll('.selectable');
  for (GraphicsElement elt in selectable_elts) {
    Rect elt_bbox = elt.getBBox();
//    util.transform_rect_svg_to_mouse_coord_main_view(elt_bbox);
    if (bboxes_intersect_generalized(elt_bbox, select_box_bbox, overlap)) {
      elts_intersecting.add(elt);
    }
  }
  return elts_intersecting;
}

bool bboxes_intersect_generalized(Rect elt_bbox, Rect select_box_bbox, bool overlap(num l1, num h1, num l2, num h2)) {
  num elt_x2 = elt_bbox.x + elt_bbox.width;
  num select_box_x2 = select_box_bbox.x + select_box_bbox.width;
  num elt_y2 = elt_bbox.y + elt_bbox.height;
  num select_box_y2 = select_box_bbox.y + select_box_bbox.height;
  return overlap(elt_bbox.x, elt_x2, select_box_bbox.x, select_box_x2) &&
      overlap(elt_bbox.y, elt_y2, select_box_bbox.y, select_box_y2);
}
