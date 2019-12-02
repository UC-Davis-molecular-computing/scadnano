import 'dart:html';
import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';

import '../model/helix.dart';
import '../model/bound_substrand.dart';
import '../app.dart';
import '../model/app_state.dart';

part 'design_main_strand_bound_substrand.over_react.g.dart';

UiFactory<DesignMainBoundSubstrandProps> ConnectedDesignMainBoundSubstrand =
    connect<AppState, DesignMainBoundSubstrandProps>(mapStateToPropsWithOwnProps: (state, props) {
  Helix helix = state.dna_design.helices[props.substrand.helix];
  return DesignMainBoundSubstrand()..helix = helix;
})(DesignMainBoundSubstrand);

@Factory()
UiFactory<DesignMainBoundSubstrandProps> DesignMainBoundSubstrand = _$DesignMainBoundSubstrand;

@Props()
class _$DesignMainBoundSubstrandProps extends UiProps {
  BoundSubstrand substrand;
  Color color;
  Helix helix;
}

@Component2()
class DesignMainBoundSubstrandComponent extends UiComponent2<DesignMainBoundSubstrandProps> {
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
    BoundSubstrand substrand = this.props.substrand;
    String id = substrand.id();

    Point<num> start_svg = props.helix.svg_base_pos(substrand.offset_5p, substrand.forward);
    Point<num> end_svg = props.helix.svg_base_pos(substrand.offset_3p, substrand.forward);

    return (Dom.line()
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
