import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';

import '../dispatcher/actions.dart';
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
class _$DesignMainBoundSubstrandProps extends FluxUiProps<BoundSubstrand, BoundSubstrand> {
  String strand_id;
}

// There's a bit of a lag re-rendering the whole strand just to change its class to "hover", so we
// go around React when _OPTIMIZE=true and set the class directly by querying the element by ID.
const _OPTIMIZE = true;
//const _OPTIMIZE = false;

@Component()
class DesignMainBoundSubstrandComponent extends FluxUiComponent<DesignMainBoundSubstrandProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    BoundSubstrand substrand = this.props.store;
    String strand_id = this.props.strand_id;

    Helix helix = app.model.dna_design.helices[substrand.helix];
    Point<num> start_svg = helix.svg_base_pos(substrand.offset_5p, substrand.forward);
    Point<num> end_svg = helix.svg_base_pos(substrand.offset_3p, substrand.forward);
    String id = util.substrand_line_id(substrand);
    Strand strand = substrand.strand;

    ReactElement substrand_line = (Dom.line()
//      ..onMouseDown = ((event) {
//        if (event.ctrlKey) {
//          Actions.strand_select_toggle(substrand.strand);
//        }
//      })
      ..onMouseDown = strand.handle_selection
      ..onMouseEnter = ((_) {
        if (_OPTIMIZE) {
          Element strand_elt = querySelector('#${strand_id}');
          strand_elt.classes.add('hover');
        } else {
          Actions.strand_hover_add(strand);
        }
      })
      ..onMouseLeave = ((_) {
        if (_OPTIMIZE) {
          Element strand_elt = querySelector('#${strand_id}');
          strand_elt.classes.remove('hover');
        } else {
          Actions.strand_hover_remove(strand);
        }
        mouse_leave_update_mouseover();
      })
      ..onMouseMove = ((event) => update_mouseover(event, helix))
      ..stroke = substrand.strand.color.toRgbColor().toCssString()
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..key = id
      ..id = id
      ..className = 'substrand-line')();
    return substrand_line;
  }
}
