import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:tuple/tuple.dart';

import '../dispatcher/actions.dart';
import '../model/crossover.dart';
import '../model/helix.dart';
import '../model/mouseover_data.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import 'design_main_mouseover_rect_helix.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';
import '../util.dart' as util;

part 'design_main_strand_paths_crossover.over_react.g.dart';

const SELECTED_CROSSOVER_COLOR = 'hotpink';

@Factory()
UiFactory<DesignMainStrandPathsCrossoverProps> DesignMainStrandPathsCrossover = _$DesignMainStrandPathsCrossover;

@Props()
class _$DesignMainStrandPathsCrossoverProps extends FluxUiProps<Crossover, Crossover> {
  Strand strand;
}

@Component()
class DesignMainStrandPathsCrossoverComponent extends FluxUiComponent<DesignMainStrandPathsCrossoverProps> {
  @override
  Map getDefaultProps() => (newProps());

  @override
  render() {
    Strand strand = this.props.strand;
    Crossover crossover = this.props.store;

    BoundSubstrand prev_substrand = crossover.prev_substrand;
    BoundSubstrand next_substrand = crossover.next_substrand;

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

//    handle_crossover_ctrl_click() {
//      Actions.crossover_select_toggle(pair_substrands);
//    }

    //TODO: figure out a way to display helix backbone rotation when mouse is on crossover

    var classname_this_curve = classname;
    if (crossover.selected()) {
      classname_this_curve += ' selected';
    }

    var path = crossover_path_description(prev_substrand, next_substrand);
    var color = strand.color.toRgbColor().toCssString();
    var id = crossover.id();

    return (Dom.path()
      ..d = path
      ..stroke = color
      ..className = classname_this_curve
      ..onMouseDown = ((ev) => ev.ctrlKey || ev.shiftKey ? crossover.handle_selection(ev) : handle_crossover_click())
      ..onMouseEnter = ((_) => update_mouseover_crossover())
      ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
      ..id = id
      ..key = id)();
  }
}

const classname = 'selectable crossover-curve';

_set_rotation_for_substrand_from_crossover(BoundSubstrand ss, BoundSubstrand other_ss, int anchor) {
  bool crossover_up = ss.helix > other_ss.helix;
  num rotation = crossover_up ? -pi / 2.0 : pi / 2.0;
  if (!ss.forward) {
    rotation = (rotation - radians(150)) % (2 * pi);
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
