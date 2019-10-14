import 'dart:html';
import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/select_mode.dart';

import '../dispatcher/actions.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import '../model/loopout.dart';
import '../app.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_strand_paths.dart';

part 'design_main_strand_loopout.over_react.g.dart';

@Factory()
UiFactory<DesignMainLoopoutProps> DesignMainLoopout = _$DesignMainLoopout;

@Props()
class _$DesignMainLoopoutProps extends FluxUiProps<Loopout, Loopout> {
  int substrand_idx;
}

@Component()
class DesignMainLoopoutComponent extends FluxUiComponent<DesignMainLoopoutProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    Loopout loopout = this.props.store;
    int substrand_idx = this.props.substrand_idx;
    Strand strand = loopout.strand;

    assert(0 < substrand_idx);
    assert(substrand_idx < strand.substrands.length - 1);

    var prev_ss = strand.substrands[substrand_idx - 1] as BoundSubstrand;
    var next_ss = strand.substrands[substrand_idx + 1] as BoundSubstrand;

    var classname = 'substrand-line loopout-line';
    if (loopout.selected()) {
      classname += ' selected';
    }
    if (app.model.select_mode_store.modes.contains(SelectModeChoice.loopout)) {
      classname += ' selectable';
    }

    if (util.is_hairpin(prev_ss, next_ss)) {
      // special case for hairpin so it's not a short straight line
      return _hairpin_arc(prev_ss, next_ss, loopout, classname);
    } else {
      String path = crossover_path_description(prev_ss, next_ss);
      String id = loopout.id();
      String color = strand.color.toRgbColor().toCssString();

      return (Dom.path()
        ..onMouseDown = loopout.handle_selection // use with mixin Selectable
        ..d = path
        ..stroke = color
        ..className = classname
        ..id = id
        ..key = id)();
    }
  }
}

ReactElement _hairpin_arc(
    BoundSubstrand prev_substrand, BoundSubstrand next_substrand, Loopout loopout, String classname) {
  var helix = app.model.dna_design.helices[prev_substrand.helix];
  var start_svg = helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
  var end_svg = helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);
  var strand = prev_substrand.strand;

  //TODO: make a design with all loopout lengths 1-20 and calibrate this
  var w = 1.5 * util.sigmoid(loopout.loopout_length - 1) * constants.BASE_WIDTH_SVG;
  var h = 10 * util.sigmoid(loopout.loopout_length - 5) * constants.BASE_HEIGHT_SVG;

  var x_offset1, x_offset2, y_offset1, y_offset2;
  if (prev_substrand.forward) {
    x_offset1 = start_svg.x + w;
    y_offset1 = start_svg.y - h;
    x_offset2 = end_svg.x + w;
    y_offset2 = end_svg.y + h;
  } else {
    x_offset1 = start_svg.x - w;
    y_offset1 = start_svg.y + h;
    x_offset2 = end_svg.x - w;
    y_offset2 = end_svg.y - h;
  }

  var c1 = Point<num>(x_offset1, y_offset1);
  var c2 = Point<num>(x_offset2, y_offset2);

  String id = loopout.id();
  ReactElement arc = (Dom.path()
    ..onMouseDown = ((event) => event.ctrlKey ? Actions.loopout_select_toggle(loopout) : null)
    ..className = classname
    ..stroke = strand.color.toRgbColor().toCssString()
    ..d = 'M ${start_svg.x} ${start_svg.y} C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${end_svg.x} ${end_svg.y}'
    ..key = id
    ..id = id)();
  return arc;
}
