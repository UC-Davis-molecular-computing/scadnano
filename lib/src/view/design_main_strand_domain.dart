import 'dart:html';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:color/color.dart';
import 'package:over_react/over_react.dart';

import '../state/strand.dart';
import '../app.dart';
import '../state/helix.dart';
import '../state/domain.dart';
import '../util.dart' as util;
import '../state/selectable.dart';
import '../actions/actions.dart' as actions;
import 'pure_component.dart';
import '../state/context_menu.dart';

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
  List<ContextMenuItem> Function(Strand strand) context_menu_strand;
}

class DesignMainDomainProps = UiProps with DesignMainDomainPropsMixin;

@Component2()
class DesignMainDomainComponent extends UiComponent2<DesignMainDomainProps> with PureComponent {
  @override
  render() {
    Domain domain = props.domain;
    String id = domain.id();

    Point<num> start_svg = props.helix.svg_base_pos(domain.offset_5p, domain.forward);
    Point<num> end_svg = props.helix.svg_base_pos(domain.offset_3p, domain.forward);

    return (Dom.line()
      ..onClick = _handle_click
      ..stroke = props.color.toHexColor().toCssString()
      ..transform = props.transform
      ..x1 = '${start_svg.x}'
      ..y1 = '${start_svg.y}'
      ..x2 = '${end_svg.x}'
      ..y2 = '${end_svg.y}'
      ..key = id
      ..id = id
      ..className = 'domain-line')(Dom.svgTitle()(tooltip_text(domain) + '\n' + props.strand_tooltip));
  }

  _handle_click(SyntheticMouseEvent event_syn) {
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

      if (edit_mode_is_nick()) {
        if (offset <= domain.start + 1 || offset >= domain.end - 1) {
          return; // need remaining substrands to be length at least 2
        }
        app.dispatch(actions.Nick(domain: domain, offset: offset));
      } else if (edit_mode_is_insertion()) {
        app.dispatch(actions.InsertionAdd(domain: domain, offset: offset));
      } else if (edit_mode_is_deletion()) {
        app.dispatch(actions.DeletionAdd(domain: domain, offset: offset));
      }
    }
  }

  // needed for capturing right-click events with React:
  // https://medium.com/@ericclemmons/react-event-preventdefault-78c28c950e46
  @override
  componentDidMount() {
    var element = querySelector('#${props.domain.id()}');
    element.addEventListener('contextmenu', on_context_menu);
  }

  @override
  componentWillUnmount() {
    var element = querySelector('#${props.domain.id()}');
    element.removeEventListener('contextmenu', on_context_menu);
    super.componentWillUnmount();
  }

  on_context_menu(Event ev) {
    MouseEvent event = ev;
    if (!event.shiftKey) {
      event.preventDefault();
      event.stopPropagation();
      app.dispatch(actions.ContextMenuShow(
          context_menu:
              ContextMenu(items: props.context_menu_strand(props.strand).build(), position: event.page)));
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
    (domain.label == null ? "" : "\n    label=${domain.label.toString()}");
