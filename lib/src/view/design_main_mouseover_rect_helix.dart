//part of '../components.dart';

import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/edit_mode.dart';

import '../state/app_state.dart';
import '../app.dart';
import '../state/mouseover_data.dart';
import '../state/helix.dart';
import '../util.dart' as util;
import '../actions/actions.dart' as actions;
import 'design_main_helix.dart';

part 'design_main_mouseover_rect_helix.over_react.g.dart';

const _ID_PREFIX = 'helix-mouseover';
const _CLASS = 'helix-mouseover';

const DEBUG_PRINT_MOUSEOVER = false;
//const DEBUG_PRINT_MOUSEOVER = true;

UiFactory<DesignMainMouseoverRectHelixProps> ConnectedDesignMainMouseoverRectHelix =
    connect<AppState, DesignMainMouseoverRectHelixProps>(mapStateToPropsWithOwnProps: (state, props) {
  Helix helix = state.dna_design.helices[props.helix_idx];
  BuiltList<MouseoverData> mouseover_datas = state.ui_state.mouseover_datas;
  bool show = state.ui_state.edit_modes.contains(EditModeChoice.backbone);
  return DesignMainMouseoverRectHelix()
    ..helix = helix
    ..show = show
    ..mouseover_datas = mouseover_datas;
})(DesignMainMouseoverRectHelix);


UiFactory<DesignMainMouseoverRectHelixProps> DesignMainMouseoverRectHelix = _$DesignMainMouseoverRectHelix;


mixin DesignMainMouseoverRectHelixProps on UiProps {
  int helix_idx;
  Helix helix;
  bool show;
  BuiltList<MouseoverData> mouseover_datas;
}


class DesignMainMouseoverRectHelixComponent extends UiComponent2<DesignMainMouseoverRectHelixProps> {
  @override
  bool shouldComponentUpdate(Map nextProps, Map nextState) {
    Helix helix = nextProps['DesignMainMouseoverRectHelixProps.helix'];
    bool show = nextProps['DesignMainMouseoverRectHelixProps.show'];
    return !(helix == props.helix && show == props.show);
  }

  @override
  render() {
    Helix helix = props.helix;

    String id = '$_ID_PREFIX-${helix.idx}';

    var width = helix.svg_width();
    var height = helix.svg_height();
    Point<num> translation = helix_main_view_translation(helix);

    return (Dom.rect()
      ..transform = 'translate(${translation.x} ${translation.y})'
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
  app.dispatch(actions.MouseoverDataClear());
}

update_mouseover(SyntheticMouseEvent event_syn, Helix helix, BuiltList<MouseoverData> mouseover_datas) {
  MouseEvent event = event_syn.nativeEvent;
  var address = util.get_address_on_helix(event, helix);
  int offset = address.offset;
  bool forward = address.forward;

  if (DEBUG_PRINT_MOUSEOVER) {
    Point<num> pan = util.current_pan(true);
    num zoom = util.current_zoom(true);
    print('mouse event: '
        'x = ${event.offset.x},   '
        'y = ${event.offset.y},   '
        'pan = (${pan.x.toStringAsFixed(2)}, ${pan.y.toStringAsFixed(2)}),   '
        'zoom = ${zoom.toStringAsFixed(2)},   '
//        'svg_x = ${svg_x.toStringAsFixed(2)},   '
//        'svg_y = ${svg_y.toStringAsFixed(2)},   '
        'helix = ${helix.idx},   '
        'offset = ${offset},   '
        'forward = ${forward}');
  }

  var mouseover_params = MouseoverParams(helix.idx, offset, forward);

  if (needs_update(mouseover_params, mouseover_datas)) {
//    print('dispatching MouseoverDataUpdate from DesignMainMouseoverRectHelix for helix ${helix.idx}');
    app.dispatch(
        actions.MouseoverDataUpdate(mouseover_params: BuiltList<MouseoverParams>([mouseover_params])));
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
        mouseover_data.domain?.forward == mouseover_params.forward) {
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

