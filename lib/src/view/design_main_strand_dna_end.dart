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
import 'package:scadnano/src/view/design_main_strand_dna_extension_end_moving.dart';

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
import 'design_main_strand.dart';
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
  late Strand strand;
  Domain? domain; // exactly one of domain or ext will be non-null
  Extension? ext;
  late Color strand_color;
  late bool is_5p;
  late bool is_scaffold;

  late String transform;
  late Helix helix;
  late HelixGroup group;
  late Geometry geometry;
  late bool selected;

  late ContextMenuStrand context_menu_strand;

  late bool drawing_potential_crossover;
  late bool moving_this_dna_end;
  late Point<double> helix_svg_position;
  late bool retain_strand_color_on_selection;
}

class DesignMainDNAEndProps = UiProps with DesignMainDNAEndPropsMixin;

@Component2()
class DesignMainDNAEndComponent extends UiComponent2<DesignMainDNAEndProps> with PureComponent {
  DNAEnd get dna_end => props.domain != null
      ? (props.is_5p ? props.domain!.dnaend_5p : props.domain!.dnaend_3p)
      : props.ext!.dnaend_free;

  bool get is_first => props.domain != null ? props.domain!.is_first && props.is_5p : props.is_5p;

  bool get is_last => props.domain != null ? props.domain!.is_last && !props.is_5p : !props.is_5p;

  bool get is_on_extension => props.ext != null;

  @override
  render() {
    assert(props.domain == null && props.ext != null || props.domain != null && props.ext == null);

    String classname;
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
      if (props.retain_strand_color_on_selection) {
        classname += ' ' + constants.css_selector_selected;
      } else {
        classname += ' ' + constants.css_selector_selected_pink;
      }
    }
    if (props.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    EndEitherPrimeProps end_props = (props.is_5p ? End5Prime() : End3Prime());
    EndMovingProps end_moving_props = ConnectedEndMoving()..svg_position_y = props.helix_svg_position.y;

    ExtensionEndMovingProps extension_end_moving_props = ConnectedExtensionEndMoving();

    DNAEnd dna_end;
    int offset;
    Point<double> pos;
    bool forward;
    double rotation_degrees = 0;

    Point<double>? extension_attached_end_svg = null;
    Color color = props.strand_color;

    if (!this.is_on_extension) {
      //XXX: need to listen to onPointerDown instead of onMouseDown for when draggable is enabled,
      // which it is when Shift or Ctrl (or Meta) keys are pressed
      // see here: https://github.com/marcojakob/dart-dnd/issues/27
      Domain domain = props.domain!;
      forward = domain.forward;
      dna_end = props.is_5p ? domain.dnaend_5p : domain.dnaend_3p;
      offset = props.is_5p ? domain.offset_5p : domain.offset_3p;
      pos = props.helix.svg_base_pos(offset, domain.forward, props.helix_svg_position.y);
      if (domain.color != null) {
        color = domain.color!;
      }
    } else {
      // is on extension
      Extension ext = props.ext!;
      forward = ext.adjacent_domain.forward;
      dna_end = ext.dnaend_free;

      extension_attached_end_svg = util.compute_extension_attached_end_svg(
          ext, ext.adjacent_domain, props.helix, props.helix_svg_position.y);
      pos = util.compute_extension_free_end_svg(
          extension_attached_end_svg, ext, ext.adjacent_domain, props.geometry);

      rotation_degrees = ext.compute_rotation();
      if (ext.color != null) {
        color = ext.color!;
      }
    }

    end_props = end_props
      ..on_pointer_down = handle_end_click_select_and_or_move_start
      ..on_pointer_up = handle_end_pointer_up_select
      ..on_mouse_up = handle_end_click_ligate_or_potential_crossover
      ..on_mouse_enter = handle_on_mouse_enter
      ..on_mouse_leave = handle_on_mouse_leave
      ..on_mouse_move = handle_on_mouse_move
      ..classname = classname
      ..pos = pos // TODO: why doesn't this the overreact analyzer error since pos is required?
      ..color = color
      ..forward = forward
      ..transform = 'rotate(${rotation_degrees})'
      ..id_ = dna_end.id
      ..key = 'nonmoving-end';

    // draw avatar of moving DNA end if it is moving
    end_moving_props = end_moving_props
      ..dna_end = dna_end
      ..helix = props.helix
      ..color = color
      ..forward = forward
      ..is_5p = props.is_5p
      ..transform = 'rotate(${rotation_degrees})'
      ..svg_position_y = props.helix_svg_position.y
      ..key = 'moving-end';

    // draw avatar of moving extension if it is moving
    extension_end_moving_props = extension_end_moving_props
      ..dna_end = dna_end
      ..ext = props.ext
      ..geometry = props.geometry
      ..attached_end_svg = extension_attached_end_svg
      ..helix = props.helix
      ..group = props.group
      ..color = color
      ..forward = forward
      ..is_5p = props.is_5p
      ..key = 'moving-extension';

    return (Dom.g()
      ..className = constants.css_selector_end_parent_group
      ..transform = props.transform)(
      end_props(),
      end_moving_props(),
      extension_end_moving_props(),
    );
  }

  @override
  componentDidMount() {
    String id;
    if (props.is_5p) {
      id = props.domain != null ? props.domain!.dnaend_5p.id : props.ext!.dnaend_free.id;
    } else {
      id = props.domain != null ? props.domain!.dnaend_3p.id : props.ext!.dnaend_free.id;
    }
    var element = querySelector('#${id}')!;
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    String id;
    if (props.is_5p) {
      id = props.domain != null ? props.domain!.dnaend_5p.id : props.ext!.dnaend_free.id;
    } else {
      id = props.domain != null ? props.domain!.dnaend_3p.id : props.ext!.dnaend_free.id;
    }
    var element = querySelector('#${id}')!;
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev as MouseEvent;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation();
      // If they clicked on a domain, send the domain's address to the context menu
      // otherwise it's an extension, then we send the address of the adjacent domain's 5'/3' end.
      Domain domain = this.is_on_extension ? props.ext!.adjacent_domain : props.domain!;
      Address address = props.is_5p ? domain.address_5p : domain.address_3p;

      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: props
                  .context_menu_strand(props.strand,
                      domain: domain,
                      address: address,
                      type: (props.is_5p ? ModificationType.five_prime : ModificationType.three_prime))
                  .build(),
              position: util.from_point_num(event.page))));
    }
  }

  handle_end_click_select_and_or_move_start(react.SyntheticPointerEvent event_synthetic) {
    if (end_selectable(dna_end)) {
      if (!this.is_on_extension) {
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
        Extension ext = props.ext!;
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
        Point<double> extension_attached_end_svg = util.compute_extension_attached_end_svg(
            ext, ext.adjacent_domain, props.helix, props.helix_svg_position.y);

        // extension_start_point is in helix group coordinate space, so add it with helix group position
        // to get canvas coordinate space
        extension_attached_end_svg += props.group.translation(props.geometry);

        Point<double> pos = util.compute_extension_free_end_svg(
            extension_attached_end_svg, ext, ext.adjacent_domain, props.geometry);
        app.dispatch(actions.DNAExtensionsMoveStart(start_point: pos, helix: props.helix));
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

    if (this.is_on_extension) {
      return;
    }

    if (edit_mode_is_pencil() && !props.drawing_potential_crossover && (is_first || is_last)) {
      var domain = props.domain;
      if (domain == null) {
        throw AssertionError('domain should not be null');
      }
      // If clicking on end of a strand, start drawing a new crossover
      int offset = props.is_5p ? domain.offset_5p : domain.offset_3p;
      var start_point_untransformed =
          props.helix.svg_base_pos(offset, domain.forward, props.helix_svg_position.y);
      var start_point = props.group.transform_point_main_view(start_point_untransformed, props.geometry);
      var address = Address(helix_idx: props.helix.idx, offset: offset, forward: domain.forward);
      var potential_crossover = PotentialCrossover(
        address: address,
        color: props.strand_color.toHexColor().toCssString(),
        dna_end_first_click: dna_end,
        start_point: start_point,
        current_point: start_point,
      );
      app.dispatch(actions.PotentialCrossoverCreate(potential_crossover: potential_crossover));
    } else if (edit_mode_is_pencil() && !props.drawing_potential_crossover && !(is_first || is_last)) {
      var domain = props.domain;
      if (domain == null) {
        throw AssertionError('domain should not be null');
      }
      // If clicking on end of a domain within a strand (i.e., end of a crossover or loopout),
      // start moving the existing crossover/loopout
      int domain_idx = props.strand.domains.indexOf(domain); // XXX: idx in domains, not substrands
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
        other_domain = props.strand.substrands[other_domain_idx_in_substrands] as Domain;
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
        other_domain = props.strand.substrands[other_domain_idx_in_substrands] as Domain;
        other_end = other_domain.dnaend_5p; // since clicked end was 3'
      }
      int other_offset = other_end.offset_inclusive;
      int other_helix_idx = other_domain.helix;
      Point<double> other_helix_svg = app.state.helix_idx_to_svg_position_map[other_helix_idx]!;
      var start_point_untransformed =
          props.helix.svg_base_pos(other_offset, other_domain.forward, other_helix_svg.y);
      var start_point = props.group.transform_point_main_view(start_point_untransformed, props.geometry);
      var address = Address(helix_idx: other_helix_idx, offset: other_offset, forward: other_domain.forward);
      var potential_crossover = PotentialCrossover(
        address: address,
        color: props.strand_color.toHexColor().toCssString(),
        dna_end_first_click: other_end,
        start_point: start_point,
        current_point: start_point,
        linker: linker,
      );
      app.dispatch(actions.PotentialCrossoverCreate(potential_crossover: potential_crossover));
    } else if (edit_mode_is_pencil() && props.drawing_potential_crossover && (is_first || is_last)) {
      // if clicking while drawing new potential crossover, make it into an actual crossover
      PotentialCrossover potential_crossover = app.store_potential_crossover.state!;
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
