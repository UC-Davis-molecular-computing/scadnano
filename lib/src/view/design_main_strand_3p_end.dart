import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';

import 'package:scadnano/src/state/helix.dart';
import '../state/app_state.dart';
import '../state/select_mode.dart';
import '../state/bound_substrand.dart';
import '../app.dart';

part 'design_main_strand_3p_end.over_react.g.dart';

Map mapStateToPropsWithOwnProps(AppState state, DesignMain3pEndProps props) {
  var select_mode_choice = props.substrand.is_last ? SelectModeChoice.end_3p_strand : SelectModeChoice.end_3p_substrand;
  bool selected = DEBUG_SELECT ? false : state.ui_state.selectables_store.selected(props.substrand.dnaend_3p);
  bool selectable = DEBUG_SELECT ? false : state.ui_state.select_mode_state.modes.contains(select_mode_choice);
  return DesignMain3pEnd()
    ..selected = selected
    ..selectable = selectable
    ..helix = state.dna_design.helices[props.substrand.helix]
    ..is_last_substrand = props.substrand.is_last;
}

UiFactory<DesignMain3pEndProps> ConnectedDesignMain3pEnd =
    connect<AppState, DesignMain3pEndProps>(mapStateToPropsWithOwnProps: mapStateToPropsWithOwnProps)(DesignMain3pEnd);

@Factory()
UiFactory<DesignMain3pEndProps> DesignMain3pEnd = _$DesignMain3pEnd;

@Props()
class _$DesignMain3pEndProps extends UiProps with ConnectPropsMixin {
  BoundSubstrand substrand;
  Color color;
  Helix helix;
  bool is_last_substrand;
  bool selected;
  bool selectable;
}

@Component2()
class DesignMain3pEndComponent extends UiComponent2<DesignMain3pEndProps> {

  @override
  render() {
    BoundSubstrand substrand = props.substrand;

    var id = substrand.dnaend_3p.id();

    var offset = substrand.offset_3p;
    var direction = substrand.forward;
    var helix = app.state.dna_design.helices[substrand.helix];
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

    var classname = 'three-prime-end' + (props.is_last_substrand ? '-last-substrand' : '');
//    if (substrand.selected_3p()) {
    if (props.selected) {
      classname += ' selected';
    }
    if (props.selectable) {
      classname += ' selectable';
    }

    var attr = Dom.polygon()
//          ..onMouseDown = substrand.dnaend_3p.handle_selection
//      ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
//      ..onMouseMove = ((event) => update_mouseover(event, helix.idx))
      ..onPointerDown = substrand.dnaend_3p.handle_selection
      ..className = classname
      ..points = points
      ..fill = props.color.toRgbColor().toCssString()
      ..id = id;
    return attr();
  }
}
