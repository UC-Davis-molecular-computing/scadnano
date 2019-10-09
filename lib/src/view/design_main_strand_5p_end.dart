import 'package:over_react/over_react.dart';

import '../dispatcher/actions.dart';
import '../model/bound_substrand.dart';
import '../app.dart';
import 'design_main_mouseover_rect_helix.dart';

part 'design_main_strand_5p_end.over_react.g.dart';

@Factory()
UiFactory<DesignMain5pEndProps> DesignMain5pEnd = _$DesignMain5pEnd;

@Props()
class _$DesignMain5pEndProps extends FluxUiProps<BoundSubstrand, BoundSubstrand> {
  bool is_first_substrand;
  String id;
}

@Component()
class DesignMain5pEndComponent extends FluxUiComponent<DesignMain5pEndProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    BoundSubstrand substrand = this.props.store;
    bool is_first_substrand = this.props.is_first_substrand;
    String id = this.props.id;

//  var first_ss = strand.first_bound_substrand();
    var helix = app.model.dna_design.helices[substrand.helix];
    var offset = substrand.offset_5p;
    var right = substrand.forward;
    var pos = helix.svg_base_pos(offset, right);

    var classname = 'five-prime-end' + (is_first_substrand ? '-first-substrand' : '');
//    if (substrand.ui_model.selected_5p) {
    if (substrand.selected_5p()) {
      classname += ' selected';
    }

    //XXX: width, height, rx, ry should be do-able in CSS, but Firefox won't display properly
    // if they are specified in CSS, but it will if they are specified here
    var box = (Dom.rect()
//      ..onMouseDown = ((event) => event.ctrlKey ? Actions.five_prime_select_toggle(substrand) : null)
//      ..onMouseDown = ((event) => event.ctrlKey ? Actions.five_prime_select_toggle(substrand) : null)
      ..onMouseDown = substrand.dnaend_5p.handle_selection
      ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
      ..onMouseMove = ((event) => update_mouseover(event, helix))
      ..className = classname
      ..x = '${pos.x - 3.5}'
      ..y = '${pos.y - 3.5}'
      ..width = '7px'
      ..height = '7px'
      ..rx = '1.5px'
      ..ry = '1.5px'
      ..fill = substrand.strand.color.toRgbColor().toCssString()
      ..id = id);
    return box();
  }
}
