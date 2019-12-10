import 'dart:html';
import 'dart:math';

import 'package:color/color.dart';
import 'package:dialog/dialog.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:scadnano/src/state/strand.dart';

import '../state/app_state.dart';
import 'package:scadnano/src/state/select_mode.dart';
import '../state/bound_substrand.dart';
import '../state/loopout.dart';
import '../app.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_strand_paths.dart';
import '../actions/actions.dart' as actions;

part 'design_main_strand_loopout.over_react.g.dart';

UiFactory<DesignMainLoopoutProps> ConnectedDesignMainLoopout =
    connect<AppState, DesignMainLoopoutProps>(mapStateToPropsWithOwnProps: (state, props) {
  var prev_ss = props.strand.substrands[props.loopout.prev_substrand_idx];
  var next_ss = props.strand.substrands[props.loopout.next_substrand_idx];
  return DesignMainLoopout()
    ..prev_substrand = prev_ss
    ..next_substrand = next_ss
    ..selected = state.ui_state.selectables_store.selected(props.loopout)
    ..selectable = state.ui_state.select_mode_state.modes.contains(SelectModeChoice.loopout);
})(DesignMainLoopout);

@Factory()
UiFactory<DesignMainLoopoutProps> DesignMainLoopout = _$DesignMainLoopout;

@Props()
class _$DesignMainLoopoutProps extends UiProps {
  Loopout loopout;
  Strand strand;
  BoundSubstrand prev_substrand;
  BoundSubstrand next_substrand;
  Color color;
  bool selected;
  bool selectable;
}

@Component2()
class DesignMainLoopoutComponent extends UiComponent2<DesignMainLoopoutProps> {
  // FluxUiComponent<DesignMainLoopoutProps> {
//  @override
//  Map getDefaultProps() => (newProps());

  @override
  render() {
    Loopout loopout = this.props.loopout;
    Color color = props.color;

    var prev_ss = props.prev_substrand;
    var next_ss = props.next_substrand;

    var classname = 'substrand-line loopout-line';
    if (props.selected) {
      classname += ' selected';
    }
    if (props.selectable) {
      classname += ' selectable';
    }

    if (util.is_hairpin(prev_ss, next_ss)) {
      // special case for hairpin so it's not a short straight line
      return _hairpin_arc(prev_ss, next_ss, loopout, classname, color);
    } else {
      String path = crossover_path_description(prev_ss, next_ss);
      String id = loopout.id();

      //XXX: need to use onPointerDown instead of onMouseDown because of the dnd Dart library:
      // https://github.com/marcojakob/dart-dnd/issues/27
      // perhaps not implemented by Safari though:
      // https://love2dev.com/blog/chrome-has-decided-to-implement-pointer-events-and-the-web-rejoices/
      return (Dom.path()
        ..d = path
        ..stroke = color.toRgbColor().toCssString()
        ..onPointerDown = ((ev) {
          loopout.handle_selection(ev);
          if (app.keys_pressed.contains(constants.KEY_CODE_LOOPOUT_CONVERT)) {
            loopout_length_change();
          }
        })
        ..className = classname
        ..id = id
        ..key = id)();
    }
  }

  loopout_length_change() async {
    int length = null;
    String prompt_to_user = "Enter loopout length (nonnegative integer):";
    do {
      var prompt_result = await prompt(prompt_to_user);
      if (prompt_result == null) {
        return;
      }
      var prompt_result_string = prompt_result.toString();
      length = int.tryParse(prompt_result_string);
      prompt_to_user =
          '"$prompt_result_string" is not a nonnegative integer. Enter loopout length (nonnegative integer):';
    } while (length == null || length < 0);

    app.dispatch(actions.LoopoutLengthChange(props.loopout, length));
  }
}

ReactElement _hairpin_arc(BoundSubstrand prev_substrand, BoundSubstrand next_substrand, Loopout loopout,
    String classname, Color color) {
  var helix = app.state.dna_design.helices[prev_substrand.helix];
  var start_svg = helix.svg_base_pos(prev_substrand.offset_3p, prev_substrand.forward);
  var end_svg = helix.svg_base_pos(next_substrand.offset_5p, next_substrand.forward);
//  var strand = prev_substrand.strand;

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
    ..className = classname
    ..stroke = color.toRgbColor().toCssString()
    ..d = 'M ${start_svg.x} ${start_svg.y} C ${c1.x} ${c1.y} ${c2.x} ${c2.y} ${end_svg.x} ${end_svg.y}'
    ..key = id
    ..id = id)();
  return arc;
}
