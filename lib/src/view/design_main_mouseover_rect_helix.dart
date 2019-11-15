//part of '../components.dart';

import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:tuple/tuple.dart';
import 'package:built_collection/built_collection.dart';

import '../model/dna_design.dart';
import '../model/model.dart';
import '../app.dart';
import '../dispatcher/actions_OLD.dart';
import '../model/mouseover_data.dart';
import '../model/helix.dart';
import '../util.dart' as util;
import '../dispatcher/actions.dart' as actions;

part 'design_main_mouseover_rect_helix.over_react.g.dart';

const _ID_PREFIX = 'helix-mouseover';
const _CLASS = 'helix-mouseover';

const DEBUG_PRINT_MOUSEOVER = false;
//const DEBUG_PRINT_MOUSEOVER = true;

//UiFactory<_$DesignMainMouseoverRectHelixProps> ConnectedDesignMainMouseoverRectHelix =
//    connect<Model, _$DesignMainMouseoverRectHelixProps>(
//  mapStateToProps: (model) => (DesignMainMouseoverRectHelix()..dna_design = model.dna_design),
//)(DesignMainMouseoverRectHelix);

@Factory()
UiFactory<DesignMainMouseoverRectHelixProps> DesignMainMouseoverRectHelix = _$DesignMainMouseoverRectHelix;

@Props()
class _$DesignMainMouseoverRectHelixProps extends UiProps {
//  DNADesign dna_design;
  Helix helix;
}

@Component2()
class DesignMainMouseoverRectHelixComponent extends UiComponent2<DesignMainMouseoverRectHelixProps> {

  @override
  render() {
    String id = '$_ID_PREFIX-${this.props.helix.idx}';
    Helix helix = this.props.helix;

    var width = helix.svg_width();
    var height = helix.svg_height();
    return (Dom.rect()
      ..transform = this.props.helix.translate()
      ..x = '0'
      ..y = '0'
      ..width = '$width'
      ..height = '$height'
      ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
      ..onMouseMove = ((event) => update_mouseover(event, helix))
      ..id = id
      ..className = _CLASS)();
  }
}

mouse_leave_update_mouseover() {
  app.store.dispatch(actions.MouseoverDataClear());
//  Actions.remove_mouseover_data();
}

update_mouseover(SyntheticMouseEvent event_syn, Helix helix) {
//FIXME: what's the proper way to do this?
  DNADesign dna_design = app.model.dna_design;

  MouseEvent event = event_syn.nativeEvent;

  //XXX: don't know why I need to correct for this here, but not when responding to a selection box mouse event
  // might be related to the fact that the mouse coordinates for the selection box are detected outside of React
  var svg_coord;
  if (browser.isFirefox) {
    svg_coord = event.offset;
  } else {
    svg_coord = util.transform_mouse_coord_to_svg_current_panzoom_main(event.offset);
  }
  num svg_x = svg_coord.x;
  num svg_y = svg_coord.y;

  int helix_idx = helix.idx;
  int offset = helix.svg_x_to_offset(svg_x);
  bool forward = helix.svg_y_is_forward(svg_y);

  if (DEBUG_PRINT_MOUSEOVER) {
    Point<num> pan = util.current_pan_main();
    num zoom = util.current_zoom_main();
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

  app.store.dispatch(actions.MouseoverDataUpdate(
      dna_design, BuiltList<Tuple3<int, int, bool>>([Tuple3(helix_idx, offset, forward)])));
//    var params = MouseoverParameters(BuiltList<Tuple3<int, int, bool>>([Tuple3(helix_idx, offset, forward)]));
//  Actions.update_mouseover_data(params);
}
