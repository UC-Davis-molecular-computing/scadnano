import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/select_mode.dart';

import '../model/bound_substrand.dart';
import '../app.dart';
import '../util.dart' as util;
import 'design_main_mouseover_rect_helix.dart';

part 'design_main_strand_5p_end.over_react.g.dart';

@Factory()
UiFactory<DesignMain5pEndProps> DesignMain5pEnd = _$DesignMain5pEnd;

@Props()
class _$DesignMain5pEndProps extends FluxUiProps<BoundSubstrand, BoundSubstrand> {
  bool is_first_substrand;
}

@Component()
class DesignMain5pEndComponent extends FluxUiComponent<DesignMain5pEndProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    BoundSubstrand substrand = this.props.store;
    bool is_first_substrand = this.props.is_first_substrand;
    var id = substrand.dnaend_5p.id();

    var helix = app.model.dna_design.helices[substrand.helix];
    var offset = substrand.offset_5p;
    var right = substrand.forward;
    var pos = helix.svg_base_pos(offset, right);

    var classname = 'five-prime-end' + (is_first_substrand ? '-first-substrand' : '');
    if (substrand.selected_5p()) {
      classname += ' selected';
    }
    if (is_first_substrand && app.model.select_mode_store.modes.contains(SelectModeChoice.end_5p_strand)
    || !is_first_substrand && app.model.select_mode_store.modes.contains(SelectModeChoice.end_5p_substrand)) {
      classname += ' selectable';
    }

    //XXX: width, height, rx, ry should be do-able in CSS. However, Firefox won't display properly
    // if they are specified in CSS, but it will if they are specified here.
    var attr = (Dom.rect()
//      ..onMouseDown = substrand.dnaend_5p.handle_selection
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
    attr.addProp('onPointerDown', substrand.dnaend_5p.handle_selection);
    return attr();
  }
}
