//part of '../components.dart';

import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/mouseover_data.dart';

import '../model/helix.dart';
import '../app.dart';
import '../util.dart' as util;

part 'design_main_mouseover_rect_helix.over_react.g.dart';

const DEBUG_PRINT_MOUSEOVER = false;
//const DEBUG_PRINT_MOUSEOVER = true;

@Factory()
UiFactory<DesignMainMouseoverRectHelixProps> DesignMainMouseoverRectHelix = _$DesignMainMouseoverRectHelix;

@Props()
class _$DesignMainMouseoverRectHelixProps extends UiProps {
  Helix helix;
//  RemoveMouseoverDataCallback remove_mouseover_data;
//  HandleMousemoveCallback handle_mousemove;
}

@Component()
class DesignMainMouseoverRectHelixComponent extends UiComponent<DesignMainMouseoverRectHelixProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    return (Dom.rect()
      ..className = 'helix-mouseover'
      ..transform = this.props.helix.transform()
      ..x = '0'
      ..y = '0'
      ..width = '${this.props.helix.svg_width()}'
      ..height = '${this.props.helix.svg_height()}'
      ..onMouseLeave = ((_) => this._remove_mouseover_data())
      ..onMouseMove = ((event) => this._handle_mousemove(event)))();
  }

  _remove_mouseover_data() {
    app.model.main_view_ui_model.mouse_over_store.remove_mouseover_data();
  }

  _handle_mousemove(SyntheticMouseEvent event_syn) {
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

    app.model.main_view_ui_model.mouse_over_store
        .update_mouseover_data(MouseoverParameters(helix_idx, offset, forward));
  }
}
