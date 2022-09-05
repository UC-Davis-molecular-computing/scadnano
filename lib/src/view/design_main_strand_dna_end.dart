import 'dart:html';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:meta/meta.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/linker.dart';
import 'package:scadnano/src/state/loopout.dart';
import 'package:scadnano/src/state/modification_type.dart';

import '../state/address.dart';
import '../state/context_menu.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../state/strand.dart';
import '../state/selectable.dart';
import '../state/dna_end.dart';
import '../state/helix.dart';
import '../state/potential_crossover.dart';
import '../state/domain.dart';
import '../state/substrand.dart';
import '../state/extension.dart';
import '../app.dart';
import '5p_end.dart';
import '3p_end.dart';
import 'design_main_strand_dna_end_moving.dart';
import 'pure_component.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;
import '../util.dart' as util;

part 'design_main_strand_dna_end.over_react.g.dart';

@Factory()
UiFactory<DesignMainDNAEndProps> DesignMainDNAEnd = _$DesignMainDNAEnd;

@Props()
mixin DesignMainDNAEndPropsMixin on UiProps {
  Strand strand;
  Domain domain;
  Extension ext;
  Color color;
  bool is_5p;
  bool is_scaffold;
  bool is_on_extension;

  String transform;
  Helix helix;
  HelixGroup group;
  Geometry geometry;
  bool selected;

  List<ContextMenuItem> Function(Strand strand,
      {@required Domain domain,
      @required Address address,
      @required ModificationType type}) context_menu_strand;

  bool drawing_potential_crossover;
  bool moving_this_dna_end;
  Point<num> helix_svg_position;
}

class DesignMainDNAEndProps = UiProps with DesignMainDNAEndPropsMixin;

@Component2()
class DesignMainDNAEndComponent extends UiComponent2<DesignMainDNAEndProps> with PureComponent {
  DNAEnd get dna_end => props.domain != null
      ? (props.is_5p ? props.domain.dnaend_5p : props.domain.dnaend_3p)
      : props.ext.dnaend_free;

  bool get is_first => props.domain != null ? props.domain.is_first && props.is_5p : props.is_5p;

  bool get is_last => props.domain != null ? props.domain.is_last && !props.is_5p : !props.is_5p;

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

    assert((props.is_on_extension && props.domain == null && props.ext != null) ||
        (!props.is_on_extension && props.domain != null && props.ext == null));

    EndEitherPrimeProps end_props = (props.is_5p ? End5Prime() : End3Prime());
    EndMovingProps end_moving_props = ConnectedEndMoving();

    DNAEnd dna_end;
    int offset;
    Point<num> pos;
    bool forward;

    if (!props.is_on_extension) {
      //XXX: need to listen to onPointerDown instead of onMouseDown for when draggable is enabled,
      // which it is when Shift or Ctrl (or Meta) keys are pressed
      // see here: https://github.com/marcojakob/dart-dnd/issues/27
      forward = props.domain.forward;
      dna_end = props.is_5p ? props.domain.dnaend_5p : props.domain.dnaend_3p;
      offset = props.is_5p ? props.domain.offset_5p : props.domain.offset_3p;
      pos = props.helix.svg_base_pos(offset, props.domain.forward, props.helix_svg_position.y);
    } else {
      // is on extension
      forward = props.ext.adjacent_domain.forward;
      dna_end = props.ext.dnaend_free;

      Point<num> extension_attached_end_svg = util.compute_extension_attached_end_svg(
          props.ext, props.ext.adjacent_domain, props.helix, props.helix_svg_position.y);

      pos = util.compute_extension_free_end_svg(
          extension_attached_end_svg, props.ext, props.ext.adjacent_domain, props.geometry);

      //TODO: apply rotation
    }

    end_props = end_props
      ..on_pointer_down = handle_end_click_select_and_or_move_start
      ..on_pointer_up = handle_end_pointer_up_select
      ..on_mouse_up = handle_end_click_ligate_or_potential_crossover
      ..on_mouse_enter = handle_on_mouse_enter
      ..on_mouse_leave = handle_on_mouse_leave
      ..on_mouse_move = handle_on_mouse_move
      ..pos = pos
      ..color = props.color
      ..classname = classname
      ..forward = forward
      ..id = dna_end.id
      ..key = 'nonmoving-end';

    // draw avatar of moving DNA end if it is moving
    end_moving_props = end_moving_props
      ..dna_end = dna_end
      ..helix = props.helix
      ..color = props.color
      ..forward = forward
      ..is_5p = props.is_5p
      ..svg_position_y = props.helix_svg_position.y
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
      var id = props.domain != null ? props.domain.dnaend_5p.id : props.ext.dnaend_free.id;
      element = querySelector('#${id}');
    } else {
      var id = props.domain != null ? props.domain.dnaend_3p.id : props.ext.dnaend_free.id;
      element = querySelector('#${id}');
    }
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element;
    if (props.is_5p) {
      element = querySelector('#${props.domain.dnaend_5p.id}');
    } else {
      element = querySelector('#${props.domain.dnaend_3p.id}');
    }
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation();
      var address = props.is_5p ? props.domain.address_5p : props.domain.address_3p;
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: props
                  .context_menu_strand(props.strand,
                      domain: props.domain,
                      address: address,
                      type: (props.is_5p ? ModificationType.five_prime : ModificationType.three_prime))
                  .build(),
              position: event.page)));
    }
  }

  handle_end_click_select_and_or_move_start(react.SyntheticPointerEvent event_synthetic) {
    if (end_selectable(dna_end)) {
      if (!props.is_on_extension) {
        // select end
        MouseEvent event = event_synthetic.nativeEvent;
        //On a mac event.button is: 0-left, 1-middle, 2-right.
        //On chrome mac, only handle_end_click_ligate_or_potential_crossover gets
        // called on a right or middle click.
        if (event.button == constants.RIGHT_CLICK_BUTTON || event.button == constants.MIDDLE_CLICK_BUTTON) {
          return;
        }
        dna_end.handle_selection_mouse_down(event);
        // set up drag detection for moving DNA ends
        app.dispatch(actions.DNAEndsMoveStart(offset: dna_end.offset_inclusive, helix: props.helix));
      } else {
        print('not yet implemented moving free end of an extension');
      }
    }
  }

  handle_end_pointer_up_select(react.SyntheticPointerEvent event_synthetic) {
    if (end_selectable(dna_end)) {
      MouseEvent event = event_synthetic.nativeEvent;
      //On a mac event.button is: 0-left, 1-middle, 2-right.
      if (event.button == constants.RIGHT_CLICK_BUTTON || event.button == constants.MIDDLE_CLICK_BUTTON) {
        return;
      }
      dna_end.handle_selection_mouse_up(event);
    }
  }

  handle_end_click_ligate_or_potential_crossover(SyntheticMouseEvent event) {
    if (event.nativeEvent.button != constants.LEFT_CLICK_BUTTON) {
      return;
    }

    if (props.is_on_extension) {
      return;
    }

    if (edit_mode_is_pencil() && !props.drawing_potential_crossover && (is_first || is_last)) {
      // If clicking on end of a strand, start drawing a new crossover
      int offset = props.is_5p ? props.domain.offset_5p : props.domain.offset_3p;
      var start_point_untransformed =
          props.helix.svg_base_pos(offset, props.domain.forward, props.helix_svg_position.y);
      var start_point = props.group.transform_point_main_view(start_point_untransformed, props.geometry);
      var address = Address(helix_idx: props.helix.idx, offset: offset, forward: props.domain.forward);
      var potential_crossover = PotentialCrossover(
        address: address,
        color: props.color.toHexColor().toCssString(),
        dna_end_first_click: dna_end,
        start_point: start_point,
        current_point: start_point,
      );
      app.dispatch(actions.PotentialCrossoverCreate(potential_crossover: potential_crossover));
    } else if (edit_mode_is_pencil() && !props.drawing_potential_crossover && !(is_first || is_last)) {
      // If clicking on end of a domain within a strand (i.e., end of a crossover or loopout),
      // start moving the existing crossover/loopout
      int domain_idx = props.strand.domains.indexOf(props.domain); // XXX: idx in domains, not substrands
      // unlike above, need to find the OPPOSITE end of the crossover/loopout from DNAEnd that was clicked
      Linker linker;
      DNAEnd other_end;
      Domain other_domain;
      if (props.is_5p) {
        /*
        5'   a    3'
        [---------+
                  | <-- linker
        <---------+ <-- clicked here, so need to find PREVIOUS domain before b, which is a
        3'   b    5'
        */
        assert(domain_idx > 0); // since !is_first
        linker = props.strand.linkers[domain_idx - 1];
        int other_domain_idx_in_substrands = linker.prev_domain_idx;
        other_domain = props.strand.substrands[other_domain_idx_in_substrands];
        other_end = other_domain.dnaend_3p; // since clicked end was 5'
      } else {
        /*
        5'   a    3'
        [---------+ <-- clicked here, so need to find NEXT domain after a, which is b
                  | <-- linker
        <---------+
        3'   b    5'
        */
        assert(domain_idx < props.strand.domains.length - 1); // since !is_last
        assert(domain_idx < props.strand.linkers.length); // since one fewer linker than Domain
        linker = props.strand.linkers[domain_idx];
        int other_domain_idx_in_substrands = linker.next_domain_idx;
        other_domain = props.strand.substrands[other_domain_idx_in_substrands];
        other_end = other_domain.dnaend_5p; // since clicked end was 3'
      }
      int other_offset = other_end.offset_inclusive;
      int other_helix_idx = other_domain.helix;
      Point<num> other_helix_svg = app.state.helix_idx_to_svg_position_map[other_helix_idx];
      var start_point_untransformed =
          props.helix.svg_base_pos(other_offset, other_domain.forward, other_helix_svg.y);
      var start_point = props.group.transform_point_main_view(start_point_untransformed, props.geometry);
      var address = Address(helix_idx: other_helix_idx, offset: other_offset, forward: other_domain.forward);
      var potential_crossover = PotentialCrossover(
        address: address,
        color: props.color.toHexColor().toCssString(),
        dna_end_first_click: other_end,
        start_point: start_point,
        current_point: start_point,
        linker: linker,
      );
      app.dispatch(actions.PotentialCrossoverCreate(potential_crossover: potential_crossover));
    } else if (edit_mode_is_pencil() && props.drawing_potential_crossover && (is_first || is_last)) {
      // if clicking while drawing new potential crossover, make it into an actual crossover
      PotentialCrossover potential_crossover = app.store_potential_crossover.state;
      if (props.is_5p == potential_crossover.dna_end_first_click.is_5p) {
        // can only connect opposite type ends with crossover
        return;
      }

      // remove view of potential crossover
      app.dispatch(actions.PotentialCrossoverRemove());

      // edit design
      if ((is_first && potential_crossover.dna_end_first_click.substrand_is_last) ||
          (is_last && potential_crossover.dna_end_first_click.substrand_is_first)) {
        assert(potential_crossover.linker == null);
        app.dispatch(actions.JoinStrandsByCrossover(
            dna_end_first_click: potential_crossover.dna_end_first_click, dna_end_second_click: dna_end));
      } else if (potential_crossover.linker != null) {
        app.dispatch(
            actions.MoveLinker(potential_crossover: potential_crossover, dna_end_second_click: dna_end));
      }
    } else if (edit_mode_is_ligate() && (is_first || is_last)) {
      app.dispatch(actions.Ligate(dna_end: dna_end));
    }
  }

  handle_on_mouse_leave(SyntheticMouseEvent event) {
    util.mouse_leave_update_mouseover();
  }

  handle_on_mouse_enter(SyntheticMouseEvent event) {
    util.update_mouseover(event, props.helix, props.helix_svg_position);
  }

  handle_on_mouse_move(SyntheticMouseEvent event) {
    util.update_mouseover(event, props.helix, props.helix_svg_position);
  }
}
