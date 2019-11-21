import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';

import '../model/model.dart';
import '../model/select_mode.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import '../app.dart';
import '../util.dart' as util;
import 'design_main_mouseover_rect_helix.dart';

part 'design_main_strand_3p_end.over_react.g.dart';

/// Connected Redux Component
///
/// As shown in the example below, the same component can be connected to Redux in
/// such a way that it behaves differently.
//UiFactory<DesignMain3pEndProps> ConnectedDesignMain3pEnd = connect<Model, DesignMain3pEndProps>(
//    mapStateToPropsWithOwnProps: (Model state, DesignMain3pEndProps own_props) =>
//      (DesignMain3pEnd()
//        ..substrand = state.dna_design.)
//)(DesignMain3pEnd);

//UiFactory<DesignMain3pEndProps> ConnectedBigCounter = connect<CounterState, CounterProps>(
//  mapStateToProps: (state) => (Counter()..currentCount = state.bigCount),
//  mapDispatchToProps: (dispatch) => (
//      Counter()
//        ..increment = () { dispatch(BigIncrementAction()); }
//        ..decrement = () { dispatch(BigDecrementAction()); }
//  ),
//)(Counter);

@Factory()
UiFactory<DesignMain3pEndProps> DesignMain3pEnd = _$DesignMain3pEnd;

@Props()
class _$DesignMain3pEndProps extends UiProps with ConnectPropsMixin {
  // FluxUiProps<BoundSubstrand, BoundSubstrand> {
  BoundSubstrand substrand;
  bool is_last_substrand;
  Color color;
}

@Component2()
class DesignMain3pEndComponent extends UiComponent2<DesignMain3pEndProps> {
  //FluxUiComponent<DesignMain3pEndProps> {
//  @override
//  Map getDefaultProps() => (newProps());

  @override
  render() {
    BoundSubstrand substrand = this.props.substrand;

    bool is_last_substrand = this.props.is_last_substrand;
    var id = substrand.dnaend_3p.id();

    var offset = substrand.offset_3p;
    var direction = substrand.forward;
    var helix = app.model.dna_design.helices[substrand.helix];
    var pos = helix.svg_base_pos(offset, direction);
    var points;
    num scale = 3.7;
    if (!substrand.forward) {
      points = '${pos.x - scale},${pos.y} '
          '${pos.x + 0.9 * scale},${pos.y + scale} '
          '${pos.x + 0.9 * scale},${pos.y - scale}';
    } else {
      points = '${pos.x + scale},${pos.y} '
          '${pos.x - 0.9 * scale},${pos.y + scale} '
          '${pos.x - 0.9 * scale},${pos.y - scale}';
    }

    var classname = 'three-prime-end' + (is_last_substrand ? '-last-substrand' : '');
//    if (substrand.selected_3p()) {
    if (substrand.dnaend_3p.selected()) {
      classname += ' selected';
    }
    if (is_last_substrand &&
            app.model.ui_model.select_mode_state.modes.contains(SelectModeChoice.end_5p_strand) ||
        !is_last_substrand &&
            app.model.ui_model.select_mode_state.modes.contains(SelectModeChoice.end_5p_substrand)) {
      classname += ' selectable';
    }

    Strand strand = app.model.dna_design.substrand_to_strand[substrand];

    var attr = Dom.polygon()
//          ..onMouseDown = substrand.dnaend_3p.handle_selection
      ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
      ..onMouseMove = ((event) => update_mouseover(event, helix.idx))
      ..onPointerDown = substrand.dnaend_3p.handle_selection
      ..className = classname
      ..points = points
      ..fill = strand.color.toRgbColor().toCssString()
      ..id = id;
    return attr();
  }
}
