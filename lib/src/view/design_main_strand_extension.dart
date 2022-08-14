import 'dart:html';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';
import 'package:react/react.dart' as react;
import 'package:scadnano/src/state/modification_type.dart';
import 'package:scadnano/src/view/transform_by_helix_group.dart';

import '../state/strand.dart';
import '../state/address.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../app.dart';
import '../state/helix.dart';
import '../state/domain.dart';
import '../state/extension.dart';
import '../util.dart' as util;
import '../state/selectable.dart';
import 'design_main_strand_dna_end.dart';
import 'pure_component.dart';
import '../state/context_menu.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_main_strand_extension.over_react.g.dart';

@Factory()
UiFactory<DesignMainExtensionProps> DesignMainExtension = _$DesignMainExtension;

@Props()
mixin DesignMainExtensionPropsMixin on UiProps {
  Extension ext;

  Domain adjacent_domain;
  Helix adjacent_helix;

  Color color;

  Strand strand;
  String strand_tooltip;
  String transform;
  Point<num> adjacent_helix_svg_position;

  List<ContextMenuItem> Function(Strand strand,
      {@required Domain domain,
      @required Address address,
      @required ModificationType type}) context_menu_strand;

  bool selected;

  BuiltMap<int, Helix> helices;
  BuiltMap<String, HelixGroup> groups;
  Geometry geometry;
}

class DesignMainExtensionProps = UiProps with DesignMainExtensionPropsMixin, TransformByHelixGroupPropsMixin;

@Component2()
class DesignMainExtensionComponent extends UiComponent2<DesignMainExtensionProps>
    with PureComponent, TransformByHelixGroup<DesignMainExtensionProps> {
  @override
  render() {
    var ext = props.ext;
    String id = props.ext.id;
    var adj_dom = props.adjacent_domain;
    var adj_helix = props.adjacent_helix;

    int end_offset = ext.is_5p ? adj_dom.offset_5p : adj_dom.offset_3p;
    Point<num> end_svg =
        adj_helix.svg_base_pos(end_offset, adj_dom.forward, props.adjacent_helix_svg_position.y);
    num x = end_svg.x;
    num y = end_svg.y;
    //TODO this is just to test; adjust these offsets
    x += 20;
    y += 10;
    Point<num> start_svg = Point<num>(x, y);

    var classname = constants.css_selector_extension;
    if (props.selected) {
      classname += ' ' + constants.css_selector_selected;
    }
    if (props.strand.is_scaffold) {
      classname += ' ' + constants.css_selector_scaffold;
    }

    return (Dom.line()
      ..className = classname
      ..onPointerDown = handle_click_down
      ..onPointerUp = handle_click_up
      ..stroke = props.color.toHexColor().toCssString()
      ..transform = props.transform
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..id = id
      ..key = id)(Dom.svgTitle()(tooltip_text(ext) + '\n' + props.strand_tooltip));
  }

  handle_click_down(react.SyntheticPointerEvent event_syn) {
    MouseEvent event = event_syn.nativeEvent;
    if (event.button == constants.LEFT_CLICK_BUTTON) {
      if (extension_selectable(props.ext)) {
        // select/deselect
        props.ext.handle_selection_mouse_down(event);
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
      if (extension_selectable(props.ext) && !currently_moving) {
        props.ext.handle_selection_mouse_up(event_syn.nativeEvent);
      }
    }
  }

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    var element = querySelector('#${props.ext.id}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.ext.id}');
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation();
      Address address = util.get_address_on_helix(event, props.adjacent_helix,
          props.groups[props.adjacent_helix.group], props.geometry, props.adjacent_helix_svg_position);
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items: props
                  .context_menu_strand(props.strand, domain: props.adjacent_domain, address: address)
                  .build(),
              position: event.page)));
    }
  }
}

tooltip_text(Extension ext) =>
    ''
        '${ext.is_5p ? "5'" : "3'"} extension:\n'
        '    num_bases=${ext.num_bases}\n' +
    (ext.name == null ? "" : "\n    name=${ext.name}") +
    (ext.label == null ? "" : "\n    label=${ext.label.toString()}");
