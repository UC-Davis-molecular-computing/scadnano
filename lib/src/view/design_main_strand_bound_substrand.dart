import 'dart:html';
import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/select_mode.dart';

import '../dispatcher/actions_OLD.dart';
import '../model/helix.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import '../app.dart';
import 'design_main_mouseover_rect_helix.dart';
import '../util.dart' as util;

part 'design_main_strand_bound_substrand.over_react.g.dart';

@Factory()
UiFactory<DesignMainBoundSubstrandProps> DesignMainBoundSubstrand = _$DesignMainBoundSubstrand;

@Props()
class _$DesignMainBoundSubstrandProps extends UiProps {
  BoundSubstrand substrand;
  Color color;
}

// There's a bit of a lag re-rendering the whole strand just to change its class to "hover", so we
// go around React when _OPTIMIZE=true and set the class directly by querying the element by ID.
const _OPTIMIZE = true;
//const _OPTIMIZE = false;

@Component2()
class DesignMainBoundSubstrandComponent extends UiComponent2<DesignMainBoundSubstrandProps> {
//  @override
//  Map getDefaultProps() => (newProps());

//  @override
//  bool shouldComponentUpdate(Map nextProps, Map nextState) {
//    BoundSubstrand substrand = props.substrand;
//    BoundSubstrand next_substrand = nextProps['DesignMainStrandProps.substrand'];
//
//    bool should = substrand != next_substrand;
////    print('shouldComponentUpdate() for strand ${strand.toString()}');
////    print(' prev_selected: $prev_selected');
////    print(' next_selected: $next_selected');
//    return should;
//  }


  @override
  render() {
//    BoundSubstrand substrand = this.props.store;
    BoundSubstrand substrand = this.props.substrand;
    String id = substrand.id();

    Helix helix = app.model.dna_design.helices[substrand.helix];
    Point<num> start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
    Point<num> end_svg = helix.svg_base_pos(substrand.offset_3p, substrand.forward);

    return (Dom.line()
      ..onMouseMove = ((event) => update_mouseover(event, helix.idx))
      ..stroke = props.color.toRgbColor().toCssString()
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..key = id
      ..id = id
      ..className = 'substrand-line')();
  }
}
