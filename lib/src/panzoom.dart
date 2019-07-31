import 'dart:html';
import 'dart:svg' hide Point;
import 'dart:math';

import 'package:dnd/dnd.dart';

const String _PANZOOMABLE_CLASS = 'panzoomable';
const String _DRAGGING_CLASS_NAME = 'dragging';

//TODO: replace this with https://github.com/ariutta/svg-pan-zoom

//TODO: the translation is terrible/jerky on Firefox and Edge, and the scaling
// was too slow on Firefox. Maybe bring in zoomspeed for scaling issue.
// Not sure what to do about bad translation.

String make_transform_attribute(double scale, Point<num> translation) =>
//XXX: the following means scale, THEN translate. So all translations are by a scaled amount.
    "translate(${translation.x} ${translation.y}) scale($scale)";

//XXX: the following means translate, THEN scale. So all scalings are with the origin moved.
//    "scale($scale) translate(${translation.x} ${translation.y})";

/// Wrapper around an SVG group element (<g> in HTML; GElement in dart:svg)
/// that makes it pannable by clicking with the mouse and dragging,
/// and zoomable with the mouse wheel (or two-finger scroll with touchpad).
/// The underlying element is accessible via this.element.
class PanzoomableSvgElement {
  double _scale;
  Point<num> _translation;
  bool _dragging = false;

  SvgSvgElement element;
  GElement _groupElement;
  Draggable draggable;

//  SvgElement _subElement;

  // These are used for communicating between dragStart and drag mouse
  // handler local functions.
  Point<num> start_translation;
  Point<num> startMousePosition;

  // used to disable dragging when Ctrl key pressed
  bool _startDragEnabled = true;

  static const ORIGIN = Point<num>(0, 0);

  PanzoomableSvgElement(SvgElement child_elt, String id,
      {double init_scale = 1, Point<num> init_translation = ORIGIN}) {
    _scale = init_scale;
    _translation = init_translation;

    element = SvgSvgElement();
    element.attributes = {
      'id': id,
      'class': _PANZOOMABLE_CLASS,
      'width': '100%',
      'height': '100%',
//      'shape-rendering': 'optimizeSpeed', //doesn't seem to speed things up noticably
    };
    element.onWheel.listen(zoom);

    // These are needed because Draggable doesn't start dragging until the
    // move has moved 4 pixels, but I want the cursor hand to close as soon
    // as the mouse button is pressed.
    // However, they don't work because Draggable stops onMouse* events.
//    element.parent.onMouseDown.listen((MouseEvent e) {
//      print('mouse down');
//      element.classes.add(_DRAGGING_CLASS_NAME);
//    });
//    element.parent.onMouseUp.listen((MouseEvent e) {
//      print('mouse up');
//      element.classes.remove(_DRAGGING_CLASS_NAME);
//    });

    //XXX: the way I use the Draggable library seems like it should do the
    // same thing as just using onMouseDown, onMouseMove, etc. However
    // there are cross-browser issues, and the onMouse* stuff only works nicely
    // in Chrome and makes horrible jerky movements in Firefox and Edge. This
    // solution crashes in Edge but works fine in Firefox. Need to test it on
    // Safari still.
    Draggable draggable =
        new Draggable(element, draggingClass: _DRAGGING_CLASS_NAME, minDragStartDistance: 0);
    draggable.onDragStart.listen(drag_start);
    draggable.onDrag.listen(drag);
    draggable.onDragEnd.listen(drag_end);

    // prevent dragging if Ctrl key pressed
    document.body.onKeyDown.listen((KeyboardEvent event) {
      if (event.ctrlKey) {
        _startDragEnabled = false;
      }
    });
    document.body.onKeyUp.listen((KeyboardEvent event) {
      _startDragEnabled = true;
    });

    _groupElement = GElement();
    _groupElement.attributes = {
      'transform': make_transform_attribute(_scale, _translation),
    };
    element.children.add(_groupElement);

    _groupElement.children.add(child_elt);
  }

  zoom(WheelEvent event) {
    double old_scale = _scale;
    double scroll_amount = event.deltaY;
//    print('scrollAmount: $scrollAmount');
    //TODO: come up with a better scheme. This ignores the magnitude of
    // event.deltaY, taking all single mouse wheel
    // movements as equal, due to there being a large difference in
    // event.deltaY between Chrome and Firefox. (much smaller in Firefox)
//    double absScrollAmount = scrollAmount.abs();
//    double scaleFactor = 1 + 0.001 * absScrollAmount;
    double scale_factor = 1.1;
    double new_scale_unclamped;
    if (scroll_amount < 0) {
      new_scale_unclamped = old_scale * scale_factor;
    } else {
      new_scale_unclamped = old_scale / scale_factor;
    }
    double new_scale = new_scale_unclamped.clamp(0.1, 10);

    double scale_ratio = new_scale / old_scale;

    // This was difficult to get right. Be CAREFUL before changing any of it.
    // Recall that the interpretation of
    //   <g transform="translate(x y) scale(s)">...</g>
    // is in reverse: FIRST scale, THEN translate. So the translation after
    // scaling in (magnified, i.e. s>1), for instance, is less than it would
    // be if translating by the same vector (x,y) when unscaled.
    Point<num> old_translation = _translation;
    Point<num> mouse_offset = event.offset;
    Point<num> mouse_offset_after_this_rescaling = mouse_offset * scale_ratio;
    Point<num> mouse_delta_after_this_rescaling = mouse_offset_after_this_rescaling - mouse_offset;
    Point<num> new_translation = old_translation * (scale_ratio) - mouse_delta_after_this_rescaling;

    _scale = new_scale;
    _translation = new_translation;
    _groupElement.attributes['transform'] = make_transform_attribute(_scale, _translation);
  }

  Point<num> currentMouseOffset;

  update_mouse_offset(MouseEvent e) {
    currentMouseOffset = e.offset;
  }

  // Listen to drag start.
  drag_start(DraggableEvent event) {
    if (_startDragEnabled) {
      this.start_translation = _translation;
      startMousePosition = event.position;
      _dragging = true;
    }
  }

  // Listen to drag.
  drag(DraggableEvent event) {
    if (_dragging) {
      Point<num> current_translation = event.position;
      Point<num> delta = current_translation - startMousePosition;
      Point<num> new_translation = this.start_translation + delta;
      // delta is scaled and so is the translation
      _translation = new_translation;
      _groupElement.attributes['transform'] = make_transform_attribute(_scale, _translation);
    }
  }

  drag_end(DraggableEvent event) {
    _dragging = false;
  }
}
