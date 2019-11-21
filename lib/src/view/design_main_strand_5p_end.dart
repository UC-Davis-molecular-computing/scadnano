import 'package:color/color.dart';
import 'package:dnd/dnd.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/select_mode.dart';
import 'package:scadnano/src/model/strand.dart';

import '../model/bound_substrand.dart';
import '../app.dart';
import '../util.dart' as util;
import 'design_main.dart';
import 'design_main_mouseover_rect_helix.dart';
import 'react_dnd.dart';

part 'design_main_strand_5p_end.over_react.g.dart';

@Factory()
UiFactory<DesignMain5pEndProps> DesignMain5pEnd = _$DesignMain5pEnd;

@Props()
class _$DesignMain5pEndProps extends UiProps {
  //FluxUiProps<BoundSubstrand, BoundSubstrand> {
  BoundSubstrand substrand;
  bool is_first_substrand;
  Color color;
}

@Component2()
class DesignMain5pEndComponent extends UiComponent2<DesignMain5pEndProps> {
  // UiComponent<DesignMain5pEndProps> {
//  @override
//  Map getDefaultProps() => (newProps());

//  @override
//  void componentDidMount() {
//    super.componentDidMount();
////    Draggable draggable =
//  }

  @override
  render() {
    BoundSubstrand substrand = this.props.substrand;

    bool is_first_substrand = this.props.is_first_substrand;
    var id = substrand.dnaend_5p.id();

    var helix = app.model.dna_design.helices[substrand.helix];
    var offset = substrand.offset_5p;
    var right = substrand.forward;
    var pos = helix.svg_base_pos(offset, right);

    var classname = 'five-prime-end' + (is_first_substrand ? '-first-substrand' : '');
//    if (substrand.selected_5p()) {
    if (substrand.dnaend_5p.selected()) {
      classname += ' selected';
    }
    if (is_first_substrand &&
            app.model.ui_model.select_mode_state.modes.contains(SelectModeChoice.end_5p_strand) ||
        !is_first_substrand &&
            app.model.ui_model.select_mode_state.modes.contains(SelectModeChoice.end_5p_substrand)) {
      classname += ' selectable';
    }

    //XXX: width, height, rx, ry should be do-able in CSS. However, Firefox won't display properly
    // if they are specified in CSS, but it will if they are specified here.

    Strand strand = app.model.dna_design.substrand_to_strand[substrand];

    //[{ isDragging }, drag]
    if (USING_REACT_DND) {
      var param = {
        'item': {'type': '5p'},
        'collect': (monitor) => {
              'isDragging': monitor.isDragging(),
            },
      };
      List drag_ret = useDrag(param);
      var props = drag_ret[0];
      var drag = drag_ret[1];
      bool isDragging = props['isDragging'];
    } else {
      //TODO: replace string-based prop setting below when OverReact repo is updated to include typed properties
      SvgProps attr = (Dom.rect()
//      ..onMouseDown = substrand.dnaend_5p.handle_selection
        ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
        ..onMouseMove = ((event) => update_mouseover(event, helix.idx))
        ..onPointerDown = substrand.dnaend_5p.handle_selection
        ..className = classname
        ..x = '${pos.x - 3.5}'
        ..y = '${pos.y - 3.5}'
        ..width = '7px'
        ..height = '7px'
        ..rx = '1.5px'
        ..ry = '1.5px'
        ..fill = strand.color.toRgbColor().toCssString()
        ..id = id);
      return attr();
    }
  }
}
