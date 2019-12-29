import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:dialog/dialog.dart';
import 'package:over_react/over_react.dart';

import 'package:scadnano/src/state/edit_mode.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:scadnano/src/view/edit_mode_queryable.dart';
import '../state/bound_substrand.dart';
import '../state/loopout.dart';
import '../app.dart';
import '../util.dart' as util;
import '../constants.dart' as constants;
import 'design_main_strand_paths.dart';
import '../actions/actions.dart' as actions;
import 'pure_component.dart';
import 'edit_mode_queryable.dart';

part 'design_main_strand_loopout.over_react.g.dart';

//UiFactory<DesignMainLoopoutProps> ConnectedDesignMainLoopout =
//    connect<AppState, DesignMainLoopoutProps>(mapStateToPropsWithOwnProps: (state, props) {
//  bool selected = state.ui_state.selectables_store.selected(props.loopout);
//  bool selectable = state.ui_state.select_mode_state.modes.contains(SelectModeChoice.loopout);
//  var prev_ss = props.strand.substrands[props.loopout.prev_substrand_idx];
//  var next_ss = props.strand.substrands[props.loopout.next_substrand_idx];
//  return DesignMainLoopout()
//    ..selected = selected
//    ..selectable = selectable
//    ..edit_modes = state.ui_state.edit_modes
//    ..prev_substrand = prev_ss
//    ..next_substrand = next_ss;
//})(DesignMainLoopout);

@Factory()
UiFactory<DesignMainLoopoutProps> DesignMainLoopout = _$DesignMainLoopout;

@Props()
class _$DesignMainLoopoutProps extends EditModePropsAbstract {
  Loopout loopout;
  Strand strand;
  Color color;

  BoundSubstrand prev_substrand;
  BoundSubstrand next_substrand;
  bool selected;
  bool selectable;
  BuiltSet<EditModeChoice> edit_modes;
}

@State()
class _$DesignMainStrandLoopoutState extends UiState {
  // making this "local" state for the component (instead of storing in the global store)
  // skips wasteful actions and updating the state just to tell if the mouse is hovering over a loopout
  bool mouse_hover;
}

@Component2()
class DesignMainLoopoutComponent
    extends UiStatefulComponent2<DesignMainLoopoutProps, DesignMainStrandLoopoutState>
    with PureComponent, EditModeQueryable<DesignMainLoopoutProps> {
  @override
  Map get initialState => (newState()..mouse_hover = false);

  @override
  render() {
    Loopout loopout = this.props.loopout;
    Color color = props.color;

    var prev_ss = props.prev_substrand;
    var next_ss = props.next_substrand;

    bool show_mouseover_rect = backbone_mode;
    bool mouse_hover = state.mouse_hover;

    var classname = 'substrand-line loopout-line';
    if (props.selected) {
      classname += ' selected';
    }
    if (props.selectable) {
      classname += ' selectable';
    }

    if (show_mouseover_rect && mouse_hover) {
      update_mouseover_loopout();
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
        ..onMouseEnter = (ev) {
          setState(newState()..mouse_hover = true);
          if (show_mouseover_rect) {
            update_mouseover_loopout();
          }
        }
        ..onMouseLeave = ((_) {
          setState(newState()..mouse_hover = false);
          if (show_mouseover_rect) {
            update_mouseover_loopout();
          }
        })
        ..onPointerDown = ((ev) {
          if (select_mode && props.selectable) {
            loopout.handle_selection_mouse_down(ev.nativeEvent);
          }
          if (loopout_mode) {
            loopout_length_change();
          }
        })
        ..onPointerUp = ((ev) {
          if (select_mode && props.selectable) {
            loopout.handle_selection_mouse_up(ev.nativeEvent);
          }
        })
        ..className = classname
        ..id = id
        ..key = id)();
    }
  }

  update_mouseover_loopout() {
    //FIXME: implement this
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
