import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/view/transform_by_helix_group.dart';

import '../state/strand.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../app.dart';
import '../state/helix.dart';
import '../state/domain.dart';
import '../util.dart' as util;
import '../state/selectable.dart';
import 'pure_component.dart';
import '../state/context_menu.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_main_strand_domain.over_react.g.dart';

@Factory()
UiFactory<DesignMainDomainProps> DesignMainDomain = _$DesignMainDomain;

@Props()
mixin DesignMainDomainPropsMixin on UiProps {
  Domain domain;
  Color color;
  String dna_sequence;

  Helix helix;
  String strand_tooltip;
  Strand strand;
  String transform;
  List<ContextMenuItem> Function(Strand strand, {Domain domain, Address address}) context_menu_strand;
  bool selected;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;
}

class DesignMainDomainProps = UiProps with DesignMainDomainPropsMixin, TransformByHelixGroupPropsMixin;

@Component2()
class DesignMainDomainComponent extends UiComponent2<DesignMainDomainProps>
    with PureComponent, TransformByHelixGroup<DesignMainDomainProps> {
  @override
  render() {
    Domain domain = props.domain;
    String id = domain.id;

    Point<num> start_svg = props.helix.svg_base_pos(domain.offset_5p, domain.forward);
    Point<num> end_svg = props.helix.svg_base_pos(domain.offset_3p, domain.forward);

    var classname = constants.css_selector_domain;
    if (props.selected) {
      classname += ' ' + constants.css_selector_selected;
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    return (Dom.line()
      ..className = classname
      ..onClick = _handle_click_for_nick_insertion_deletion
      // TODO(benlee12): add listener for adding info previously from mouseover data
      // update ui state's some new domain field that tracks which domain is being hovered over
      // --> displays info in footer
      ..onMouseLeave = ((_) => util.mouse_leave_update_mouseover())
      //XXX: it matters that we reference props.mouseover_datas, not a local variable
      // this ensures that when subsequent mouse events happen, the most recent mouseover_datas is examined,
      // otherwise the callback is not updated until render executes again
      ..onMouseEnter = ((event) => util.update_mouseover(event, props.helix))
      ..onMouseMove = ((event) => util.update_mouseover(event, props.helix))
      ..onPointerDown = handle_click_down
      ..onPointerUp = handle_click_up
      ..stroke = props.color.toHexColor().toCssString()
      ..transform = props.transform
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..id = id
      ..key = id)(Dom.svgTitle()(tooltip_text(domain) + '\n' + props.strand_tooltip));
  }

  _handle_click_for_nick_insertion_deletion(SyntheticMouseEvent event_syn) {
    if (edit_mode_is_nick() || edit_mode_is_insertion() || edit_mode_is_deletion()) {
      var domain = props.domain;
      MouseEvent event = event_syn.nativeEvent;
      var group = app.state.design.groups[props.helix.group];
      var geometry = app.state.design.geometry;
      var address = util.get_address_on_helix(event, props.helix, group, geometry);
      int offset = address.offset;

      if (offset <= domain.start || offset >= domain.end) {
        return; // cannot have nick/insertion/deletion on end
      }

      // if Ctrl key is pressed (Windows/Linux) or Cmd key (Mac), add deletions/insertions to all helices
      bool all_helices = event.ctrlKey || event.metaKey;

      if (edit_mode_is_nick()) {
        if (offset <= domain.start + 1 || offset >= domain.end - 1) {
          return; // need remaining substrands to be length at least 2
        }
        app.dispatch(actions.Nick(domain: domain, offset: offset));
      } else if (edit_mode_is_insertion()) {
        app.dispatch(actions.InsertionAdd(domain: domain, offset: offset, all_helices: all_helices));
      } else if (edit_mode_is_deletion()) {
        app.dispatch(actions.DeletionAdd(domain: domain, offset: offset, all_helices: all_helices));
      }
    }
  }

  handle_click_down(react.SyntheticPointerEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    if (event.button == constants.LEFT_CLICK_BUTTON) {
      if (domain_selectable(props.domain)) {
        // select/deselect
        props.domain.handle_selection_mouse_down(event);
        // set up drag detection for moving DNA ends
        var address = util.find_closest_address(event, [props.helix], props.groups, props.geometry);
        app.dispatch(actions.DomainsMoveStartSelectedDomains(address: address));
      }
    }
  }

  handle_click_up(react.SyntheticPointerEvent event_syn) {
    if (event_syn.nativeEvent.button == constants.LEFT_CLICK_BUTTON) {
      //XXX: This is tricky. If we condition on !props.currently_moving, then this achieves something we
      // want, which is that if we are moving a group of strands, and we are in a disallowed position where
      // the pointer itself (so also some strands) are positioned directly over a visible part of a strand,
      // then it would otherwise become selected on mouse up, when really we just want to end the move.
      bool currently_moving = app.state.ui_state.strands_move != null ||
          app.state.ui_state.domains_move != null ||
          app.state.ui_state.dna_ends_are_moving;
      if (domain_selectable(props.domain) && !currently_moving) {
        props.domain.handle_selection_mouse_up(event_syn.nativeEvent);
      }
    }
  }

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    var element = querySelector('#${props.domain.id}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.domain.id}');
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation();
      Address address =
          util.get_address_on_helix(event, props.helix, props.groups[props.helix.group], props.geometry);
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: props.context_menu_strand(props.strand, domain: props.domain, address: address).build(),
              position: event.page)));
    }
  }
}

tooltip_text(Domain domain) =>
    ''
        '${domain.forward ? 'forward' : 'reverse'} domain:\n'
        '    length=${domain.dna_length()}\n'
        '    helix=${domain.helix}\n'
        '    start=${domain.start}\n'
        '    end=${domain.end}' +
    (domain.name == null ? "" : "\n    name=${domain.name}") +
    (domain.label == null ? "" : "\n    label=${domain.label.toString()}");
