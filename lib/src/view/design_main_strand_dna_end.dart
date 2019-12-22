import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:over_react/over_react_redux.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/dna_end.dart';
import 'package:scadnano/src/state/edit_mode.dart';
//import 'package:dnd/dnd.dart';

import 'package:scadnano/src/state/helix.dart';
import 'package:scadnano/src/state/potential_crossover.dart';
import '../state/app_state.dart';
import 'package:scadnano/src/state/select_mode.dart';
import '../state/bound_substrand.dart';
import '../app.dart';
import 'design_main.dart';
import '../actions/actions.dart' as actions;

part 'design_main_strand_dna_end.over_react.g.dart';

Map mapStateToPropsWithOwnProps(AppState state, DesignMainDNAEndProps props) {
  SelectModeChoice select_mode_choice;
  if (props.is_5p) {
    select_mode_choice =
        props.substrand.is_first ? SelectModeChoice.end_5p_strand : SelectModeChoice.end_5p_substrand;
  } else {
    select_mode_choice =
        props.substrand.is_last ? SelectModeChoice.end_3p_strand : SelectModeChoice.end_3p_substrand;
  }
  bool selected = DEBUG_SELECT
      ? false
      : state.ui_state.selectables_store
          .selected(props.is_5p ? props.substrand.dnaend_5p : props.substrand.dnaend_3p);
  bool selectable =
      DEBUG_SELECT ? false : state.ui_state.select_mode_state.modes.contains(select_mode_choice);
  return DesignMainDNAEnd()
    ..selected = selected
    ..selectable = selectable
    ..helix = state.dna_design.helices[props.substrand.helix]
    ..select_mode = state.ui_state.edit_modes.contains(EditModeChoice.select)
    ..pencil_mode = state.ui_state.edit_modes.contains(EditModeChoice.pencil)
    ..join_mode = state.ui_state.edit_modes.contains(EditModeChoice.ligate)
    ..drawing_potential_crossover = state.ui_state.drawing_potential_crossover;
}

UiFactory<DesignMainDNAEndProps> ConnectedDesignMainDNAEnd = connect<AppState, DesignMainDNAEndProps>(
    mapStateToPropsWithOwnProps: mapStateToPropsWithOwnProps)(DesignMainDNAEnd);

@Factory()
UiFactory<DesignMainDNAEndProps> DesignMainDNAEnd = _$DesignMainDNAEnd;

@Props()
class _$DesignMainDNAEndProps extends UiProps {
  BoundSubstrand substrand;
  Color color;
  bool is_5p;

  Helix helix;
  bool selected;
  bool selectable;
  bool select_mode;
  bool pencil_mode;
  bool join_mode;
  bool drawing_potential_crossover;
}

@Component2()
class DesignMainDNAEndComponent extends UiComponent2<DesignMainDNAEndProps> {
  DNAEnd get dna_end => props.is_5p ? props.substrand.dnaend_5p : props.substrand.dnaend_3p;

  bool get is_first => props.substrand.is_first && props.is_5p;

  bool get is_last => props.substrand.is_last && !props.is_5p;

  @override
  render() {
    BoundSubstrand substrand = this.props.substrand;

    var id = dna_end.id();

    var helix = app.state.dna_design.helices[substrand.helix];
    var offset = substrand.offset_5p;
    var right = substrand.forward;

    var classname = '${props.is_5p ? 'five' : 'three'}-prime-end' +
        (is_first && props.is_5p ? '-first-substrand' : '') +
        (is_last && !props.is_5p ? '-last-substrand' : '');

//    if (substrand.selected_5p()) {
    if (props.selected) {
      classname += ' selected';
    }
    if (props.selectable) {
      classname += ' selectable';
    }

    //XXX: width, height, rx, ry should be do-able in CSS. However, Firefox won't display properly
    // if they are specified in CSS, but it will if they are specified here.

    //[{ isDragging }, drag]
    if (USING_REACT_DND) {
//      var param = {
//        'item': {'type': '5p'},
//        'collect': (monitor) => {
//              'isDragging': monitor.isDragging(),
//            },
//      };
//      List drag_ret = useDrag(param);
//      var props = drag_ret[0];
//      var drag = drag_ret[1];
//      bool isDragging = props['isDragging'];
    } else {
      var on_pointer_down = handle_end_click_select_and_or_move_start;
      if (props.is_5p) {
        var pos = helix.svg_base_pos(offset, right);
        num width = 7;
        //XXX: need to listen to onPointerDown instead of onMouseDown for when draggable is enabled,
        // which it is when Shift or Ctrl (or Meta) keys are pressed
        // see here: https://github.com/marcojakob/dart-dnd/issues/27
        return (Dom.rect()
          ..onPointerDown = on_pointer_down //dna_end.handle_selection
//          ..onMouseDown = handle_end_click_select_and_or_move //dna_end.handle_selection
          ..onMouseUp = ((ev) => handle_end_click_ligate_or_potential_crossover())
          ..className = classname
          ..x = '${pos.x - width / 2}'
          ..y = '${pos.y - width / 2}'
          ..width = '${width}px'
          ..height = '${width}px'
          ..rx = '1.5px'
          ..ry = '1.5px'
          ..fill = props.color.toRgbColor().toCssString()
          ..id = id)();
      } else {
        var offset = substrand.offset_3p;
        var direction = substrand.forward;
        var helix = app.state.dna_design.helices[substrand.helix];
        var pos = helix.svg_base_pos(offset, direction);
        var points;
        num scale = 3.7;
        if (!substrand.forward) {
          points = '${pos.x - scale},${pos.y} '
              '${pos.x + 0.9 * scale},${pos.y + scale} '
              '${pos.x + 0.9 * scale},${pos.y - scale}';
        } else {
          points = '${pos.x + scale},${pos.y} '
              '${pos.x - 0.9 * scale},${pos.y + scale} '
              '${pos.x - 0.9 * scale},${pos.y - scale}';
        }

        return (Dom.polygon()
          ..onPointerDown = on_pointer_down //dna_end.handle_selection
//          ..onMouseDown = handle_end_click_select_and_or_move //dna_end.handle_selection
          ..onMouseUp = ((ev) => handle_end_click_ligate_or_potential_crossover())
          ..className = classname
          ..points = points
          ..fill = props.color.toRgbColor().toCssString()
          ..id = id)();
      }
    }
  }

//  handle_end_click_select_and_or_move(react.SyntheticPointerEvent event) {
  handle_end_click_select_and_or_move_start(react.SyntheticPointerEvent event) {
    // select end
    dna_end.handle_selection(event);

    if (props.select_mode) {
      // set up drag detection for moving DNA ends
      app.dispatch(actions.DNAEndsMoveStart(offset: dna_end.offset_inclusive, helix: props.helix));
    }
  }

  handle_end_click_ligate_or_potential_crossover() {
    if (props.pencil_mode && !props.drawing_potential_crossover && (is_first || is_last)) {
      int offset = props.is_5p ? props.substrand.offset_5p : props.substrand.offset_3p;
      Point<num> start_point = props.helix.svg_base_pos(offset, props.substrand.forward);
      var potential_crossover = PotentialCrossover(
        helix_idx: props.helix.idx,
        forward: props.substrand.forward,
        offset: offset,
        color: props.color.toHexColor().toCssString(),
        dna_end_first_click: dna_end,
        start_point: start_point,
        current_point: start_point,
      );
      app.dispatch(actions.PotentialCrossoverCreate(potential_crossover: potential_crossover));
    } else if (props.pencil_mode && props.drawing_potential_crossover && (is_first || is_last)) {
      PotentialCrossover potential_crossover = app.store_potential_crossover.state;

      //FIXME: can we avoid this global variable access? probably not since there's multiple stores
      app.dispatch(actions.PotentialCrossoverRemove());
      if ((is_first && potential_crossover.dna_end_first_click.substrand_is_last) ||
          (is_last && potential_crossover.dna_end_first_click.substrand_is_first)) {
        app.dispatch(actions.JoinStrandsByCrossover(
            potential_crossover: potential_crossover, dna_end_second_click: dna_end));
      }
    } else if (props.join_mode && (is_first || is_last)) {
      app.dispatch(actions.Ligate(dna_end: dna_end));
    }
  }
}
