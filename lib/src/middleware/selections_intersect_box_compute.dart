import 'dart:html';
import 'dart:svg';

import 'package:built_collection/built_collection.dart';
import 'package:redux/redux.dart';

import '../state/select_mode.dart';
import '../state/selection_box.dart';
import '../app.dart';
import '../state/selectable.dart';
import '../view/design.dart';
import '../state/app_state.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

//XXX: This seems to require middleware to handle cleanly.
// It seems difficult to put enough state into AppState to reliably detect when one SVG element
// overlaps another in a way that is robust to future changes in how we draw.
// Maybe figure out some way to do this with middleware so the reducer can remain pure.
selections_intersect_box_compute_middleware(Store<AppState> store, action, NextDispatcher next) {
  if (action is actions.SelectionsAdjust) {
    var state = store.state;
    var selectables_store = state.ui_state.selectables_store;
    RectElement select_box = querySelector('#selection-box-main') as RectElement;
    if (select_box == null) {
      return selectables_store;
    }

    Rectangle<num> select_box_bbox = select_box.getBoundingClientRect();

    //XXX: Firefox does not have getIntersectionList or getEnclosureList
    // (no progress for 10 years on that: https://bugzilla.mozilla.org/show_bug.cgi?id=501421)
    // Besides, it didn't work well in Chrome and I basically had to implement it myself based on bounding boxes.

    bool is_origami = state.design.is_origami;
    var select_modes = state.ui_state.select_mode_state.modes;
    Set<SvgElement> elts_overlapping =
        enclosure_list_in_elt(MAIN_VIEW_SVG_ID, select_box_bbox, select_modes, is_origami).toSet();

    var selectable_by_id = state.design.selectable_by_id;
    List<Selectable> overlapping_now = [
      for (var elt in elts_overlapping) if (selectable_by_id.containsKey(elt.id)) selectable_by_id[elt.id]
    ];

    List<Selectable> overlapping_now_select_mode_enabled = [];
    for (var obj in overlapping_now) {
      if (state.ui_state.select_mode_state.is_selectable(obj)) {
        overlapping_now_select_mode_enabled.add(obj);
      }
    }

    app.dispatch(actions.SelectOrToggleItems(
        items: overlapping_now_select_mode_enabled.build(), toggle: action.toggle));
  } else {
    next(action);
  }
}

//// gets list of elements associated to Selectables that intersect select_box_bbox in elements with classname
//List<SvgElement> intersection_list_in_elt(String classname, Rect select_box_bbox) {
//  return generalized_intersection_list_in_elt(classname, select_box_bbox, intervals_overlap);
//}

// gets list of elements associated to Selectables that intersect select_box_bbox in elements with classname
List<SvgElement> enclosure_list_in_elt(String classname, Rectangle<num> select_box_bbox,
    Iterable<SelectModeChoice> select_modes, bool is_origami) {
  return generalized_intersection_list_in_elt(
      classname, select_box_bbox, select_modes, is_origami, interval_contained);
}

//XXX: It's simpler to check whether the bounding rectangle in "browser viewport coordinates",
// i.e., elt.getBoundingClientRect()
// (instead of "transformed SVG coordinates") contains the getBoundingClientRect() rectangle of the
// selection box. Here's why it's not straightforward to use getBBox() for both, even though that was
// sufficient before we implemented HelixGroups and the ability to transform them.
//
// Three kinds of GraphicsElements are selectable:
// - strands (SVG g object)
// - loopouts/crossovers (SVG path)
// - DNA ends (SVG rect and polygon)
//
// Strands have no transform applied to them, other than the one applied to the whole g element directly
// under the svgsvg element, which is also applied to the selection box, so no need to correct for that.
//   (CSS class "strand")
//
// Loopouts and crossovers have a transform applied directly to their path
//   (CSS class "loopout-curve" or "crossover-curve")
//
// DNAEnds have a transform applied to the parent group
//   (CSS class "dna-ends")
//
// We cannot simply try to use getCtm() to undo these transforms on these specific elements, because that
// would also undo all transforms all the way up to the root SVG element. But the selection box itself
// had the top-level g transform (for panning and zooming) applied to it. So the simplest thing is just
// to call getBoundingClientRect() on *everything*, which essentially untransforms all of them all the
// way up to the root of the whole DOM and gives absolute coordinates within the browser's viewport.

generalized_intersection_list_in_elt(String classname, Rectangle<num> select_box_bbox,
    Iterable<SelectModeChoice> select_modes, bool is_origami, bool overlap(num l1, num h1, num l2, num h2)) {
  List<SvgElement> elts_intersecting = [];
  List<Element> selectable_elts = find_selectable_elements(select_modes, is_origami);

  for (GraphicsElement elt in selectable_elts) {
    Rectangle<num> elt_bbox = elt.getBoundingClientRect();
    if (bboxes_intersect_generalized(elt_bbox, select_box_bbox, overlap)) {
      elts_intersecting.add(elt);
    }
  }
  return elts_intersecting;
}

List<Element> find_selectable_elements(Iterable<SelectModeChoice> select_modes, bool is_origami) {
  List<SelectModeChoice> select_modes_not_scaffold_or_staple = [
    for (var mode in select_modes)
      if (mode != SelectModeChoice.scaffold && mode != SelectModeChoice.staple) mode
  ];
  if (select_modes_not_scaffold_or_staple.isEmpty) {
    return [];
  }

  List<String> selectors = [];
  if (is_origami &&
      (!select_modes.contains(SelectModeChoice.scaffold) ||
          !select_modes.contains(SelectModeChoice.staple))) {
    if (select_modes.contains(SelectModeChoice.scaffold)) {
      for (var mode in select_modes_not_scaffold_or_staple) {
        selectors.add('.${SelectModeChoice.scaffold.css_selector()}.${mode.css_selector()}');
      }
    } else if (select_modes.contains(SelectModeChoice.staple)) {
      for (var mode in select_modes) {
        selectors.add(':not(.${SelectModeChoice.scaffold.css_selector()}).${mode.css_selector()}');
      }
    }
  } else {
    // not origami, but origami and both scaffold and staples are selectable, just select anything
    // with the correct mode. Otherwise use the more complex logic above to pick apart between
    // parts marked as scaffold versus those that are not.
    for (var mode in select_modes_not_scaffold_or_staple) {
      selectors.add('.${mode.css_selector()}');
    }
  }
  List<Element> selectable_elts = querySelectorAll(selectors.join(', '));
  return selectable_elts;
}

bool bboxes_intersect_generalized(
    Rectangle<num> elt_bbox, Rectangle<num> select_box_bbox, bool overlap(num l1, num h1, num l2, num h2)) {
  num elt_x2 = elt_bbox.left + elt_bbox.width;
  num select_box_x2 = select_box_bbox.left + select_box_bbox.width;
  num elt_y2 = elt_bbox.top + elt_bbox.height;
  num select_box_y2 = select_box_bbox.top + select_box_bbox.height;
  return overlap(elt_bbox.left, elt_x2, select_box_bbox.left, select_box_x2) &&
      overlap(elt_bbox.top, elt_y2, select_box_bbox.top, select_box_y2);
}

// indicates if real line interval (l1,h1) \subseteq (l2,h2)
bool interval_contained(num l1, num h1, num l2, num h2) {
  return l1 >= l2 && h1 <= h2;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// intersection geometry

class Box {
  num height;
  num width;
  num x;
  num y;

  factory Box.from(Rect svg_rect) =>
      Box(svg_rect.x, svg_rect.y, width: svg_rect.width, height: svg_rect.height);

  factory Box.from_selection_box(SelectionBox box) => Box(box.x, box.y, width: box.width, height: box.height);

  Box(this.x, this.y, {num height = null, num width = null, num x2 = null, num y2 = null}) {
    if (width == null && x2 == null) {
      throw ArgumentError('at least one of height or x2 must be non-null');
    } else if (x2 == null) {
      this.width = width;
    } else if (width == null) {
      this.width = x2 - x;
    }

    if (height == null && y2 == null) {
      throw ArgumentError('at least one of height or x2 must be non-null');
    } else if (y2 == null) {
      this.height = height;
    } else if (height == null) {
      this.height = y2 - y;
    }
  }

  num get x2 => x + width;

  num get y2 => y + height;

  set x2(num x2new) {
    width = x2new - x;
  }

  set y2(num y2new) {
    height = y2new - y;
  }
}

// gets list of elements associated to Selectables that intersect select_box_bbox
List<E> intersection_list<E>(List<E> elts, List<Box> bboxes, Box select_box) =>
    generalized_intersection_list(elts, bboxes, select_box, intervals_overlap);

// gets list of elements associated to Selectables that intersect select_box_bbox
List<E> enclosure_list<E>(Iterable<E> elts, List<Box> bboxes, Box select_box) =>
    generalized_intersection_list(elts, bboxes, select_box, interval_contained);

// indicates if (l1,h1) intersect (l2,h2) \neq empty
bool intervals_overlap(num l1, num h1, num l2, num h2) {
  return h1 >= l2 && h2 >= l1;
}

List<E> generalized_intersection_list<E>(
    Iterable<E> elts, List<Box> bboxes, Box select_box, bool overlap(num l1, num h1, num l2, num h2)) {
  if (elts.length != bboxes.length) {
    throw ArgumentError(
        'elts (length ${elts.length}) and bboxes (length ${bboxes.length}) must have same length');
  }
  List<E> elts_intersecting = [];
//  for (int i = 0; i < elts.length; i++) {
  int i = 0;
  for (E elt in elts) {
    Box elt_bbox = bboxes[i++];
    if (boxes_intersect_generalized(elt_bbox, select_box, overlap)) {
      elts_intersecting.add(elt);
    }
  }
  return elts_intersecting;
}

bool boxes_intersect_generalized(Box elt_bbox, Box select_box, bool overlap(num l1, num h1, num l2, num h2)) {
  num elt_x2 = elt_bbox.x + elt_bbox.width;
  num select_box_x2 = select_box.x + select_box.width;
  num elt_y2 = elt_bbox.y + elt_bbox.height;
  num select_box_y2 = select_box.y + select_box.height;
  return overlap(elt_bbox.x, elt_x2, select_box.x, select_box_x2) &&
      overlap(elt_bbox.y, elt_y2, select_box.y, select_box_y2);
}
