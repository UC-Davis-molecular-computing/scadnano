import 'dart:html';
import 'dart:math';

import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/context_menu.dart';
import 'package:scadnano/src/state/geometry.dart';
import 'package:scadnano/src/state/group.dart';
import 'package:scadnano/src/state/strand.dart';
import 'package:built_collection/built_collection.dart';

import '../state/selectable.dart';
import '../state/dna_end.dart';
import '../state/helix.dart';
import '../state/potential_crossover.dart';
import '../state/domain.dart';
import '../app.dart';
import '5p_end.dart';
import '3p_end.dart';
import 'design_main_strand_dna_end_moving.dart';
import 'pure_component.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_main_strand_dna_end.over_react.g.dart';

@Factory()
UiFactory<DesignMainDNAEndProps> DesignMainDNAEnd = _$DesignMainDNAEnd;

@Props()
mixin DesignMainDNAEndPropsMixin on UiProps {
  Strand strand;
  Domain domain;
  Color color;
  bool is_5p;
  bool is_scaffold;

  String transform;
  Helix helix;
  HelixGroup group;
  Geometry geometry;
  bool selected;
  List<ContextMenuItem> Function(Strand strand, {bool is_5p}) context_menu_strand;
  bool drawing_potential_crossover;
  bool moving_this_dna_end;
}

class DesignMainDNAEndProps = UiProps with DesignMainDNAEndPropsMixin;

@Component2()
class DesignMainDNAEndComponent extends UiComponent2<DesignMainDNAEndProps> with PureComponent {
  DNAEnd get dna_end => props.is_5p ? props.domain.dnaend_5p : props.domain.dnaend_3p;

  bool get is_first => props.domain.is_first && props.is_5p;

  bool get is_last => props.domain.is_last && !props.is_5p;

  @override
  render() {
    var classname;
    if (props.is_5p) {
      if (is_first && props.is_5p) {
        classname = constants.css_selector_end_5p_strand;
      } else {
        classname = constants.css_selector_end_5p_domain;
      }
    } else {
      if (is_last && !props.is_5p) {
        classname = constants.css_selector_end_3p_strand;
      } else {
        classname = constants.css_selector_end_3p_domain;
      }
    }

    if (props.selected) {
      classname += ' ' + constants.css_selector_selected;
    }
    if (props.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    //XXX: need to listen to onPointerDown instead of onMouseDown for when draggable is enabled,
    // which it is when Shift or Ctrl (or Meta) keys are pressed
    // see here: https://github.com/marcojakob/dart-dnd/issues/27
    Domain substrand = this.props.domain;
    DNAEnd dna_end = props.is_5p ? substrand.dnaend_5p : substrand.dnaend_3p;
    var helix = app.state.design.helices[substrand.helix];
    var offset = props.is_5p ? substrand.offset_5p : substrand.offset_3p;
    var pos = helix.svg_base_pos(offset, substrand.forward);

    EndEitherPrimeProps end_props = (props.is_5p ? End5Prime() : End3Prime());
    end_props = end_props
      ..on_pointer_down = handle_end_click_select_and_or_move_start
      ..on_pointer_up = handle_end_pointer_up_select
      ..on_mouse_up = handle_end_click_ligate_or_potential_crossover
      ..pos = pos
      ..color = props.color
      ..classname = classname
      ..forward = substrand.forward
      ..id = dna_end.id()
      ..key = 'nonmoving-end';

    // draw avatar of moving DNA end if it is moving
    EndMovingProps end_moving_props = ConnectedEndMoving();
    end_moving_props = end_moving_props
      ..dna_end = dna_end
      ..helix = helix
      ..color = props.color
      ..forward = substrand.forward
      ..is_5p = props.is_5p
      ..key = 'moving-end';

    return (Dom.g()
      ..className = constants.css_selector_end_parent_group
      ..transform = props.transform)(
      end_props(),
      end_moving_props(),
    );
  }

  @override
  componentDidMount() {
    var element;
    if (props.is_5p) {
      element = querySelector('#${props.domain.dnaend_5p.id()}');
    } else {
      element = querySelector('#${props.domain.dnaend_3p.id()}');
    }
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element;
    if (props.is_5p) {
      element = querySelector('#${props.domain.dnaend_5p.id()}');
    } else {
      element = querySelector('#${props.domain.dnaend_3p.id()}');
    }
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation();
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: props.context_menu_strand(props.strand, is_5p: props.is_5p).build(),
              position: event.page)));
    }
  }

//  handle_end_click_select_and_or_move(react.SyntheticPointerEvent event) {
  handle_end_click_select_and_or_move_start(react.SyntheticPointerEvent event_synthetic) {
    if (end_selectable(dna_end)) {
      // select end
      MouseEvent event = event_synthetic.nativeEvent;
      if (event.button == constants.RIGHT_CLICK_BUTTON || event.button == constants.MIDDLE_CLICK_BUTTON) {
        return;
      }
      dna_end.handle_selection_mouse_down(event);
      // set up drag detection for moving DNA ends
      app.dispatch(actions.DNAEndsMoveStart(offset: dna_end.offset_inclusive, helix: props.helix));
    }
  }

  handle_end_pointer_up_select(react.SyntheticPointerEvent event_synthetic) {
    if (end_selectable(dna_end)) {
      MouseEvent event = event_synthetic.nativeEvent;
      dna_end.handle_selection_mouse_up(event);
    }
  }

  handle_end_click_ligate_or_potential_crossover(SyntheticMouseEvent event) {
    if (event.nativeEvent.button != constants.LEFT_CLICK_BUTTON) {
      return;
    }

    if (edit_mode_is_pencil() && !props.drawing_potential_crossover && (is_first || is_last)) {
      int offset = props.is_5p ? props.domain.offset_5p : props.domain.offset_3p;
      var start_point_untransformed = props.helix.svg_base_pos(offset, props.domain.forward);
      var start_point = props.group.transform_point_main_view(start_point_untransformed, props.geometry);
      var potential_crossover = PotentialCrossover(
        helix_idx: props.helix.idx,
        forward: props.domain.forward,
        offset: offset,
        color: props.color.toHexColor().toCssString(),
        dna_end_first_click: dna_end,
        start_point: start_point,
        current_point: start_point,
      );
      app.dispatch(actions.PotentialCrossoverCreate(potential_crossover: potential_crossover));
    } else if (edit_mode_is_pencil() && props.drawing_potential_crossover && (is_first || is_last)) {
      PotentialCrossover potential_crossover = app.store_potential_crossover.state;
      if (props.is_5p == potential_crossover.dna_end_first_click.is_5p) {
        // can only connect opposite type ends with crossover
        return;
      }
      //FIXME: can we avoid this global variable access? probably not since there's multiple stores
      app.dispatch(actions.PotentialCrossoverRemove());
      if ((is_first && potential_crossover.dna_end_first_click.substrand_is_last) ||
          (is_last && potential_crossover.dna_end_first_click.substrand_is_first)) {
        app.dispatch(actions.JoinStrandsByCrossover(
            dna_end_first_click: potential_crossover.dna_end_first_click, dna_end_second_click: dna_end));
      }
    } else if (edit_mode_is_ligate() && (is_first || is_last)) {
      app.dispatch(actions.Ligate(dna_end: dna_end));
    }
  }
}
