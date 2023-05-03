import 'dart:html';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:over_react/over_react.dart';
import 'package:built_collection/built_collection.dart';
import 'package:scadnano/src/state/substrand.dart';

import '../state/strand.dart';
import '../state/address.dart';
import '../state/geometry.dart';
import '../state/group.dart';
import '../app.dart';
import '../state/helix.dart';
import '../state/domain.dart';
import '../util.dart' as util;
import '../state/selectable.dart';
import 'design_main_strand_dna_end.dart';
import 'pure_component.dart';
import '../state/context_menu.dart';
import '../state/modification_type.dart';
import '../actions/actions.dart' as actions;
import '../constants.dart' as constants;

part 'design_main_strand_domain_name.over_react.g.dart';

UiFactory<DesignMainStrandDomainNameProps> DesignMainStrandDomainName = _$DesignMainStrandDomainName;

mixin DesignMainStrandDomainNamePropsMixin on UiProps {
  Strand strand;
  Domain domain;
  Helix helix;
  Geometry geometry;
  BuiltMap<String, HelixGroup> helix_groups;

  int font_size;
  bool show_dna;
  String transform;
  Point<num> helix_svg_position;

  List<ContextMenuItem> Function(Strand strand,
      {@required Substrand substrand,
      @required Address address,
      @required ModificationType type}) context_menu_strand;
}

class DesignMainStrandDomainNameProps = UiProps with DesignMainStrandDomainNamePropsMixin;

class DesignMainStrandDomainNameComponent extends UiComponent2<DesignMainStrandDomainNameProps>
    with PureComponent {
  @override
  render() {
    Point<num> start_svg =
        props.helix.svg_base_pos(props.domain.start, props.domain.forward, props.helix_svg_position.y);
    Point<num> end_svg =
        props.helix.svg_base_pos(props.domain.end - 1, props.domain.forward, props.helix_svg_position.y);
    Point<num> mid_svg = (start_svg + end_svg) * 0.5;

    String baseline = props.domain.forward ? 'baseline' : 'hanging';

    // offset depends on whether we are showing DNA, so they don't overlap
    num offset_of_dna = props.show_dna ? props.helix.geometry.base_height_svg : 0;

    var dy = props.geometry.base_height_svg * 0.7 + offset_of_dna;
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
      ..className = constants.css_selector_domain_name_text)(props.domain.name);
  }

  String id() => props.domain.id + '_name';

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
