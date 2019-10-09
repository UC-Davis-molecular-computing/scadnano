import 'package:over_react/over_react.dart';

import '../dispatcher/actions.dart';
import '../model/bound_substrand.dart';
import '../app.dart';
import 'design_main_mouseover_rect_helix.dart';

part 'design_main_strand_3p_end.over_react.g.dart';

@Factory()
UiFactory<DesignMain3pEndProps> DesignMain3pEnd = _$DesignMain3pEnd;

@Props()
class _$DesignMain3pEndProps extends FluxUiProps<BoundSubstrand, BoundSubstrand> {
  bool is_last_substrand;
  String id;
}

@Component()
class DesignMain3pEndComponent extends FluxUiComponent<DesignMain3pEndProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    BoundSubstrand substrand = this.props.store;
    String id = this.props.id;
    bool is_last_substrand = this.props.is_last_substrand;

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
//    if (substrand.ui_model.selected_3p) {
    if (substrand.selected_3p()) {
      classname += ' selected';
    }

    ReactElement triangle = (Dom.polygon()
//      ..onMouseDown = ((event) => event.ctrlKey ? Actions.three_prime_select_toggle(substrand) : null)
          ..onMouseDown = substrand.dnaend_3p.handle_selection
          ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
//      ..onMouseMove = ((event) => update_mouseover(event, helix))
          ..onMouseMove = ((event) {
            update_mouseover(event, helix);
//        print('${querySelector('#$id')}');
          })
          ..className = classname
          ..points = points
          ..fill = substrand.strand.color.toRgbColor().toCssString()
          ..id = id //XXX: this id is not showing up in the DOM; not sure why
        )();
    return triangle;
  }
}
