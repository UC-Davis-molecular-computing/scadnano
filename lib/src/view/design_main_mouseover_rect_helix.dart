//part of '../components.dart';

import 'dart:html';
import 'dart:math';
import 'dart:svg' hide Point;

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:scadnano/src/model/mouseover_data.dart';
import 'package:scadnano/src/view/design.dart';

import '../model/helix.dart';
import '../util.dart' as util;

part 'design_main_mouseover_rect_helix.over_react.g.dart';

const _ID_PREFIX = 'helix-mouseover';
const _CLASS = 'helix-mouseover';

const DEBUG_PRINT_MOUSEOVER = false;
//const DEBUG_PRINT_MOUSEOVER = true;

@Factory()
UiFactory<DesignMainMouseoverRectHelixProps> DesignMainMouseoverRectHelix = _$DesignMainMouseoverRectHelix;

@Props()
class _$DesignMainMouseoverRectHelixProps extends UiProps {
  Helix helix;
}

@Component()
class DesignMainMouseoverRectHelixComponent extends UiComponent<DesignMainMouseoverRectHelixProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    String id = '$_ID_PREFIX-${this.props.helix.idx()}';
    return (Dom.rect()
      ..id = id
      ..className = _CLASS
      ..transform = this.props.helix.translate()
      ..x = '0'
      ..y = '0'
      ..width = '${this.props.helix.svg_width()}'
      ..height = '${this.props.helix.svg_height()}'
      ..onMouseDown = this._dispatch_mouse_click_to_covered_elts
      ..onMouseLeave = ((_) => this._handle_mouse_leave())
      ..onMouseMove = ((event) => this._handle_mousemove(event, id)))();
  }

  _handle_mouse_leave() {
    Actions.remove_mouseover_data();
    for (SvgElement elt_removed in this._elts_covered) {
      elt_removed.classes.remove('hover');
//      print('  removed ${elt_removed.id}');
    }
    this._elts_covered.clear();
  }

  _handle_mousemove(SyntheticMouseEvent event_syn, String id) {
    MouseEvent event = event_syn.nativeEvent;
    Point<num> pan = util.current_pan();
    num zoom = util.current_zoom();

    var svg_coord = util.transform(event.offset, pan, zoom);
    num svg_x = svg_coord.x;
    num svg_y = svg_coord.y;

    int helix_idx = this.props.helix.idx();
    int offset = this.props.helix.svg_x_to_offset(svg_x);
    bool forward = this.props.helix.svg_y_is_forward(svg_y);

    if (DEBUG_PRINT_MOUSEOVER) {
      print('mouse event: '
          'x = ${event.offset.x},   '
          'y = ${event.offset.y},   '
          'pan = (${pan.x.toStringAsFixed(2)}, ${pan.y.toStringAsFixed(2)}),   '
          'zoom = ${zoom.toStringAsFixed(2)},   '
          'svg_x = ${svg_x.toStringAsFixed(2)},   '
          'svg_y = ${svg_y.toStringAsFixed(2)},   '
          'helix = ${helix_idx},   '
          'offset = ${offset},   '
          'forward = ${forward}');
    }

    Actions.update_mouseover_data(MouseoverParameters(helix_idx, offset, forward));

    _mouse_move_svg_elts_at_same_position(event_syn, id);
  }

  Set _elts_covered = Set<SvgElement>();

  _mouse_move_svg_elts_at_same_position(SyntheticMouseEvent event, String id) {
    var elts = document.elementsFromPoint(event.clientX, event.clientY);
    var svg_elt = querySelector('#${MAIN_VIEW_SVG_ID}');
    int idx_svg_elt = elts.indexOf(svg_elt);

    var new_elts = elts.sublist(0, idx_svg_elt).toSet();
    var this_elt = querySelector('#$id');
    new_elts.remove(this_elt);
    var old_elts = Set<SvgElement>.from(this._elts_covered);

    var elts_added = new_elts.difference(old_elts);
    var elts_removed = old_elts.difference(new_elts);

    for (SvgElement elt_added in elts_added) {
      elt_added.classes.add('hover');
//      print('  added   ${elt_added.id}');
    }
    for (SvgElement elt_removed in elts_removed) {
      elt_removed.classes.remove('hover');
//      print('  removed ${elt_removed.id}');
    }

    this._elts_covered = new_elts;
  }

  _dispatch_mouse_click_to_covered_elts(SyntheticMouseEvent event_syn) {
    MouseEvent event_orig = event_syn.nativeEvent;
    //XXX: since React does all event listening at the DOM root, we cannot send another event of the same
    // type (mousedown) without inadvertently tripping the double-click handler in svg-pan-zoom. So we use
    // this hack to send a mouseup, which must be detected by the covered SVG elts.
    MouseEvent event = MouseEvent(
      'mouseup', //XXX: see comment above
      view: event_orig.view,
      detail: event_orig.detail,
      screenX: event_syn.screenX,
      screenY: event_syn.screenY,
      clientX: event_syn.clientX,
      clientY: event_syn.clientY,
      button: event_orig.button,
      canBubble: true, //XXX: stopImmediatePropagation didn't work to stop double-click, but this did
      //canBubble: event_orig.canBubble, // doesn't work with event_syn or event_orig
//      cancelable: true,
      cancelable: event_orig.cancelable,
      ctrlKey: event_orig.ctrlKey,
      altKey: event_orig.altKey,
      shiftKey: event_orig.shiftKey,
      metaKey: event_orig.metaKey,
      relatedTarget: event_orig.relatedTarget,
    );

    for (SvgElement elt in this._elts_covered) {
      elt.dispatchEvent(event);
//      elt.click(); // doesn't work with SVG elements; but we can do it manually as above
    }
  }
}
