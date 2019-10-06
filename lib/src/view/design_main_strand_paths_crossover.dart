import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/dispatcher/actions.dart';
import 'package:scadnano/src/model/helix.dart';
import 'package:scadnano/src/model/mouseover_data.dart';
import 'package:tuple/tuple.dart';

import '../model/strand.dart';
import 'design_main_mouseover_rect_helix.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';

part 'design_main_strand_paths_crossover.over_react.g.dart';

const SELECTED_CROSSOVER_COLOR = 'hotpink';

@Factory()
UiFactory<DesignMainStrandPathsCrossoverProps> DesignMainStrandPathsCrossover = _$DesignMainStrandPathsCrossover;

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
    return _crossover_arc(this.props.strand, this.props.idx);
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
ReactElement _crossover_arc(Strand strand, int i) {
  assert(i < strand.substrands.length - 1);
  assert(strand.substrands[i].is_bound_substrand());
  assert(strand.substrands[i + 1].is_bound_substrand());
  var prev_substrand = strand.substrands[i] as BoundSubstrand;
  var next_substrand = strand.substrands[i + 1] as BoundSubstrand;

  var id = 'crossover-${i}-${strand.toString()}';

  handle_crossover_click() {
    for (var ss in [prev_substrand, next_substrand]) {
      var other_ss = ss == prev_substrand ? next_substrand : prev_substrand;
      int anchor = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;
      _set_rotation_for_substrand_from_crossover(ss, other_ss, anchor);
    }
  }

  update_mouseover_crossover() {
    List<Tuple3<int, int, bool>> param_list = [];
    for (var ss in [prev_substrand, next_substrand]) {
      Helix helix = app.model.dna_design.helices[ss.helix];
      int offset = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;
      bool forward = ss.forward;
      param_list.add(Tuple3<int, int, bool>(helix.idx(), offset, forward));
    }
    var params = MouseoverParameters(param_list);
    Actions.update_mouseover_data(params);
  }

  //TODO: figure out a way to display helix backbone rotation when mouse is on crossover
  var classname_this_curve = classname;
  var path = crossover_path_description(prev_substrand, next_substrand);
  var color = strand.color.toRgbColor().toCssString();
  return (Dom.path()
    ..d = path
    ..stroke = color
    ..className = classname_this_curve
    ..onMouseDown = ((_) => handle_crossover_click())
    ..onMouseEnter = ((_) => update_mouseover_crossover())
    ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
    ..id = id
    ..key = id)();
}

_set_rotation_for_substrand_from_crossover(BoundSubstrand ss, BoundSubstrand other_ss, int anchor) {
  bool crossover_up = ss.helix > other_ss.helix;
  num rotation = crossover_up ? -pi / 2.0 : pi / 2.0;
//  print('setting rotation for ss on helix ${ss.helix} to ${degrees_str(rotation)}');
  if (!ss.forward) {
//    var old = rotation;
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

String degrees_str(num radians, [int decimal_places = 2]) =>
    ((radians * 360.0 / (2 * pi)) % 360.0).toStringAsFixed(decimal_places);

String radians_str(num degrees, [int decimal_places = 2]) =>
    ((degrees * (2 * pi) / 360.0) % (2 * pi)).toStringAsFixed(decimal_places);

num radians(num degrees) => (degrees * (2 * pi) / 360.0) % (2 * pi);
