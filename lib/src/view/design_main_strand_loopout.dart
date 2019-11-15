import 'dart:html';
import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/select_mode.dart';

import '../dispatcher/actions_OLD.dart';
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
class _$DesignMainLoopoutProps extends UiProps { //FluxUiProps<Loopout, Loopout> {
  Loopout loopout;
  int substrand_idx;
  Color color;
}

@Component2()
class DesignMainLoopoutComponent extends UiComponent2<DesignMainLoopoutProps> { // FluxUiComponent<DesignMainLoopoutProps> {
//  @override
//  Map getDefaultProps() => (newProps());

  @override
  render() {
    Loopout loopout = this.props.loopout;
    int substrand_idx = this.props.substrand_idx;
//    Strand strand = loopout.strand;

    assert(0 < substrand_idx);
//    assert(substrand_idx < strand.substrands.length - 1);

//    var prev_ss = strand.substrands[substrand_idx - 1] as BoundSubstrand;
//    var next_ss = strand.substrands[substrand_idx + 1] as BoundSubstrand;
    var prev_ss = loopout.prev_substrand;
    var next_ss = loopout.next_substrand;

    var classname = 'substrand-line loopout-line';
    if (loopout.selected()) {
      classname += ' selected';
    }
    if (app.model.ui_model.select_mode_state.modes.contains(SelectModeChoice.loopout)) {
      classname += ' selectable';
    }

    if (util.is_hairpin(prev_ss, next_ss)) {
      // special case for hairpin so it's not a short straight line
      return _hairpin_arc(prev_ss, next_ss, loopout, classname, props.color);
    } else {
      String path = crossover_path_description(prev_ss, next_ss);
      String id = loopout.id();
//      String color = strand.color.toRgbColor().toCssString();

      //TODO: find way to not repeat ourselves by reusing the Selectable logic between components
      // loopout, crossover, 5p-end, 3p-end, strand
      // There's a pattern called higher-order component in React but it's not clear how to implement it in
      // OverReact.

      //XXX: need to use onPointerDown instead of onMouseDown because of the dnd Dart library:
      // https://github.com/marcojakob/dart-dnd/issues/27
      // perhaps not implemented by Safari though:
      // https://love2dev.com/blog/chrome-has-decided-to-implement-pointer-events-and-the-web-rejoices/
      return (Dom.path()
//        ..onMouseDown = loopout.handle_selection // use with mixin Selectable
        ..d = path
        ..stroke = props.color.toRgbColor().toCssString()
        ..onPointerDown = loopout.handle_selection
        ..className = classname
        ..id = id
        ..key = id)();
    }
  }
}

ReactElement _hairpin_arc(
    BoundSubstrand prev_substrand, BoundSubstrand next_substrand, Loopout loopout, String classname, Color color) {
  var helix = app.model.dna_design.helices[prev_substrand.helix];
  var start_svg = helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
  var end_svg = helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);
//  var strand = prev_substrand.strand;

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
    ..onMouseDown = ((event) => event.ctrlKey ? Actions_OLD.loopout_select_toggle(loopout) : null)
    ..className = classname
    ..stroke = color.toRgbColor().toCssString()
    ..d = 'M ${start_svg.x} ${start_svg.y} C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${end_svg.x} ${end_svg.y}'
    ..key = id
    ..id = id)();
  return arc;
}
