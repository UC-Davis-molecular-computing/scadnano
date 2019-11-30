//part of '../components.dart';

import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:built_collection/built_collection.dart';

import '../model/model.dart';
import '../app.dart';
import '../model/mouseover_data.dart';
import '../model/helix.dart';
import '../util.dart' as util;
import '../actions/actions.dart' as actions;

part 'design_main_mouseover_rect_helix.over_react.g.dart';

const _ID_PREFIX = 'helix-mouseover';
const _CLASS = 'helix-mouseover';

const DEBUG_PRINT_MOUSEOVER = false;
//const DEBUG_PRINT_MOUSEOVER = true;

UiFactory<DesignMainMouseoverRectHelixProps> ConnectedDesignMainMouseoverRectHelix =
    connect<Model, DesignMainMouseoverRectHelixProps>(mapStateToPropsWithOwnProps: (model, props) {
  Helix helix = model.dna_design.helices[props.helix_idx];
  BuiltList<MouseoverData> mouseover_datas = model.ui_model.mouseover_datas;
//  print('ConnectedDesignMainMouseoverRectHelix connect');
//  print('  model.ui_model.mouseover_datas: ${model.ui_model.mouseover_datas}');
  bool show = model.ui_model.show_mouseover_rect;
  return DesignMainMouseoverRectHelix()
    ..helix = helix
    ..show = show
    ..mouseover_datas = mouseover_datas;
})(DesignMainMouseoverRectHelix);

@Factory()
UiFactory<DesignMainMouseoverRectHelixProps> DesignMainMouseoverRectHelix = _$DesignMainMouseoverRectHelix;

@Props()
class _$DesignMainMouseoverRectHelixProps extends UiProps {
  int helix_idx;
  Helix helix;
  bool show;
  BuiltList<MouseoverData> mouseover_datas;
}

@Component2()
class DesignMainMouseoverRectHelixComponent extends UiComponent2<DesignMainMouseoverRectHelixProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    int helix_idx = props.helix_idx;
    int helix_idx_next = nextProps['DesignMainMouseoverRectHelixProps.helix_idx'];
    bool show = props.show;
    bool show_next = nextProps['DesignMainMouseoverRectHelixProps.show'];
    return !(helix_idx == helix_idx_next && show == show_next);
  }

  @override
  render() {
//    print('rendering DesignMainMouseoverRectHelix');
    Helix helix = props.helix;
    BuiltList<MouseoverData> mouseover_datas = props.mouseover_datas;

    String id = '$_ID_PREFIX-${helix.idx}';

    var width = helix.svg_width();
    var height = helix.svg_height();
    return (Dom.rect()
      ..transform = helix.translate()
      ..x = '0'
      ..y = '0'
      ..width = '$width'
      ..height = '$height'
      ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
      //XXX: it matters that we reference props.mouseover_datas, not a local variable
      // this ensures that when subsequent mouse events happen, the most recent mouseover_datas is examined,
      // otherwise the callback is not updated until render executes again
      ..onMouseEnter = ((event) => update_mouseover(event, helix, props.mouseover_datas))
      ..onMouseMove = ((event) => update_mouseover(event, helix, props.mouseover_datas))
      ..id = id
      ..className = _CLASS)();
  }
}

mouse_leave_update_mouseover() {
  app.store.dispatch(actions.MouseoverDataClear());
}

update_mouseover(SyntheticMouseEvent event_syn, Helix helix, BuiltList<MouseoverData> mouseover_datas) {

  MouseEvent event = event_syn.nativeEvent;

  //XXX: don't know why I need to correct for this here, but not when responding to a selection box mouse event
  // might be related to the fact that the mouse coordinates for the selection box are detected outside of React
  var svg_coord;
  if (browser.isFirefox) {
    svg_coord = event.offset;
  } else {
    svg_coord = util.transform_mouse_coord_to_svg_current_panzoom(event.offset, true);
  }
  num svg_x = svg_coord.x;
  num svg_y = svg_coord.y;

  int offset = helix.svg_x_to_offset(svg_x);
  bool forward = helix.svg_y_is_forward(svg_y);

  if (DEBUG_PRINT_MOUSEOVER) {
    Point<num> pan = util.current_pan(true);
    num zoom = util.current_zoom_main();
    print('mouse event: '
        'x = ${event.offset.x},   '
        'y = ${event.offset.y},   '
        'pan = (${pan.x.toStringAsFixed(2)}, ${pan.y.toStringAsFixed(2)}),   '
        'zoom = ${zoom.toStringAsFixed(2)},   '
        'svg_x = ${svg_x.toStringAsFixed(2)},   '
        'svg_y = ${svg_y.toStringAsFixed(2)},   '
        'helix = ${helix.idx},   '
        'offset = ${offset},   '
        'forward = ${forward}');
  }

  var mouseover_params = MouseoverParams(helix.idx, offset, forward);

  //FIXME
  var dna_design = app.model.dna_design;

  if (needs_update(mouseover_params, mouseover_datas)) {
//    print('dispatching MouseoverDataUpdate from DesignMainMouseoverRectHelix for helix ${helix.idx}');
    app.store.dispatch(
        actions.MouseoverDataUpdate(dna_design, BuiltList<MouseoverParams>([mouseover_params])));
  } else {
//    print('skipping MouseoverDataUpdate from DesignMainMouseoverRectHelix for helix ${helix.idx}');
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
        mouseover_data.substrand?.forward == mouseover_params.forward) {
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

