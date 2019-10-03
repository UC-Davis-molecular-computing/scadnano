import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/helix.dart';

import '../model/strand.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';

part 'design_main_strand_paths_crossover.over_react.g.dart';

const SELECTED_CROSSOVER_COLOR = 'hotpink';

@Factory()
UiFactory<DesignMainStrandPathsCrossoverProps> DesignMainStrandPathsCrossover =
    _$DesignMainStrandPathsCrossover;

@Props()
class _$DesignMainStrandPathsCrossoverProps extends UiProps {
  Strand strand;
  int idx;
}

@Component()
class DesignMainStrandPathsCrossoverComponent extends UiComponent<DesignMainStrandPathsCrossoverProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    // We need a hidden arc that is not dashed to make it easier to select, otherwise the mouse pointed
    // needs to hit one of the dashes to select it.
    return (Dom.g()..className = 'crossover-paths')(
//      _crossover_arc(this.props.strand, this.props.idx, true),
      _crossover_arc(this.props.strand, this.props.idx, false),
    );
  }
}

const classname = 'crossover-curve';
const classname_hidden = 'crossover-curve-hidden';
const classname_unhidden = 'crossover-curve-unhidden';
const classname_mouseover = 'crossover-curve-mouseover ' + classname;

on_mouse_enter(SyntheticMouseEvent ev) {
  ev.target.setAttribute('class', classname_unhidden);
}

on_mouse_leave(SyntheticMouseEvent ev) {
  ev.target.setAttribute('class', classname_hidden);
}

/// crossover arc from bound substrand i to bound substrand i+1
ReactElement _crossover_arc(Strand strand, int i, bool hidden) {
  assert(i < strand.substrands.length - 1);
  assert(strand.substrands[i].is_bound_substrand());
  assert(strand.substrands[i + 1].is_bound_substrand());
  var prev_substrand = strand.substrands[i] as BoundSubstrand;
  var next_substrand = strand.substrands[i + 1] as BoundSubstrand;

  var id = (hidden ? '-hidden' : '') + 'crossover-${i}-${strand.toString()}';
  var on_mouse_enter_callback = null;
  var on_mouse_leave_callback = null;

  on_mouse_up(SyntheticMouseEvent ev) {
    for (var ss in [prev_substrand, next_substrand]) {
      var other_ss = ss == prev_substrand ? next_substrand : prev_substrand;
      int anchor = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;
      _set_rotation_for_substrand_from_crossover(ss, other_ss, anchor);
    }
  }

  var on_mouse_up_callback = on_mouse_up;

  if (hidden) {
    on_mouse_enter_callback = on_mouse_enter;
    on_mouse_leave_callback = on_mouse_leave;
  }
  var classname_this_curve = classname;
  if (hidden) {
    classname_this_curve = classname_hidden;
  }
  var color = hidden ? SELECTED_CROSSOVER_COLOR : null;
  var crossover = arc(prev_substrand, next_substrand, classname_this_curve,
      id: id,
      on_mouse_up: on_mouse_up_callback,
      on_mouse_enter: on_mouse_enter_callback,
      on_mouse_leave: on_mouse_leave_callback,
      color: color);
  return crossover;
}

_set_rotation_for_substrand_from_crossover(BoundSubstrand ss, BoundSubstrand other_ss, int anchor) {
  bool crossover_up = ss.helix > other_ss.helix;
  num rotation = crossover_up ? -pi / 2.0 : pi / 2.0;
//  print('setting rotation for ss on helix ${ss.helix} to ${degrees_str(rotation)}');
  if (!ss.forward) {
    var old = rotation;
    rotation = (rotation - radians(150)) % (2 * pi);
//    print('changing rotation for helix ${ss.helix} from ${degrees_str(old)} to ${degrees_str(rotation)}');
  }

  //TODO: figure out a way to communicate the helix without reaching into the global variable
  int helix_idx = ss.helix;
  Helix helix = app.model.dna_design.helices[helix_idx];
  num old_rotation = helix.rotation;
  int old_anchor = helix.rotation_anchor;

  var params = SetHelixRotationActionParameters(helix_idx, anchor, rotation, old_anchor, old_rotation);
  var action_pack = SetHelixRotationActionPack(params);
  app.send_action(action_pack);
}

String degrees_str(num radians, [int decimal_places = 2]) => ((radians * 360.0 / (2 * pi)) % 360.0).toStringAsFixed(decimal_places);

String radians_str(num degrees, [int decimal_places = 2]) => ((degrees * (2 * pi) / 360.0) % (2 * pi)).toStringAsFixed(decimal_places);

num radians(num degrees) => (degrees * (2 * pi) / 360.0) % (2 * pi);
