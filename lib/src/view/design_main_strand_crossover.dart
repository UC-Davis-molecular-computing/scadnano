import 'dart:math';

import 'package:over_react/over_react.dart';
import 'package:scadnano/src/model/model.dart';
import 'package:scadnano/src/model/select_mode.dart';
import 'package:tuple/tuple.dart';
import 'package:built_collection/built_collection.dart';

import '../dispatcher/actions_OLD.dart';
import '../model/crossover.dart';
import '../model/helix.dart';
import '../model/mouseover_data.dart';
import '../model/strand.dart';
import '../model/bound_substrand.dart';
import 'design_main_mouseover_rect_helix.dart';
import 'design_main_strand_paths.dart';
import '../app.dart';
import '../dispatcher/actions.dart' as actions;

part 'design_main_strand_crossover.over_react.g.dart';

const SELECTED_CROSSOVER_COLOR = 'hotpink';

@Factory()
UiFactory<DesignMainStrandCrossoverProps> DesignMainStrandCrossover = _$DesignMainStrandCrossover;

@Props()
class _$DesignMainStrandCrossoverProps extends UiProps {
  Strand strand;
  Crossover crossover;
}

@Component2()
class DesignMainStrandCrossoverComponent extends UiComponent2<DesignMainStrandCrossoverProps> {
  @override
  render() {
    Strand strand = props.strand;
    Crossover crossover = props.crossover;

    BoundSubstrand prev_substrand = crossover.prev_substrand;
    BoundSubstrand next_substrand = crossover.next_substrand;

    handle_crossover_click() {
      for (var ss in [prev_substrand, next_substrand]) {
        var other_ss = ss == prev_substrand ? next_substrand : prev_substrand;
        int anchor = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;

        var action = actions.HelixRotationSetAtOther(ss.helix, other_ss.helix, ss.forward, anchor);
        app.store.dispatch(action);
//        _set_rotation_for_substrand_from_crossover(ss, other_ss, anchor);
      }
    }

    update_mouseover_crossover() {
      List<MouseoverParams> param_list = [];
      for (var ss in [prev_substrand, next_substrand]) {
        //FIXME: better way to get dna_design
        Helix helix = app.model.dna_design.helices[ss.helix];
        int offset = ss == prev_substrand ? ss.offset_3p : ss.offset_5p;
        bool forward = ss.forward;
        param_list.add(MouseoverParams(helix.idx, offset, forward));
      }

      app.store.dispatch(
          actions.MouseoverDataUpdate(app.model.dna_design, BuiltList<MouseoverParams>(param_list)));
//      var params = MouseoverParameters(BuiltList<Tuple3<int, int, bool>>(param_list));
//      Actions.update_mouseover_data(params);
    }

//    handle_crossover_ctrl_click() {
//      Actions.crossover_select_toggle(pair_substrands);
//    }

    //TODO: figure out a way to display helix backbone rotation when mouse is on crossover

    var classname_this_curve = 'crossover-curve';
    if (crossover.selected()) {
      classname_this_curve += ' selected';
    }
    if (app.model.ui_model.select_mode_state.modes.contains(SelectModeChoice.crossover)) {
      classname_this_curve += ' selectable';
    }

    var path = crossover_path_description(prev_substrand, next_substrand);
    var color = strand.color.toRgbColor().toCssString();
    var id = crossover.id();

    var attr = Dom.path()
      ..d = path
      ..stroke = color
      ..className = classname_this_curve
//      ..onMouseDown = ((ev) => ev.ctrlKey || ev.shiftKey ? crossover.handle_selection(ev) : handle_crossover_click())
      ..onMouseEnter = ((_) => update_mouseover_crossover())
//      ..onMouseLeave = ((_) => mouse_leave_update_mouseover())
      ..onMouseLeave = ((_) {
        mouse_leave_update_mouseover();
      })
      ..onPointerDown = ((ev) => ev.nativeEvent.ctrlKey || ev.nativeEvent.shiftKey
          ? crossover.handle_selection(ev)
          : handle_crossover_click())
      ..id = id
      ..key = id;
    return attr();
  }
}

//_set_rotation_for_substrand_from_crossover(BoundSubstrand ss, BoundSubstrand other_ss, int anchor) {
////  bool crossover_up = ss.helix > other_ss.helix;
////  num rotation = crossover_up ? 0 : pi;
//
//
//
//  if (!ss.forward) {
//    rotation = (rotation - radians(150)) % (2 * pi);
//  }
//
//  var helix_rotation_action = actions.HelixRotationSet(ss.helix, rotation, anchor);
//
//  //FIXME: on the second call model is null, possibly because we aren't intended to access a global
//  // variable in this way. Try making this a connected component and call dispatch that way
//  app.store.dispatch(helix_rotation_action);
//}

//XXX: restore this code if the above fails. Above only worked for crossovers one on top of the other in
// the square lattice.

_set_rotation_for_substrand_from_crossover(BoundSubstrand ss, BoundSubstrand other_ss, int anchor) {
  bool crossover_up = ss.helix > other_ss.helix;
  num rotation = crossover_up ? 0 : pi;
  if (!ss.forward) {
    rotation = (rotation - radians(150)) % (2 * pi);
  }

  var helix_rotation_action = actions.HelixRotationSet(ss.helix, rotation, anchor);

  //FIXME: on the second call model is null, possibly because we aren't intended to access a global
  // variable in this way. Try making this a connected component and call dispatch that way
  app.store.dispatch(helix_rotation_action);
}

String degrees_str(num radians, [int decimal_places = 2]) =>
    ((radians * 360.0 / (2 * pi)) % 360.0).toStringAsFixed(decimal_places);

String radians_str(num degrees, [int decimal_places = 2]) =>
    ((degrees * (2 * pi) / 360.0) % (2 * pi)).toStringAsFixed(decimal_places);

num radians(num degrees) => (degrees * (2 * pi) / 360.0) % (2 * pi);
