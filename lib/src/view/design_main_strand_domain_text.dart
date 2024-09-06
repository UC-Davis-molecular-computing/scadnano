// @dart=2.9
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/substrand.dart';

import '../state/group.dart';
import '../state/geometry.dart';
import '../state/domain.dart';
import 'pure_component.dart';
import '../state/helix.dart';
import '../state/context_menu.dart';
import '../state/strand.dart';
import '../state/address.dart';
import '../state/modification_type.dart';
import '../app.dart';
import '../constants.dart' as constants;
import '../util.dart' as util;
import '../actions/actions.dart' as actions;

part 'design_main_strand_domain_text.over_react.g.dart';

// general component for "text to a domain" (e.g, strand name, domain name, strand label)
UiFactory<DesignMainStrandDomainTextProps> DesignMainStrandDomainText = _$DesignMainStrandDomainText;

mixin DesignMainStrandDomainTextPropsMixin on UiProps {
  Strand strand;
  Domain domain; // domain next to which we draw strand name
  Helix helix;
  Geometry geometry;
  BuiltMap<String, HelixGroup> helix_groups;
  String text;
  String css_selector_text;

  int font_size;
  int num_stacked;
  String transform;
  Point<num> helix_svg_position;

  List<ContextMenuItem> Function(Strand strand,
      {@required Substrand substrand,
      @required Address address,
      @required ModificationType type}) context_menu_strand;
}

class DesignMainStrandDomainTextProps = UiProps with DesignMainStrandDomainTextPropsMixin;

class DesignMainStrandDomainTextComponent extends UiComponent2<DesignMainStrandDomainTextProps>
    with PureComponent {
  @override
  render() {
    Point<num> start_svg =
        props.helix.svg_base_pos(props.domain.start, props.domain.forward, props.helix_svg_position.y);
    Point<num> end_svg =
        props.helix.svg_base_pos(props.domain.end - 1, props.domain.forward, props.helix_svg_position.y);
    Point<num> mid_svg = (start_svg + end_svg) * 0.5;

    String baseline = props.domain.forward ? 'baseline' : 'hanging';

    // offset depends on whether we are showing DNA and/or domain names, so they don't overlap
    num y_offset = props.num_stacked * props.helix.geometry.base_height_svg;

    var dy = props.geometry.base_height_svg * 0.7 + y_offset;
    if (props.domain.forward) {
      dy = -dy;
    }

    return (Dom.text()
      ..x = '${mid_svg.x}'
      ..y = '${mid_svg.y}'
      ..dy = '${dy}'
      ..id = id()
      ..transform = props.transform
      ..fontSize = props.font_size
      ..dominantBaseline = baseline
      ..className = props.css_selector_text)(props.text);
  }

  String id() => props.strand.id + '_name';

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    var element = querySelector('#${id()}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${id()}');
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation();
      Address address = util.find_closest_address(event, [props.helix], props.helix_groups, props.geometry,
          {props.helix.idx: props.helix_svg_position}.build());
      app.dispatch(actions.ContextMenuShow(
          context_menu: ContextMenu(
              items:
                  props.context_menu_strand(props.strand, substrand: props.domain, address: address).build(),
              position: event.page)));
    }
  }
}
